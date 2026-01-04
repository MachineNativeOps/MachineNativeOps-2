#!/usr/bin/env python3
"""
Task Creator - AI-assisted task creation with decomposition

This script helps create well-structured tasks with sub-issues following
the AI Behavior Contract principles of proactive task decomposition.

Usage:
    python3 create-task.py --interactive
    python3 create-task.py --from-file task.yaml
    python3 create-task.py --analyze "Implement new monitoring system"

Requirements:
    - PyGithub: pip install PyGithub
    - pyyaml: pip install pyyaml
"""

import argparse
import json
import os
import sys
from typing import Dict, List, Optional
import yaml

try:
    from github import Github
except ImportError:
    print("Error: PyGithub not installed. Run: pip install PyGithub")
    sys.exit(1)


class TaskDecomposer:
    """Analyzes tasks and suggests decomposition"""
    
    COMPLEXITY_KEYWORDS = {
        'low': ['update', 'fix', 'add', 'remove', 'simple', 'quick'],
        'medium': ['implement', 'create', 'refactor', 'enhance', 'improve'],
        'high': ['design', 'architecture', 'system', 'integrate', 'migrate'],
        'critical': ['platform', 'infrastructure', 'security', 'compliance']
    }
    
    CATEGORY_KEYWORDS = {
        '00-vision-strategy': ['strategy', 'vision', 'roadmap', 'planning'],
        '01-architecture': ['architecture', 'design', 'structure', 'pattern'],
        '30-agents': ['agent', 'automation', 'ai', 'orchestration'],
        '40-self-healing': ['healing', 'recovery', 'resilience', 'monitoring'],
        'documentation': ['docs', 'documentation', 'readme', 'guide'],
        'security': ['security', 'vulnerability', 'compliance', 'audit']
    }
    
    def analyze_task(self, description: str) -> Dict:
        """Analyze task description and suggest metadata"""
        description_lower = description.lower()
        
        # Detect complexity
        complexity = 'medium'  # default
        for level, keywords in self.COMPLEXITY_KEYWORDS.items():
            if any(kw in description_lower for kw in keywords):
                complexity = level
                break
        
        # Detect category
        category = 'other'
        for cat, keywords in self.CATEGORY_KEYWORDS.items():
            if any(kw in description_lower for kw in keywords):
                category = cat
                break
        
        # Suggest decomposition
        words = description.split()
        should_decompose = len(words) > 10 or complexity in ['high', 'critical']
        
        return {
            'complexity': complexity,
            'category': category,
            'should_decompose': should_decompose,
            'suggested_subtasks': self._suggest_subtasks(description, complexity)
        }
    
    def _suggest_subtasks(self, description: str, complexity: str) -> List[str]:
        """Suggest sub-task breakdown"""
        if complexity == 'low':
            return [
                f"Complete main work: {description}",
                "Add tests",
                "Update documentation"
            ]
        elif complexity == 'medium':
            return [
                "Design and plan approach",
                f"Implement core functionality: {description}",
                "Add comprehensive tests",
                "Update documentation and examples"
            ]
        elif complexity in ['high', 'critical']:
            return [
                "Architecture design and review",
                "Implement phase 1: Core components",
                "Implement phase 2: Integration layer",
                "Add comprehensive test suite",
                "Security and compliance review",
                "Documentation and runbooks",
                "Deployment and monitoring setup"
            ]
        return []


