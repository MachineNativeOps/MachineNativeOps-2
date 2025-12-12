"""
Tests for governance framework
"""
import sys
from pathlib import Path

import pytest

sys.path.append(str(Path(__file__).resolve().parents[2]))
from structure_baseline import (  # noqa: E402
    REQUIRED_DIMENSIONS,
    REQUIRED_ROOT_FILES,
    missing_items,
)

def test_governance_structure_exists(governance_root):
    """Test that governance structure exists"""
    assert governance_root.exists()
    assert (governance_root / "README.md").exists()

def test_dimensions_exist(governance_root):
    """Test that all dimension directories exist"""
    # Note: 10-stakeholder moved to _legacy/10-stakeholder (2025-12-12)
    # Now using 10-policy for layered governance framework

    missing = missing_items(governance_root, REQUIRED_DIMENSIONS)
    assert not missing, f"Missing dimensions: {missing}"

def test_root_files_exist(governance_root):
    """Test that root files exist"""
    missing = missing_items(governance_root, REQUIRED_ROOT_FILES)
    assert not missing, f"Missing root files: {missing}"
