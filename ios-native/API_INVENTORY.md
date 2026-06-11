# Native API Inventory

## Existing API Shape Used By The App

- `GET /api/v1/auths/` restores a session and returns the current user plus a
  bearer token.
- `GET /api/v1/auths/signout` signs out the current bearer/cookie session.
- `GET /api/v1/users/user/settings` reads user UI settings.
- `POST /api/v1/users/user/settings/update` updates user UI settings.
- `GET /api/v1/codex/chats` lists chats.
- `POST /api/v1/codex/chats` creates a chat.
- `GET /api/v1/codex/chats/:chatId` loads chat detail.
- `PATCH /api/v1/codex/chats/:chatId` updates chat metadata.
- `POST /api/v1/codex/chats/:chatId/stop` stops a running chat.
- `POST /api/v1/codex/chats/:chatId/messages/stream` streams a message via SSE.
- `GET /api/v1/codex/chats/:chatId/runs/:runId/stream` resumes a run stream.
- `POST /api/v1/codex/chats/:chatId/queue` queues a follow-up message.
- `GET /api/v1/codex/spaces` lists spaces/workplaces.
- `GET /api/v1/codex/spaces/:spaceId/view/status` must return `view_model` for
  native rendering.
- `GET /api/v1/codex/chats/:chatId/view/status` must return `view_model` for
  native rendering.

## Existing HTTP Contract For Native

The web Portal already uses HTTP APIs. Native should follow that contract rather
than waiting for new backend feature work.

- Base URL: `https://portal.openteam.ai`
- App health/config:
  - `GET /health`
  - `GET /api/config`
  - `GET /api/version`
- Official apps catalog:
  - `GET /api/v1/apps/official/catalog`
- Auth/session:
  - `POST /api/v1/auths/email/code`
  - `POST /api/v1/auths/email/verify`
  - `GET /api/v1/auths/`
  - `GET /api/v1/auths/signout`
  - `POST /api/v1/auths/signin` for the existing password-style auth flow.
- Team selection is Gateway Team selection in the current web app:
  - `GET /api/v1/gateways/teams`
  - Each team item has a `gateway_id`; chat APIs use that gateway id.
- Gateway-scoped chat data:
  - `GET /api/v1/codex/chats?gateway_id=:gatewayId`
  - `POST /api/v1/codex/chats` with `gateway_id`
  - `GET /api/v1/codex/chats/:chatId?gateway_id=:gatewayId`
  - `POST /api/v1/codex/chats/:chatId/messages/stream?gateway_id=:gatewayId`
  - `GET /api/v1/codex/chats/:chatId/runs/:runId/stream?gateway_id=:gatewayId`
  - `POST /api/v1/codex/chats/:chatId/stop?gateway_id=:gatewayId`

The iOS client now points at `https://portal.openteam.ai`, consumes
health/config/version/catalog, verifies email/code through the production auth
endpoints, maps `PortalTeam.gateway_id`, and sends that selected gateway id for
chat list/detail/create/stream/view/stop requests.

## Local Backend Verification

```sh
npm run server:build
```

The local Portal backend build completed successfully during API inspection.
Native parity should use the existing HTTP contract above; any auth-specific
shim should be treated as temporary until the production auth API contract is
mapped exactly.

## Production Probe

Production probes on 2026-06-04 confirmed:

- `GET https://portal.openteam.ai/health` returns `200`.
- `GET https://portal.openteam.ai/api/config` returns `200`.
- `GET https://portal.openteam.ai/api/version` returns `200`.
- `GET https://portal.openteam.ai/api/v1/apps/official/catalog` returns `200`.
  The current production catalog includes CanLII, Westlaw Canada, and Bible
  Study.
- `POST https://portal.openteam.ai/api/v1/auths/email/code` returns `201` with
  `success` and `expires_in_seconds`.
- `POST https://portal.openteam.ai/api/v1/auths/email/verify` returns `201` with
  a user object containing `token`.
- `GET https://portal.openteam.ai/api/v1/gateways/teams` requires auth and
  returns team items with `gateway_id`.
- `GET https://portal.openteam.ai/api/v1/codex/chats?gateway_id=...` requires
  auth and returns the App Review chat list.

The opt-in iOS production API smoke covers these public endpoints plus the
App Review auth/team/chat-detail path. The opt-in iOS UI smoke verifies native
rendering for the production catalog sheet and App Review chat detail.

## Mobile Parity Checklist

- Auth: email entry, code entry, session restore, signout.
- Team: list teams, switch active team, preserve last selected team.
- Chat: list, search, detail, markdown response, tool activity, feedback actions.
- Composer: text, model/speed picker, connected apps, skills, attachments, voice.
- Runtime: streaming, stop, queue, resume after reconnect/background.
- Settings: account, appearance, general, team, connected services.
- Workspace/workflow: render `view_model` only; block HTML-only views until backend
  provides structured data.