class TaskCreator:
    """Creates GitHub issues using the task template"""
    
    def __init__(self, token: Optional[str] = None):
        self.token = token or os.getenv('GITHUB_TOKEN')
        if not self.token:
            raise ValueError("GitHub token required. Set GITHUB_TOKEN env var or pass --token")
        
        self.gh = Github(self.token)
        self.decomposer = TaskDecomposer()
    
    def create_task(self, repo_name: str, task_data: Dict) -> str:
        """Create a task issue on GitHub"""
        repo = self.gh.get_repo(repo_name)
        
        # Build issue body from template
        body = self._build_issue_body(task_data)
        
        # Create issue
        issue = repo.create_issue(
            title=f"[Task]: {task_data['title']}",
            body=body,
            labels=self._get_labels(task_data)
        )
        
        return issue.html_url
    
    def _build_issue_body(self, data: Dict) -> str:
        """Build issue body matching the template format"""
        subtasks = '\n'.join(f"- [ ] {task}" for task in data.get('subtasks', []))
        
        acceptance = '\n'.join(f"- [ ] {criterion}" for criterion in data.get('acceptance_criteria', []))
        
        body = f"""### Is there an existing issue for this?

- [x] I have searched the existing issues

### Task Overview

{data.get('overview', 'No overview provided')}

### Task Complexity

{data.get('complexity', 'Medium').capitalize()}

### Category

{data.get('category', 'other')}

### Sub-Tasks Breakdown

{subtasks}

### Execution Plan

{data.get('execution_plan', 'No execution plan provided')}

### Dependencies

{data.get('dependencies', 'None')}

### Acceptance Criteria

{acceptance}

### Priority

{data.get('priority', 'P2 - Medium')}

### Required Inputs

{data.get('required_inputs', 'None specified')}

### Expected Outputs

{data.get('expected_outputs', 'No outputs specified')}

### Success Metrics

{data.get('success_metrics', 'No metrics specified')}

### Governance Compliance

{self._format_compliance_checks(data.get('governance_compliance', {}))}

### Risk Assessment

{data.get('risk_assessment', 'No risks identified')}

### Additional Context

{data.get('additional_context', 'None')}

### Contribution

{self._format_contribution(data.get('contribution', []))}
"""
        return body
    
    def _format_compliance_checks(self, compliance: Dict) -> str:
        """Format governance compliance checkboxes"""
        checks = [
            ('fhs', 'Task follows FHS 3.0 compliance guidelines'),
            ('immutability', 'Task aligns with controlplane immutability principles'),
            ('validation', 'Task includes proper validation and audit trails'),
            ('contract', 'Task follows AI Behavior Contract principles')
        ]
        
        lines = []
        for key, label in checks:
            checked = 'x' if compliance.get(key, False) else ' '
            lines.append(f"- [{checked}] {label}")
        
        return '\n'.join(lines)
    
    def _format_contribution(self, contributions: List[str]) -> str:
        """Format contribution checkboxes"""
        all_options = [
            'I will implement this task',
            'I can help with testing',
            'I can help with code review',
            'I can help with documentation'
        ]
        
        lines = []
        for option in all_options:
            checked = 'x' if option in contributions else ' '
            lines.append(f"- [{checked}] {option}")
        
        return '\n'.join(lines)
    
    def _get_labels(self, data: Dict) -> List[str]:
        """Get labels for the issue"""
        labels = ['task', 'triage']
        
        # Add complexity label
        complexity = data.get('complexity', 'medium').lower()
        labels.append(f'complexity/{complexity}')
        
        # Add priority label
        priority = data.get('priority', 'P2')
        if priority.startswith('P'):
            labels.append(f'priority/{priority[:2]}')
        
        return labels


