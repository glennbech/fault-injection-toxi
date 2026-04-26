# Chaos Engineering Lab: Building Antifragile Systems

## Overview

This hands-on lab teaches chaos engineering principles through practical experimentation with a real-world web application. You will deploy **Coffee Chaos** - a premium coffee bean e-commerce store - with a containerized microservice backend, intentionally inject failures using ToxiProxy, observe how the system degrades, and then implement resilience patterns to make it antifragile.

Coffee Chaos is a React-based single-page application featuring six specialty coffee varieties from around the world. Users can browse products with detailed tasting notes, add items to their cart, adjust quantities, and complete checkout. Orders are posted to a Go microservice and stored in DynamoDB. The entire application runs locally in Docker containers, making it easy to experiment with network failures in a controlled environment.

This lab is divided into three parts:
- **Part 1:** Deploy the system, run chaos experiments, observe failures
- **Part 2:** Implement tactical robustness improvements (choose one: retries, validation, or circuit breaker)
- **Part 3:** Use AI to explore strategic re-architecture for resilience

By the end of this lab, you will understand:
- How distributed systems fail under stress
- The scientific method of chaos engineering
- Practical resilience patterns: retries, timeouts, circuit breakers, validation
- How to use AI assistants effectively for architectural design
- How to build systems that improve from failure

## Getting Started with GitHub Codespaces

This lab is designed to run in GitHub Codespaces, which provides a complete development environment in your browser.

### Launch Your Codespace

1. Fork or clone this repository to your GitHub account
2. Click the green "Code" button
3. Select the "Codespaces" tab
4. Click "Create codespace on main"

GitHub will automatically set up your environment with:
- Terraform pre-installed
- Go toolchain for microservice development
- Docker for running ToxiProxy
- AWS CLI pre-configured
- All dependencies ready to use

Your Codespace will be ready in 1-2 minutes. No local installation required!

## Architecture

```mermaid
graph LR
    A[Web Browser] -->|HTTP| B[React Webapp<br/>Port 3000]
    B -->|HTTP POST| C[ToxiProxy<br/>Port 8000]
    C -->|Proxy| D[Go Microservice<br/>Port 8080]
    D -->|AWS SDK| E[(DynamoDB Table)]

    style A fill:#e1f5ff,stroke:#01579b
    style B fill:#e8f5e9,stroke:#1b5e20
    style C fill:#fff3e0,stroke:#e65100
    style D fill:#f3e5f5,stroke:#4a148c
    style E fill:#e8f5e9,stroke:#1b5e20
```

**How it works:**
- Users browse coffee products and add them to their shopping cart in the React webapp (port 3000)
- When users click checkout, orders are posted via HTTP to a Go microservice
- **ToxiProxy sits between the webapp and microservice to inject network failures** (port 8000)
- The Go microservice processes orders and stores them in DynamoDB (port 8080)
- All services run in Docker containers orchestrated by Docker Compose

