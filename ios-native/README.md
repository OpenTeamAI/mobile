# OpenTeam Portal Native iOS

This is the phased native iOS rebuild for OpenTeam Portal. It is intentionally
separate from the current React Native WebView wrapper in `../app` so the
existing App Store build can stay stable while the native app reaches parity.

## Targets

- Bundle identifier: `com.openteam.portal`
- Marketing version: `1.1`
- Build number: `4`
- Minimum iOS: `15.1`
- UI framework: SwiftUI
- Networking: `URLSession` + async/await
- Streaming: native Server-Sent Events parser
- Session storage: Keychain
- Cache storage: Core Data-backed JSON payload cache

## Current Implementation Slice

- Native app shell, auth flow, team picker, chat list/detail, composer, settings
  sheets, and structured workspace renderer scaffold.
- Strongly typed Portal/Codex models matching the current web API shape.
- API client wired to production health/config/version, official apps catalog,
  email-code auth, gateway teams, and gateway-scoped Codex chat APIs.
- The home composer opens native Connected apps and Skills sheets backed by
  `GET /api/v1/apps/official/catalog`.
- No WebView or iframe fallback is included.

## Production Contract

The native app follows the current Portal HTTP contract:

- `GET /health`
- `GET /api/config`
- `GET /api/version`
- `GET /api/v1/apps/official/catalog`
- `POST /api/v1/auths/email/code`
- `POST /api/v1/auths/email/verify`
- `GET /api/v1/gateways/teams`
- `GET /api/v1/codex/chats?gateway_id=:gatewayId`
- `GET /api/v1/codex/chats/:chatId?gateway_id=:gatewayId`
- `POST /api/v1/codex/chats/:chatId/messages/stream?gateway_id=:gatewayId`
- `POST /api/v1/codex/chats/:chatId/stop?gateway_id=:gatewayId`

Workspace and workflow screens also require every mobile-visible view to expose
`view_model`; HTML-only views are intentionally not rendered by this app.

## Build

Open `OpenTeamPortal.xcodeproj`, or run:

```sh
xcodebuild -project OpenTeamPortal.xcodeproj -scheme OpenTeamPortal -sdk iphonesimulator build
```

## Tests

```sh
xcodebuild -project OpenTeamPortal.xcodeproj -scheme OpenTeamPortal -sdk iphonesimulator -destination 'platform=iOS Simulator,id=B9DF08AB-D2A4-47D4-8687-845BB2A7370D' test
xcodebuild -project OpenTeamPortal.xcodeproj -scheme OpenTeamPortal -sdk iphonesimulator -destination 'platform=iOS Simulator,id=B9DF08AB-D2A4-47D4-8687-845BB2A7370D' -only-testing:OpenTeamPortalTests/PortalLiveSmokeTests/testAppReviewAuthTeamChatDetailSmoke OTHER_SWIFT_FLAGS='-D OPENTEAM_LIVE_SMOKE' test
xcodebuild -project OpenTeamPortal.xcodeproj -scheme OpenTeamPortal -sdk iphonesimulator -destination 'platform=iOS Simulator,id=B9DF08AB-D2A4-47D4-8687-845BB2A7370D' -only-testing:OpenTeamPortalUITests/PortalAppReviewUITests/testAppReviewLoginLoadsChatDetail OTHER_SWIFT_FLAGS='-D OPENTEAM_UI_SMOKE' test
```
