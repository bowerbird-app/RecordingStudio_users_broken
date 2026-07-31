# RecordingStudioUsers

`recording_studio_users` is a Rails engine for provisioning users in RecordingStudio-based applications.

## What it provides

- Devise-oriented user provisioning hooks
- One private `UserRoot` per user
- Append-only `Profile` revisions with stable current-profile pointer
- Avatar metadata tracking with policy-aware helper APIs
- View helpers for user name, avatar, and identity text
- Generators for install, migrations, user integration, and profile backfill

## Installation

```ruby
gem "recording_studio_users"
```

Then run:

```bash
bundle install
bin/rails generate recording_studio_users:install
bin/rails db:migrate
```

## Host User model

```ruby
class User < ApplicationRecord
  include RecordingStudioUsers::User
end
```

## Public API highlights

- `RecordingStudioUsers.provision(user, actor: nil)`
- `RecordingStudioUsers.provisioned?(user)`
- `RecordingStudioUsers.user_root_for(user)`
- `RecordingStudioUsers.profile_for(user)`
- `RecordingStudioUsers.revise_profile(user:, actor:, attributes:, impersonator: nil)`
- `RecordingStudioUsers.upload_avatar(user:, signed_blob_id:, actor:, impersonator: nil)`
- `RecordingStudioUsers.remove_avatar(user:, actor:, impersonator: nil)`
- `RecordingStudioUsers.display_name(user, context: nil)`
- `RecordingStudioUsers.initials(user, context: nil)`
- `RecordingStudioUsers.avatar_for(user, size: :medium, context: nil)`
- `RecordingStudioUsers.preload_user_information(users, include: %i[profile avatar], context: nil)`

## Notes

This repository still includes `docs/gem_template/` as historical template reference material.
