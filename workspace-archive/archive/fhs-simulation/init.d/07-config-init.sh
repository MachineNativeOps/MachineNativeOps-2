#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Configuration System Initialization
# =============================================================================
# 配置系統初始化腳本
# 職責：建立環境變數管理、配置中心、多環境配置、配置驗證
# 依賴：06-database-init.sh
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
    log_info "載入配置系統設定..."
    
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    CONFIG_SYSTEM_FILE=".root.config.yaml"
    log_success "配置系統設定載入完成"
}

# 建立環境變數管理
setup_environment_variables() {
    log_info "建立環境變數管理系統..."
    
    mkdir -p "config/environments"
    
    # 開發環境
    cat > "config/environments/development.env" << EOF
# Development Environment Configuration
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=debug

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=machinenativeops_core
DB_USER=machinenativeops_user
DB_PASSWORD=dev_password_123
DB_SSL_MODE=disable

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=dev_redis_password
REDIS_DB=0

# API Configuration
API_HOST=localhost
API_PORT=8000
API_VERSION=v1
API_TIMEOUT=30s

# Security Configuration
JWT_SECRET=dev_jwt_secret_key_change_in_production
JWT_EXPIRES_IN=24h
BCRYPT_ROUNDS=10

# Multi-Platform Configuration
WEB_URL=http://localhost:3000
MOBILE_API_URL=http://localhost:8000/api
DESKTOP_API_URL=http://localhost:8000/api

# External Services
EMAIL_SERVICE=smtp
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=dev@example.com
SMTP_PASSWORD=dev_smtp_password

# Monitoring
MONITORING_ENABLED=true
METRICS_PORT=9090
HEALTH_CHECK_PORT=8080

# File Storage
STORAGE_TYPE=local
STORAGE_PATH=./storage
MAX_FILE_SIZE=100MB
ALLOWED_FILE_TYPES=jpg,png,pdf,doc,docx

# Feature Flags
FEATURE_REGISTRATION=true
FEATURE_EMAIL_VERIFICATION=false
FEATURE_MULTI_TENANT=true
FEATURE_ANALYTICS=true
EOF
    
    # 測試環境
    cat > "config/environments/testing.env" << EOF
# Testing Environment Configuration
ENVIRONMENT=testing
DEBUG=false
LOG_LEVEL=info

# Database Configuration (use test databases)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=machinenativeops_core_test
DB_USER=machinenativeops_test
DB_PASSWORD=test_password_123
DB_SSL_MODE=disable

# Redis Configuration (use test Redis)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=test_redis_password
REDIS_DB=1

# API Configuration
API_HOST=localhost
API_PORT=8001
API_VERSION=v1
API_TIMEOUT=10s

# Security Configuration
JWT_SECRET=test_jwt_secret_key
JWT_EXPIRES_IN=1h
BCRYPT_ROUNDS=4

# External Services (use mock services)
EMAIL_SERVICE=mock
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASSWORD=

# Monitoring
MONITORING_ENABLED=false
METRICS_PORT=9091
HEALTH_CHECK_PORT=8081

# File Storage
STORAGE_TYPE=memory
STORAGE_PATH=
MAX_FILE_SIZE=10MB
ALLOWED_FILE_TYPES=txt,json

# Feature Flags
FEATURE_REGISTRATION=true
FEATURE_EMAIL_VERIFICATION=false
FEATURE_MULTI_TENANT=false
FEATURE_ANALYTICS=false
EOF
    
    # 生產環境
    cat > "config/environments/production.env" << EOF
# Production Environment Configuration
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=warn

# Database Configuration
DB_HOST=\${DB_HOST}
DB_PORT=\${DB_PORT}
DB_NAME=\${DB_NAME}
DB_USER=\${DB_USER}
DB_PASSWORD=\${DB_PASSWORD}
DB_SSL_MODE=require
DB_POOL_SIZE=20

# Redis Configuration
REDIS_HOST=\${REDIS_HOST}
REDIS_PORT=\${REDIS_PORT}
REDIS_PASSWORD=\${REDIS_PASSWORD}
REDIS_DB=0
REDIS_POOL_SIZE=10

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_VERSION=v1
API_TIMEOUT=30s
API_RATE_LIMIT=1000

# Security Configuration
JWT_SECRET=\${JWT_SECRET}
JWT_EXPIRES_IN=8h
BCRYPT_ROUNDS=12
SESSION_SECRET=\${SESSION_SECRET}

# Multi-Platform Configuration
WEB_URL=\${WEB_URL}
MOBILE_API_URL=\${MOBILE_API_URL}
DESKTOP_API_URL=\${DESKTOP_API_URL}

# External Services
EMAIL_SERVICE=ses
EMAIL_FROM=\${EMAIL_FROM}
AWS_REGION=\${AWS_REGION}
AWS_ACCESS_KEY_ID=\${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=\${AWS_SECRET_ACCESS_KEY}

# Monitoring
MONITORING_ENABLED=true
METRICS_PORT=9090
HEALTH_CHECK_PORT=8080
PROMETHEUS_ENABLED=true
GRAFANA_ENABLED=true

# File Storage
STORAGE_TYPE=s3
AWS_S3_BUCKET=\${AWS_S3_BUCKET}
AWS_S3_REGION=\${AWS_S3_REGION}
MAX_FILE_SIZE=500MB
ALLOWED_FILE_TYPES=jpg,jpeg,png,gif,pdf,doc,docx,xls,xlsx,ppt,pptx

# Feature Flags
FEATURE_REGISTRATION=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_MULTI_TENANT=true
FEATURE_ANALYTICS=true
FEATURE_BACKUP=true
FEATURE_AUDIT_LOG=true
EOF
    
    # 建立 .env 範本
    cat > ".env.template" << EOF
# Environment Configuration Template
# Copy this file to .env and fill in the values

# Environment
ENVIRONMENT=development

# Database (required for production)
DB_HOST=
DB_PORT=5432
DB_NAME=machinenativeops_core
DB_USER=machinenativeops_user
DB_PASSWORD=

# Redis (required for production)
REDIS_HOST=
REDIS_PORT=6379
REDIS_PASSWORD=

# Security (required for production)
JWT_SECRET=
SESSION_SECRET=

# AWS (required for production)
AWS_REGION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=

# Email
EMAIL_FROM=

# Multi-Platform URLs
WEB_URL=
MOBILE_API_URL=
DESKTOP_API_URL=
EOF
    
    log_success "環境變數管理系統建立完成"
}

# 建立配置中心
setup_configuration_center() {
    log_info "建立配置中心..."
    
    mkdir -p "config/center"
    
    # 配置中心主配置
    cat > "config/center/config-center.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ConfigurationCenter
metadata:
  name: config-center
  namespace: machinenativeops
spec:
  storage:
    type: database
    database: machinenativeops_core
    table: configurations
  cache:
    enabled: true
    ttl: 300s
    backend: redis
  validation:
    enabled: true
    schemaValidation: true
    typeChecking: true
  versioning:
    enabled: true
    autoVersion: true
    retention: 100
  encryption:
    enabled: true
    algorithm: AES-256-GCM
    keyRotation: 90d
  audit:
    enabled: true
    logChanges: true
    logAccess: true
  environments:
    - name: development
      description: "Development environment"
      autoRefresh: true
      refreshInterval: 60s
    - name: testing
      description: "Testing environment"
      autoRefresh: true
      refreshInterval: 300s
    - name: staging
      description: "Staging environment"
      autoRefresh: true
      refreshInterval: 600s
    - name: production
      description: "Production environment"
      autoRefresh: false
      requireApproval: true
status:
  phase: initialized
  configurations: 0
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 配置資料庫 schema
    cat > "config/center/config-schema.sql" << 'EOF'
-- Configuration Center Database Schema

-- Configurations table
CREATE TABLE IF NOT EXISTS configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(255) NOT NULL,
    value TEXT,
    environment VARCHAR(100) NOT NULL,
    version INTEGER DEFAULT 1,
    type VARCHAR(50) DEFAULT 'string',
    encrypted BOOLEAN DEFAULT false,
    schema_validation JSONB,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE(key, environment)
);

-- Configuration history
CREATE TABLE IF NOT EXISTS configuration_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    configuration_id UUID NOT NULL REFERENCES configurations(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_reason TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    changed_by UUID REFERENCES users(id)
);

-- Configuration access log
CREATE TABLE IF NOT EXISTS configuration_access_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    configuration_id UUID REFERENCES configurations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- Configuration approvals
CREATE TABLE IF NOT EXISTS configuration_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    configuration_id UUID REFERENCES configurations(id) ON DELETE CASCADE,
    requester_id UUID REFERENCES users(id),
    approver_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    comments TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_configurations_key ON configurations(key);
CREATE INDEX IF NOT EXISTS idx_configurations_environment ON configurations(environment);
CREATE INDEX IF NOT EXISTS idx_configuration_history_config ON configuration_history(configuration_id);
CREATE INDEX IF NOT EXISTS idx_configuration_access_log_config ON configuration_access_log(configuration_id);
CREATE INDEX IF NOT EXISTS idx_configuration_access_log_user ON configuration_access_log(user_id);
CREATE INDEX IF NOT EXISTS idx_configuration_approvals_config ON configuration_approvals(configuration_id);

-- Trigger for updated_at
CREATE TRIGGER update_configurations_updated_at BEFORE UPDATE ON configurations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF
    
    log_success "配置中心建立完成"
}

