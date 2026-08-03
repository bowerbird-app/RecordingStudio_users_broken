# RecordingStudioUsers

`RecordingStudioUsers` is a data-focused Rails engine for user-owned Recording Studio roots and immutable profile history.
It does not own authentication, routes, access policy, or host user lifecycle callbacks.

## Requirements

- Ruby 3.3+
- Rails 8.1
- PostgreSQL with UUID and JSONB support
- RecordingStudio 3.x
- A host user model with a UUID primary key

The foundation was implemented against RecordingStudio `v3.0.3` (`8db9ca701c862f354363edee460fad9d3b6a0b65`).
RecordingStudio is not currently published on RubyGems, so applications must declare its source:

```ruby
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v3.0.3"
gem "recording_studio_users", github: "bowerbird-app/RecordingStudio_users"
```

## Install

```bash
bundle install
bin/rails generate recording_studio_users:install --user-model=User
bin/rails generate recording_studio_users:migrations
bin/rails db:migrate
```

The append-only guard is a PostgreSQL trigger. Applications that load schema snapshots instead of replaying migrations
must use `config.active_record.schema_format = :sql` so `db:structure:load` preserves it.

Without `--user-model`, the generator only copies the initializer. Add the concern yourself:

```ruby
class User < ApplicationRecord
  include RecordingStudioUsers::User
end
```

The generator deliberately does not mount routes, create users, add authentication callbacks, grant access, install
attachments, or register admin resources.

## Configuration

```ruby
RecordingStudioUsers.configure do |config|
  config.user_class_name = "User"
  config.profile_search_limit = 25

  config.user_name_resolver = ->(user) { user.name.presence || user.email }
  config.user_loader = ->(id:) { User.find_by(id: id) }

  config.policy_resolver = lambda do |actor:, user:, record:|
    MyUsersPolicy.new(actor: actor, user: user, record: record)
  end

  config.profile_searcher = lambda do |query:, relation:, limit:|
    relation.where("LOWER(display_name) LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%")
            .limit(limit)
  end
end
```

Defaults are fail-closed:

- Reads and profile writes are allowed only when actor and user are the same persisted polymorphic identity.
- Cross-user search is denied.
- Search is capped at 100 results.
- Reads never provision records.
- Admin registration is disabled.

Unknown configuration keys and invalid callable contracts raise `RecordingStudioUsers::ConfigurationError`.

## Provisioning and profile revisions

Provision explicitly after the host application has created and authorized a user:

```ruby
result = RecordingStudioUsers::Services::ProvisionUser.call(
  user: current_user,
  actor: current_user,
  profile_attributes: {
    display_name: "Ada Lovelace",
    locale: "en"
  }
)
```

Provisioning is idempotent. It creates:

1. one UUID `RecordingStudioUsers::UserRoot` for the host user;
2. one Recording Studio root recording;
3. one child profile recording with an immutable `RecordingStudioUsers::Profile` snapshot.

Revise through RecordingStudio's public `Recording#revise` API:

```ruby
profile = RecordingStudioUsers::Services::ReviseProfile.call(
  user: current_user,
  actor: current_user,
  expected_profile_id: current_user.recording_studio_users_profile.id,
  profile_attributes: { display_name: "Ada King" },
  event_metadata: { source: "settings" }
)
```

`expected_profile_id` provides optimistic stale-write protection. A revision creates a new profile row and keeps the
old row referenced by Recording Studio history. No-op revisions return the current snapshot without adding an event.

## Lookup and presentation

These helpers are side-effect free:

```ruby
RecordingStudioUsers.user_root_for(user)
RecordingStudioUsers.root_recording_for(user)
RecordingStudioUsers.profile_recording_for(user)
RecordingStudioUsers.profile_for(user)
RecordingStudioUsers.display_name_for(user)
RecordingStudioUsers.initials_for(user)

user.recording_studio_users_profile
user.recording_studio_users_display_name
```

`RecordingStudioUsers.load_user(id:)` accepts a bounded identifier and enforces that a custom loader returns the
configured user class or `nil`.

`RecordingStudioUsers::Search::Profiles.call(actor:, query:, limit:)` searches active current snapshots only. A custom
search callable receives `query:`, a prefiltered `relation:`, and the normalized `limit:`. It must return profiles or an
Active Record relation of profiles; the engine intersects the result with the active scope and reapplies the limit.

## Optional integrations

See [docs/INTEGRATIONS.md](docs/INTEGRATIONS.md) for verified API status and exact blockers. In summary:

- RecordingStudioAdmin resource registration is supported only when explicitly enabled and its public API is loaded.
- Accessible first-grant bootstrap is not implemented because its current public API authorizes through an existing
  manager grant.
- Attachable profile avatars are not implemented because its current public API has no singleton attachment or
  profile-avatar delivery contract.

No integration uses addon internals.
