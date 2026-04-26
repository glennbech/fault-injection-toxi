# Part 2: Robustness Improvements

## Introduction

Now that you've experienced the chaos of distributed systems firsthand, it's time to make your application more robust. In this part, you'll implement improvements to handle network failures, timeouts, and other issues gracefully.

## Task Overview

Choose **ONE** of the three robustness improvements below to implement. After implementing your chosen improvement:

1. **Deploy** your changes (both Lambda and/or webapp as needed)
2. **Test** using your ToxiProxy setup from Part 1
3. **Observe** how your improvement affects the application behavior
4. **Document** your findings (what worked, what didn't, what you learned)

> **Important**: Implement one improvement at a time. Deploy, test, and observe before moving to the next one.

---

## Option 1: Frontend Retry Logic with Exponential Backoff

### Problem
When the Lambda function is slow or temporarily unavailable, the frontend gives up after a single failed request. Users see an error immediately, even though the backend might recover in a few seconds.

### Current Behavior
In `webapp/src/components/Cart.jsx:32-44`, a single fetch request is made:

```javascript
const response = await fetch(LAMBDA_URL, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(order)
})

if (!response.ok) {
  throw new Error(`HTTP error! status: ${response.status}`)
}
```

### Your Task
Implement a retry mechanism with exponential backoff in the Cart component:

1. **Add retry logic**: If the request fails, retry up to 3 times
2. **Exponential backoff**: Wait 1s, then 2s, then 4s between retries
3. **User feedback**: Update the status message to show retry attempts
4. **Timeout handling**: Add a timeout to each fetch request (e.g., 10 seconds)

### Hints
- Create a `retryFetch()` helper function that wraps the fetch call
- Use `setTimeout()` or `async/await` with delays for backoff
- Consider using `AbortController` for request timeouts
- Update UI to show "Retrying (attempt 2/3)..." messages

### Testing with ToxiProxy
```bash
# Simulate temporary outage (recovers after 5 seconds)
curl -X POST http://localhost:8474/proxies/lambda/toxics \
  -d '{
    "name": "latency_spike",
    "type": "latency",
    "attributes": {"latency": 3000}
  }'

# Try checkout - your retry logic should succeed after 1-2 retries

# Remove toxic
curl -X DELETE http://localhost:8474/proxies/lambda/toxics/latency_spike
```

### Success Criteria
- Application successfully completes checkout even with temporary network issues
- User sees clear feedback about retry attempts
- No duplicate orders are created

---

## Option 2: Lambda Request Validation and Error Handling

### Problem
The Lambda function doesn't validate incoming requests thoroughly. Invalid data can cause crashes or be stored in DynamoDB. There's also no idempotency protection against duplicate requests.

### Current Behavior
In `lambda/main.go:68-79`, minimal validation is performed:

```go
var order Order
if err := json.Unmarshal([]byte(request.Body), &order); err != nil {
  // Only checks if JSON is parsable
  return events.LambdaFunctionURLResponse{
    StatusCode: 400,
    Body: fmt.Sprintf(`{"error": "Invalid request body: %v"}`, err),
  }, nil
}
```

### Your Task
Add comprehensive validation and error handling to the Lambda function:

1. **Request validation**:
   - Verify `order.Items` is not empty
   - Validate that item prices are positive numbers
   - Validate that quantities are positive integers
   - Check that `order.Total` matches the sum of items
   - Ensure `order.Timestamp` is a valid ISO8601 date

2. **Idempotency**:
   - Accept an optional `idempotency_key` in the request
   - Before processing, check if an order with this key already exists
   - Return the existing order if found (preventing duplicates)
   - Store the idempotency key in DynamoDB

3. **Error responses**:
   - Return specific HTTP status codes (400 for validation, 409 for duplicates, 500 for server errors)
   - Include detailed error messages that help debug issues

### Hints
- Create a `validateOrder()` function that returns specific validation errors
- Add `IdempotencyKey` field to the `Order` and `OrderRecord` structs
- Use DynamoDB's `ConditionExpression` to prevent duplicate keys
- Consider adding GSI on `IdempotencyKey` for efficient lookups

### Testing with ToxiProxy
```bash
# Test with duplicate submissions
# In your browser console:
const order = {
  items: [{id: "1", name: "Coffee", price: 15.99, quantity: 1}],
  total: 15.99,
  timestamp: new Date().toISOString(),
  idempotency_key: "test-123"
}

// Send twice - should get same order ID both times
await fetch(LAMBDA_URL, {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify(order)
})
```

### Success Criteria
- Invalid orders are rejected with clear error messages
- Duplicate submissions return the same order ID without creating duplicates
- All validation errors include helpful messages for debugging

---

## Option 3: Circuit Breaker Pattern in Frontend

### Problem
When the Lambda function is completely down, the frontend keeps trying to send requests, leading to poor user experience. Each checkout attempt takes the full timeout period before failing.

### Current Behavior
Every checkout attempt makes a request to the Lambda, regardless of previous failures. If the backend is down, users experience repeated long waits.

### Your Task
Implement the Circuit Breaker pattern in the frontend:

1. **Circuit states**:
   - **Closed**: Normal operation, requests go through
   - **Open**: Too many failures detected, fail fast without making requests
   - **Half-Open**: After timeout, try one request to test if backend recovered

2. **Failure threshold**: Open circuit after 3 consecutive failures

3. **Recovery timeout**: After 30 seconds in Open state, transition to Half-Open

4. **User feedback**:
   - Show when circuit is open ("Service temporarily unavailable, will retry in 25s")
   - Show countdown timer
   - Allow manual "Try Again" button

### Hints
- Create a `CircuitBreaker` class or React hook (e.g., `useCircuitBreaker()`)
- Track failure count and circuit state in React state or localStorage
- Use `setTimeout()` to handle recovery timeout
- Consider showing a different UI when circuit is open

### Implementation Example Structure
```javascript
class CircuitBreaker {
  constructor(failureThreshold = 3, recoveryTimeout = 30000) { ... }

  async execute(fn) {
    if (this.state === 'OPEN') {
      // Check if recovery timeout elapsed
      // If yes, try half-open, otherwise fail fast
    }

    try {
      const result = await fn()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }

  onSuccess() { /* Reset failure count */ }
  onFailure() { /* Increment failures, maybe open circuit */ }
}
```

### Testing with ToxiProxy
```bash
# Simulate complete backend failure
curl -X POST http://localhost:8474/proxies/lambda/toxics \
  -d '{
    "name": "timeout",
    "type": "timeout",
    "attributes": {"timeout": 0}
  }'

# Try checkout 3 times - circuit should open
# Wait for recovery period - circuit should allow one test request

# Remove toxic
curl -X DELETE http://localhost:8474/proxies/lambda/toxics/timeout

# Circuit should close and requests succeed
```

### Success Criteria
- Circuit opens after repeated failures
- Users get immediate feedback when circuit is open
- Circuit recovers automatically when backend comes back
- No wasted requests when backend is known to be down

---

## Deployment and Testing Workflow

### 1. Make Your Changes
Edit the appropriate files (`Cart.jsx` for frontend options, `main.go` for backend option)

### 2. Deploy

**For Lambda changes:**
```bash
cd lambda
AWS_PROFILE=YOUR_PROFILE make upload
cd ../infra/env/prod
AWS_PROFILE=YOUR_PROFILE terraform apply
```

**For Frontend changes:**
```bash
cd webapp
npm run build
# Upload to S3 (use your deployment method)
```

### 3. Test with ToxiProxy
```bash
# Start ToxiProxy if not running
docker run -d --name toxiproxy \
  -p 8474:8474 -p 8000:8000 \
  ghcr.io/shopify/toxiproxy

# Configure proxy (see PART-1-CHAOS.md)
```

### 4. Document Your Findings

Create a file `ROBUSTNESS-FINDINGS.md` with:

```markdown
# Robustness Improvement Findings

## Improvement Implemented
[Option 1, 2, or 3]

## Changes Made
- File changed: ...
- Key code changes: ...

## Testing Performed
- Toxic used: ...
- Test scenario: ...
- Expected behavior: ...
- Actual behavior: ...

## Observations
- What worked well: ...
- What didn't work as expected: ...
- Unexpected discoveries: ...

## Metrics
- Before: [e.g., 100% failure rate with 3s latency]
- After: [e.g., 95% success rate with 3s latency after retries]

## Lessons Learned
[Your insights about building robust distributed systems]
```

---

## Bonus Challenges

If you complete one improvement and want to do more:

1. **Combine improvements**: Implement multiple patterns together
2. **Add monitoring**: Log metrics about failures, retries, circuit state
3. **Add progressive enhancement**:
   - Save cart to localStorage during checkout
   - Implement offline mode with queue
4. **Add health checks**: Create a `/health` endpoint in Lambda, frontend pings it

---

## Questions to Consider

As you implement and test your improvements:

1. What's the trade-off between user experience and backend load?
2. How do you prevent duplicate orders when implementing retries?
3. What happens if the user closes the browser during a retry?
4. How would you monitor the effectiveness of these improvements in production?
5. Which improvement provides the best value for the least complexity?

---

## Next Steps

After completing Part 2, you'll move to **Part 3: AI-Assisted Re-Architecture**, where you'll use Claude Code to explore more significant architectural improvements to make the system truly robust and scalable.
