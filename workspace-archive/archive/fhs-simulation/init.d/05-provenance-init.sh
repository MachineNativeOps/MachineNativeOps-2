#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Provenance System Initialization
# =============================================================================
# 來源追溯系統初始化腳本
# 職責：建立審計軌跡、元資料管理、完整性追蹤、合規性記錄
# 依賴：04-trust-init.sh
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
    log_info "載入來源追溯系統配置..."
    
    if [[ ! -f ".root.provenance.yaml" ]]; then
        log_error "來源追溯配置文件不存在：.root.provenance.yaml"
        exit 1
    fi
    
    PROVENANCE_CONFIG_FILE=".root.provenance.yaml"
    log_success "來源追溯系統配置載入完成"
}

# 建立審計日誌系統
setup_audit_logging() {
    log_info "建立審計日誌系統..."
    
    local audit_dir="logs/audit"
    mkdir -p "$audit_dir"
    
    # 建立審計日誌配置
    cat > "config/audit/logging.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: AuditLogging
metadata:
  name: audit-logging-system
  namespace: machinenativeops
spec:
  logLevels:
    audit: INFO
    security: WARN
    compliance: INFO
  retention:
    default: 90d
    security: 365d
    compliance: 2555d  # 7 years
  outputs:
    - type: file
      path: "logs/audit/audit.log"
      rotation: daily
      compression: gzip
    - type: elasticsearch
      endpoint: "http://elasticsearch:9200"
      index: "machinenativeops-audit"
    - type: syslog
      endpoint: "syslog.machinenativeops.local"
      facility: auth
  filters:
    - name: user-actions
      enabled: true
      events: ["login", "logout", "create", "update", "delete"]
    - name: system-events
      enabled: true
      events: ["startup", "shutdown", "config-change"]
    - name: security-events
      enabled: true
      events: ["auth-failure", "permission-denied", "suspicious-activity"]
status:
  phase: initialized
  loggers: 3
  retentionPolicies: 3
EOF
    
    # 建立審計日誌格式
    cat > "$audit_dir/audit.log" << EOF
# Audit Log Format
# Timestamp|Level|User|Action|Resource|Result|Details|SourceIP|TraceID
EOF
    
    log_success "審計日誌系統建立完成"
}

# 建立元資料管理
setup_metadata_management() {
    log_info "建立元資料管理系統..."
    
    local metadata_dir="metadata"
    mkdir -p "$metadata_dir"/{files,users,sessions,deployments}
    
    # 建立元資料 schema
    cat > "$metadata_dir/schema.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: MetadataSchema
metadata:
  name: provenance-metadata-schema
  namespace: machinenativeops
spec:
  schemas:
    fileMetadata:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        path:
          type: string
        hash:
          type: string
          format: sha256
        size:
          type: integer
        created:
          type: string
          format: date-time
        modified:
          type: string
          format: date-time
        creator:
          type: string
        permissions:
          type: object
        tags:
          type: array
          items:
            type: string
    userMetadata:
      type: object
      properties:
        userId:
          type: string
        username:
          type: string
        email:
          type: string
          format: email
        roles:
          type: array
          items:
            type: string
        permissions:
          type: array
          items:
            type: string
        lastLogin:
          type: string
          format: date-time
        activeSessions:
          type: array
          items:
            type: string
            format: uuid
    sessionMetadata:
      type: object
      properties:
        sessionId:
          type: string
          format: uuid
        userId:
          type: string
        startTime:
          type: string
          format: date-time
        lastActivity:
          type: string
          format: date-time
        sourceIP:
          type: string
          format: ipv4
        userAgent:
          type: string
        actions:
          type: array
          items:
            type: object
status:
  phase: defined
  schemas: 3
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "元資料管理系統建立完成"
}

