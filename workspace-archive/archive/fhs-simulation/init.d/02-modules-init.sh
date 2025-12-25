#!/bin/bash
# 🧩 Root 模組系統初始化腳本
# MachineNativeOps Root Layer Modules Initializer - Phase 2
# Version: 1.0.0

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/machinenativenops/modules-init.log"
readonly START_TIME=$(date +%s)
readonly MNO_ROOT="/opt/machinenativenops"
readonly MNO_CONFIG="/etc/machinenativenops"
readonly MODULES_CONFIG="$MNO_CONFIG/.root.modules.yaml"

# 顏色定義
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} ${timestamp} - $*" | tee -a "$LOG_FILE"
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} ${timestamp} - $*" | tee -a "$LOG_FILE"
}

# 檢查前置條件
check_prerequisites() {
    if [[ ! -f "$MNO_CONFIG/INIT_STATUS" ]] || ! grep -q "Phase 1.*Completed" "$MNO_CONFIG/INIT_STATUS"; then
        log_error "Phase 1 initialization must be completed first"
        exit 1
    fi
    
    if [[ ! -f "$MODULES_CONFIG" ]]; then
        log_error "Modules configuration file not found: $MODULES_CONFIG"
        exit 1
    fi
}

# 註冊模組
register_modules() {
    log_info "Registering modules..."
    
    mkdir -p "$MNO_CONFIG/modules/registry"
    
    # 創建模組註冊狀態
    cat > "/var/lib/machinenativenops/modules/registry-status.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: ModuleRegistryStatus
metadata:
  name: module-registry-status
  namespace: machinenativenops-modules
spec:
  status: "initializing"
  total_modules: 8
  registered_modules: 0
  start_time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    
    # 註冊核心模組
    local core_modules=(
        "config-manager:Configuration management module"
        "logging-service:Logging service module"
        "trust-manager:Trust management module"
        "governance-engine:Governance engine module"
        "provenance-tracker:Provenance tracking module"
        "integrity-validator:Integrity validation module"
        "super-execution-engine:Super execution engine module"
        "monitoring-service:Monitoring service module"
    )
    
    for module_def in "${core_modules[@]}"; do
        local module_name=$(echo "$module_def" | cut -d':' -f1)
        local module_desc=$(echo "$module_def" | cut -d':' -f2)
        
        cat > "$MNO_CONFIG/modules/registry/${module_name}.yaml" << EOF
apiVersion: machinenativenops.io/v1
kind: ModuleRegistration
metadata:
  name: $module_name
  namespace: machinenativenops-modules
spec:
  description: "$module_desc"
  version: "1.0.0"
  enabled: true
  auto_start: true
  registration_time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
        
        log_info "Registered module: $module_name"
    done
    
    # 更新註冊狀態
    sed -i 's/status: "initializing"/status: "completed"/' "/var/lib/machinenativenops/modules/registry-status.yaml"
    sed -i 's/registered_modules: 0/registered_modules: 8/' "/var/lib/machinenativenops/modules/registry-status.yaml"
}

# 初始化模組系統
main() {
    echo -e "${GREEN}=== MachineNativeOps Modules Initialization - Phase 2 ===${NC}"
    
    check_prerequisites
    register_modules
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo -e "${GREEN}Phase 2 modules initialization completed in ${duration} seconds${NC}"
    log_info "Modules initialization completed successfully"
    
    echo -e "${GREEN}Next Phase: Run 03-super-execution-init.sh${NC}"
}

# 錯誤處理
trap 'log_error "Module initialization failed at line $LINENO"; exit 1' ERR

main "$@"