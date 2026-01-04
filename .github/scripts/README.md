# Task Creation Scripts

This directory contains scripts and tools for creating well-structured tasks with sub-issues.

## Files

### Scripts

- **`create-task.py`** - AI-assisted task creation tool with interactive mode
- **`requirements.txt`** - Python dependencies for task scripts

### Examples

- **`examples/task-example.yaml`** - Complete example of a task configuration file

## Quick Start

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Interactive Mode

```bash
python3 create-task.py --interactive
```

This will guide you through creating a well-structured task step-by-step.

### From YAML File

```bash
python3 create-task.py --from-file examples/task-example.yaml
```

### Analyze Task Complexity

```bash
python3 create-task.py --analyze "Implement new monitoring system"
```

## Features

- ✅ AI-powered task complexity analysis
- ✅ Automatic category detection
- ✅ Sub-task decomposition suggestions
- ✅ GitHub issue creation with proper formatting
- ✅ Governance compliance validation
- ✅ Priority and label auto-assignment

## Environment Variables

- `GITHUB_TOKEN` - GitHub personal access token (required for creating issues)

## See Also

- [Task Decomposition Guide](../TASK_DECOMPOSITION_GUIDE.md)
- [AI Behavior Contract](../AI-BEHAVIOR-CONTRACT.md)
- [Issue Templates](../ISSUE_TEMPLATE/)
