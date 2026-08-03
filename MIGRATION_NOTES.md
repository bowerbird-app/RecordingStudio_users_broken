# Migration notes

This repository is now `recording_studio_users` with the Ruby namespace `RecordingStudioUsers`.

Host applications moving from the starter repository must:

1. replace the old path gem name with `recording_studio_users`;
2. run `recording_studio_users:install` and `recording_studio_users:migrations`;
3. include `RecordingStudioUsers::User` in the host user model;
4. provision existing users explicitly with `RecordingStudioUsers::Services::ProvisionUser`;
5. define a host policy before enabling cross-user reads, search, or admin behavior.

There is no automatic data backfill or authentication callback.
