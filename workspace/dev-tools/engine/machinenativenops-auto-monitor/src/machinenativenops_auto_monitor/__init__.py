"""
MachineNativeOps Auto-Monitor Module

自動化監控模組，提供全方位的系統監控、告警和數據收集功能。
對齊 MachineNativeOps 標準：
- namespace: machinenativenops
- registry: registry.machinenativeops.io
- certificate: etc/machinenativeops/pkl
- cluster token: super-agent-etcd-cluster
"""

__version__ = "2.0.0"
__author__ = "MachineNativeOps Auto-Monitor Team"
__email__ = "auto-monitor@machinenativeops.io"
__description__ = "MachineNativeOps Auto-Monitor - System monitoring with full compliance"
__namespace__ = "machinenativenops"
__registry__ = "registry.machinenativeops.io"
__certificate_path__ = "etc/machinenativeops/pkl"
__cluster_token__ = "super-agent-etcd-cluster"

from .app import AutoMonitorApp
from .alerts import AlertManager
from .collectors import MetricsCollector
from .config import MonitorConfig
from .storage import DataStorage

__all__ = [
    "AutoMonitorApp",
    "AlertManager", 
    "MetricsCollector",
    "MonitorConfig",
    "DataStorage"
]
