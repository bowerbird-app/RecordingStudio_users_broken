RecordingStudioUsers installation is intentionally conservative.

1. Review `config/initializers/recording_studio_users.rb`.
2. Include `RecordingStudioUsers::User` in your user model (or rerun this generator with `--user-model=User`).
3. Run `bin/rails generate recording_studio_users:migrations`.
4. Run `bin/rails db:migrate`.
5. Provision users explicitly with `RecordingStudioUsers::Services::ProvisionUser`.

No routes, authentication callbacks, access grants, attachments, or admin screens were added.
