# MVP Scope

## Included

- local settings via `shared_preferences`
- local bedtime state for nightly outcomes
- scheduled local notifications via `flutter_local_notifications`
- timezone-aware reminder scheduling
- one-night-at-a-time summary resolution
- local streak persistence
- Android and iOS friendly setup where possible

## Deferred

- notification action buttons
- background summary processing without app launch
- watch support
- widgets and lock-screen surfaces
- history list or calendar
- backup and device sync
- adaptive reminder timing
- anti-scroll integrations and screen-time APIs

## Platform Notes

- reminder delivery depends on user-granted notification permission
- iOS local notifications cannot guarantee an in-app summary without opening the app
- Android exact timing can still vary because the MVP uses inexact local scheduling to avoid exact-alarm permission complexity
