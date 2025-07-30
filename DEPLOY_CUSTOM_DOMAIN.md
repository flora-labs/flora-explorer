# Deploy to explorer.flora.network - Quick Guide

## Step 1: Request SSL Certificate
```bash
aws acm request-certificate \
  --domain-name explorer.flora.network \
  --validation-method DNS \
  --region us-east-1
```

## Step 2: Validate Certificate
1. Go to AWS Certificate Manager (ACM) in us-east-1
2. Find your certificate request
3. Add the CNAME record to your DNS (Route 53 or external)
4. Wait for validation (usually ~5 minutes)

## Step 3: Get Certificate ARN
```bash
aws acm list-certificates --region us-east-1
```

## Step 4: Deploy with CloudFront
```bash
./deploy-with-cloudfront.sh arn:aws:acm:us-east-1:XXXX:certificate/YYYY
```

## Step 5: Update DNS
After CloudFront deploys (15-20 mins), create CNAME:
- Name: `explorer`
- Value: `dxxxxx.cloudfront.net` (from deployment output)

## Alternative: Manual Steps

### S3 Only (no HTTPS):
```bash
bun run deploy
```
Access at: http://flora-explorer-1753896988.s3-website-us-east-1.amazonaws.com

### With Custom Domain (HTTPS):
1. Certificate in ACM (us-east-1)
2. CloudFront distribution
3. CNAME in DNS

---

**Current S3 Bucket**: flora-explorer-1753896988  
**Region**: us-west-1  
**S3 URL**: http://flora-explorer-1753896988.s3-website-us-west-1.amazonaws.com