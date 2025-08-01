# frozen_string_literal: true
describe DiscourseAi::Automation::LlmTriage do
  fab!(:post)
  fab!(:reply) { Fabricate(:post, topic: post.topic, user: Fabricate(:user)) }
  fab!(:llm_model)

  def triage(**args)
    DiscourseAi::Automation::LlmTriage.handle(**args)
  end

  before { enable_current_plugin }

  it "does nothing if it does not pass triage" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["good"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        hide_topic: true,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        automation: nil,
      )
    end

    expect(post.topic.reload.visible).to eq(true)
  end

  it "can hide topics on triage" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        hide_topic: true,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        automation: nil,
      )
    end

    expect(post.topic.reload.visible).to eq(false)
  end

  it "can categorize topics on triage" do
    category = Fabricate(:category)

    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        category_id: category.id,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        automation: nil,
      )
    end

    expect(post.topic.reload.category_id).to eq(category.id)
  end

  it "can reply to topics on triage" do
    user = Fabricate(:user)
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        canned_reply: "test canned reply 123",
        canned_reply_user: user.username,
        automation: nil,
      )
    end

    reply = post.topic.posts.order(:post_number).last

    expect(reply.raw).to eq("test canned reply 123")
    expect(reply.user.id).to eq(user.id)
  end

  it "can add posts to the review queue" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        automation: nil,
      )
    end

    reviewable = ReviewablePost.last

    expect(reviewable.target).to eq(post)
    expect(reviewable.reviewable_scores.first.reason).to include("bad")
  end

  it "can handle spam flags" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        flag_type: :spam,
        automation: nil,
      )
    end

    expect(post.reload).to be_hidden
    expect(post.topic.reload.visible).to eq(false)
  end

  it "can handle spam+silence flags" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        flag_type: :spam_silence,
        automation: nil,
      )
    end

    expect(post.reload).to be_hidden
    expect(post.topic.reload.visible).to eq(false)
    expect(post.user.silenced?).to eq(true)
  end

  it "can handle flag + hide" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        flag_type: :review_hide,
        automation: nil,
      )
    end

    reviewable = ReviewablePost.last

    expect(reviewable.target).to eq(post)
    expect(reviewable.reviewable_scores.first.reason).to include("bad")
    expect(post.reload).to be_hidden
  end

  it "does not silence the user if the flag fails" do
    Fabricate(
      :post_action,
      post: post,
      user: Discourse.system_user,
      post_action_type_id: PostActionType.types[:spam],
    )
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        flag_type: :spam_silence,
        automation: nil,
      )
    end

    expect(post.user.reload).not_to be_silenced
  end

  it "can handle garbled output from LLM" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["Bad.\n\nYo"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        automation: nil,
      )
    end

    reviewable = ReviewablePost.last

    expect(reviewable&.target).to eq(post)
  end

  it "treats search_for_text as case-insensitive" do
    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "BAD",
        flag_post: true,
        automation: nil,
      )
    end

    reviewable = ReviewablePost.last

    expect(reviewable.target).to eq(post)
  end

  it "includes post uploads when triaging" do
    post_upload = Fabricate(:image_upload, posts: [post])

    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        automation: nil,
      )

      triage_prompt = DiscourseAi::Completions::Llm.prompts.last

      expect(triage_prompt.messages.last[:content].last).to eq({ upload_id: post_upload.id })
    end
  end

  it "includes stop_sequences in the completion call" do
    sequences = %w[GOOD BAD]

    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do |spy|
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        automation: nil,
        stop_sequences: sequences,
      )

      expect(spy.model_params[:stop_sequences]).to contain_exactly(*sequences)
    end
  end

  it "append rule tags instead of replacing them" do
    tag_1 = Fabricate(:tag)
    tag_2 = Fabricate(:tag)
    post.topic.update!(tags: [tag_1])

    DiscourseAi::Completions::Llm.with_prepared_responses(["bad"]) do
      triage(
        post: post,
        model: llm_model.id.to_s,
        system_prompt: "test %%POST%%",
        search_for_text: "bad",
        flag_post: true,
        tags: [tag_2.name],
        automation: nil,
      )
    end

    expect(post.topic.reload.tags).to contain_exactly(tag_1, tag_2)
  end
end
