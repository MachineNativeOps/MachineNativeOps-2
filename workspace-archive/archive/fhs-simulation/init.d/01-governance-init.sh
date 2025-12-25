#!/bin/bash
# 🏛️ Root 治理系統初始化腳本
# MachineNativeOps Root Layer Governance Initializer - Phase 1
# Version: 1.0.0
# Last Modified: 2025-12-20T22:00:00Z

# =============================================================================
# MachineNativeOps Root Governance System Initializer - Phase 1
# =============================================================================
# This script initializes the governance system for the MachineNativeOps root layer.
# It runs after the basic system initialization and sets up the governance
# framework, policies, and access control mechanisms.
# =============================================================================

# 設定嚴格模式
set -euo pipefail

# === 全域變數 ===
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_PATH="$(dirname "$0")"
readonly LOG_FILE="/var/log/machinenativenops/governance-init.log"
readonly START_TIME=$(date +%s)
readonly MNO_ROOT="/opt/machinenativenops"
readonly MNO_CONFIG="/etc/machinenativenops"
readonly MNO_LOGS="/var/log/machinenativenops"
readonly GOVERNANCE_CONFIG="$MNO_CONFIG/.root.governance.yaml"

# 顏色定義
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# === 日誌函數 ===
log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} ${timestamp} - $*" | tee -a "$LOG_FILE"
}

log_warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $*" | tee -a "$LOG_FILE"
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} ${timestamp} - $*" | tee -a "$LOG_FILE"
}

log_debug() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $*" | tee -a "$LOG_FILE"
}

