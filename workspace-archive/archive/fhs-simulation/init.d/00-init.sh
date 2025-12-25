#!/bin/bash
# 🚀 Root 系統基礎初始化腳本
# MachineNativeOps Root Layer Initializer - Phase 0
# Version: 1.0.0
# Last Modified: 2025-12-20T22:00:00Z

# =============================================================================
# MachineNativeOps Root System Initializer - Phase 0
# =============================================================================
# This script performs the initial system preparation and environment setup
# for the MachineNativeOps root layer. It runs first in the initialization
# sequence and prepares the foundation for all subsequent phases.
# =============================================================================

# 設定嚴格模式
set -euo pipefail

# === 全域變數 ===
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_PATH="$(dirname "$0")"
readonly LOG_FILE="/var/log/machinenativenops/root-init.log"
readonly START_TIME=$(date +%s)
readonly MNO_ROOT="/opt/machinenativenops"
readonly MNO_CONFIG="/etc/machinenativenops"
readonly MNO_LOGS="/var/log/machinenativenops"

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

# === 檢查函數 ===
check_prerequisites() {
    log_info "Checking system prerequisites..."
    
    local prerequisites=(
        "root_user:Check if running as root"
        "bash_version:Check bash version >= 4.0"
        "kernel_version:Check kernel version >= 5.4.0"
        "memory_size:Check available memory >= 2GB"
        "disk_space:Check available disk space >= 10GB"
    )
    
    local total=${#prerequisites[@]}
    local current=0
    
    for prereq in "${prerequisites[@]}"; do
        current=$((current + 1))
        local check_name=$(echo "$prereq" | cut -d':' -f1)
        local check_desc=$(echo "$prereq" | cut -d':' -f2)
        
        show_progress $current $total "$check_desc"
        
        case "$check_name" in
            "root_user")
                if [[ $EUID -ne 0 ]]; then
                    log_error "This script must be run as root"
                    exit 1
                fi
                ;;
            "bash_version")
                if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
                    log_error "Bash version 4.0 or higher required"
                    exit 1
                fi
                ;;
            "kernel_version")
                local kernel_version=$(uname -r | cut -d'-' -f1)
                if ! awk 'BEGIN{exit!(ARGV[1] >= ARGV[2])}' "$kernel_version" "5.4.0"; then
                    log_error "Kernel version 5.4.0 or higher required"
                    exit 1
                fi
                ;;
            "memory_size")
                local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
                local mem_gb=$((mem_kb / 1024 / 1024))
                if [[ $mem_gb -lt 2 ]]; then
                    log_error "Minimum 2GB RAM required"
                    exit 1
                fi
                ;;
            "disk_space")
                local disk_kb=$(df / | awk 'NR==2 {print $4}')
                local disk_gb=$((disk_kb / 1024 / 1024))
                if [[ $disk_gb -lt 10 ]]; then
                    log_error "Minimum 10GB disk space required"
                    exit 1
                fi
                ;;
        esac
        
        sleep 0.1
    done
    
    echo
    log_info "All prerequisites checks passed"
}

