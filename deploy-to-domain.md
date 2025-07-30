# Deploy to explorer.flora.network

## Prerequisites
- Domain `flora.network` managed in Route 53 (or ability to update DNS)
- AWS CLI configured

## Steps

### 1. Request SSL Certificate in ACM (us-east-1)
```bash
aws acm request-certificate \
  --domain-name explorer.flora.network \
  --validation-method DNS \
  --region us-east-1
```

### 2. Create CloudFront Distribution
```bash
aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json
```

### 3. Update Route 53 (or your DNS)
Create CNAME record:
- Name: explorer
- Value: [CloudFront distribution domain]

## CloudFront Configuration
The S3 bucket (flora-explorer-1753896988) needs:
- Origin: S3 website endpoint (not S3 API endpoint)
- Viewer Protocol Policy: Redirect HTTP to HTTPS
- Alternate Domain Names: explorer.flora.network
- SSL Certificate: ACM certificate from step 1
- Default Root Object: index.html
- Error Pages: 404 → /index.html (for SPA routing)