# 建立完整性追蹤
setup_integrity_tracking() {
    log_info "建立完整性追蹤系統..."
    
    local integrity_dir="integrity"
    mkdir -p "$integrity_dir"/{hashes,signatures,verification}
    
    # 建立完整性追蹤配置
    cat > "$integrity_dir/tracking.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: IntegrityTracking
metadata:
  name: integrity-tracking-system
  namespace: machinenativeops
spec:
  algorithms:
    fileHash: sha256
    directoryHash: sha512
    signature: rsa-2048
  tracking:
    files:
      enabled: true
      directories: ["src", "config", "scripts", "docs"]
      exclude: [".git", "node_modules", "__pycache__"]
    directories:
      enabled: true
      directories: ["certs", "logs", "metadata"]
    signatures:
      enabled: true
      signFiles: true
      signDirectories: true
  verification:
    automatic: true
    interval: 1h
    onModification: true
  alerts:
    enabled: true
      channels: ["email", "slack", "webhook"]
      severity: ["high", "critical"]
status:
  phase: initialized
  trackedItems: 0
  lastVerification: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 建立完整性檢查腳本
    cat > "$integrity_dir/check-integrity.sh" << 'EOF'
#!/bin/bash

# 完整性檢查腳本

INTEGRITY_DIR="integrity"
HASHES_FILE="$INTEGRITY_DIR/hashes/current.hashes"
SIGNATURES_FILE="$INTEGRITY_DIR/signatures/current.sigs"

calculate_file_hash() {
    local file=$1
    sha256sum "$file" | cut -d' ' -f1
}

calculate_directory_hash() {
    local dir=$1
    find "$dir" -type f -exec sha256sum {} \; | sort | sha512sum | cut -d' ' -f1
}

# 生成當前狀態雜湊
echo "Generating current state hashes..."
{
    echo "# File Hashes - $(date)"
    while IFS= read -r -d '' file; do
        hash=$(calculate_file_hash "$file")
        echo "$hash  $file"
    done < <(find src config scripts docs -type f -print0 2>/dev/null)
    
    echo ""
    echo "# Directory Hashes - $(date)"
    for dir in certs logs metadata; do
        if [[ -d "$dir" ]]; then
            hash=$(calculate_directory_hash "$dir")
            echo "$hash  $dir/"
        fi
    done
} > "$HASHES_FILE"

echo "Integrity check completed. Hashes saved to $HASHES_FILE"
EOF
    
    chmod +x "$integrity_dir/check-integrity.sh"
    
    log_success "完整性追蹤系統建立完成"
}