**About ToxiProxy:**
ToxiProxy was created by Shopify to simulate network conditions and test application resilience in distributed systems. It acts as a transparent TCP proxy that can inject various network failures (latency, timeouts, bandwidth limits) on demand through a simple HTTP API. Originally built for Shopify's microservices infrastructure, it's now widely used across the industry to test how applications behave under adverse network conditions. Learn more at the [ToxiProxy GitHub repository](https://github.com/Shopify/toxiproxy).

### Docker Compose Setup

The application uses three interconnected Docker containers that start with a single command:

1. **webapp** (React + Vite on port 3000)
   - Serves the frontend application with hot-reload enabled
   - Configured to send requests to ToxiProxy on port 8000

2. **toxiproxy** (ports 8000 and 8474)
   - Acts as a transparent proxy between webapp and Go service
   - Port 8000: Proxy endpoint (webapp → toxiproxy → go-service)
   - Port 8474: Control API for injecting network failures

3. **go-service** (port 8080)
   - HTTP server that processes order requests
   - Connects to AWS DynamoDB using SDK
   - Requires AWS credentials via environment variables

All containers communicate through a Docker bridge network (`chaos-network`).

### Configure Environment Variables

Before starting the services, you need to set up environment variables for AWS credentials.

**Create a `.env` file in the root directory:**

```bash
# AWS Credentials (required)
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_SESSION_TOKEN=your_session_token_here  # If using temporary credentials

# AWS Configuration
AWS_REGION=eu-north-1

# Application Configuration
STUDENT_ID=your-unique-id  # Replace with your name (lowercase, no spaces)
TABLE_NAME=chaos-coffee-your-unique-id  # DynamoDB table name (will be set after Terraform)
```

**Important:** The `TABLE_NAME` will be updated after you deploy infrastructure with Terraform in Step 3.

## Lab Structure

This lab follows the chaos engineering cycle:

1. **Steady State**: Understand how the system works normally
2. **Hypothesis**: Predict how it will fail under stress
3. **Experiment**: Inject real-world failures
4. **Observation**: Measure the impact
5. **Improvement**: Implement resilience patterns
6. **Validation**: Verify the improvements

---

# Part 1: Chaos Engineering Experiments

In Part 1, you will deploy a deliberately fragile system, run chaos experiments, and observe how it fails.

## Step 1: Familiarize with the Code

Explore the repository structure using the VS Code file explorer.

### Explore the Go Microservice

Open `service/main.go` in the VS Code editor.

**Key observations:**
- The HTTP handler accepts POST requests with JSON payload
- It stores data in DynamoDB with `student_id` as partition key
- Simple error handling with basic logging
- Runs as a standalone HTTP server in Docker

### Explore the Web Application

The webapp is a React single-page application built with Vite. Open these key files in VS Code:

- `webapp/src/App.jsx` - Main application component
- `webapp/src/components/Cart.jsx` - Shopping cart with checkout logic
- `webapp/src/data/products.js` - Six specialty coffee products

**Key observations:**
- React with Vite build tool
- Six premium coffee products with detailed tasting notes
- Shopping cart with add/remove functionality and quantity controls
- Makes POST requests to microservice endpoint on checkout
- **No retry logic** - failures show immediately
- Basic error handling displays error messages but doesn't retry failed requests

### Explore the Infrastructure

Open the Terraform files in VS Code:

- `infra/main.tf` - Main infrastructure definition
- `infra/variables.tf` - Input variables
- `infra/outputs.tf` - Output values

**Key observations:**
- Terraform module that requires `student_id` variable
- Creates DynamoDB table with on-demand billing
- IAM role with DynamoDB permissions

## Step 2: Deploy DynamoDB Infrastructure

Before starting the application, you need to create the DynamoDB table using Terraform.

From your Codespace terminal, create a deployment directory:

```bash
mkdir -p deployment
cd deployment
```

Create a `main.tf` file that uses the module:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

module "coffee_chaos" {
  source = "../infra"

  student_id = "YOUR_NAME_HERE"  # Replace with your name (lowercase, no spaces)
}

output "dynamodb_table_name" {
  value = module.coffee_chaos.dynamodb_table_name
  description = "DynamoDB table for storing orders"
}
```

Deploy the infrastructure:

```bash
terraform init
terraform plan
terraform apply
```

**Save the output!** Copy the `dynamodb_table_name` value - you'll need it in the next step.

## Step 3: Start All Services with Docker Compose

Now that you have the DynamoDB table, update your `.env` file with the table name from Terraform output:

```bash
TABLE_NAME=chaos-coffee-your-student-id  # Use the actual table name from Terraform
```

Return to the project root directory and start all services with a single command:

```bash
cd /workspace/itevu4340  # Or your project root
docker-compose up -d
```

This command will:
1. Build the Go microservice Docker image
2. Start the microservice on port 8080
3. Start ToxiProxy on port 8000 (proxy) and 8474 (control API)
4. Start the React webapp on port 3000
5. Create a shared Docker network for inter-container communication

Verify all containers are running:

```bash
docker-compose ps
```

You should see all three services (go-service, toxiproxy, webapp) with status "Up".

## Step 4: Access and Test the Application

### Open the Webapp in Your Browser

The webapp is now running on port 3000. In GitHub Codespaces:

1. Click the "Ports" tab at the bottom of VS Code
2. Find port 3000 (webapp)
3. Click the globe icon to open in your browser

The webapp should be accessible at a URL like: `https://[codespace-name]-3000.preview.app.github.dev`

### Test Normal Operation

1. Browse the six specialty coffee products
2. Add items to your cart (observe the smooth animations)
3. Adjust quantities using the + and - buttons
4. Click the "Checkout" button

**What should happen:**
- The order is sent to the microservice via HTTP POST through ToxiProxy
- The microservice stores the order in DynamoDB
- You'll see a success message
- The cart clears automatically

If you see errors, check:
- Docker containers are running (`docker-compose ps`)
- DynamoDB table name is configured correctly in `docker-compose.yml`
- AWS credentials are set in your environment
- DynamoDB table was created successfully

**Document your observation:**
- How fast is the checkout process?
- What feedback does the UI provide?
- How responsive does the application feel?

## Step 5: Hypothesize About Network Failures

Before injecting chaos, make predictions using the scientific method.

**Write down your hypothesis:**

1. **What will happen when we add 2000ms latency?**
   - How will the UI respond?
   - Will users click checkout multiple times?
   - What will happen to DynamoDB (duplicate records)?

2. **What will happen when we add 50% packet loss?**
   - How many requests will fail?
   - Will the UI show errors?
   - What will users think is broken?

3. **What will happen when we add random timeouts?**
   - Will some requests succeed?
   - How will users know if their order worked?

**Save your hypotheses** - you'll compare them to actual results.

## Step 6: Configure ToxiProxy

ToxiProxy is already configured and running from Step 2. It sits between your webapp and the Go microservice to inject network failures.

### How ToxiProxy is Configured

The `docker-compose.yml` file configures ToxiProxy to:
- Listen on port 8000 (proxy endpoint)
- Forward requests to the Go microservice on port 8080
- Expose port 8474 for the control API (to inject failures)

All services run in the same Docker network, so they can communicate using container names:

```yaml
toxiproxy:
  image: ghcr.io/shopify/toxiproxy:latest
  ports:
    - "8000:8000"  # Proxy endpoint
    - "8474:8474"  # Control API
  networks:
    - app-network
```

The webapp is pre-configured in `webapp/src/config.js` to use ToxiProxy:

```javascript
export const SERVICE_URL = 'http://localhost:8000';  // Through ToxiProxy
```

### Add Latency Toxic

Use curl to add toxics via the ToxiProxy HTTP API:

```bash
# Add 2000ms latency
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{"name": "latency", "type": "latency", "attributes": {"latency": 2000}}'
```

### Managing Toxics with curl

ToxiProxy provides an HTTP API on port 8474 for managing network failures.

**List all active toxics:**
```bash
curl http://localhost:8474/proxies/chaos-proxy/toxics
```

**Add a toxic:**
```bash
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "my-toxic-name",
    "type": "latency",
    "attributes": {"latency": 2000}
  }'
```

**Delete a specific toxic** (toxic name goes at the end of the URL):
```bash
curl -X DELETE http://localhost:8474/proxies/chaos-proxy/toxics/my-toxic-name
```

**Check proxy status:**
```bash
curl http://localhost:8474/proxies/chaos-proxy
```

**Troubleshooting:** If you get a 404 error, the proxy might not be loaded. Restart ToxiProxy:
```bash
docker-compose restart toxiproxy
# Wait a few seconds, then verify
curl http://localhost:8474/proxies
```

### Available Toxic Types

ToxiProxy supports many failure modes you can inject beyond the latency example we've seen:

**Latency:** Add delay to requests
```bash
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{"name": "slow-response", "type": "latency", "attributes": {"latency": 2000, "jitter": 500}}'
```
- `latency`: Base delay in milliseconds
- `jitter`: Random variation (±jitter ms)

**Timeout:** Close connection after delay
```bash
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{"name": "connection-timeout", "type": "timeout", "attributes": {"timeout": 3000}}'
```
- `timeout`: Milliseconds before closing connection

**Bandwidth:** Limit throughput
```bash
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{"name": "slow-network", "type": "bandwidth", "attributes": {"rate": 1024}}'
```
- `rate`: Bytes per second (1024 = 1KB/s)

**Slicer:** Slice data into small packets with delays
```bash
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{"name": "packet-loss", "type": "slicer", "attributes": {"average_size": 64, "size_variation": 32, "delay": 10}}'
```
- `average_size`: Average packet size in bytes
- `size_variation`: Variation in packet size
- `delay`: Delay between packets in milliseconds

## Step 7: Test the Enterprise Architecture Decision

### The Scenario

Your enterprise architect just announced a new mandate:

> **"All API requests must complete within 5 seconds or they will be terminated by our infrastructure."**

**The reasoning:**
- During peak hours (Black Friday, holiday sales), slow requests pile up
- They consume connection pools, memory, and database connections
- This causes cascading failures that crash upstream systems
- The architect's solution: "Kill anything over 5 seconds to protect the infrastructure"

**Your challenge:** Test if this 5-second timeout is safe for your coffee ordering system.

### Current Service Behavior

Your Go microservice calls three external services sequentially:

- **Credit card processing**: ~500-900ms (but can be 2-3x slower during peak)
- **SAP inventory update**: ~600-900ms (but can be 2-3x slower during peak)
- **DHL shipping creation**: ~500-700ms (but can be 2-3x slower during peak)

**Normal conditions:** 2-3 seconds total ✅
**Peak load conditions:** Could be 5-9 seconds total ⚠️

### The Experiments

You'll run three experiments to test the impact of the 5-second timeout under different load conditions.

**Before you start:** Write down your hypothesis for each experiment.

---

### Experiment 1: Baseline - Normal Day (No Chaos)

**Hypothesis:** *What do you expect will happen on a normal day with no external service delays?*

**Setup:** No toxics - test the service in its natural state

**Steps:**
1. Make sure all toxics are cleared:
   ```bash
   curl http://localhost:8474/proxies/chaos-proxy/toxics
   # Should return: []
   ```

2. Place 3-5 orders and observe:
   - Success rate
   - Response times (check browser Network tab)
   - Backend logs: `docker logs -f chaos-coffee-service`

**Expected Result:** All orders should succeed in 2-3 seconds.

---

### Experiment 2: Busy Hour - External Services Under Load

**Hypothesis:** *What happens when external services slow down during a busy hour? Will the 5-second timeout cause problems?*

**Scenario:** Credit card processors and SAP are slower than usual (1.5x delay)

**Setup:**
```bash
# Add 1500ms latency (simulates external services under load)
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "peak-load-latency",
    "type": "latency",
    "attributes": {"latency": 1500}
  }'

# Add 5-second timeout (enterprise architecture rule)
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "enterprise-timeout",
    "type": "timeout",
    "attributes": {"timeout": 5000}
  }'
```

**Service processing time now:** 2-3 seconds + 1.5 seconds = **3.5-4.5 seconds**

**Steps:**
1. Place 10 orders (do this multiple times)
2. Track results in a table:

| Attempt | Frontend Result | Actual Time | Saved to DB? |
|---------|----------------|-------------|--------------|
| 1       | Success/Error  | ~X sec     | Yes/No       |
| 2       | Success/Error  | ~X sec     | Yes/No       |
| ...     | ...            | ...         | ...          |

3. Check DynamoDB after:
   ```bash
   aws dynamodb scan --table-name chaos-coffee-${STUDENT_ID} \
     --query 'Count'
   ```

**What to observe:**
- Do all orders succeed?
- Are any orders close to the 5-second limit?
- What happens to orders that time out?

**Clean up:**
```bash
curl -X DELETE http://localhost:8474/proxies/chaos-proxy/toxics/peak-load-latency
curl -X DELETE http://localhost:8474/proxies/chaos-proxy/toxics/enterprise-timeout
```

---

### Experiment 3: Black Friday - External Services Very Slow

**Hypothesis:** *What happens during peak load (Black Friday) when external services are very slow? Will many orders fail?*

**Scenario:** External services are under heavy load (3x normal delay)

**Setup:**
```bash
# Add 3000ms latency (simulates heavy external load)
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "black-friday-latency",
    "type": "latency",
    "attributes": {"latency": 3000}
  }'

# Add 5-second timeout (enterprise rule)
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "enterprise-timeout",
    "type": "timeout",
    "attributes": {"timeout": 5000}
  }'
```

**Service processing time now:** 2-3 seconds + 3 seconds = **5-6 seconds**

**Steps:**
1. Place 10 orders
2. Observe the failure rate
3. Check backend logs - did the service finish processing even when frontend timed out?
   ```bash
   docker logs chaos-coffee-service --tail 30
   ```
4. Check DynamoDB - how many orders were actually saved?

**Critical Discovery:**
You'll likely find that:
- Frontend shows "Order failed: HTTP error! status: 500"
- But the backend successfully saved many orders to DynamoDB
- Users think their order failed and might try again
- **Result:** Duplicate orders and confused customers

**Clean up:**
```bash
curl -X DELETE http://localhost:8474/proxies/chaos-proxy/toxics/black-friday-latency
curl -X DELETE http://localhost:8474/proxies/chaos-proxy/toxics/enterprise-timeout
```

## Step 8: Reflect and Document Your Findings

Compare your hypothesis to actual observations:

**Analysis Questions:**

1. **What was the worst user experience?**
   - Long waits with no feedback?
   - Silent failures?
   - Duplicate actions?

2. **What resilience patterns would help?**
   - Retries for transient failures?
   - Timeouts to fail fast?
   - Optimistic UI updates?
   - Circuit breaker to prevent cascading failures?
   - Loading indicators and progress feedback?

3. **What should the steady state be?**
   - Response time < 500ms for 99% of requests?
   - No duplicate records?
   - Clear error messages?
   - Graceful degradation under load?

**Document your findings:**

Create a brief report with:
- Hypothesis for each experiment
- Actual observed behavior
- Screenshots or logs showing failures
- List of proposed improvements

Save your findings - you'll implement improvements in Part 2.

---

# Part 2: Robustness Improvements

Now that you've experienced the chaos of distributed systems firsthand, it's time to make your application more robust. In this part, you'll implement improvements to handle network failures, timeouts, and other issues gracefully.

## Task Overview

Choose **ONE** of the three robustness improvements below to implement. After implementing your chosen improvement:

1. **Deploy** your changes (rebuild containers and/or restart webapp as needed)
2. **Test** using your ToxiProxy setup from Part 1
3. **Observe** how your improvement affects the application behavior
4. **Document** your findings (what worked, what didn't, what you learned)

> **Important**: Implement one improvement at a time. Deploy, test, and observe before moving to the next one.

## Option 1: Frontend Retry Logic with Exponential Backoff

### Problem
When the microservice is slow or temporarily unavailable, the frontend gives up after a single failed request. Users see an error immediately, even though the backend might recover in a few seconds.

### Current Behavior
In `webapp/src/components/Cart.jsx:32-44`, a single fetch request is made with no retry logic.

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
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -d '{"name": "latency_spike", "type": "latency", "attributes": {"latency": 3000}}'

# Try checkout - your retry logic should succeed after 1-2 retries

# Remove toxic
curl -X DELETE http://localhost:8474/proxies/chaos-proxy/toxics/latency_spike
```

### Success Criteria
- Application successfully completes checkout even with temporary network issues
- User sees clear feedback about retry attempts
- No duplicate orders are created

## Option 2: Microservice Request Validation and Error Handling

### Problem
The Go microservice doesn't validate incoming requests thoroughly. Invalid data can cause crashes or be stored in DynamoDB. There's also no idempotency protection against duplicate requests.

### Current Behavior
In `service/main.go`, minimal validation is performed - only checks if JSON is parsable.

### Your Task
Add comprehensive validation and error handling to the microservice:

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

### Testing
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
await fetch('http://localhost:8000', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify(order)
})
```

### Success Criteria
- Invalid orders are rejected with clear error messages
- Duplicate submissions return the same order ID without creating duplicates
- All validation errors include helpful messages for debugging

## Option 3: Circuit Breaker Pattern in Frontend

### Problem
When the microservice is completely down, the frontend keeps trying to send requests, leading to poor user experience. Each checkout attempt takes the full timeout period before failing.

### Current Behavior
Every checkout attempt makes a request to the microservice, regardless of previous failures. If the backend is down, users experience repeated long waits.

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

### Testing with ToxiProxy
```bash
# Simulate complete backend failure
curl -X POST http://localhost:8474/proxies/chaos-proxy/toxics \
  -d '{"name": "timeout", "type": "timeout", "attributes": {"timeout": 0}}'

# Try checkout 3 times - circuit should open
# Wait for recovery period - circuit should allow one test request

# Remove toxic
curl -X DELETE http://localhost:8474/proxies/chaos-proxy/toxics/timeout

# Circuit should close and requests succeed
```

### Success Criteria
- Circuit opens after repeated failures
- Users get immediate feedback when circuit is open
- Circuit recovers automatically when backend comes back
- No wasted requests when backend is known to be down

## Deployment Workflow

### For Microservice changes (Option 2):
```bash
# Rebuild and restart the microservice container
docker-compose up -d --build service
```

### For Frontend changes (Options 1 & 3):
The Vite dev server will automatically reload when you save files. If changes don't appear, restart it:
```bash
cd webapp
npm run dev
```

## Document Your Findings

Create a file `ROBUSTNESS-FINDINGS.md` with:

```markdown
# Robustness Improvement Findings

## Improvement Implemented
[Option 1, 2, or 3]

## Changes Made
- Files changed: ...
- Key code changes: ...

## Testing Performed
- Toxic used: ...
- Expected behavior: ...
- Actual behavior: ...

## Observations
- What worked well: ...
- Unexpected discoveries: ...

## Metrics
- Before: [e.g., 100% failure rate with 3s latency]
- After: [e.g., 95% success rate after retries]

## Lessons Learned
[Your insights about building robust distributed systems]
```

---

# Part 3: AI-Assisted Re-Architecture

In Parts 1 and 2, you worked with chaos engineering and tactical robustness improvements. Now you'll explore how AI can help you think bigger: **re-architecting the entire solution** for robustness, scalability, and maintainability.

This part focuses on **working effectively with AI coding assistants** like Claude Code to explore architectural alternatives, evaluate trade-offs, and implement more sophisticated solutions.

## Learning Objectives

- Learn how to prompt AI assistants for architectural guidance
- Compare minimal context vs. detailed context prompting strategies
- Use plan mode to explore solutions before implementation
- Critically evaluate AI-generated architectural proposals
- Document the AI collaboration process

## Overview of Experiments

You'll perform **three experiments** with Claude Code, each using a different prompting strategy:

1. **Minimal Context Experiment**: Give vague requirements ("make it robust")
2. **Detailed Context Experiment**: Provide specific architectural goals
3. **Plan Mode Experiment**: Use Claude Code's plan mode for collaborative design

After each experiment, you'll **take notes** on the AI's suggestions, your assessment of them, and what you learned.

## Experiment 1: Minimal Context

### The Prompt

Start a conversation with Claude Code and say:

```
Make my application more robust.
```

That's it. Don't provide additional context unless Claude asks.

### What to Observe

- What questions does Claude ask?
- What assumptions does Claude make?
- What solutions does Claude propose?
- How specific or generic are the suggestions?
- Does Claude explore the codebase before suggesting changes?

### Take Notes

Create a file `AI-EXPERIMENT-1-MINIMAL.md` documenting:
- Claude's questions and assumptions
- Solutions proposed
- Your assessment (strengths, weaknesses, surprises)
- What you learned about prompting AI

## Experiment 2: Detailed Context

### The Prompt

Start a **new conversation** with detailed requirements:

```
I want to re-architect my coffee shop application for better robustness and decoupling.

Current architecture:
- React frontend with client-side cart state
- Direct synchronous calls to AWS Lambda Function URL
- Lambda writes to DynamoDB immediately
- No CORS headers (intentionally broken for learning)

Problems I want to solve:
1. Frontend is tightly coupled to Lambda - failures affect user experience immediately
2. No way to retry failed orders
3. Orders are lost if Lambda fails after accepting the request
4. No visibility into order status
5. Difficult to test and debug distributed failures

Goals for re-architecture:
- Decouple frontend from backend processing
- Make order submission asynchronous and reliable
- Add order status tracking
- Implement proper error recovery
- Maintain simplicity (this is a learning project, not production)

Technologies I'm already using:
- AWS Lambda, DynamoDB, S3, CloudFront
- React frontend
- Terraform for IaC

Please suggest an architecture that achieves these goals. Explain the trade-offs and what components I'd need to add.
```

### What to Observe

- How does Claude's response differ from Experiment 1?
- Does Claude suggest specific AWS services or patterns?
- Does Claude explain trade-offs?
- Are the suggestions practical given your constraints?

### Take Notes

Create `AI-EXPERIMENT-2-DETAILED.md` documenting:
- Architecture proposed
- Components to add and their trade-offs
- Technologies suggested
- Comparison to Experiment 1
- What you learned

## Experiment 3: Plan Mode Collaboration

### The Workflow

1. Start a **new conversation** and enter **plan mode**
2. Ask Claude to explore multiple architectural options
3. Iterate on the proposals through back-and-forth discussion
4. Refine until you have a clear plan

### Example Iteration

```
I want to improve the robustness of my coffee shop application. Before we write any code, let's create a plan.

Current situation:
- Frontend makes direct synchronous calls to Lambda
- Lambda writes to DynamoDB immediately
- No retry logic or error recovery

I want to explore architectural options that:
- Reduce coupling between frontend and backend
- Allow the system to handle temporary failures gracefully
- Don't require major rewrites (incremental improvements are OK)

Let's discuss a few approaches and their trade-offs before deciding on one.
```

Then iterate with questions like:
- "What if we wanted to keep the synchronous API but add retry logic?"
- "How does the SQS approach compare to using Step Functions?"
- "What's the minimal viable improvement we could ship this week?"

### Take Notes

Create `AI-EXPERIMENT-3-PLAN-MODE.md` documenting:
- The iteration log (questions asked, responses)
- Final plan agreed upon
- How plan mode changed the collaboration
- Quality assessment of the final plan

## Optional: Implement the Plan

If time permits, implement one of the proposed architectures and document what worked vs. what needed adjustment in `AI-EXPERIMENT-3-IMPLEMENTATION.md`.

## Reflection

After completing all experiments, create `AI-EXPERIMENTS-REFLECTION.md`:

```markdown
# Overall Reflection on AI-Assisted Architecture

## Key Learnings
1. [Most important lesson]
2. [Second lesson]
3. [Third lesson]

## Best Practices Discovered
- Prompting strategies that work
- How to iterate effectively
- When to trust vs question AI

## The Human's Role
- What can AI not do (yet)?
- Where was your expertise critical?
- What decisions should always be human-made?
```

## Discussion Questions

Prepare to discuss:

1. Which prompting strategy worked best?
2. Did AI suggest anything you wouldn't have thought of?
3. When would you use AI for architecture decisions in real work?
4. What are the risks of following AI architectural suggestions?
5. How do you validate AI-generated designs?

---

## Cleanup

When you're done with the lab, clean up your resources:

### Stop All Docker Services

From the project root directory:

```bash
docker-compose down
```

This will stop and remove all containers (webapp, toxiproxy, go-service).

### Destroy AWS Infrastructure

From the terminal in your Codespace:

```bash
cd deployment
terraform destroy
```

### Delete Your Codespace

1. Go to https://github.com/codespaces
2. Find your Codespace for this repository
3. Click the three dots menu
4. Select "Delete"

This ensures you don't accumulate storage charges for the Codespace.

## Conclusion

You've completed a full chaos engineering cycle:

1. Built a distributed system
2. Established steady state behavior
3. Hypothesized about failure modes
4. Injected real-world failures
5. Observed degradation
6. Implemented resilience patterns
7. Validated improvements

**Key Learnings:**

- Distributed systems fail in complex ways
- Latency is a common failure mode that cascades
- User experience degrades without proper error handling
- Resilience patterns (retries, timeouts, circuit breakers) are essential
- Chaos engineering helps you find weaknesses before users do
- Antifragile systems improve from stress and failure

## Additional Challenges

1. **Add CloudWatch Alarms** - Alert when microservice errors exceed threshold
2. **Implement Request Deduplication** - Use idempotency keys
3. **Add Caching** - Store orders locally, sync periodically
4. **Multi-Region** - Deploy to two regions for higher availability
5. **Chaos in Production** - Gradually roll out chaos to real users (with safeguards!)

## References

- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [ToxiProxy Documentation](https://github.com/Shopify/toxiproxy)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
