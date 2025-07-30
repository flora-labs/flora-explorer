# Flora Explorer Deployment Guide

## Current Status
- **Live URL**: http://flora-explorer-1753896988.s3-website-us-west-1.amazonaws.com
- **S3 Bucket**: flora-explorer-1753896988 (us-west-1)
- **Deployment Command**: `bun run deploy`

## Quick Deploy
```bash
bun run deploy
```

This command will:
1. Build the Vue app with Vite
2. Sync files to S3 bucket
3. Configure S3 for static website hosting

## Deploy with Custom Domain (https://explorer.flora.network)
See [DEPLOY_CUSTOM_DOMAIN.md](./DEPLOY_CUSTOM_DOMAIN.md) for full instructions.

Quick steps:
1. Request SSL certificate in ACM
2. Run `./deploy-with-cloudfront.sh <CERTIFICATE_ARN>`
3. Update DNS with CloudFront domain

## Files
- `package.json` - Contains deploy scripts
- `deploy-with-cloudfront.sh` - Automated CloudFront deployment
- `cloudfront-config.json` - CloudFront configuration template
- `DEPLOY_CUSTOM_DOMAIN.md` - Detailed custom domain instructions