# 建立動態配置管理
setup_dynamic_configuration() {
    log_info "建立動態配置管理..."
    
    mkdir -p "config/dynamic"
    
    # 動態配置定義
    cat > "config/dynamic/dynamic-configs.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: DynamicConfigurations
metadata:
  name: dynamic-configs
  namespace: machinenativeops
spec:
  configurations:
    # API Configuration
    - key: api.rate_limit
      type: integer
      defaultValue: 1000
      environment: production
      description: "API rate limit per minute"
      validation:
        min: 1
        max: 10000
    
    - key: api.timeout
      type: duration
      defaultValue: "30s"
      environment: production
      description: "API request timeout"
    
    # Feature Flags
    - key: features.registration_enabled
      type: boolean
      defaultValue: true
      environment: production
      description: "Enable user registration"
    
    - key: features.email_verification_required
      type: boolean
      defaultValue: true
      environment: production
      description: "Require email verification"
    
    - key: features.multi_tenant_enabled
      type: boolean
      defaultValue: false
      environment: production
      description: "Enable multi-tenant support"
    
    # Security Configuration
    - key: security.jwt_expires_in
      type: duration
      defaultValue: "8h"
      environment: production
      description: "JWT token expiration time"
    
    - key: security.session_timeout
      type: duration
      defaultValue: "24h"
      environment: production
      description: "User session timeout"
    
    - key: security.password_min_length
      type: integer
      defaultValue: 12
      environment: production
      description: "Minimum password length"
      validation:
        min: 8
        max: 128
    
    # Performance Configuration
    - key: performance.db_pool_size
      type: integer
      defaultValue: 20
      environment: production
      description: "Database connection pool size"
      validation:
        min: 1
        max: 100
    
    - key: performance.cache_ttl
      type: duration
      defaultValue: "300s"
      environment: production
      description: "Default cache TTL"
    
    # Storage Configuration
    - key: storage.max_file_size
      type: string
      defaultValue: "500MB"
      environment: production
      description: "Maximum file upload size"
    
    - key: storage.allowed_types
      type: array
      defaultValue: ["jpg", "jpeg", "png", "gif", "pdf", "doc", "docx"]
      environment: production
      description: "Allowed file upload types"
    
    # Monitoring Configuration
    - key: monitoring.metrics_enabled
      type: boolean
      defaultValue: true
      environment: production
      description: "Enable metrics collection"
    
    - key: monitoring.alert_threshold_cpu
      type: float
      defaultValue: 80.0
      environment: production
      description: "CPU alert threshold percentage"
      validation:
        min: 0
        max: 100
    
    - key: monitoring.alert_threshold_memory
      type: float
      defaultValue: 85.0
      environment: production
      description: "Memory alert threshold percentage"
      validation:
        min: 0
        max: 100
  
  # Configuration groups
  groups:
    - name: api
      configurations: ["api.rate_limit", "api.timeout"]
      description: "API related configurations"
    
    - name: features
      configurations: ["features.registration_enabled", "features.email_verification_required", "features.multi_tenant_enabled"]
      description: "Feature flags"
    
    - name: security
      configurations: ["security.jwt_expires_in", "security.session_timeout", "security.password_min_length"]
      description: "Security configurations"
    
    - name: performance
      configurations: ["performance.db_pool_size", "performance.cache_ttl"]
      description: "Performance tuning configurations"
    
    - name: storage
      configurations: ["storage.max_file_size", "storage.allowed_types"]
      description: "File storage configurations"
    
    - name: monitoring
      configurations: ["monitoring.metrics_enabled", "monitoring.alert_threshold_cpu", "monitoring.alert_threshold_memory"]
      description: "Monitoring and alerting configurations"

status:
  phase: defined
  configurations: 16
  groups: 6
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 配置變更腳本
    cat > "config/dynamic/update-config.sh" << 'EOF'
#!/bin/bash

# Dynamic Configuration Update Script

CONFIG_CENTER_URL="http://localhost:8080"
ENVIRONMENT=${1:-development}
KEY=$2
VALUE=$3

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <environment> <key> <value>"
    echo "Example: $0 production api.rate_limit 2000"
    exit 1
fi

echo "Updating configuration: $KEY = $VALUE (environment: $ENVIRONMENT)"

# Update configuration via API
curl -X PUT "$CONFIG_CENTER_URL/api/config/$ENVIRONMENT/$KEY" \
    -H "Content-Type: application/json" \
    -d "{&quot;value&quot;: &quot;$VALUE&quot;, &quot;changeReason&quot;: &quot;Manual update via script&quot;}"

echo "Configuration update requested"
EOF
    
    chmod +x "config/dynamic/update-config.sh"
    
    log_success "動態配置管理建立完成"
}