# === 進度報告函數 ===
show_progress() {
    local current=$1
    local total=$2
    local description=$3
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${PURPLE}[PROGRESS]${NC} ["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%% - %s" $percentage "$description"
}

# === 檢查前置條件 ===
check_prerequisites() {
    log_info "Checking governance initialization prerequisites..."
    
    # 檢查 Phase 0 是否完成
    if [[ ! -f "$MNO_CONFIG/INIT_STATUS" ]] || ! grep -q "Status: Completed" "$MNO_CONFIG/INIT_STATUS"; then
        log_error "Phase 0 initialization must be completed first"
        log_error "Please run 00-init.sh first"
        exit 1
    fi
    
    # 檢查治理配置檔案
    if [[ ! -f "$GOVERNANCE_CONFIG" ]]; then
        log_error "Governance configuration file not found: $GOVERNANCE_CONFIG"
        exit 1
    fi
    
    # 檢查必要目錄
    local required_dirs=(
        "$MNO_CONFIG/policies"
        "$MNO_CONFIG/rules"
        "$MNO_CONFIG/acls"
        "$MNO_LOGS/governance"
        "/var/lib/machinenativenops/governance"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_warn "Creating missing directory: $dir"
            mkdir -p "$dir"
        fi
    done
    
    log_info "Prerequisites check passed"
}

# === 驗證治理配置 ===
validate_governance_config() {
    log_info "Validating governance configuration..."
    
    # 使用 Python 進行 YAML 驗證
    if command -v python3 >/dev/null; then
        python3 -c "
import yaml
import sys

try:
    with open('$GOVERNANCE_CONFIG', 'r') as f:
        config = yaml.safe_load(f)
    
    # 檢查必要的結構
    required_sections = ['apiVersion', 'kind', 'spec']
    for section in required_sections:
        if section not in config:
            print(f'Missing required section: {section}')
            sys.exit(1)
    
    # 檢查規格結構
    spec = config['spec']
    required_spec_sections = ['roles', 'policies', 'audit_rules']
    for section in required_spec_sections:
        if section not in spec:
            print(f'Missing required spec section: {section}')
            sys.exit(1)
    
    print('Governance configuration validation passed')
    
except Exception as e:
    print(f'Configuration validation failed: {e}')
    sys.exit(1)
" 2>/dev/null || {
        log_error "Governance configuration validation failed"
        exit 1
    }
    else
        log_info "Governance configuration is valid"
    fi
}

# === 創建治理角色 ===
create_governance_roles() {
    log_info "Creating governance roles..."
    
    # 從配置檔案提取角色定義
    local roles=(
        "system-administrator:Complete system administration privileges"
        "security-administrator:Security and trust management privileges"
        "module-developer:Module development and management privileges"
        "auditor:Audit and compliance verification privileges"
        "operator:System operation and monitoring privileges"
    )
    
    local total=${#roles[@]}
    local current=0
    
    for role_def in "${roles[@]}"; do
        current=$((current + 1))
        local role_name=$(echo "$role_def" | cut -d':' -f1)
        local role_desc=$(echo "$role_def" | cut -d':' -f2)
        
        show_progress $current $total "Creating role: $role_name"
        
        # 創建角色配置檔案
        cat > "$MNO_CONFIG/roles/${role_name}.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: GovernanceRole
metadata:
  name: $role_name
  namespace: machinenativenops-governance
  labels:
    machinenativeops.io/component: "governance"
    machinenativeops.io/tier: "role"
spec:
  description: "$role_desc"
  permissions:
    - "system:*"
    - "governance:*"
    - "modules:*"
    - "trust:*"
    - "provenance:*"
    - "execution:*"
    - "integrity:*"
  constraints:
    - "audit_required: true"
    - "mfa_required: true"
    - "time_window: business_hours"
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  created_by: $SCRIPT_NAME
EOF
        
        log_debug "Created role: $role_name"
        sleep 0.1
    done
    
    echo
    log_info "Governance roles created"
}

# === 部署治理策略 ===
deploy_governance_policies() {
    log_info "Deploying governance policies..."
    
    # 基本訪問控制策略
    cat > "$MNO_CONFIG/policies/access-control.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: GovernancePolicy
metadata:
  name: access-control-policy
  namespace: machinenativenops-governance
spec:
  description: "Access control and permission management"
  rules:
    - id: "ACL-001"
      name: "require-mfa-admin"
      description: "Require MFA for administrative operations"
      condition: "user.roles contains 'system-administrator' OR user.roles contains 'security-administrator'"
      action: "require_mfa"
      effect: "allow"
      priority: 100
    - id: "ACL-002"
      name: "audit-sensitive-operations"
      description: "Audit all sensitive operations"
      condition: "operation.sensitivity >= 'high'"
      action: "audit_log"
      effect: "allow"
      priority: 90
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    # 數據保護策略
    cat > "$MNO_CONFIG/policies/data-protection.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: GovernancePolicy
metadata:
  name: data-protection-policy
  namespace: machinenativenops-governance
spec:
  description: "Data protection and privacy controls"
  rules:
    - id: "DPP-001"
      name: "encrypt-sensitive-data"
      description: "Encrypt all sensitive data at rest and in transit"
      condition: "data.sensitivity >= 'high'"
      action: "encrypt"
      effect: "require"
      priority: 100
    - id: "DPP-002"
      name: "data-retention-policy"
      description: "Enforce data retention periods"
      condition: "data.type = 'audit_log'"
      action: "retention_period: 7_years"
      effect: "require"
      priority: 90
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    # 變更管理策略
    cat > "$MNO_CONFIG/policies/change-management.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: GovernancePolicy
metadata:
  name: change-management-policy
  namespace: machinenativenops-governance
spec:
  description: "Change management and approval workflow"
  rules:
    - id: "CMP-001"
      name: "require-change-approval"
      description: "Require approval for production changes"
      condition: "environment = 'production' AND change.type in ['config', 'code', 'infrastructure']"
      action: "require_approval"
      effect: "require"
      priority: 100
    - id: "CMP-002"
      name: "change-validation"
      description: "Validate all changes before deployment"
      condition: "change.status = 'pending'"
      action: "validate_change"
      effect: "require"
      priority: 90
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    log_info "Governance policies deployed"
}

# === 設定審核規則 ===
setup_audit_rules() {
    log_info "Setting up audit rules..."
    
    # 系統存取審核
    cat > "$MNO_CONFIG/rules/system-access-audit.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: AuditRule
metadata:
  name: system-access-audit
  namespace: machinenativenops-governance
spec:
  description: "Audit all system access attempts"
  enabled: true
  scope:
    - "authentication"
    - "authorization"
    - "session_management"
  events:
    - "login_success"
    - "login_failure"
    - "permission_granted"
    - "permission_denied"
    - "session_created"
    - "session_terminated"
  retention: "2_years"
  alert_threshold: 10
  alert_actions:
    - "notify_security_team"
    - "lock_account_temporarily"
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    # 資料存取審核
    cat > "$MNO_CONFIG/rules/data-access-audit.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: AuditRule
metadata:
  name: data-access-audit
  namespace: machinenativenops-governance
spec:
  description: "Audit all sensitive data access"
  enabled: true
  scope:
    - "data_access"
    - "data_modification"
    - "data_export"
  events:
    - "sensitive_data_read"
    - "sensitive_data_write"
    - "data_export"
    - "data_deletion"
  retention: "7_years"
  alert_threshold: 5
  alert_actions:
    - "notify_data_protection_officer"
    - "create_incident_ticket"
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    # 配置變更審核
    cat > "$MNO_CONFIG/rules/configuration-change-audit.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: AuditRule
metadata:
  name: configuration-change-audit
  namespace: machinenativenops-governance
spec:
  description: "Audit all configuration changes"
  enabled: true
  scope:
    - "system_configuration"
    - "policy_configuration"
    - "role_configuration"
  events:
    - "config_modified"
    - "policy_created"
    - "policy_modified"
    - "policy_deleted"
    - "role_assigned"
    - "role_revoked"
  retention: "5_years"
  alert_threshold: 1
  alert_actions:
    - "notify_system_administrator"
    - "create_change_record"
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    log_info "Audit rules configured"
}

# === 創建存取控制清單 ===
create_access_control_lists() {
    log_info "Creating access control lists..."
    
    # 系統管理員 ACL
    cat > "$MNO_CONFIG/acls/system-administrator.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: AccessControlList
metadata:
  name: system-administrator-acl
  namespace: machinenativenops-governance
spec:
  role: "system-administrator"
  permissions:
    read:
      - "system:*"
      - "governance:*"
      - "modules:*"
      - "trust:*"
      - "provenance:*"
      - "execution:*"
      - "integrity:*"
    write:
      - "system:*"
      - "governance:*"
      - "modules:*"
      - "trust:*"
      - "provenance:*"
      - "execution:*"
      - "integrity:*"
    execute:
      - "system:*"
      - "execution:*"
  constraints:
    - "mfa_required: true"
    - "audit_required: true"
    - "approval_not_required: true"
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    # 安全管理員 ACL
    cat > "$MNO_CONFIG/acls/security-administrator.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: AccessControlList
metadata:
  name: security-administrator-acl
  namespace: machinenativenops-governance
spec:
  role: "security-administrator"
  permissions:
    read:
      - "system:*"
      - "governance:*"
      - "modules:*"
      - "trust:*"
      - "provenance:*"
      - "integrity:*"
    write:
      - "trust:*"
      - "integrity:*"
      - "governance:security_policies"
    execute:
      - "trust:*"
      - "integrity:*"
  constraints:
    - "mfa_required: true"
    - "audit_required: true"
    - "approval_not_required: false"
  created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    log_info "Access control lists created"
}

# === 初始化治理引擎 ===
initialize_governance_engine() {
    log_info "Initializing governance engine..."
    
    # 創建治理引擎狀態檔案
    cat > "/var/lib/machinenativenops/governance/engine-status.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: GovernanceEngineStatus
metadata:
  name: governance-engine
  namespace: machinenativenops-governance
spec:
  status: "initializing"
  version: "1.0.0"
  start_time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  configuration_loaded: false
  policies_enforced: false
  audit_active: false
  components:
    - name: "policy_engine"
      status: "stopped"
      pid: null
    - name: "audit_engine"
      status: "stopped"
      pid: null
    - name: "access_controller"
      status: "stopped"
      pid: null
    - name: "role_manager"
      status: "stopped"
      pid: null
EOF
    
    # 創建治理引擎啟動腳本
    cat > "$MNO_ROOT/sbin/governance-engine" << 'EOF'
#!/bin/bash
# MachineNativeOps Governance Engine
# This script starts the governance engine

GPIVERANCE_ROOT="/var/lib/machinenativenops/governance"
LOG_FILE="/var/log/machinenativenops/governance/engine.log"
PID_FILE="/var/run/machinenativenops/governance-engine.pid"

case "$1" in
    start)
        echo "Starting governance engine..."
        # 在實際實現中，這裡會啟動治理引擎進程
        echo $$ > "$PID_FILE"
        echo "Governance engine started with PID: $$"
        ;;
    stop)
        echo "Stopping governance engine..."
        if [[ -f "$PID_FILE" ]]; then
            kill $(cat "$PID_FILE") 2>/dev/null || true
            rm -f "$PID_FILE"
        fi
        echo "Governance engine stopped"
        ;;
    status)
        if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Governance engine is running (PID: $(cat "$PID_FILE"))"
        else
            echo "Governance engine is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$MNO_ROOT/sbin/governance-engine"
    
    log_info "Governance engine initialized"
}

