"""
Tests for governance framework
"""
import importlib.util
from pathlib import Path
from types import ModuleType

import pytest


def load_structure_module(governance_root: Path) -> ModuleType:
    """Load structure_baseline without mutating sys.path."""
    module_path = governance_root / "structure_baseline.py"
    spec = importlib.util.spec_from_file_location("structure_baseline", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # type: ignore[call-arg]
    return module


@pytest.fixture
def baseline(governance_root: Path) -> ModuleType:
    return load_structure_module(governance_root)

def test_governance_structure_exists(governance_root):
    """Test that governance structure exists"""
    assert governance_root.exists()
    assert (governance_root / "README.md").exists()

def test_dimensions_exist(governance_root, baseline):
    """Test that all dimension directories exist"""
<<<<<<< HEAD
    # Note: 10-stakeholder moved to _legacy/10-stakeholder (2025-12-12)
    # Now using 10-policy for layered governance framework
=======
    expected_dims = [
        "00-vision-strategy", "01-architecture", "02-decision",
        "03-change", "04-risk", "05-compliance", "06-security",
        "07-audit", "08-process", "09-performance", "10-stakeholder",
        "11-tools-systems", "12-culture-capability", 
        "13-metrics-reporting", "14-improvement"
    ]
    
    for dim in expected_dims:
        dim_path = governance_root / dim
        assert dim_path.exists(), f"Dimension {dim} does not exist"
>>>>>>> origin/alert-autofix-37

    missing = baseline.missing_items(governance_root, baseline.REQUIRED_DIMENSIONS)
    assert not missing, f"Missing dimensions: {missing}"

def test_root_files_exist(governance_root, baseline):
    """Test that root files exist"""
    missing = baseline.missing_items(governance_root, baseline.REQUIRED_ROOT_FILES)
    assert not missing, f"Missing root files: {missing}"