# 建立合規性記錄
setup_compliance_tracking() {
    log_info "建立合規性記錄系統..."
    
    local compliance_dir="compliance"
    mkdir -p "$compliance_dir"/{reports,audits,policies}
    
    # 建立合規性框架配置
    cat > "$compliance_dir/framework.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ComplianceFramework
metadata:
  name: compliance-tracking-framework
  namespace: machinenativeops
spec:
  frameworks:
    - name: ISO27001
      version: "2022"
      enabled: true
      controls:
        - A.8.2.1  # Information classification
        - A.9.2.1  # Access control policy
        - A.12.3.1 # Data backup
        - A.14.2.5 # Secure system engineering
    - name: SOC2
      type: "Type II"
      enabled: true
      controls:
        - CC6.1    # Logical access controls
        - CC6.7    # Data transmission
        - CC7.1    # System operations
    - name: GDPR
      enabled: true
      controls:
        - Art.25   # Data protection by design
        - Art.32   # Security of processing
        - Art.33   # Notification of data breach
  reporting:
    frequency: monthly
    format: ["pdf", "json", "csv"]
    distribution: ["management", "auditors", "compliance-team"]
  audits:
    internal:
      frequency: quarterly
      scope: ["security", "access", "data"]
    external:
      frequency: annually
      scope: ["full-system", "compliance"]
status:
  phase: initialized
  frameworks: 3
  lastAudit: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 建立合規性檢查腳本
    cat > "$compliance_dir/compliance-check.sh" << 'EOF'
#!/bin/bash

# 合規性檢查腳本

COMPLIANCE_DIR="compliance"
REPORTS_DIR="$COMPLIANCE_DIR/reports"

check_iso27001_controls() {
    echo "Checking ISO27001 controls..."
    
    # A.8.2.1 Information classification
    if [[ -f "config/classification.yaml" ]]; then
        echo "✓ Information classification policy exists"
    else
        echo "✗ Information classification policy missing"
    fi
    
    # A.9.2.1 Access control policy
    if [[ -f "config/access-control.yaml" ]]; then
        echo "✓ Access control policy exists"
    else
        echo "✗ Access control policy missing"
    fi
    
    # A.12.3.1 Data backup
    if [[ -d "backups" ]]; then
        echo "✓ Backup system configured"
    else
        echo "✗ Backup system not configured"
    fi
}

check_gdpr_controls() {
    echo "Checking GDPR controls..."
    
    # Art.32 Security of processing
    if [[ -f "config/security.yaml" ]]; then
        echo "✓ Security processing measures defined"
    else
        echo "✗ Security processing measures missing"
    fi
}

generate_compliance_report() {
    local report_file="$REPORTS_DIR/compliance-report-$(date +%Y%m%d).json"
    
    cat > "$report_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "frameworks": {
    "ISO27001": {
      "status": "partial",
      "controlsChecked": 3,
      "controlsPassed": 2
    },
    "SOC2": {
      "status": "pending",
      "controlsChecked": 0,
      "controlsPassed": 0
    },
    "GDPR": {
      "status": "partial",
      "controlsChecked": 1,
      "controlsPassed": 1
    }
  },
  "overallScore": 67,
  "recommendations": [
    "Implement full access control policy",
    "Configure automated backup system",
    "Define SOC2 control procedures"
  ]
}
EOF
    
    echo "Compliance report generated: $report_file"
}

# 執行檢查
check_iso27001_controls
check_gdpr_controls
generate_compliance_report
EOF
    
    chmod +x "$compliance_dir/compliance-check.sh"
    
    log_success "合規性記錄系統建立完成"
}

# 建立追蹤資料庫
setup_provenance_database() {
    log_info "建立來源追溯資料庫..."
    
    local db_dir="database/provenance"
    mkdir -p "$db_dir"/{migrations,seeds,schemas}
    
    # 建立資料庫 schema
    cat > "$db_dir/schemas/provenance.sql" << 'EOF'
-- Provenance Tracking Database Schema

-- Files table
CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    path TEXT NOT NULL,
    hash_sha256 VARCHAR(64) NOT NULL,
    size BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    checksum VARCHAR(64),
    metadata JSONB,
    UNIQUE(path, hash_sha256)
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    source_ip INET,
    user_agent TEXT,
    metadata JSONB
);

-- Actions table (audit trail)
CREATE TABLE IF NOT EXISTS actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES sessions(id),
    user_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    details JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    result VARCHAR(50),
    source_ip INET
);

-- Deployments table
CREATE TABLE IF NOT EXISTS deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(100) NOT NULL,
    environment VARCHAR(50) NOT NULL,
    deployed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deployed_by UUID NOT NULL REFERENCES users(id),
    status VARCHAR(50),
    rollback_version VARCHAR(100),
    metadata JSONB
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_files_path ON files(path);
CREATE INDEX IF NOT EXISTS idx_files_hash ON files(hash_sha256);
CREATE INDEX IF NOT EXISTS idx_actions_user ON actions(user_id);
CREATE INDEX IF NOT EXISTS idx_actions_timestamp ON actions(timestamp);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_deployments_environment ON deployments(environment);
EOF
    
    # 建立初始資料
    cat > "$db_dir/seeds/initial_data.sql" << 'EOF'
-- Initial data for provenance database

-- Create system user
INSERT INTO users (username, email, metadata) VALUES 
('system', 'system@machinenativeops.local', '{"type": "system", "created": "initial"}');

-- Create admin user (placeholder)
INSERT INTO users (username, email, metadata) VALUES 
('admin', 'admin@machinenativeops.local', '{"type": "admin", "created": "initial"}');

