# Architecture

## Ownership

- The host `User` remains the authentication and account record.
- `RecordingStudioUsers::UserRoot` is the one-to-one UUID root recordable for that user.
- `RecordingStudioUsers::Profile` is an immutable snapshot below the user root.
- `RecordingStudio::Recording` is the stable profile identity and points at the current snapshot.
- `RecordingStudio::Event` retains the append-only revision timeline.

## Write path

`ProvisionUser` creates missing identity records explicitly and idempotently. `ReviseProfile` locks the root, checks an
optional expected snapshot ID, and calls RecordingStudio's public `Recording#revise` API. Neither service bypasses
RecordingStudio hierarchy validation.

## Read path

Lookup helpers do not call `RecordingStudio.root_recording_for`, because that public helper creates missing roots.
Instead they query the public `RecordingStudio::Recording` model for an existing root and use the documented
`recordings_query` API for the profile child.

## Policy boundary

Policy is evaluated before provisioning, revision, or search. The default policy supports self-service only and denies
search. Loaders and presentation helpers do not make authorization decisions; callers must authorize access to any
user object they expose.
