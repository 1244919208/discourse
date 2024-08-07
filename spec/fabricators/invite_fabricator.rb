# frozen_string_literal: true

Fabricator(:invite) do
  invited_by(fabricator: :user)
  email "iceking@ADVENTURETIME.ooo"
end

Fabricator(:invited_group) do
  group
  invite
end
