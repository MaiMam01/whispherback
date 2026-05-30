# WhisperBack Admin Panel (Phase 2)

Next.js dashboard for user metrics, storage, crash rates, and Premium flag management.

## Planned stack

- Next.js 14 (App Router)
- AWS Amplify hosting
- Cognito admin auth (separate from mobile user pool)

## Endpoints consumed

See [docs/api-contracts.md](../docs/api-contracts.md) — `/admin/*` routes.

## Bootstrap (Phase 2)

```bash
npx create-next-app@latest admin --typescript --app --eslint
cd admin
npm install
npm run dev
```

Status: **stub** — implement in Phase 2 after local MVP QA sign-off.
