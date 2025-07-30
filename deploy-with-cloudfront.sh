#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Flora Explorer Deployment Script${NC}"
echo "=================================="

# Check if certificate ARN is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: ./deploy-with-cloudfront.sh <ACM_CERTIFICATE_ARN>${NC}"
    echo ""
    echo "Steps to get certificate ARN:"
    echo "1. Request certificate:"
    echo "   aws acm request-certificate --domain-name explorer.flora.network --validation-method DNS --region us-east-1"
    echo ""
    echo "2. Validate it in ACM console"
    echo ""
    echo "3. Get ARN:"
    echo "   aws acm list-certificates --region us-east-1"
    exit 1
fi

CERT_ARN=$1

# Update CloudFront config with certificate ARN
echo -e "${YELLOW}Updating CloudFront configuration...${NC}"
sed -i.bak "s|REPLACE_WITH_YOUR_CERTIFICATE_ARN|$CERT_ARN|g" cloudfront-config.json

# Build the application
echo -e "${YELLOW}Building application...${NC}"
bun run build-only

# Sync to S3
echo -e "${YELLOW}Syncing to S3...${NC}"
aws s3 sync dist/ s3://flora-explorer-1753896988 --delete --region us-west-1

# Ensure S3 website is configured
echo -e "${YELLOW}Configuring S3 website...${NC}"
aws s3 website s3://flora-explorer-1753896988 --index-document index.html --error-document index.html --region us-west-1

# Create or update CloudFront distribution
echo -e "${YELLOW}Creating CloudFront distribution...${NC}"
DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}CloudFront distribution created: $DISTRIBUTION_ID${NC}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Wait for distribution to deploy (15-20 minutes)"
    echo "2. Get CloudFront domain name:"
    echo "   aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text"
    echo "3. Create CNAME record in Route 53:"
    echo "   - Name: explorer"
    echo "   - Value: [CloudFront domain from step 2]"
else
    echo -e "${RED}Error creating distribution. It might already exist.${NC}"
    echo "To list existing distributions:"
    echo "aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==\`Flora Explorer\`].Id' --output text"
fi

# Restore original config
mv cloudfront-config.json.bak cloudfront-config.json