def interactive_mode():
    """Interactive task creation"""
    print("🚀 Task Creator - Interactive Mode")
    print("=" * 50)
    
    decomposer = TaskDecomposer()
    
    # Get task description
    print("\n1. Task Description:")
    title = input("   Enter task title: ").strip()
    overview = input("   Enter detailed overview: ").strip()
    
    # Analyze task
    print("\n🔍 Analyzing task...")
    analysis = decomposer.analyze_task(f"{title} {overview}")
    
    print(f"\n   Suggested complexity: {analysis['complexity'].upper()}")
    print(f"   Suggested category: {analysis['category']}")
    
    complexity = input(f"   Confirm complexity [{analysis['complexity']}]: ").strip() or analysis['complexity']
    category = input(f"   Confirm category [{analysis['category']}]: ").strip() or analysis['category']
    
    # Get sub-tasks
    print("\n2. Sub-Tasks:")
    print("   Suggested breakdown:")
    for i, task in enumerate(analysis['suggested_subtasks'], 1):
        print(f"     {i}. {task}")
    
    use_suggested = input("\n   Use suggested sub-tasks? [Y/n]: ").strip().lower() != 'n'
    
    if use_suggested:
        subtasks = analysis['suggested_subtasks']
    else:
        print("   Enter sub-tasks (empty line to finish):")
        subtasks = []
        while True:
            task = input(f"     Sub-task {len(subtasks) + 1}: ").strip()
            if not task:
                break
            subtasks.append(task)
    
    # Get other details
    print("\n3. Additional Details:")
    execution_plan = input("   Execution plan: ").strip()
    priority = input("   Priority [P0/P1/P2/P3] (default P2): ").strip() or "P2"
    
    # Build task data
    task_data = {
        'title': title,
        'overview': overview,
        'complexity': complexity,
        'category': category,
        'subtasks': subtasks,
        'execution_plan': execution_plan,
        'priority': f"{priority} - {'Critical' if priority == 'P0' else 'High' if priority == 'P1' else 'Medium' if priority == 'P2' else 'Low'}",
        'acceptance_criteria': [
            'All sub-tasks completed',
            'Tests passing',
            'Documentation updated',
            'Code reviewed'
        ],
        'governance_compliance': {
            'fhs': True,
            'immutability': True,
            'validation': True,
            'contract': True
        }
    }
    
    # Save to file
    print("\n4. Save Configuration:")
    save = input("   Save to YAML file? [y/N]: ").strip().lower() == 'y'
    
    if save:
        filename = input("   Filename [task.yaml]: ").strip() or "task.yaml"
        with open(filename, 'w') as f:
            yaml.dump(task_data, f, default_flow_style=False)
        print(f"   ✅ Saved to {filename}")
    
    # Create issue
    create = input("\n   Create GitHub issue? [y/N]: ").strip().lower() == 'y'
    
    if create:
        repo = input("   Repository [MachineNativeOps/machine-native-ops]: ").strip() or "MachineNativeOps/machine-native-ops"
        
        try:
            creator = TaskCreator()
            url = creator.create_task(repo, task_data)
            print(f"\n✅ Task created successfully!")
            print(f"   URL: {url}")
        except Exception as e:
            print(f"\n❌ Error creating task: {e}")
    else:
        print("\n📋 Task data prepared but not created on GitHub")


def main():
    parser = argparse.ArgumentParser(
        description='AI-assisted task creation with decomposition',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Interactive mode
  python3 create-task.py --interactive
  
  # From YAML file
  python3 create-task.py --from-file task.yaml --repo MachineNativeOps/machine-native-ops
  
  # Analyze task complexity
  python3 create-task.py --analyze "Implement self-healing monitoring system"
        """
    )
    
    parser.add_argument('--interactive', '-i', action='store_true',
                       help='Interactive task creation mode')
    parser.add_argument('--from-file', '-f', type=str,
                       help='Create task from YAML file')
    parser.add_argument('--analyze', '-a', type=str,
                       help='Analyze task description and suggest decomposition')
    parser.add_argument('--repo', '-r', type=str,
                       default='MachineNativeOps/machine-native-ops',
                       help='GitHub repository (owner/repo)')
    parser.add_argument('--token', '-t', type=str,
                       help='GitHub personal access token (or set GITHUB_TOKEN env var)')
    
    args = parser.parse_args()
    
    if args.interactive:
        interactive_mode()
    elif args.analyze:
        decomposer = TaskDecomposer()
        analysis = decomposer.analyze_task(args.analyze)
        
        print("\n📊 Task Analysis")
        print("=" * 50)
        print(f"Complexity: {analysis['complexity'].upper()}")
        print(f"Category: {analysis['category']}")
        print(f"Should decompose: {'Yes' if analysis['should_decompose'] else 'No'}")
        print("\nSuggested sub-tasks:")
        for i, task in enumerate(analysis['suggested_subtasks'], 1):
            print(f"  {i}. {task}")
    elif args.from_file:
        with open(args.from_file) as f:
            task_data = yaml.safe_load(f)
        
        try:
            creator = TaskCreator(args.token)
            url = creator.create_task(args.repo, task_data)
            print(f"✅ Task created: {url}")
        except Exception as e:
            print(f"❌ Error: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
