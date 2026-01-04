# Task Decomposition Guide

## Overview

This guide explains how to create and manage tasks with sub-issues in the MachineNativeOps repository, following the [AI Behavior Contract](.github/AI-BEHAVIOR-CONTRACT.md) principles.

## Why Task Decomposition?

Following the **AI Behavior Contract Section 3: Proactive Task Decomposition**, we decompose large or complex tasks into manageable sub-tasks to:

1. **Improve Clarity**: Each sub-task has a clear, focused objective
2. **Enable Parallel Work**: Multiple contributors can work on different sub-tasks
3. **Track Progress**: Visual progress tracking through GitHub's task list feature
4. **Reduce Risk**: Smaller tasks are easier to review, test, and rollback
5. **Enhance Accountability**: Clear ownership and dependencies

## Creating a Task with Sub-Issues

### Step 1: Choose the Right Template

Navigate to [New Issue](../../issues/new/choose) and select:
- **📋 Task with Sub-Issues** - For complex work requiring decomposition

### Step 2: Fill Out the Template

Follow the structured template to provide:

1. **Task Overview**: High-level description of what needs to be done
2. **Complexity Assessment**: Helps determine if decomposition is needed
3. **Category**: Maps to governance dimensions (00-80) or system layers
4. **Sub-Tasks Breakdown**: Use GitHub's task list syntax:
   ```markdown
   - [ ] Sub-task 1: Implement configuration loader
   - [ ] Sub-task 2: Add validation logic (depends on Sub-task 1)
   - [ ] Sub-task 3: Write integration tests
   ```

5. **Execution Plan**: Recommended order with rationale
6. **Dependencies**: Files, systems, or team members needed
7. **Acceptance Criteria**: Clear definition of "done"
8. **Priority**: P0-P3 classification

### Step 3: Convert Sub-Tasks to Issues (Optional)

GitHub supports converting task list items to issues:

1. Hover over a task list item in the issue
2. Click the circle icon that appears
3. Select "Convert to issue"
4. This creates a linked sub-issue with automatic tracking

**Example:**
```markdown
Parent Issue: #100 - Implement Monitoring System
- #101 Sub-issue: Set up metrics collection
- #102 Sub-issue: Configure alerting rules
- #103 Sub-issue: Create dashboard views
```

## Task Decomposition Principles

### Atomic Sub-Tasks

Each sub-task should be:
- ✅ **Independent**: Can be completed without other sub-tasks (unless dependencies are explicit)
- ✅ **Testable**: Has clear success criteria
- ✅ **Reviewable**: Small enough for focused code review
- ✅ **Documented**: Changes include necessary documentation updates

### Dependencies

Clearly mark dependencies:
```markdown
- [ ] Sub-task 1: Create schema definition
- [ ] Sub-task 2: Implement validator (depends on Sub-task 1)
- [ ] Sub-task 3: Add CLI interface (depends on Sub-task 2)
```

### Ownership

Assign sub-tasks to specific team members or AI agents:
```markdown
- [ ] @alice: Design API endpoints
- [ ] @bob: Implement authentication
- [ ] @agent-security: Run security scan
```

## Integration with AI Behavior Contract

This task template enforces AI Behavior Contract principles:

### 1. No Vague Excuses
- **Required Inputs** field forces specificity
- **Dependencies** section identifies blockers upfront

### 2. Binary Responses with Specifics
- **Expected Outputs** defines deliverables
- **Acceptance Criteria** provides clear completion definition

### 3. Proactive Task Decomposition
- **Sub-Tasks Breakdown** field is required
- **Execution Plan** ensures thought-out approach
- **Complexity** dropdown triggers decomposition awareness

### 4. Draft Mode by Default
- Template encourages planning before implementation
- Review and approval workflow before execution

### 5. Global Optimization
- **Category** field maps to governance framework
- **Governance Compliance** checklist ensures alignment
- **Risk Assessment** considers system-wide impact

## Examples

### Example 1: Simple Task (Low Complexity)

```yaml
Task: Update README with new installation instructions
Complexity: Low
Category: documentation

Sub-Tasks:
- [ ] Add prerequisites section
- [ ] Update installation steps
- [ ] Add troubleshooting section

Execution Plan:
1. Document prerequisites first (foundation)
2. Then installation steps (main content)
3. Finally troubleshooting (reference)

Acceptance Criteria:
- [ ] All sections complete
- [ ] Markdown linting passes
- [ ] Reviewed by documentation team
```

### Example 2: Complex Task (High Complexity)