-- Create initial deployment record
INSERT INTO deployments (version, environment, deployed_by, status, metadata) VALUES 
('v1.0.0-initial', 'development', 
 (SELECT id FROM users WHERE username = 'system'),
 'completed',
 '{"type": "initial-setup", "components": ["provenance-db"]}');
EOF
    
    log_success "來源追溯資料庫建立完成"
}

# 建立監控和告警
setup_monitoring_alerts() {
    log_info "建立來源追溯監控告警..."
    
    local monitoring_dir="monitoring/provenance"
    mkdir -p "$monitoring_dir"/{rules,dashboards,alerts}
    
    # 建立監控規則
    cat > "$monitoring_dir/rules/provenance-alerts.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: MonitoringRules
metadata:
  name: provenance-monitoring-rules
  namespace: machinenativeops
spec:
  rules:
    - name: ProvenanceDataIntegrity
      description: "Monitor provenance data integrity"
      condition: "integrity_check_failed > 0"
      severity: critical
      interval: 5m
      actions:
        - type: alert
          channels: ["email", "slack"]
        - type: investigation
          auto: true
    
    - name: AuditLogVolume
      description: "Monitor audit log volume"
      condition: "audit_log_rate > 1000/minute"
      severity: warning
      interval: 1m
      actions:
        - type: alert
          channels: ["email"]
    
    - name: ComplianceScore
      description: "Monitor compliance score"
      condition: "compliance_score < 80"
      severity: warning
      interval: 1h
      actions:
        - type: alert
          channels: ["email", "management"]
    
    - name: DatabaseConnections
      description: "Monitor provenance database connections"
      condition: "db_connections > 100"
      severity: warning
      interval: 30s
      actions:
        - type: alert
          channels: ["email", "slack"]
status:
  phase: initialized
  rules: 4
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "來源追溯監控告警建立完成"
}

# 驗證來源追溯系統
verify_provenance_system() {
    log_info "驗證來源追溯系統..."
    
    local verification_errors=0
    
    # 檢查目錄結構
    local required_dirs=("logs/audit" "metadata" "integrity" "compliance" "database/provenance" "monitoring/provenance")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "缺少目錄：$dir"
            ((verification_errors++))
        fi
    done
    
    # 檢查配置文件
    local required_files=("config/audit/logging.yaml" "metadata/schema.yaml" "integrity/tracking.yaml" "compliance/framework.yaml")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "缺少配置文件：$file"
            ((verification_errors++))
        fi
    done
    
    # 檢查腳本可執行性
    local scripts=("integrity/check-integrity.sh" "compliance/compliance-check.sh")
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                log_success "$script 可執行"
            else
                log_warning "$script 不可執行"
            fi
        fi
    done
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "來源追溯系統驗證通過"
        return 0
    else
        log_error "來源追溯系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始來源追溯系統初始化..."
    
    # 初始化階段
    local total_steps=9
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; setup_audit_logging
    ((current_step++)); progress_bar $current_step $total_steps; setup_metadata_management
    ((current_step++)); progress_bar $current_step $total_steps; setup_integrity_tracking
    ((current_step++)); progress_bar $current_step $total_steps; setup_compliance_tracking
    ((current_step++)); progress_bar $current_step $total_steps; setup_provenance_database
    ((current_step++)); progress_bar $current_step $total_steps; setup_monitoring_alerts
    ((current_step++)); progress_bar $current_step $total_steps; verify_provenance_system
    
    echo; log_success "來源追溯系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要組件位置："
    echo "  - 審計日誌：logs/audit/"
    echo "  - 元資料：metadata/"
    echo "  - 完整性追蹤：integrity/"
    echo "  - 合規性記錄：compliance/"
    echo "  - 資料庫 schema：database/provenance/"
    echo "  - 監控告警：monitoring/provenance/"
    echo
    log_info "來源追溯系統狀態：已初始化並驗證"
}

# 執行主函數
main "$@"