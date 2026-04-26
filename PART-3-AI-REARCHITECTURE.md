# Part 3: AI-Assisted Re-Architecture

## Introduction

In Parts 1 and 2, you worked with chaos engineering and tactical robustness improvements. Now you'll explore how AI can help you think bigger: **re-architecting the entire solution** for robustness, scalability, and maintainability.

This part focuses on **working effectively with AI coding assistants** like Claude Code to explore architectural alternatives, evaluate trade-offs, and implement more sophisticated solutions.

## Learning Objectives

- Learn how to prompt AI assistants for architectural guidance
- Compare minimal context vs. detailed context prompting strategies
- Use plan mode to explore solutions before implementation
- Critically evaluate AI-generated architectural proposals
- Document the AI collaboration process

---

## Overview of Exercises

You'll perform **three experiments** with Claude Code, each using a different prompting strategy:

1. **Minimal Context Experiment**: Give vague requirements ("make it robust")
2. **Detailed Context Experiment**: Provide specific architectural goals
3. **Plan Mode Experiment**: Use Claude Code's plan mode for collaborative design

After each experiment, you'll **take notes** on the AI's suggestions, your assessment of them, and what you learned. At the end, we'll discuss the results as a class.

---

## Setup: Preparing Your Environment

Before starting, create a branch for experimentation:

```bash
git checkout -b ai-rearchitecture-experiments
```

This allows you to experiment freely without affecting your main branch.

---

## Experiment 1: Minimal Context ("Make It Robust")

### Objective
See what happens when you give an AI assistant minimal context and vague requirements.

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

Create a file `AI-EXPERIMENT-1-MINIMAL.md`:

```markdown
# Experiment 1: Minimal Context

## Initial Prompt
"Make my application more robust."

## Claude's Response

### Questions Asked
- [List any questions Claude asked]

### Assumptions Made
- [What did Claude assume about the problem?]

### Solutions Proposed
1. [First suggestion]
2. [Second suggestion]
...

### Code Changes Suggested
- [What files did Claude want to modify?]
- [What patterns/technologies did Claude suggest?]

## My Assessment

### Strengths
- [What did Claude get right?]

### Weaknesses
- [What did Claude miss or misunderstand?]

### Surprises
- [Anything unexpected?]

## What I Learned
[Your insights about prompting AI assistants]
```

### Reset After Experiment

```bash
# If you want to discard changes and start fresh
git reset --hard
git clean -fd
```

---

## Experiment 2: Detailed Context (Decoupled Architecture)

### Objective
See how providing specific requirements and architectural goals affects AI suggestions.

### The Prompt

Start a **new conversation** with Claude Code. Provide detailed context:

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
- Does Claude provide implementation guidance?

### Take Notes

Create `AI-EXPERIMENT-2-DETAILED.md`:

```markdown
# Experiment 2: Detailed Context

## Initial Prompt
[Copy your full prompt]

## Claude's Response

### Architecture Proposed
[High-level description or diagram of suggested architecture]

### Components to Add
1. [e.g., "SQS queue between frontend and Lambda"]
   - Purpose: [why]
   - Trade-offs: [what you gain/lose]

2. [Next component]
   ...

### Technologies Suggested
- [List any new AWS services or patterns]

### Implementation Steps Outlined
1. [First step]
2. [Second step]
...

### Trade-offs Explained
- [What trade-offs did Claude identify?]
- [Cost, complexity, latency, etc.]

## My Assessment

### Strengths
- [What solutions seem promising?]
- [What's well-explained?]

### Weaknesses
- [What's impractical?]
- [What's over-engineered?]
- [What's missing?]

### Questions Raised
- [What would you need to research?]
- [What's unclear?]

## Comparison to Experiment 1
- How did detailed context change Claude's suggestions?
- Which approach gave better results?

## What I Learned
[Insights about effective prompting]
```

### Optional: Ask Follow-Up Questions

Try drilling deeper:
- "How would I implement the SQS queue approach with Terraform?"
- "What's the simplest possible improvement I could make?"
- "How would this affect costs?"
- "Show me code for [specific component]"

Document these follow-ups in your notes.

