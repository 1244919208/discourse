# frozen_string_literal: true

DiscourseAutomation::Triggerable.add(DiscourseAutomation::Triggers::POST_CREATED_EDITED) do
  field :action_type,
        component: :choices,
        extra: {
          content: [
            {
              id: "created",
              name: "discourse_automation.triggerables.post_created_edited.created",
            },
            { id: "edited", name: "discourse_automation.triggerables.post_created_edited.edited" },
          ],
        }
  field :restricted_archetype,
        component: :choices,
        extra: {
          content: [
            { id: "regular", name: "discourse_automation.triggerables.post_created_edited.topics" },
            {
              id: "private_message",
              name: "discourse_automation.triggerables.post_created_edited.personal_messages",
            },
          ],
        }
  field :restricted_categories, component: :categories
  field :exclude_subcategories, component: :boolean
  field :restricted_tags, component: :tags
  field :restricted_groups, component: :groups
  field :restricted_user_group, component: :group
  field :ignore_automated, component: :boolean
  field :ignore_group_members, component: :boolean
  field :valid_trust_levels, component: :"trust-levels"
  field :original_post_only, component: :boolean
  field :first_post_only, component: :boolean
  field :first_topic_only, component: :boolean
  field :skip_via_email, component: :boolean

  placeholder :topic_url
  placeholder :topic_title
end