# 建立配置驗證系統
setup_configuration_validation() {
    log_info "建立配置驗證系統..."
    
    mkdir -p "config/validation"
    
    # 配置驗證規則
    cat > "config/validation/validation-rules.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ConfigurationValidation
metadata:
  name: config-validation-rules
  namespace: machinenativeops
spec:
  rules:
    # Database validation
    - name: database_connection_check
      type: database
      description: "Validate database connection parameters"
      configuration: "database.*"
      validation:
        - field: host
          required: true
          type: string
          pattern: '^[a-zA-Z0-9.-]+$'
        - field: port
          required: true
          type: integer
          min: 1
          max: 65535
        - field: name
          required: true
          type: string
          minLength: 1
        - field: ssl_mode
          type: string
          allowedValues: ["disable", "require", "verify-ca", "verify-full"]
    
    # Security validation
    - name: security_secrets_validation
      type: security
      description: "Validate security secrets"
      configuration: "security.*"
      validation:
        - field: jwt_secret
          required: true
          type: string
          minLength: 32
          noDefault: true
        - field: session_secret
          required: true
          type: string
          minLength: 32
          noDefault: true
    
    # API validation
    - name: api_configuration_validation
      type: api
      description: "Validate API configuration"
      configuration: "api.*"
      validation:
        - field: rate_limit
          type: integer
          min: 1
          max: 100000
        - field: timeout
          type: duration
          min: "1s"
          max: "300s"
    
    # Storage validation
    - name: storage_configuration_validation
      type: storage
      description: "Validate storage configuration"
      configuration: "storage.*"
      validation:
        - field: type
          required: true
          type: string
          allowedValues: ["local", "s3", "gcs", "azure"]
        - field: max_file_size
          type: size
          min: "1MB"
          max: "10GB"
  
  # Environment-specific validation
  environments:
    production:
      strict: true
      requireEncryption: true
      noDefaults: true
      requiredFields: ["database.host", "database.password", "security.jwt_secret"]
    
    development:
      strict: false
      requireEncryption: false
      noDefaults: false
    
    testing:
      strict: false
      requireEncryption: false
      noDefaults: false

status:
  phase: defined
  rules: 4
  environments: 3
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 驗證腳本
    cat > "config/validation/validate-config.sh" << 'EOF'
#!/bin/bash

# Configuration Validation Script

ENVIRONMENT=${1:-development}
CONFIG_FILE="config/environments/${ENVIRONMENT}.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "Validating configuration for environment: $ENVIRONMENT"

# Load configuration
set -a
source "$CONFIG_FILE"
set +a

# Validation functions
validate_database() {
    echo "Validating database configuration..."
    
    if [[ -z "$DB_HOST" ]]; then
        echo "❌ DB_HOST is required"
        return 1
    fi
    
    if [[ -z "$DB_PORT" ]]; then
        echo "❌ DB_PORT is required"
        return 1
    fi
    
    if [[ "$DB_PORT" -lt 1 || "$DB_PORT" -gt 65535 ]]; then
        echo "❌ DB_PORT must be between 1 and 65535"
        return 1
    fi
    
    echo "✅ Database configuration valid"
}

validate_security() {
    echo "Validating security configuration..."
    
    if [[ -z "$JWT_SECRET" ]]; then
        echo "❌ JWT_SECRET is required"
        return 1
    fi
    
    if [[ ${#JWT_SECRET} -lt 32 ]]; then
        echo "❌ JWT_SECRET must be at least 32 characters"
        return 1
    fi
    
    echo "✅ Security configuration valid"
}

validate_api() {
    echo "Validating API configuration..."
    
    if [[ -z "$API_PORT" ]]; then
        echo "❌ API_PORT is required"
        return 1
    fi
    
    if [[ "$API_PORT" -lt 1 || "$API_PORT" -gt 65535 ]]; then
        echo "❌ API_PORT must be between 1 and 65535"
        return 1
    fi
    
    echo "✅ API configuration valid"
}

# Production-specific validations
validate_production() {
    if [[ "$ENVIRONMENT" == "production" ]]; then
        echo "Validating production-specific requirements..."
        
        if [[ "$DEBUG" == "true" ]]; then
            echo "❌ DEBUG should be false in production"
            return 1
        fi
        
        if [[ "$LOG_LEVEL" == "debug" ]]; then
            echo "❌ LOG_LEVEL should not be debug in production"
            return 1
        fi
        
        if [[ "$DB_SSL_MODE" == "disable" ]]; then
            echo "❌ DB_SSL_MODE should not be disable in production"
            return 1
        fi
        
        echo "✅ Production requirements valid"
    fi
}

# Run validations
validation_errors=0

validate_database || ((validation_errors++))
validate_security || ((validation_errors++))
validate_api || ((validation_errors++))
validate_production || ((validation_errors++))

echo
if [[ $validation_errors -eq 0 ]]; then
    echo "🎉 All validations passed!"
    exit 0
else
    echo "❌ $validation_errors validation(s) failed"
    exit 1
fi
EOF
    
    chmod +x "config/validation/validate-config.sh"
    
    log_success "配置驗證系統建立完成"
}

# 建立配置同步機制
setup_configuration_sync() {
    log_info "建立配置同步機制..."
    
    mkdir -p "config/sync"
    
    # 配置同步配置
    cat > "config/sync/sync-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ConfigurationSync
metadata:
  name: config-sync
  namespace: machinenativeops
spec:
  syncStrategy: bidirectional
  syncInterval: 30s
  conflictResolution: manual
  
  sources:
    - name: database
      type: database
      priority: 1
      autoSync: true
    - name: files
      type: file
      priority: 2
      autoSync: true
      paths:
        - "config/environments/*.env"
        - "config/dynamic/*.yaml"
    - name: environment
      type: environment
      priority: 3
      autoSync: false
      prefix: MNO_
  
  destinations:
    - name: api_service
      type: service
      endpoint: "http://api-service:8000/api/config/sync"
      authentication: jwt
    - name: web_app
      type: client
      endpoint: "http://web-app:3000/api/config"
      authentication: oauth2
    - name: mobile_app
      type: client
      endpoint: "https://api.machinenativeops.com/mobile/config"
      authentication: api_key
  
  filters:
    - name: exclude_secrets
      type: exclude
      patterns: ["*.secret", "*.password", "*.key"]
    - name: include_public
      type: include
      patterns: ["features.*", "api.*", "ui.*"]
  
  notifications:
    enabled: true
    channels: ["webhook", "slack"]
    events: ["synced", "failed", "conflict"]

status:
  phase: configured
  sources: 3
  destinations: 3
  lastSync: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 同步腳本
    cat > "config/sync/sync-configs.sh" << 'EOF'
#!/bin/bash

# Configuration Synchronization Script

ENVIRONMENT=${1:-development}
CONFIG_CENTER_URL="http://localhost:8080"

echo "Syncing configurations for environment: $ENVIRONMENT"

# Sync from database to files
sync_from_database() {
    echo "Syncing from database..."
    
    curl -X GET "$CONFIG_CENTER_URL/api/config/$ENVIRONMENT" \
        -H "Accept: application/json" | \
        jq -r '.configurations[] | "\(.key)=\(.value)"' > "config/environments/${ENVIRONMENT}.synced.env"
    
    echo "Database configurations synced to file"
}

# Sync from files to database
sync_from_files() {
    echo "Syncing from files..."
    
    while IFS='=' read -r key value; do
        if [[ ! -z "$key" && ! -z "$value" && "$key" != \#* ]]; then
            curl -X PUT "$CONFIG_CENTER_URL/api/config/$ENVIRONMENT/$key" \
                -H "Content-Type: application/json" \
                -d "{&quot;value&quot;: &quot;$value&quot;, &quot;source&quot;: &quot;file_sync&quot;}"
        fi
    done < "config/environments/${ENVIRONMENT}.env"
    
    echo "File configurations synced to database"
}

# Sync to services
sync_to_services() {
    echo "Syncing to services..."
    
    # Sync to API service
    curl -X POST "$CONFIG_CENTER_URL/api/sync/services" \
        -H "Content-Type: application/json" \
        -d "{&quot;environment&quot;: &quot;$ENVIRONMENT&quot;, &quot;services&quot;: [&quot;api&quot;, &quot;web&quot;, &quot;mobile&quot;]}"
    
    echo "Configurations synced to services"
}

# Choose sync direction based on argument
case ${2:-database} in
    database)
        sync_from_database
        ;;
    files)
        sync_from_files
        ;;
    services)
        sync_to_services
        ;;
    all)
        sync_from_database
        sync_to_services
        ;;
    *)
        echo "Usage: $0 <environment> <direction>"
        echo "Directions: database, files, services, all"
        exit 1
        ;;
esac

echo "Configuration sync completed"
EOF
    
    chmod +x "config/sync/sync-configs.sh"
    
    log_success "配置同步機制建立完成"
}