# === 創建必要目錄 ===
create_directories() {
    log_info "Creating necessary directories..."
    
    local directories=(
        "$MNO_ROOT"
        "$MNO_CONFIG"
        "$MNO_LOGS"
        "/var/lib/machinenativenops"
        "/var/run/machinenativenops"
        "/var/cache/machinenativenops"
        "/var/backups/machinenativenops"
        "/tmp/machinenativenops"
        "$MNO_CONFIG/trust"
        "$MNO_CONFIG/certs"
        "$MNO_CONFIG/keys"
        "$MNO_CONFIG/secrets"
        "$MNO_CONFIG/policies"
        "$MNO_CONFIG/workflows"
        "$MNO_CONFIG/baselines"
    )
    
    local total=${#directories[@]}
    local current=0
    
    for dir in "${directories[@]}"; do
        current=$((current + 1))
        show_progress $current $total "Creating $dir"
        
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            chmod 755 "$dir"
            log_debug "Created directory: $dir"
        else
            log_debug "Directory already exists: $dir"
        fi
        
        sleep 0.1
    done
    
    echo
    log_info "Directory structure created"
}

# === 設定檔案權限 ===
set_permissions() {
    log_info "Setting file permissions..."
    
    # 設定安全目錄權限
    chmod 700 "$MNO_CONFIG/trust" 2>/dev/null || true
    chmod 700 "$MNO_CONFIG/keys" 2>/dev/null || true
    chmod 700 "$MNO_CONFIG/secrets" 2>/dev/null || true
    chmod 755 "$MNO_CONFIG/certs" 2>/dev/null || true
    chmod 755 "$MNO_CONFIG/policies" 2>/dev/null || true
    
    # 設定日誌目錄權限
    chmod 755 "$MNO_LOGS" 2>/dev/null || true
    touch "$LOG_FILE" 2>/dev/null || true
    chmod 644 "$LOG_FILE" 2>/dev/null || true
    
    # 設定執行權限
    chmod +x "$MNO_ROOT/bin"/* 2>/dev/null || true
    chmod +x "$MNO_ROOT/sbin"/* 2>/dev/null || true
    
    log_info "File permissions set"
}

# === 創建基本檔案 ===
create_basic_files() {
    log_info "Creating basic configuration files..."
    
    # 創建版本檔案
    cat > "$MNO_CONFIG/VERSION" << EOF
MachineNativeOps Root Layer
Version: 1.0.0
Build Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Kernel: $(uname -r)
OS: $(uname -s) $(uname -r)
Architecture: $(uname -m)
EOF
    
    # 創建系統資訊檔案
    cat > "$MNO_CONFIG/SYSTEM_INFO" << EOF
System Information
=================
Hostname: $(hostname)
Domain: $(domainname)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)
Architecture: $(uname -m)
CPU: $(nproc) cores
Memory: $(free -h | grep '^Mem:' | awk '{print $2}')
Disk: $(df -h / | awk 'NR==2 {print $2}')
Uptime: $(uptime -p)
EOF
    
    # 創建初始化狀態檔案
    cat > "$MNO_CONFIG/INIT_STATUS" << EOF
MachineNativeOps Initialization Status
====================================
Phase 0 (Basic Init): $(date -u +%Y-%m-%dT%H:%M:%SZ)
Status: In Progress
Start Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Completion Time: TBD
EOF
    
    log_info "Basic files created"
}

# === 檢查系統服務 ===
check_system_services() {
    log_info "Checking system services status..."
    
    local services=(
        "systemd:systemd:System management daemon"
        "journald:systemd-journald:Logging service"
        "networkd:systemd-networkd:Network management"
        "resolved:systemd-resolved:DNS resolution"
        "timesyncd:systemd-timesyncd:Time synchronization"
    )
    
    local total=${#services[@]}
    local current=0
    
    for service in "${services[@]}"; do
        current=$((current + 1))
        local service_name=$(echo "$service" | cut -d':' -f1)
        local service_desc=$(echo "$service" | cut -d':' -f3)
        
        show_progress $current $total "Checking $service_desc"
        
        if systemctl is-active --quiet "$service_name"; then
            log_debug "Service $service_name is running"
        else
            log_warn "Service $service_name is not running"
        fi
        
        sleep 0.1
    done
    
    echo
    log_info "System services check completed"
}

# === 檢查網路連接 ===
check_network_connectivity() {
    log_info "Checking network connectivity..."
    
    # 檢查基本網路介面
    if ip link show | grep -q "state UP"; then
        log_info "Network interfaces are up"
    else
        log_warn "No active network interfaces found"
    fi
    
    # 檢查 DNS 解析
    if nslookup google.com >/dev/null 2>&1; then
        log_info "DNS resolution is working"
    else
        log_warn "DNS resolution may not be working properly"
    fi
    
    # 檢查外部連接（可選）
    if timeout 5 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_info "External connectivity is available"
    else
        log_warn "External connectivity may not be available"
    fi
}

# === 檢查硬體支援 ===
check_hardware_support() {
    log_info "Checking hardware support..."
    
    # 檢查 CPU 特性
    if grep -q "sse4_2" /proc/cpuinfo; then
        log_info "CPU supports SSE4.2 instructions"
    else
        log_warn "CPU may not support required instruction sets"
    fi
    
    # 檢查虛擬化支援
    if grep -q "vmx\|svm" /proc/cpuinfo; then
        log_info "Hardware virtualization is supported"
    else
        log_warn "Hardware virtualization may not be supported"
    fi
    
    # 检查 TPM 支援（可選）
    if [[ -d "/sys/class/tpm" ]]; then
        log_info "TPM device is available"
    else
        log_info "TPM device not found (optional)"
    fi
}

# === 設定環境變數 ===
setup_environment() {
    log_info "Setting up environment variables..."
    
    # 載入 MachineNativeOps 環境
    if [[ -f "$MNO_CONFIG/.root.env.sh" ]]; then
        source "$MNO_CONFIG/.root.env.sh"
        log_info "MachineNativeOps environment loaded"
    else
        log_warn "MachineNativeOps environment file not found"
    fi
    
    # 設定關鍵環境變數
    export MACHINENATIVEOPS_ROOT="$MNO_ROOT"
    export MACHINENATIVEOPS_CONFIG="$MNO_CONFIG"
    export MACHINENATIVEOPS_LOGS="$MNO_LOGS"
    export MACHINENATIVEOPS_INIT_PHASE="0"
    
    log_info "Environment variables set"
}

# === 創初始化鎖定檔案 ===
create_lock_file() {
    log_info "Creating initialization lock file..."
    
    local lock_file="/var/run/machinenativenops/init.lock"
    local pid_file="/var/run/machinenativenops/init.pid"
    
    # 創建鎖定檔案
    echo "$$" > "$pid_file"
    touch "$lock_file"
    
    log_info "Lock file created: $lock_file (PID: $$)"
}

# === 更新初始化狀態 ===
update_init_status() {
    log_info "Updating initialization status..."
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    cat > "$MNO_CONFIG/INIT_STATUS" << EOF
MachineNativeOps Initialization Status
====================================
Phase 0 (Basic Init): $(date -u +%Y-%m-%dT%H:%M:%SZ)
Status: Completed
Start Time: $(date -u -d "@$START_TIME" +%Y-%m-%dT%H:%M:%SZ)
Completion Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Duration: ${duration} seconds
Script: $SCRIPT_NAME
PID: $$
EOF
    
    log_info "Initialization status updated"
}

# === 主函數 ===
main() {
    echo -e "${CYAN}=== MachineNativeOps Root Layer Initialization - Phase 0 ===${NC}"
    echo -e "${CYAN}Script: $SCRIPT_NAME${NC}"
    echo -e "${CYAN}Start Time: $(date)${NC}"
    echo
    
    # 檢查是否已經初始化
    if [[ -f "/var/run/machinenativenops/init.lock" ]]; then
        log_warn "Initialization lock file exists - checking if initialization is complete"
        
        if grep -q "Status: Completed" "$MNO_CONFIG/INIT_STATUS" 2>/dev/null; then
            log_info "Initialization appears to be complete"
            log_info "If you want to re-initialize, remove the lock file: /var/run/machinenativenops/init.lock"
            exit 0
        else
            log_warn "Previous initialization may have failed - proceeding with cleanup"
            rm -f "/var/run/machinenativenops/init.lock" 2>/dev/null || true
            rm -f "/var/run/machinenativenops/init.pid" 2>/dev/null || true
        fi
    fi
    
    # 創建鎖定檔案
    create_lock_file
    
    # 執行初始化步驟
    log_info "Starting Phase 0 initialization..."
    
    check_prerequisites
    create_directories
    set_permissions
    create_basic_files
    check_system_services
    check_network_connectivity
    check_hardware_support
    setup_environment
    
    # 更新狀態
    update_init_status
    
    # 計算總耗時
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    
    echo
    echo -e "${GREEN}=== Phase 0 Initialization Completed Successfully ===${NC}"
    echo -e "${GREEN}Total Duration: ${total_duration} seconds${NC}"
    echo -e "${GREEN}Completion Time: $(date)${NC}"
    echo
    
    log_info "Phase 0 initialization completed successfully in ${total_duration} seconds"
    
    # 下一步提示
    echo -e "${CYAN}Next Phase:${NC} Run 01-governance-init.sh to initialize the governance system"
}

# === 錯誤處理 ===
cleanup_on_error() {
    log_error "Initialization failed at line $1"
    
    # 清理鎖定檔案
    rm -f "/var/run/machinenativenops/init.lock" 2>/dev/null || true
    rm -f "/var/run/machinenativenops/init.pid" 2>/dev/null || true
    
    # 更新狀態為失敗
    cat > "$MNO_CONFIG/INIT_STATUS" << EOF
MachineNativeOps Initialization Status
====================================
Phase 0 (Basic Init): $(date -u +%Y-%m-%dT%H:%M:%SZ)
Status: Failed
Start Time: $(date -u -d "@$START_TIME" +%Y-%m-%dT%H:%M:%SZ)
Failure Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Script: $SCRIPT_NAME
PID: $$
Error Line: $1
EOF
    
    exit 1
}

# 設定錯誤處理
trap 'cleanup_on_error $LINENO' ERR

# === 執行主函數 ===
main "$@"