---

## Experiment 3: Plan Mode Collaboration

### Objective
Use Claude Code's plan mode to collaboratively design a solution before implementing.

### What is Plan Mode?

Plan mode lets you:
- Explore solutions without writing code yet
- Discuss trade-offs and alternatives
- Iterate on the design before committing to implementation

### The Workflow

1. **Start a new conversation** with Claude Code

2. **Enter plan mode** (check Claude Code docs for how to activate it)

3. **Provide context and ask for a plan**:

```
I want to improve the robustness of my coffee shop application. Before we write any code, let's create a plan.

Current situation:
- Frontend makes direct synchronous calls to Lambda
- Lambda writes to DynamoDB immediately
- No retry logic or error recovery
- No order status tracking

I want to explore architectural options that:
- Reduce coupling between frontend and backend
- Allow the system to handle temporary failures gracefully
- Don't require major rewrites (incremental improvements are OK)

Let's discuss a few approaches and their trade-offs before deciding on one.
```

4. **Iterate on the plan**:
   - Ask Claude to suggest 2-3 alternative approaches
   - Discuss pros/cons of each
   - Ask clarifying questions
   - Request modifications to the proposals

5. **Refine until you have a clear plan**

6. **Document the plan** before implementing

### Example Iteration Questions

- "What if we wanted to keep the synchronous API but add retry logic?"
- "How does the SQS approach compare to using Step Functions?"
- "What's the minimal viable improvement we could ship this week?"
- "If we had unlimited time, what would the ideal architecture look like?"

### Take Notes

Create `AI-EXPERIMENT-3-PLAN-MODE.md`:

```markdown
# Experiment 3: Plan Mode Collaboration

## Initial Prompt
[Your opening prompt]

## Iteration Log

### Round 1: Initial Proposals
Claude suggested:
1. [Approach 1]
2. [Approach 2]
3. [Approach 3]

### Round 2: Clarifying Questions
I asked: [your question]
Claude responded: [summary]

### Round 3: Refinement
[Continue documenting the back-and-forth]

## Final Plan

### Chosen Approach
[What you decided on]

### Architecture Diagram
[Draw or describe the agreed architecture]

### Components
1. [Component 1]: [purpose]
2. [Component 2]: [purpose]
...

### Implementation Steps
1. [Step 1]
2. [Step 2]
...

### Trade-offs Accepted
- [Trade-off 1]
- [Trade-off 2]

## My Assessment

### What Plan Mode Enabled
- [How was this different from experiments 1 & 2?]
- [What was better about the collaborative approach?]

### Quality of Final Plan
- [Is this plan better than the previous experiments?]
- [Is it practical and implementable?]
- [What would you change?]

### The Collaboration Experience
- [How did it feel to work with Claude in plan mode?]
- [Did the back-and-forth improve the solution?]
- [What worked well? What didn't?]

## What I Learned
[Insights about using AI for architectural design]
```

---

## Optional: Implement the Plan

If time permits and you found a promising architecture in Experiment 3:

1. **Exit plan mode** and ask Claude to help implement
2. **Work incrementally**: Pick one component to implement first
3. **Test thoroughly** using your ToxiProxy setup from Part 1
4. **Document** what worked and what needed adjustment

Create `AI-EXPERIMENT-3-IMPLEMENTATION.md` if you do this:

```markdown
# Implementation of Plan Mode Architecture

## Plan Summary
[Brief recap of chosen architecture]

## Implementation Steps Taken
1. [What you built first]
2. [What you built second]
...

## Code Changes
- [Files modified]
- [New files created]
- [Key patterns implemented]

## Testing Results
- [How you tested]
- [What worked]
- [What broke]
- [How you fixed issues]

## Delta: Plan vs Reality
- [What changed during implementation?]
- [What was harder than expected?]
- [What was easier than expected?]

## Final Assessment
- [Is the system more robust?]
- [Was the AI's plan accurate?]
- [What would you do differently?]
```

---

## Class Discussion Preparation

After completing the experiments, prepare to discuss:

### Prompting Effectiveness
1. Which prompting strategy worked best?
2. How did context quality affect AI suggestions?
3. When should you give minimal vs detailed context?

