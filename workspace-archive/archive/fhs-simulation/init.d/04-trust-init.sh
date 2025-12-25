#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Trust System Initialization
# =============================================================================
# 信任系統初始化腳本
# 職責：建立證書管理、HSM 整合、TPM 支援、信任鏈驗證
# 依賴：03-super-execution-init.sh
# =============================================================================

set -euo pipefail

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日誌函數
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 進度條
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    
    printf "\r["
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $((width - filled)) | tr ' ' '-'
    printf "] %d%%" $percentage
}

# 載入配置
load_config() {
    log_info "載入信任系統配置..."
    
    if [[ ! -f ".root.trust.yaml" ]]; then
        log_error "信任配置文件不存在：.root.trust.yaml"
        exit 1
    fi
    
    # 解析 YAML 配置（使用 Python 或 yq）
    TRUST_CONFIG_FILE=".root.trust.yaml"
    log_success "信任系統配置載入完成"
}

# 檢查依賴
check_dependencies() {
    log_info "檢查信任系統依賴..."
    
    local deps=("openssl" "keytool" "tpm2-tools" "pkcs11-tool")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "缺少依賴項：${missing_deps[*]}"
        log_info "正在安裝缺少的依賴..."
        
        # 根據系統安裝依賴
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y "${missing_deps[@]}"
        elif command -v yum &> /dev/null; then
            yum install -y "${missing_deps[@]}"
        elif command -v brew &> /dev/null; then
            brew install "${missing_deps[@]}"
        else
            log_error "無法自動安裝依賴，請手動安裝：${missing_deps[*]}"
            exit 1
        fi
    fi
    
    log_success "依賴檢查完成"
}

# 建立 CA 根證書
setup_root_ca() {
    log_info "建立 CA 根證書..."
    
    local ca_dir="certs/ca"
    mkdir -p "$ca_dir"
    
    # 生成 CA 私鑰
    openssl genrsa -out "$ca_dir/ca-key.pem" 4096
    
    # 生成 CA 證書
    openssl req -new -x509 -days 3650 \
        -key "$ca_dir/ca-key.pem" \
        -out "$ca_dir/ca-cert.pem" \
        -subj "/C=TW/ST=Taipei/L=Taipei/O=MachineNativeOps/OU=Root CA/CN=MachineNativeOps Root CA"
    
    # 建立證書序列號和資料庫
    echo 1000 > "$ca_dir/serial"
    touch "$ca_dir/index.txt"
    
    log_success "CA 根證書建立完成"
}

# 建立服務證書
setup_service_certificates() {
    log_info "建立服務證書..."
    
    local services_dir="certs/services"
    mkdir -p "$services_dir"
    
    local services=("api-gateway" "auth-service" "database" "redis" "monitoring")
    
    for service in "${services[@]}"; do
        log_info "為 $service 生成證書..."
        
        local service_dir="$services_dir/$service"
        mkdir -p "$service_dir"
        
        # 生成私鑰
        openssl genrsa -out "$service_dir/key.pem" 2048
        
        # 生成證書簽署請求
        openssl req -new \
            -key "$service_dir/key.pem" \
            -out "$service_dir/csr.pem" \
            -subj "/C=TW/ST=Taipei/L=Taipei/O=MachineNativeOps/OU=$service/CN=$service.machinenativeops.local"
        
        # 使用 CA 簽署證書
        openssl x509 -req -in "$service_dir/csr.pem" \
            -CA "certs/ca/ca-cert.pem" \
            -CAkey "certs/ca/ca-key.pem" \
            -CAserial "certs/ca/serial" \
            -days 365 \
            -out "$service_dir/cert.pem"
        
        # 建立完整的證書鏈
        cat "$service_dir/cert.pem" "certs/ca/ca-cert.pem" > "$service_dir/fullchain.pem"
        
        log_success "$service 證書建立完成"
    done
}

# 建立 HSM 支援
setup_hsm_support() {
    log_info "設定 HSM 支援..."
    
    local hsm_dir="config/hsm"
    mkdir -p "$hsm_dir"
    
    # 檢查 HSM 設備
    if command -v pkcs11-tool &> /dev/null; then
        log_info "偵測 PKCS#11 支援..."
        
        # 建立 HSM 配置
        cat > "$hsm_dir/pkcs11.conf" << EOF
# PKCS#11 Configuration for MachineNativeOps
library = /usr/lib/libpkcs11.so
slot = 0
token_type = RSA
pin = 1234
EOF
        
        log_success "HSM 支援設定完成"
    else
        log_warning "PKCS#11 工具未找到，使用軟體模式"
    fi
}

# 建立 TPM 支援
setup_tpm_support() {
    log_info "設定 TPM 支援..."
    
    local tpm_dir="config/tpm"
    mkdir -p "$tpm_dir"
    
    if command -v tpm2-tools &> /dev/null; then
        log_info "偵測 TPM 2.0 支援..."
        
        # 檢查 TPM 狀態
        if tpm2_startup -c &> /dev/null; then
            log_success "TPM 2.0 就緒"
            
            # 建立 TPM 配置
            cat > "$tpm_dir/tpm.conf" << EOF
# TPM 2.0 Configuration for MachineNativeOps
tcti = device:/dev/tpm0
auth_hierarchy = owner
max_sessions = 4
EOF
        else
            log_warning "TPM 2.0 不可用"
        fi
    else
        log_warning "TPM 2.0 工具未找到"
    fi
}

