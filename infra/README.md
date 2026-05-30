# WhisperBack Infrastructure (Phase 2)

AWS serverless backend per Technical Proposal FG-2026-WB-TECH-002.

## Services

| Service | Purpose |
|---------|---------|
| Cognito | User auth (Google + email) |
| DynamoDB | Playlist/schedule metadata sync |
| S3 | Audio file storage (pre-signed URLs) |
| Lambda + API Gateway | Sync orchestrator |
| Amplify | Admin panel hosting |
| CloudWatch | Monitoring |

## Bootstrap (Phase 2)

```bash
cd infra
npm install aws-cdk-lib constructs
cdk init app --language typescript
cdk deploy WhisperBackStaging
```

See [docs/api-contracts.md](../docs/api-contracts.md) for API shapes.

Status: **stub** — deploy after mobile local MVP passes QA checklist.