# === 啟動治理服務 ===
start_governance_services() {
    log_info "Starting governance services..."
    
    # 創建 systemd 服務檔案（如果支援）
    if command -v systemctl >/dev/null; then
        cat > "/etc/systemd/system/machinenativenops-governance.service" << EOF
[Unit]
Description=MachineNativeOps Governance Engine
After=network.target
Wants=network.target

[Service]
Type=forking
ExecStart=$MNO_ROOT/sbin/governance-engine start
ExecStop=$MNO_ROOT/sbin/governance-engine stop
ExecReload=$MNO_ROOT/sbin/governance-engine restart
PIDFile=/var/run/machinenativenops/governance-engine.pid
Restart=always
RestartSec=10
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
        
        # 重新載入 systemd 配置
        systemctl daemon-reload
        
        # 啟用服務
        systemctl enable machinenativenops-governance.service
        
        # 啟動服務
        systemctl start machinenativenops-governance.service
        
        log_info "Governance systemd service started"
    else
        # 手動啟動
        "$MNO_ROOT/sbin/governance-engine" start
        log_info "Governance service started manually"
    fi
}

# === 驗證治理系統 ===
verify_governance_system() {
    log_info "Verifying governance system..."
    
    # 檢查服務狀態
    if command -v systemctl >/dev/null; then
        if systemctl is-active --quiet machinenativenops-governance; then
            log_info "Governance service is running"
        else
            log_warn "Governance service is not running"
        fi
    fi
    
    # 檢查配置檔案
    local config_files=(
        "$GOVERNANCE_CONFIG"
        "$MNO_CONFIG/policies/access-control.yaml"
        "$MNO_CONFIG/policies/data-protection.yaml"
        "$MNO_CONFIG/policies/change-management.yaml"
        "$MNO_CONFIG/rules/system-access-audit.yaml"
        "$MNO_CONFIG/acls/system-administrator.yaml"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            log_debug "Configuration file exists: $config_file"
        else
            log_warn "Configuration file missing: $config_file"
        fi
    done
    
    log_info "Governance system verification completed"
}

# === 更新初始化狀態 ===
update_init_status() {
    log_info "Updating initialization status..."
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    # 更新治理初始化狀態
    cat > "/var/lib/machinenativenops/governance/init-status.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: GovernanceInitStatus
metadata:
  name: governance-init-status
  namespace: machinenativenops-governance
spec:
  phase: "1"
  name: "governance-init"
  status: "completed"
  start_time: $(date -u -d "@$START_TIME" +%Y-%m-%dT%H:%M:%SZ)
  completion_time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  duration: ${duration} seconds
  script: "$SCRIPT_NAME"
  components_initialized:
    - "governance_roles"
    - "governance_policies"
    - "audit_rules"
    - "access_control_lists"
    - "governance_engine"
    - "governance_services"
EOF
    
    # 更新整體初始化狀態
    if [[ -f "$MNO_CONFIG/INIT_STATUS" ]]; then
        sed -i "s/Status: Completed/Status: In Progress/" "$MNO_CONFIG/INIT_STATUS"
        echo "Phase 1 (Governance Init): $(date -u +%Y-%m-%dT%H:%M:%SZ) - Completed in ${duration}s" >> "$MNO_CONFIG/INIT_STATUS"
    fi
    
    log_info "Initialization status updated"
}

# === 主函數 ===
main() {
    echo -e "${CYAN}=== MachineNativeOps Root Layer Governance Initialization - Phase 1 ===${NC}"
    echo -e "${CYAN}Script: $SCRIPT_NAME${NC}"
    echo -e "${CYAN}Start Time: $(date)${NC}"
    echo
    
    # 檢查前置條件
    check_prerequisites
    
    # 執行初始化步驟
    log_info "Starting Phase 1 governance initialization..."
    
    validate_governance_config
    create_governance_roles
    deploy_governance_policies
    setup_audit_rules
    create_access_control_lists
    initialize_governance_engine
    start_governance_services
    verify_governance_system
    update_init_status
    
    # 計算總耗時
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    
    echo
    echo -e "${GREEN}=== Phase 1 Governance Initialization Completed Successfully ===${NC}"
    echo -e "${GREEN}Total Duration: ${total_duration} seconds${NC}"
    echo -e "${GREEN}Completion Time: $(date)${NC}"
    echo
    
    log_info "Phase 1 governance initialization completed successfully in ${total_duration} seconds"
    
    # 下一步提示
    echo -e "${CYAN}Next Phase:${NC} Run 02-modules-init.sh to initialize the module system"
}

# === 錯誤處理 ===
cleanup_on_error() {
    log_error "Governance initialization failed at line $1"
    
    # 更新狀態為失敗
    cat > "/var/lib/machinenativenops/governance/init-status.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: GovernanceInitStatus
metadata:
  name: governance-init-status
  namespace: machinenativenops-governance
spec:
  phase: "1"
  name: "governance-init"
  status: "failed"
  start_time: $(date -u -d "@$START_TIME" +%Y-%m-%dT%H:%M:%SZ)
  failure_time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  script: "$SCRIPT_NAME"
  error_line: $1
EOF
    
    exit 1
}

# 設定錯誤處理
trap 'cleanup_on_error $LINENO' ERR

# === 執行主函數 ===
main "$@"