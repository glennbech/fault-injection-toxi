# Chaos Coffee Lambda Function

This Lambda function receives coffee shop orders from the webapp and stores them in DynamoDB.

## Architecture

- **Runtime:** Go 1.21 (custom runtime on Amazon Linux 2023)
- **Trigger:** Lambda Function URL (no API Gateway)
- **Storage:** DynamoDB table with PK/SK pattern
- **Permissions:** IAM role with DynamoDB PutItem permission
- **Timeout:** 5 seconds (intentionally tight for chaos engineering)

## Order Processing Flow

When an order is received, the Lambda function performs these operations **synchronously**:

1. **Parse and validate** the order request
2. **Save to DynamoDB** - stores the order record
3. **Charge credit card** - mock external call (500-1000ms random delay)
4. **Update SAP ERP** - mock external call (500-1000ms random delay)
5. **Create DHL shipping order** - mock external call (500-1000ms random delay)

**Total processing time:** 1.5-3 seconds (plus DynamoDB latency)

### Mock External Service Delays

The Lambda includes three mock external service calls to simulate real-world dependencies. **Each call has a random delay between 500-1000 milliseconds:**

| Function | Delay | Purpose |
|----------|-------|---------|
| `chargeCreditCard()` | **500-1000ms** | Simulates payment processor API (Stripe, etc.) |
| `updateSAP()` | **500-1000ms** | Simulates enterprise ERP system update |
| `orderShippingDHL()` | **500-1000ms** | Simulates shipping provider API call |

**Total delay range:** 1500-3000ms (1.5-3 seconds) per order

These delays are **intentional** for the chaos engineering lab, demonstrating:
- Long-running synchronous operations that block the Lambda
- Cascading timeouts when external services are slow
- The fragility of distributed synchronous chains
- Why async/event-driven architectures matter in production systems

**Critical Timing Constraint:**
- Lambda timeout: **5 seconds**
- Processing time: **1.5-3 seconds** (mock delays only)
- Remaining buffer: **2-3.5 seconds** for DynamoDB operations and network overhead
- Adding ToxiProxy latency (e.g., 1-2 seconds) will likely cause timeouts!

## Data Model

### DynamoDB Table Structure

```
PK (Partition Key): student_id
SK (Sort Key): ORDER#<uuid>
```

### Order Record

```json
{
  "PK": "john-doe",
  "SK": "ORDER#123e4567-e89b-12d3-a456-426614174000",
  "order_id": "123e4567-e89b-12d3-a456-426614174000",
  "items": [
    {
      "id": "ethiopian-yirgacheffe",
      "name": "Ethiopian Yirgacheffe",
      "price": 18.99,
      "quantity": 2
    }
  ],
  "total": 37.98,
  "timestamp": "2024-01-15T10:30:00.000Z",
  "created_at": "2024-01-15T10:30:05.123Z"
}
```

## Environment Variables

The Lambda function requires these environment variables (set by Terraform):

- `TABLE_NAME`: DynamoDB table name
- `STUDENT_ID`: Student identifier for data partitioning

## Building

Build the Lambda function:

```bash
make build
```

This creates a `bootstrap` binary (required name for custom Go runtime).

## Creating Deployment Package

Create the deployment zip:

```bash
make package
```

This creates `function.zip` containing the `bootstrap` binary.

## Deployment

The function is deployed via Terraform. See `../infra/` directory.

After making code changes:

1. Build and package: `make package`
2. Copy `function.zip` to a location accessible by Terraform
3. Run `terraform apply` from the infra directory

## Testing Locally

You can test the handler with a sample event:

```bash
go run main.go
```

To test with AWS credentials:

```bash
export TABLE_NAME=chaos-coffee-test
export STUDENT_ID=test-student
export AWS_REGION=us-east-1

go run main.go
```

## Intentional Design Choices

### No CORS Headers

This Lambda function **intentionally does not include CORS headers** in the response. This is part of the chaos engineering exercise where students will:

1. First encounter CORS errors when calling the Lambda from the webapp
2. Understand browser security and same-origin policy
3. Learn how to configure CORS properly

**Note for students:** In Part 3 of the lab, you'll need to decide how to handle CORS. Options include:
- Adding CORS headers in the Lambda response
- Configuring CORS in Terraform (for Function URLs)
- Understanding why this is a common failure mode in distributed systems

### Simple Error Handling

The function has basic error handling. Students can improve this by:
- Adding structured logging
- Implementing retry logic
- Adding input validation
- Handling edge cases

## Dependencies

```bash
go mod download
```

Dependencies:
- `aws-lambda-go`: AWS Lambda Go SDK
- `aws-sdk-go-v2`: AWS SDK for Go v2
- `uuid`: UUID generation for order IDs

## Logs

View logs in CloudWatch Logs after deployment:

```bash
aws logs tail /aws/lambda/<function-name> --follow
```

## Cost Considerations

- Lambda: Free tier includes 1M requests/month
- DynamoDB: On-demand pricing (pay per request)
- Logs: CloudWatch Logs retention (configurable)

For this lab, costs should be minimal (< $1) if cleaned up after use.