# 建立配置監控
setup_configuration_monitoring() {
    log_info "建立配置監控系統..."
    
    mkdir -p "config/monitoring"
    
    # 配置監控規則
    cat > "config/monitoring/config-monitoring.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ConfigurationMonitoring
metadata:
  name: config-monitoring
  namespace: machinenativeops
spec:
  metrics:
    enabled: true
    collectionInterval: 30s
    
  alerts:
    - name: config_change_detected
      description: "Configuration change detected"
      condition: "config_changes_count > 0"
      severity: info
      channels: ["slack", "email"]
    
    - name: config_validation_failed
      description: "Configuration validation failed"
      condition: "config_validation_errors > 0"
      severity: warning
      channels: ["email", "slack"]
    
    - name: config_sync_failed
      description: "Configuration synchronization failed"
      condition: "config_sync_failures > 0"
      severity: critical
      channels: ["email", "slack", "pagerduty"]
    
    - name: critical_config_changed
      description: "Critical configuration changed"
      condition: "critical_config_changes > 0"
      severity: critical
      channels: ["email", "slack", "pagerduty"]
  
  dashboards:
    - name: configuration_overview
      description: "Configuration system overview"
      panels:
        - title: "Total Configurations"
          metrics: ["config_total_count"]
        - title: "Config Changes"
          metrics: ["config_changes_rate"]
        - title: "Validation Status"
          metrics: ["config_validation_status"]
        - title: "Sync Status"
          metrics: ["config_sync_status"]
  
  criticalConfigurations:
    - "security.jwt_secret"
    - "security.session_secret"
    - "database.password"
    - "storage.type"
    - "features.multi_tenant_enabled"

status:
  phase: initialized
  metrics: 4
  alerts: 4
  dashboards: 1
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "配置監控系統建立完成"
}

