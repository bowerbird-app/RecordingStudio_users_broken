RecordingStudioUsers install complete.

Next steps:

1. Review `config/initializers/recording_studio_users.rb`.
2. Run `bin/rails generate recording_studio_users:migrations`.
3. Run `bin/rails db:migrate`.
4. Ensure `User` includes `RecordingStudioUsers::User`.
5. Run `bin/rails generate recording_studio_users:backfill_profiles` for existing users.
6. Verify sign up/sign in, profile edit, and avatar flows.
