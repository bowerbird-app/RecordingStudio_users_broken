# Foundation summary

The engine owns user-root identity and immutable profile snapshots. RecordingStudio owns recording identity and event
history. The host owns authentication, authorization expansion, user lifecycle, routes, and optional addon policy.

Safe defaults avoid write-on-read behavior, cross-user access, implicit grants, implicit attachments, and automatic
admin registration.