# 驗證配置系統
verify_configuration_system() {
    log_info "驗證配置系統..."
    
    local verification_errors=0
    
    # 檢查環境配置文件
    local environments=("development" "testing" "production")
    for env in "${environments[@]}"; do
        if [[ -f "config/environments/${env}.env" ]]; then
            log_success "${env} 環境配置存在"
        else
            log_error "${env} 環境配置不存在"
            ((verification_errors++))
        fi
    done
    
    # 檢查配置中心
    if [[ -f "config/center/config-center.yaml" ]]; then
        log_success "配置中心配置存在"
    else
        log_error "配置中心配置不存在"
        ((verification_errors++))
    fi
    
    # 檢查腳本可執行性
    local scripts=("config/dynamic/update-config.sh" "config/validation/validate-config.sh" "config/sync/sync-configs.sh")
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                log_success "$script 可執行"
            else
                log_warning "$script 不可執行"
            fi
        fi
    done
    
    # 測試配置驗證
    if [[ -x "config/validation/validate-config.sh" ]]; then
        if "config/validation/validate-config.sh" development &> /dev/null; then
            log_success "配置驗證腳本測試通過"
        else
            log_warning "配置驗證腳本測試失敗"
        fi
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "配置系統驗證通過"
        return 0
    else
        log_error "配置系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始配置系統初始化..."
    
    # 初始化階段
    local total_steps=8
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; setup_environment_variables
    ((current_step++)); progress_bar $current_step $total_steps; setup_configuration_center
    ((current_step++)); progress_bar $current_step $total_steps; setup_dynamic_configuration
    ((current_step++)); progress_bar $current_step $total_steps; setup_configuration_validation
    ((current_step++)); progress_bar $current_step $total_steps; setup_configuration_sync
    ((current_step++)); progress_bar $current_step $total_steps; setup_configuration_monitoring
    ((current_step++)); progress_bar $current_step $total_steps; verify_configuration_system
    
    echo; log_success "配置系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - 環境配置：config/environments/"
    echo "  - 配置中心：config/center/"
    echo "  - 動態配置：config/dynamic/"
    echo "  - 配置驗證：config/validation/"
    echo "  - 配置同步：config/sync/"
    echo "  - 配置監控：config/monitoring/"
    echo
    log_info "配置系統狀態：已初始化並驗證"
}

# 執行主函數
main "$@"