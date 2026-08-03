RecordingStudioUsers installation is intentionally conservative.

The generator copies an initializer and only edits a user model when
`--user-model=...` is explicitly supplied. Install migrations separately:

```bash
bin/rails generate recording_studio_users:migrations
bin/rails db:migrate
```
