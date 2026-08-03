# Optional integration status

Sources were inspected on 2026-08-03. Optional gems are not runtime dependencies of this engine.

## RecordingStudioAccessible

Verified source: `0.4.1`, commit `ee481b78ddcd9c38e729965bf3e21a3319adcb31`.

Public `RecordingStudioAccessible.grant_access(recording:, actor:, role:, manager_actor:)` exists. Its grant service
calls `AccessManagementPolicy`, whose default authorizer requires the manager actor to already have the admin role.
There is no public first-grant or bootstrap entry point.

`RecordingStudioUsers::Integrations::Accessible.grant_first_access!` therefore raises
`IntegrationUnavailableError`. A host may define and audit its own bootstrap policy, then call Accessible's public
grant API. This engine does not mutate Accessible configuration temporarily or create access recordables directly.

## RecordingStudioAttachable

Verified source: `0.2.0`, commit `0e16f93503b66663b759d303f757c3d66d8f0a8e`.

The public capability API supports attachment upload/query/revision and fixed image variants. It does not expose a
singleton attachment constraint or a profile-avatar delivery abstraction. Enabling generic attachments would not
guarantee one active avatar or define a provider-neutral presentation contract.

`RecordingStudioUsers::Integrations::Attachable.install_profile_avatar!` therefore raises
`IntegrationUnavailableError`. No Attachable internals are called.

## RecordingStudioAdmin

Verified source: `1.1.0`, commit `1d60015619eb2cdad774435b588bc89b2bd29dee`.

Public `RecordingStudioAdmin::Resource` and `RecordingStudioAdmin.register_resource` APIs exist. Set
`config.register_admin_resource = true` only in a host that has loaded a compatible Admin version and registered the
configured `admin_section_key`. Registration is reload-safe through Admin's public registry.

Admin `1.1.0` currently declares `recording_studio_accessible ~> 0.3`, while the newest inspected Accessible tag is
`0.4.1`. This engine does not add or force either optional dependency; the host must resolve a compatible set.