### Solution Quality
4. Which experiment produced the best architecture?
5. Did AI suggest anything you wouldn't have thought of?
6. What did AI miss or misunderstand?

### Practical Application
7. When would you use AI for architecture decisions in real work?
8. What are the risks of following AI architectural suggestions?
9. How do you validate AI-generated designs?

### Collaboration Patterns
10. How did plan mode change the process?
11. What role should the human play vs the AI?
12. How do you maintain agency and critical thinking when using AI?

---

## Deliverables

Submit the following files:

1. `AI-EXPERIMENT-1-MINIMAL.md` - Notes from minimal context experiment
2. `AI-EXPERIMENT-2-DETAILED.md` - Notes from detailed context experiment
3. `AI-EXPERIMENT-3-PLAN-MODE.md` - Notes from plan mode collaboration
4. `AI-EXPERIMENT-3-IMPLEMENTATION.md` - (Optional) Implementation notes
5. `AI-EXPERIMENTS-REFLECTION.md` - Your overall reflection:

```markdown
# Overall Reflection on AI-Assisted Architecture

## Key Learnings
1. [Most important lesson]
2. [Second lesson]
3. [Third lesson]

## Best Practices Discovered
- [Prompting strategies that work]
- [How to iterate effectively]
- [When to trust vs question AI]

## Surprises
- [What surprised you?]

## Future Applications
- [How will you use AI assistants in future projects?]
- [What will you be cautious about?]

## Comparison to Traditional Approach
- How is AI-assisted architecture different from:
  - Reading documentation?
  - Asking a senior engineer?
  - Trial and error?

## The Human's Role
- What can AI not do (yet)?
- Where was your expertise critical?
- What decisions should always be human-made?
```

---

## Tips for Success

### Prompting Best Practices
- **Be specific** about constraints (budget, time, team size, existing tech)
- **State your goals** explicitly (performance, cost, maintainability, etc.)
- **Provide context** about what you've tried and what didn't work
- **Ask for trade-offs**, not just solutions
- **Request explanations**, not just code

### Critical Evaluation
- **Don't blindly trust** AI suggestions
- **Research unfamiliar services** - does AWS even have that service?
- **Consider costs** - some AI suggestions can be expensive
- **Think about operations** - can you actually maintain this?
- **Verify with docs** - does the suggested code actually work?

### Effective Iteration
- **Ask "why"** - understand the reasoning behind suggestions
- **Propose alternatives** - "what if we used X instead of Y?"
- **Challenge assumptions** - "why do you assume we need that?"
- **Request simpler options** - "what's the absolute minimal change?"

---

## Bonus Challenges

### Challenge 1: Cost Analysis
Ask Claude to estimate AWS costs for each proposed architecture. Compare to current costs.

### Challenge 2: Migration Plan
Ask Claude to create a step-by-step migration plan from current architecture to the improved one, with rollback strategy.

### Challenge 3: Testing Strategy
Ask Claude to suggest how to test the new architecture, including chaos engineering scenarios.

### Challenge 4: Documentation
Ask Claude to generate architecture decision records (ADRs) for the chosen approach.

---

## Resources

- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Martin Fowler - Patterns of Distributed Systems](https://martinfowler.com/articles/patterns-of-distributed-systems/)
- [Release It! by Michael Nygard](https://pragprog.com/titles/mnee2/release-it-second-edition/)

---

## Conclusion

This exercise demonstrates that AI coding assistants are powerful tools for **exploring architectural options** and **learning new patterns**, but they require:

- **Effective prompting** to get useful suggestions
- **Critical evaluation** to separate good ideas from impractical ones
- **Domain knowledge** to ask the right questions
- **Human judgment** to make final decisions

The best results come from **collaboration**: using AI to augment your thinking, not replace it.

---

## Next Steps

After Part 3, you'll have experienced:
1. **Chaos engineering** to discover failure modes
2. **Tactical improvements** to handle specific failures
3. **Strategic re-architecture** with AI assistance

In the final discussion, we'll synthesize these experiences and discuss how to apply these practices in real-world projects.