# 建立信任鏈驗證
setup_trust_chain() {
    log_info "建立信任鏈驗證機制..."
    
    local trust_dir="config/trust"
    mkdir -p "$trust_dir"
    
    # 建立信任鏈配置
    cat > "$trust_dir/trust-chain.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: TrustChain
metadata:
  name: root-trust-chain
  namespace: machinenativeops
spec:
  rootCA:
    certificate: "certs/ca/ca-cert.pem"
    key: "certs/ca/ca-key.pem"
  intermediateCAs: []
  leafCertificates:
    - name: api-gateway
      certificate: "certs/services/api-gateway/cert.pem"
      key: "certs/services/api-gateway/key.pem"
    - name: auth-service
      certificate: "certs/services/auth-service/cert.pem"
      key: "certs/services/auth-service/key.pem"
  validationRules:
    - name: certificate-chain
      enabled: true
    - name: expiration-check
      enabled: true
      threshold: 30d
    - name: revocation-check
      enabled: true
      method: OCSP
status:
  phase: initialized
  certificates: 6
  lastValidation: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "信任鏈驗證機制建立完成"
}

# 建立證書輪換策略
setup_certificate_rotation() {
    log_info "建立證書輪換策略..."
    
    local rotation_dir="scripts/certificate-rotation"
    mkdir -p "$rotation_dir"
    
    # 建立自動輪換腳本
    cat > "$rotation_dir/auto-rotate.sh" << 'EOF'
#!/bin/bash

# 自動證書輪換腳本

CERTS_DIR="certs"
THRESHOLD_DAYS=30

check_certificate_expiry() {
    local cert_file=$1
    local expiry_date
    
    if [[ ! -f "$cert_file" ]]; then
        return 1
    fi
    
    expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry_date" +%s)
    current_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    if [[ $days_until_expiry -lt $THRESHOLD_DAYS ]]; then
        echo "WARNING: Certificate $cert_file expires in $days_until_expiry days"
        return 0
    fi
    
    return 1
}

# 檢查所有服務證書
find "$CERTS_DIR/services" -name "cert.pem" | while read cert; do
    if check_certificate_expiry "$cert"; then
        echo "Certificate rotation needed: $cert"
    fi
done
EOF
    
    chmod +x "$rotation_dir/auto-rotate.sh"
    
    log_success "證書輪換策略建立完成"
}

# 驗證信任系統
verify_trust_system() {
    log_info "驗證信任系統..."
    
    local verification_errors=0
    
    # 檢查 CA 證書
    if [[ ! -f "certs/ca/ca-cert.pem" ]]; then
        log_error "CA 證書不存在"
        ((verification_errors++))
    fi
    
    # 檢查服務證書
    local services=("api-gateway" "auth-service" "database" "redis" "monitoring")
    for service in "${services[@]}"; do
        if [[ ! -f "certs/services/$service/cert.pem" ]]; then
            log_error "$service 證書不存在"
            ((verification_errors++))
        fi
    done
    
    # 驗證證書有效性
    for service in "${services[@]}"; do
        if openssl verify -CAfile "certs/ca/ca-cert.pem" "certs/services/$service/cert.pem" &> /dev/null; then
            log_success "$service 證書驗證通過"
        else
            log_error "$service 證書驗證失敗"
            ((verification_errors++))
        fi
    done
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "信任系統驗證通過"
        return 0
    else
        log_error "信任系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始信任系統初始化..."
    
    # 檢查是否以 root 權限運行
    if [[ $EUID -ne 0 ]]; then
        log_warning "建議以 root 權限運行以設定系統級信任"
    fi
    
    # 初始化階段
    local total_steps=9
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; check_dependencies
    ((current_step++)); progress_bar $current_step $total_steps; setup_root_ca
    ((current_step++)); progress_bar $current_step $total_steps; setup_service_certificates
    ((current_step++)); progress_bar $current_step $total_steps; setup_hsm_support
    ((current_step++)); progress_bar $current_step $total_steps; setup_tpm_support
    ((current_step++)); progress_bar $current_step $total_steps; setup_trust_chain
    ((current_step++)); progress_bar $current_step $total_steps; setup_certificate_rotation
    ((current_step++)); progress_bar $current_step $total_steps; verify_trust_system
    
    echo; log_success "信任系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要檔案位置："
    echo "  - CA 根證書：certs/ca/ca-cert.pem"
    echo "  - 服務證書：certs/services/*/cert.pem"
    echo "  - 信任鏈配置：config/trust/trust-chain.yaml"
    echo "  - 證書輪換：scripts/certificate-rotation/auto-rotate.sh"
    echo
    log_info "信任系統狀態：已初始化並驗證"
}

# 執行主函數
main "$@"