```yaml
Task: Implement Self-Healing Monitoring System
Complexity: High
Category: 40-self-healing

Sub-Tasks:
- [ ] Design monitoring architecture
- [ ] Implement metrics collection agent
- [ ] Create alerting rules engine
- [ ] Build auto-remediation workflows
- [ ] Add dashboard visualization
- [ ] Write operational runbooks

Execution Plan:
1. Architecture design (foundation)
2. Metrics collection (data layer)
3. Alerting rules (intelligence layer)
4. Auto-remediation (action layer)
5. Dashboard (visibility layer)
6. Runbooks (operational layer)

Rationale: Each layer builds on the previous, allowing
incremental testing and validation.

Dependencies:
- controlplane/baseline/config/monitoring-config.yaml
- workspace/src/governance/40-self-healing/framework.yaml
- Access to Prometheus/Grafana instances
- @team-sre for operational review

Acceptance Criteria:
- [ ] All sub-tasks completed
- [ ] End-to-end tests passing
- [ ] Performance benchmarks met (< 100ms latency)
- [ ] Security scan clean
- [ ] Documentation complete
- [ ] SRE team approval
- [ ] Deployed to staging environment

Success Metrics:
- Detection time: < 30 seconds
- Remediation time: < 2 minutes
- False positive rate: < 5%
- System uptime: > 99.9%
```

## Workflow Integration

### CI/CD Pipeline

Tasks created with this template integrate with:

1. **Baseline Validation**: `.github/workflows/baseline-validation.yml`
2. **Enhanced Validation**: `.github/workflows/enhanced-validation.yml`
3. **Controlplane Integration**: `.github/workflows/controlplane-integration.yml`

### Agent Orchestration

AI agents can:
- Analyze task complexity and suggest decomposition
- Auto-assign sub-tasks based on agent capabilities
- Track progress and update task lists
- Generate completion reports

### Governance Integration

Tasks map to the 55-dimension governance framework:

| Dimension | Mapping |
|-----------|---------|
| 00 | Vision & Strategy alignment |
| 01 | Architecture decisions |
| 10 | Policy enforcement |
| 30 | Agent coordination |
| 40 | Self-healing capabilities |
| 70 | Audit trail generation |
| 80 | Feedback loop integration |

## Best Practices

### DO ✅

- Break tasks into 2-5 sub-tasks (optimal for tracking)
- Use clear, action-oriented language ("Implement X", "Update Y")
- Specify measurable acceptance criteria
- Document dependencies upfront
- Link to related issues/PRs
- Update task lists as work progresses
- Add labels for filtering and search

### DON'T ❌

- Create sub-tasks that are too granular (< 1 hour work)
- Leave dependencies implicit or undocumented
- Skip acceptance criteria definition
- Ignore governance compliance checks
- Create circular dependencies
- Leave tasks open without updates for > 2 weeks

## Automation Features

### Auto-Labeling

Tasks are automatically labeled based on:
- Category selection → adds dimension label (e.g., `dimension/30-agents`)
- Complexity → adds complexity label (e.g., `complexity/high`)
- Priority → adds priority label (e.g., `priority/P1`)

### Task List Conversion

GitHub automatically:
- Tracks completion percentage in issue title
- Shows progress bar in issue list
- Updates parent issue when sub-issues close
- Triggers workflows on task completion

### Integration with Projects

Tasks sync with GitHub Projects:
- Auto-add to project board based on category
- Update status as sub-tasks complete
- Generate burndown charts
- Track velocity metrics

## Monitoring and Reporting

### Progress Tracking

View task progress:
```bash
# List all tasks with completion status
gh issue list --label "task" --json number,title,state,labels

# View specific task details
gh issue view 123 --json number,title,body,taskLists
```

### Analytics

Generate reports:
- Task completion rate by category
- Average time to completion
- Sub-task distribution
- Dependency analysis

## References

- [AI Behavior Contract](.github/AI-BEHAVIOR-CONTRACT.md)
- [Governance Framework](workspace/src/governance/README.md)
- [GitHub Task Lists Documentation](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-task-lists)
- [FHS Implementation](FHS_IMPLEMENTATION.md)
- [Controlplane Usage](controlplane/CONTROLPLANE_USAGE.md)

## Support

For questions or issues with task creation:
1. Check existing [documentation](workspace/docs/)
2. Review [governance guides](workspace/src/governance/)
3. Ask in team Slack channel
4. Create a new issue using the **Documentation** template

---

**Version:** 1.0.0  
**Last Updated:** 2026-01-04  
**Maintainer:** MachineNativeOps Platform Team
