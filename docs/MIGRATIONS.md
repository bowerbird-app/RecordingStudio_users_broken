# Migrations

The migrations create:

- `recording_studio_users_user_roots` with a UUID primary key and unique polymorphic host-user identity;
- `recording_studio_users_profiles` with UUID identity, a user-root foreign key, profile fields, JSONB metadata, and
  `created_at` only.

Profile rows intentionally have no `updated_at`. `RecordingStudio::Recordable` rejects update and destroy operations
after persistence, and a PostgreSQL trigger rejects direct SQL updates/deletes. Revisions create new rows through
RecordingStudio. Any legally required erasure needs an explicit, audited migration that temporarily removes this
guard; ordinary application code cannot delete snapshots.

The schema expects PostgreSQL UUID generation to be available and the host user model to use a UUID primary key before
these migrations run. Install RecordingStudio's core migrations first.

Set `config.active_record.schema_format = :sql`. Ruby `schema.rb` dumps do not preserve PostgreSQL trigger functions;
`structure.sql` does.
