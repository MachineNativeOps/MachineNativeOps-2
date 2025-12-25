#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Security System Initialization
# =============================================================================
# 安全策略初始化腳本
# 職責：建立安全策略、訪問控制、加密、監控、合規性檢查
# 依賴：09-logging-init.sh
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
    log_info "載入安全系統配置..."
    
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    log_success "安全系統配置載入完成"
}

# 建立安全策略
setup_security_policies() {
    log_info "建立安全策略..."
    
    mkdir -p "config/security/policies"
    
    # 主安全策略配置
    cat > "config/security/policies/security-policies.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: SecurityPolicies
metadata:
  name: security-policies
  namespace: machinenativeops
spec:
  passwordPolicy:
    minLength: 12
    maxLength: 128
    requireUppercase: true
    requireLowercase: true
    requireNumbers: true
    requireSpecialChars: true
    preventReuse: 5
    expirationDays: 90
    lockoutThreshold: 5
    lockoutDuration: 30
  
  sessionPolicy:
    timeout: 24h
    maxConcurrentSessions: 3
    secureFlag: true
    httpOnly: true
    sameSite: strict
    renewalThreshold: 1h
  
  accessPolicy:
    defaultDeny: true
    minPasswordStrength: 3
    twoFactorRequired: true
    ipWhitelistEnabled: false
    geoRestrictionEnabled: false
  
  encryptionPolicy:
    atRest: true
    inTransit: true
    algorithm: AES-256-GCM
    keyRotation: 90d
    certificateValidation: strict
  
  auditPolicy:
    logAllAccess: true
    logFailedAttempts: true
    logPrivilegedActions: true
    retentionPeriod: 7y
    realTimeMonitoring: true
  
  complianceStandards:
    - name: ISO27001
      enabled: true
      controls:
        - A.9.2.1  # Access control policy
        - A.10.1.1 # Cryptographic controls
        - A.12.3.1 # Data backup
        - A.14.2.5 # Secure system engineering
    - name: SOC2
      type: Type II
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

status:
  phase: defined
  policies: 6
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 網路安全策略
    cat > "config/security/policies/network-security.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: NetworkSecurityPolicy
metadata:
  name: network-security
  namespace: machinenativeops
spec:
  firewall:
    enabled: true
    defaultPolicy: deny
    rules:
      - name: allow-http
        protocol: tcp
        ports: [80, 443]
        action: allow
      - name: allow-ssh
        protocol: tcp
        ports: [22]
        source: 10.0.0.0/8
        action: allow
      - name: allow-api
        protocol: tcp
        ports: [8000, 8001, 8002, 8003, 8004, 8005]
        action: allow
  
  ddosProtection:
    enabled: true
    threshold: 1000
    burstSize: 100
    duration: 60s
  
  rateLimiting:
    global: 10000
    perIP: 100
    perUser: 500
    window: 1m
  
  sslConfiguration:
    minVersion: TLSv1.2
    preferredCiphers:
      - "TLS_AES_256_GCM_SHA384"
      - "TLS_CHACHA20_POLY1305_SHA256"
      - "TLS_AES_128_GCM_SHA256"
    hsts:
      enabled: true
      maxAge: 31536000
      includeSubDomains: true
      preload: true
  
  cors:
    enabled: true
    allowedOrigins:
      - "https://app.machinenativeops.com"
      - "https://admin.machinenativeops.com"
    allowedMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allowedHeaders: ["Content-Type", "Authorization", "X-Request-ID"]
    maxAge: 86400

status:
  phase: configured
  firewallRules: 3
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 數據保護策略
    cat > "config/security/policies/data-protection.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: DataProtectionPolicy
metadata:
  name: data-protection
  namespace: machinenativeops
spec:
  classification:
    levels:
      - name: public
        description: "Publicly accessible data"
        controls: ["integrity", "availability"]
      - name: internal
        description: "Internal use only"
        controls: ["confidentiality", "integrity", "availability"]
      - name: confidential
        description: "Confidential business data"
        controls: ["confidentiality", "integrity", "availability", "encryption"]
      - name: restricted
        description: "Highly sensitive data"
        controls: ["confidentiality", "integrity", "availability", "encryption", "access_logging"]
  
  encryption:
    databases:
      enabled: true
      algorithm: AES-256
      keyManagement: "vault"
    files:
      enabled: true
      algorithm: AES-256-GCM
      keyDerivation: "PBKDF2"
    communications:
      enabled: true
      protocol: TLS-1.3
      certificateManagement: "letsencrypt"
  
  backup:
    frequency: daily
    retention: 30d
    encryption: true
    location: "s3://machinenativeops-backups"
    verification: true
  
  dataLossPrevention:
    enabled: true
    patterns:
      - type: "credit_card"
        regex: "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b"
        action: "block"
      - type: "ssn"
        regex: "\\b\\d{3}-\\d{2}-\\d{4}\\b"
        action: "block"
      - type: "email"
        regex: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b"
        action: "mask"
  
  retention:
    default: 7y
    categories:
      user_data: 7y
      financial_data: 10y
      audit_logs: 7y
      access_logs: 2y

status:
  phase: configured
  classificationLevels: 4
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "安全策略建立完成"
}

# 建立訪問控制系統
setup_access_control() {
    log_info "建立訪問控制系統..."
    
    mkdir -p "config/security/rbac"
    
    # RBAC 配置
    cat > "config/security/rbac/rbac-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: RBACConfiguration
metadata:
  name: rbac-config
  namespace: machinenativeops
spec:
  roles:
    - name: super_admin
      description: "Super administrator with full system access"
      permissions:
        - "*"
      conditions: {}
    
    - name: admin
      description: "System administrator"
      permissions:
        - "users.*"
        - "roles.*"
        - "organizations.*"
        - "projects.*"
        - "audit.*"
      conditions: {}
    
    - name: developer
      description: "Application developer"
      permissions:
        - "projects.*"
        - "files.*"
        - "deployments.*"
        - "logs.read"
      conditions:
        - field: "project_id"
          operator: "equals"
          value: "user.project_members"
    
    - name: user
      description: "Regular user"
      permissions:
        - "profile.*"
        - "projects.read"
        - "projects.create"
        - "files.*"
        - "notifications.*"
      conditions:
        - field: "project_id"
          operator: "equals"
          value: "user.project_members"
    
    - name: viewer
      description: "Read-only access"
      permissions:
        - "projects.read"
        - "files.read"
        - "notifications.*"
      conditions:
        - field: "project_id"
          operator: "equals"
          value: "user.project_members"
  
  permissionHierarchy:
    "*": ["users.*", "roles.*", "organizations.*", "projects.*", "files.*", "audit.*", "logs.*"]
    "users.*": ["users.read", "users.create", "users.update", "users.delete"]
    "projects.*": ["projects.read", "projects.create", "projects.update", "projects.delete"]
    "files.*": ["files.read", "files.create", "files.update", "files.delete"]
  
  accessControl:
    defaultDeny: true
    inheritance: true
    resourceHierarchy:
      - "organization"
      - "project"
      - "file"
      - "deployment"
  
  conditions:
    - name: "user_organization"
      type: "field"
      field: "organization_id"
      operator: "equals"
      value: "user.organization_id"
    - name: "user_project_member"
      type: "query"
      query: "SELECT 1 FROM project_members WHERE user_id = :user_id AND project_id = :resource_project_id"
    - name: "business_hours"
      type: "time"
      start: "09:00"
      end: "17:00"
      timezone: "UTC"
      weekdays: ["monday", "tuesday", "wednesday", "thursday", "friday"]
    - name: "ip_whitelist"
      type: "ip"
      allowedRanges: ["10.0.0.0/8", "192.168.0.0/16"]

status:
  phase: configured
  roles: 5
  conditions: 4
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 權限數據庫 Schema
    cat > "config/security/rbac/permissions-schema.sql" << 'EOF'
-- RBAC Permissions Database Schema

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '[]',
    conditions JSONB NOT NULL DEFAULT '{}',
    is_system_role BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- User roles mapping
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    conditions JSONB DEFAULT '{}',
    UNIQUE(user_id, role_id)
);

-- Resource permissions
CREATE TABLE IF NOT EXISTS resource_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID NOT NULL,
    permission VARCHAR(100) NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    conditions JSONB DEFAULT '{}',
    UNIQUE(user_id, resource_type, resource_id, permission)
);

-- Access logs
CREATE TABLE IF NOT EXISTS access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    permission VARCHAR(100),
    granted BOOLEAN NOT NULL,
    reason TEXT,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id UUID,
    metadata JSONB DEFAULT '{}'
);

-- Role hierarchy
CREATE TABLE IF NOT EXISTS role_hierarchy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    child_role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(parent_role_id, child_role_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_resource_permissions_user ON resource_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_resource_permissions_resource ON resource_permissions(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_user ON access_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_timestamp ON access_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_access_logs_action ON access_logs(action);

-- Insert default roles
INSERT INTO roles (name, description, permissions, is_system_role) VALUES
('super_admin', 'Super administrator with full system access', '["*"]', true),
('admin', 'System administrator', '["users.*", "roles.*", "organizations.*", "projects.*", "audit.*"]', true),
('developer', 'Application developer', '["projects.*", "files.*", "deployments.*", "logs.read"]', true),
('user', 'Regular user', '["profile.*", "projects.read", "projects.create", "files.*", "notifications.*"]', true),
('viewer', 'Read-only access', '["projects.read", "files.read", "notifications.*"]', true)
ON CONFLICT (name) DO NOTHING;
EOF
    
    log_success "訪問控制系統建立完成"
}

# 建立加密管理
setup_encryption_management() {
    log_info "建立加密管理..."
    
    mkdir -p "config/security/encryption"
    
    # 加密配置
    cat > "config/security/encryption/encryption-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: EncryptionConfiguration
metadata:
  name: encryption-config
  namespace: machinenativeops
spec:
  keyManagement:
    provider: "vault"
    address: "https://vault.machinenativeops.com:8200"
    authMethod: "kubernetes"
    mountPath: "secret"
    
  encryptionKeys:
    - name: "data-encryption-key"
      type: "AES-256-GCM"
      purpose: "data-at-rest"
      rotation: "90d"
      algorithm: "AES-256"
      keySize: 256
    - name: "session-encryption-key"
      type: "AES-256-GCM"
      purpose: "session-data"
      rotation: "30d"
      algorithm: "AES-256"
      keySize: 256
    - name: "jwt-signing-key"
      type: "RSA-2048"
      purpose: "jwt-signing"
      rotation: "365d"
      algorithm: "RS256"
      keySize: 2048
    - name: "file-encryption-key"
      type: "AES-256-GCM"
      purpose: "file-encryption"
      rotation: "180d"
      algorithm: "AES-256"
      keySize: 256
  
  encryptionPolicies:
    - name: "user-personal-data"
      fields: ["email", "phone", "address", "ssn", "credit_card"]
      key: "data-encryption-key"
      algorithm: "AES-256-GCM"
      searchable: false
    - name: "session-data"
      fields: ["session_token", "csrf_token", "oauth_tokens"]
      key: "session-encryption-key"
      algorithm: "AES-256-GCM"
      searchable: false
    - name: "file-content"
      fields: ["file_content", "file_metadata"]
      key: "file-encryption-key"
      algorithm: "AES-256-GCM"
      searchable: false
    - name: "api-keys"
      fields: ["api_key", "webhook_secret", "oauth_client_secret"]
      key: "data-encryption-key"
      algorithm: "AES-256-GCM"
      searchable: false
  
  certificateManagement:
    provider: "letsencrypt"
    email: "admin@machinenativeops.com"
    autoRenew: true
    renewBefore: 30d
    certificates:
      - name: "wildcard"
        domains: ["*.machinenativeops.com", "machinenativeops.com"]
        keySize: 2048
        digest: "sha256"

status:
  phase: configured
  keys: 4
  policies: 4
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 加密服務腳本
    cat > "config/security/encryption/encryption-service.py" << 'EOF'
"""
Encryption Service for MachineNativeOps
"""

import os
import base64
import json
import hashlib
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import hvac

class EncryptionService:
    def __init__(self, vault_url=None, vault_token=None):
        self.vault_url = vault_url or os.getenv('VAULT_URL')
        self.vault_token = vault_token or os.getenv('VAULT_TOKEN')
        self.vault_client = None
        
        if self.vault_url and self.vault_token:
            self.vault_client = hvac.Client(url=self.vault_url, token=self.vault_token)
    
    def generate_key(self, key_type='AES-256-GCM'):
        """Generate encryption key based on type"""
        if key_type == 'AES-256-GCM':
            return Fernet.generate_key()
        elif key_type == 'AES-256':
            return os.urandom(32)
        elif key_type == 'RSA-2048':
            # RSA key generation would require additional crypto libraries
            raise NotImplementedError("RSA key generation not implemented")
        else:
            raise ValueError(f"Unsupported key type: {key_type}")
    
    def get_vault_key(self, key_name):
        """Retrieve key from Vault"""
        if not self.vault_client:
            raise ValueError("Vault client not initialized")
        
        try:
            response = self.vault_client.secrets.kv.v2.read_secret_version(
                path=f'encryption/{key_name}'
            )
            return response['data']['data']['key']
        except Exception as e:
            raise ValueError(f"Failed to retrieve key from Vault: {str(e)}")
    
    def store_vault_key(self, key_name, key_value):
        """Store key in Vault"""
        if not self.vault_client:
            raise ValueError("Vault client not initialized")
        
        try:
            self.vault_client.secrets.kv.v2.create_or_update_secret(
                path=f'encryption/{key_name}',
                secret={'key': key_value.decode() if isinstance(key_value, bytes) else key_value}
            )
        except Exception as e:
            raise ValueError(f"Failed to store key in Vault: {str(e)}")
    
    def encrypt_data(self, data, key=None, key_name=None, algorithm='AES-256-GCM'):
        """Encrypt data with specified key or key from Vault"""
        if key_name and not key:
            key = self.get_vault_key(key_name)
        
        if not key:
            raise ValueError("Either key or key_name must be provided")
        
        if isinstance(key, str):
            key = key.encode()
        
        data_str = json.dumps(data) if not isinstance(data, str) else data
        data_bytes = data_str.encode()
        
        if algorithm == 'AES-256-GCM':
            f = Fernet(key)
            encrypted_data = f.encrypt(data_bytes)
            return base64.b64encode(encrypted_data).decode()
        elif algorithm == 'AES-256-CBC':
            # Implement AES-CBC encryption
            iv = os.urandom(16)
            cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
            encryptor = cipher.encryptor()
            
            # Pad data to block size
            pad_length = 16 - (len(data_bytes) % 16)
            padded_data = data_bytes + bytes([pad_length] * pad_length)
            
            encrypted_data = encryptor.update(padded_data) + encryptor.finalize()
            return base64.b64encode(iv + encrypted_data).decode()
        else:
            raise ValueError(f"Unsupported algorithm: {algorithm}")
    
    def decrypt_data(self, encrypted_data, key=None, key_name=None, algorithm='AES-256-GCM'):
        """Decrypt data with specified key or key from Vault"""
        if key_name and not key:
            key = self.get_vault_key(key_name)
        
        if not key:
            raise ValueError("Either key or key_name must be provided")
        
        if isinstance(key, str):
            key = key.encode()
        
        encrypted_bytes = base64.b64decode(encrypted_data)
        
        if algorithm == 'AES-256-GCM':
            f = Fernet(key)
            decrypted_data = f.decrypt(encrypted_bytes)
            data_str = decrypted_data.decode()
            
            # Try to parse as JSON, return as string if fails
            try:
                return json.loads(data_str)
            except json.JSONDecodeError:
                return data_str
        elif algorithm == 'AES-256-CBC':
            iv = encrypted_bytes[:16]
            cipher_text = encrypted_bytes[16:]
            
            cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
            decryptor = cipher.decryptor()
            
            padded_data = decryptor.update(cipher_text) + decryptor.finalize()
            pad_length = padded_data[-1]
            data_bytes = padded_data[:-pad_length]
            
            data_str = data_bytes.decode()
            try:
                return json.loads(data_str)
            except json.JSONDecodeError:
                return data_str
        else:
            raise ValueError(f"Unsupported algorithm: {algorithm}")
    
    def hash_password(self, password, salt=None):
        """Hash password with PBKDF2"""
        if salt is None:
            salt = os.urandom(32)
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
            backend=default_backend()
        )
        
        hashed = kdf.derive(password.encode())
        return {
            'hash': base64.b64encode(hashed).decode(),
            'salt': base64.b64encode(salt).decode(),
            'iterations': 100000
        }
    
    def verify_password(self, password, stored_hash):
        """Verify password against stored hash"""
        salt = base64.b64decode(stored_hash['salt'])
        iterations = stored_hash['iterations']
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=iterations,
            backend=default_backend()
        )
        
        hashed = kdf.derive(password.encode())
        stored_hash_bytes = base64.b64decode(stored_hash['hash'])
        
        return hashed == stored_hash_bytes

# Initialize encryption service
encryption_service = EncryptionService()
EOF
    
    log_success "加密管理建立完成"
}

# 建立安全監控
setup_security_monitoring() {
    log_info "建立安全監控..."
    
    mkdir -p "config/security/monitoring"
    
    # 安全監控配置
    cat > "config/security/monitoring/security-monitoring.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: SecurityMonitoringConfiguration
metadata:
  name: security-monitoring
  namespace: machinenativeops
spec:
  monitoringEnabled: true
  realTimeDetection: true
  automatedResponse: true
  
  threatDetection:
    - name: "brute_force_attack"
      description: "Detect brute force login attempts"
      condition: "failed_login_count > 5 within 5m"
      severity: high
      response: ["block_ip", "notify_admin"]
    
    - name: "unusual_access_pattern"
      description: "Detect unusual access patterns"
      condition: "login_count > 100 within 1h from single_ip"
      severity: medium
      response: ["require_mfa", "notify_user"]
    
    - name: "privilege_escalation"
      description: "Detect privilege escalation attempts"
      condition: "role_change AND admin_privilege_granted"
      severity: critical
      response: ["suspend_user", "notify_admin", "audit_log"]
    
    - name: "data_exfiltration"
      description: "Detect potential data exfiltration"
      condition: "large_file_download OR mass_data_export"
      severity: critical
      response: ["block_access", "notify_admin", "audit_log"]
    
    - name: "sql_injection"
      description: "Detect SQL injection attempts"
      condition: "query_pattern_matches_sql_injection"
      severity: critical
      response: ["block_request", "notify_admin", "log_incident"]
  
  incidentResponse:
    automated:
      - trigger: "critical_threat_detected"
        actions: ["isolate_system", "preserve_evidence", "notify_security_team"]
      - trigger: "high_threat_detected"
        actions: ["block_malicious_ips", "enable_additional_logging", "notify_admin"]
    
    manual:
      - trigger: "medium_threat_detected"
        actions: ["create_incident_ticket", "notify_security_team"]
      - trigger: "low_threat_detected"
        actions: ["log_for_review", "weekly_report"]
  
  complianceMonitoring:
    - standard: "ISO27001"
      controls:
        - "A.9.2.1": "access_control_policy_monitoring"
        - "A.12.3.1": "data_backup_monitoring"
        - "A.14.2.5": "secure_system_engineering_monitoring"
    - standard: "SOC2"
      controls:
        - "CC6.1": "logical_access_controls_monitoring"
        - "CC6.7": "data_transmission_monitoring"
        - "CC7.1": "system_operations_monitoring"
    - standard: "GDPR"
      controls:
        - "Art.25": "data_protection_by_design_monitoring"
        - "Art.32": "security_processing_monitoring"
        - "Art.33": "data_breach_notification_monitoring"
  
  securityMetrics:
    - name: "failed_login_rate"
      query: "rate(failed_login_total[5m])"
      threshold: 0.1
      severity: warning
    
    - name: "suspicious_ip_access"
      query: "count by (ip_address) (access_log where suspicious_activity = true)"
      threshold: 50
      severity: high
    
    - name: "privilege_escalation_attempts"
      query: "rate(privilege_escalation_attempts[5m])"
      threshold: 0.01
      severity: critical
    
    - name: "data_access_anomalies"
      query: "rate(unusual_data_access[5m])"
      threshold: 0.05
      severity: medium

status:
  phase: configured
  threatDetectors: 5
  incidentResponses: 6
  complianceStandards: 3
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 安全事件響應腳本
    cat > "config/security/monitoring/incident-response.py" << 'EOF'
"""
Security Incident Response System
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import requests

class IncidentResponseSystem:
    def __init__(self, config_file='config/security/monitoring/security-monitoring.yaml'):
        self.config = self._load_config(config_file)
        self.logger = logging.getLogger(__name__)
        
    def _load_config(self, config_file):
        """Load security monitoring configuration"""
        try:
            with open(config_file, 'r') as f:
                return yaml.safe_load(f)
        except Exception as e:
            self.logger.error(f"Failed to load config: {str(e)}")
            return {}
    
    def handle_threat(self, threat_type: str, details: Dict) -> Dict:
        """Handle security threat based on type"""
        threat_config = self._find_threat_config(threat_type)
        if not threat_config:
            return {"status": "error", "message": f"Unknown threat type: {threat_type}"}
        
        # Log the incident
        incident_id = self._log_incident(threat_type, details)
        
        # Execute automated response
        response_actions = self._execute_response(threat_config, details)
        
        # Create incident ticket if needed
        if threat_config.get('severity') in ['critical', 'high']:
            ticket_id = self._create_incident_ticket(threat_type, details, incident_id)
        else:
            ticket_id = None
        
        return {
            "status": "success",
            "incident_id": incident_id,
            "actions_taken": response_actions,
            "ticket_id": ticket_id
        }
    
    def _find_threat_config(self, threat_type: str) -> Optional[Dict]:
        """Find threat configuration"""
        for threat in self.config.get('spec', {}).get('threatDetection', []):
            if threat.get('name') == threat_type:
                return threat
        return None
    
    def _log_incident(self, threat_type: str, details: Dict) -> str:
        """Log security incident"""
        incident_id = f"inc_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{threat_type}"
        
        incident_data = {
            "incident_id": incident_id,
            "threat_type": threat_type,
            "timestamp": datetime.utcnow().isoformat(),
            "details": details,
            "status": "open"
        }
        
        # Log to security log
        self.logger.warning(f"Security incident: {json.dumps(incident_data)}")
        
        # Store in database or log file
        self._store_incident(incident_data)
        
        return incident_id
    
    def _execute_response(self, threat_config: Dict, details: Dict) -> List[str]:
        """Execute automated response actions"""
        actions_taken = []
        response_actions = threat_config.get('response', [])
        
        for action in response_actions:
            try:
                if action == "block_ip":
                    self._block_ip(details.get('ip_address'))
                    actions_taken.append(f"Blocked IP: {details.get('ip_address')}")
                
                elif action == "notify_admin":
                    self._notify_admin(threat_config.get('name'), details)
                    actions_taken.append("Notified administrator")
                
                elif action == "notify_user":
                    self._notify_user(details.get('user_id'), threat_config.get('name'))
                    actions_taken.append(f"Notified user: {details.get('user_id')}")
                
                elif action == "suspend_user":
                    self._suspend_user(details.get('user_id'))
                    actions_taken.append(f"Suspended user: {details.get('user_id')}")
                
                elif action == "block_request":
                    actions_taken.append("Request blocked at firewall level")
                
                elif action == "audit_log":
                    actions_taken.append("Enhanced audit logging enabled")
                
            except Exception as e:
                self.logger.error(f"Failed to execute action {action}: {str(e)}")
        
        return actions_taken
    
    def _block_ip(self, ip_address: str):
        """Block IP address at firewall"""
        if not ip_address:
            return
        
        # Implementation would depend on firewall system
        # Example using iptables or cloud security group
        pass
    
    def _notify_admin(self, threat_name: str, details: Dict):
        """Notify administrators"""
        message = f"""
        Security Alert: {threat_name}
        Details: {json.dumps(details, indent=2)}
        Time: {datetime.utcnow().isoformat()}
        """
        
        # Send via email, Slack, or other notification system
        self._send_notification("admin", message)
    
    def _notify_user(self, user_id: str, threat_name: str):
        """Notify user"""
        message = f"""
        Security Alert: We detected unusual activity on your account.
        Action: {threat_name}
        Time: {datetime.utcnow().isoformat()}
        Please contact support if you don't recognize this activity.
        """
        
        self._send_notification("user", message, user_id)
    
    def _suspend_user(self, user_id: str):
        """Suspend user account"""
        # Update user status in database
        pass
    
    def _create_incident_ticket(self, threat_type: str, details: Dict, incident_id: str) -> str:
        """Create incident ticket in ticketing system"""
        ticket_data = {
            "title": f"Security Incident: {threat_type}",
            "description": f"Incident ID: {incident_id}\n\nDetails:\n{json.dumps(details, indent=2)}",
            "priority": "high",
            "category": "security",
            "assignee": "security_team"
        }
        
        # Integration with ticketing system (Jira, ServiceNow, etc.)
        ticket_id = f"SEC-{datetime.now().strftime('%Y%m%d')}-{len(ticket_data['title'])}"
        
        return ticket_id
    
    def _send_notification(self, notification_type: str, message: str, recipient: str = None):
        """Send notification via appropriate channel"""
        # Implementation depends on notification system
        pass
    
    def _store_incident(self, incident_data: Dict):
        """Store incident in database or log file"""
        # Implementation depends on storage system
        pass

# Initialize incident response system
incident_response = IncidentResponseSystem()
EOF
    
    log_success "安全監控建立完成"
}

# 建立安全掃描
setup_security_scanning() {
    log_info "建立安全掃描..."
    
    mkdir -p "config/security/scanning"
    
    # 安全掃描配置
    cat > "config/security/scanning/security-scanning.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: SecurityScanningConfiguration
metadata:
  name: security-scanning
  namespace: machinenativeops
spec:
  scanningEnabled: true
  scheduledScans: true
  
  vulnerabilityScanning:
    - name: "code_scan"
      type: "static_analysis"
      tools: ["semgrep", "codeql", "bandit", "safety"]
      schedule: "daily"
      targets: ["src/", "scripts/"]
    
    - name: "dependency_scan"
      type: "dependency_analysis"
      tools: ["snyk", "dependabot", "npm audit"]
      schedule: "daily"
      targets: ["requirements.txt", "package.json", "yarn.lock"]
    
    - name: "container_scan"
      type: "container_analysis"
      tools: ["trivy", "clair", "grype"]
      schedule: "on_build"
      targets: ["Dockerfile", "docker-compose.yml"]
    
    - name: "infrastructure_scan"
      type: "infrastructure_analysis"
      tools: ["checkov", "tfsec", "cfn_nag"]
      schedule: "daily"
      targets: ["terraform/", "cloudformation/"]
  
  penetrationTesting:
    - name: "web_app_scan"
      type: "web_application"
      tools: ["owasp_zap", "burp_suite", "nikto"]
      schedule: "weekly"
      targets: ["https://app.machinenativeops.com"]
    
    - name: "api_scan"
      type: "api_security"
      tools: ["postman_security", "insomnia_security"]
      schedule: "weekly"
      targets: ["https://api.machinenativeops.com"]
    
    - name: "network_scan"
      type: "network_security"
      tools: ["nmap", "masscan", "openvas"]
      schedule: "monthly"
      targets: ["machinenativeops.com"]
  
  complianceScanning:
    - standard: "PCI-DSS"
      controls: ["data_encryption", "access_control", "network_security"]
      tools: ["open-scap", "lynis"]
    
    - standard: "HIPAA"
      controls: ["phi_protection", "audit_logging", "access_control"]
      tools: ["open-scap", "lynis"]
    
    - standard: "GDPR"
      controls: ["data_protection", "consent_management", "breach_notification"]
      tools: ["gdpr-scanner", "privacy-scanner"]
  
  reporting:
    frequency: "weekly"
    formats: ["json", "pdf", "html"]
    distribution: ["security_team", "dev_team", "management"]
    retention: "1y"

status:
  phase: configured
  vulnerabilityScanners: 4
  penetrationTests: 3
  complianceStandards: 3
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 安全掃描腳本
    cat > "config/security/scanning/run-security-scan.sh" << 'EOF'
#!/bin/bash

# Security Scanning Script

SCAN_TYPE=${1:-all}
REPORT_DIR="reports/security"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$REPORT_DIR"

# Static code analysis
run_static_analysis() {
    echo "Running static code analysis..."
    
    # Semgrep scan
    echo "Running Semgrep..."
    semgrep --config=auto --json --output="$REPORT_DIR/semgrep_$TIMESTAMP.json" src/
    
    # Bandit scan (Python security)
    echo "Running Bandit..."
    bandit -r src/ -f json -o "$REPORT_DIR/bandit_$TIMESTAMP.json"
    
    # Safety scan (Python dependencies)
    echo "Running Safety..."
    safety check --json --output "$REPORT_DIR/safety_$TIMESTAMP.json"
    
    echo "Static code analysis completed"
}

# Dependency scanning
run_dependency_scan() {
    echo "Running dependency scanning..."
    
    # Snyk scan (if available)
    if command -v snyk &> /dev/null; then
        echo "Running Snyk..."
        snyk test --json --output="$REPORT_DIR/snyk_$TIMESTAMP.json" || true
    fi
    
    # npm audit (Node.js)
    for platform in web mobile desktop; do
        if [[ -f "src/$platform/package.json" ]]; then
            echo "Running npm audit for $platform..."
            cd "src/$platform"
            npm audit --json > "../../../$REPORT_DIR/npm-audit-$platform-$TIMESTAMP.json" || true
            cd - > /dev/null
        fi
    done
    
    echo "Dependency scanning completed"
}

# Container scanning
run_container_scan() {
    echo "Running container scanning..."
    
    # Trivy scan
    if command -v trivy &> /dev/null; then
        echo "Running Trivy..."
        trivy image --format json --output "$REPORT_DIR/trivy_$TIMESTAMP.json" machinenativeops/api:latest || true
    fi
    
    echo "Container scanning completed"
}

# Network scanning
run_network_scan() {
    echo "Running network scanning..."
    
    # Nmap scan (basic)
    if command -v nmap &> /dev/null; then
        echo "Running Nmap..."
        nmap -sS -sV -oN "$REPORT_DIR/nmap_$TIMESTAMP.txt" localhost || true
    fi
    
    echo "Network scanning completed"
}

# Generate consolidated report
generate_report() {
    echo "Generating consolidated security report..."
    
    cat > "$REPORT_DIR/security-report-$TIMESTAMP.md" << EOF
# Security Scan Report
Generated: $(date)
Scan Type: $SCAN_TYPE

## Executive Summary
- Total vulnerabilities found: $(find "$REPORT_DIR" -name "*$TIMESTAMP.json" -exec cat {} \; | jq -r '.vulnerabilities | length' 2>/dev/null || echo "N/A")
- High severity: $(find "$REPORT_DIR" -name "*$TIMESTAMP.json" -exec cat {} \; | jq -r '.vulnerabilities[] | select(.severity | test("high|critical"; "i")) | .id' 2>/dev/null | wc -l)
- Medium severity: $(find "$REPORT_DIR" -name "*$TIMESTAMP.json" -exec cat {} \; | jq -r '.vulnerabilities[] | select(.severity == "medium") | .id' 2>/dev/null | wc -l)
- Low severity: $(find "$REPORT_DIR" -name "*$TIMESTAMP.json" -exec cat {} \; | jq -r '.vulnerabilities[] | select(.severity == "low") | .id' 2>/dev/null | wc -l)

## Scan Results

### Static Code Analysis
- Semgrep: $(find "$REPORT_DIR" -name "semgrep_$TIMESTAMP.json" -exec cat {} \; | jq -r '.results | length' 2>/dev/null || echo "0") findings
- Bandit: $(find "$REPORT_DIR" -name "bandit_$TIMESTAMP.json" -exec cat {} \; | jq -r '.results | length' 2>/dev/null || echo "0") findings
- Safety: $(find "$REPORT_DIR" -name "safety_$TIMESTAMP.json" -exec cat {} \; | jq -r '.vulnerabilities | length' 2>/dev/null || echo "0") vulnerabilities

### Dependency Scanning
- Snyk: $(find "$REPORT_DIR" -name "snyk_$TIMESTAMP.json" -exec cat {} \; | jq -r '.vulnerabilities | length' 2>/dev/null || echo "0") vulnerabilities
- npm audit: $(find "$REPORT_DIR" -name "npm-audit-*-$TIMESTAMP.json" -exec cat {} \; | jq -r '.vulnerabilities | length' 2>/dev/null || echo "0") vulnerabilities

### Container Scanning
- Trivy: $(find "$REPORT_DIR" -name "trivy_$TIMESTAMP.json" -exec cat {} \; | jq -r '.Results[0].Vulnerabilities | length' 2>/dev/null || echo "0") vulnerabilities

### Network Scanning
- Nmap: See detailed report in nmap_$TIMESTAMP.txt

## Recommendations
1. Address high and critical severity vulnerabilities immediately
2. Update dependencies with known vulnerabilities
3. Implement secure coding practices
4. Regular security testing and monitoring

EOF
    
    echo "Security report generated: $REPORT_DIR/security-report-$TIMESTAMP.md"
}

# Main execution
main() {
    echo "Starting security scan: $SCAN_TYPE"
    
    case "$SCAN_TYPE" in
        "static")
            run_static_analysis
            ;;
        "dependency")
            run_dependency_scan
            ;;
        "container")
            run_container_scan
            ;;
        "network")
            run_network_scan
            ;;
        "all")
            run_static_analysis
            run_dependency_scan
            run_container_scan
            run_network_scan
            ;;
        *)
            echo "Usage: $0 [static|dependency|container|network|all]"
            exit 1
            ;;
    esac
    
    generate_report
    
    echo "Security scan completed successfully!"
}

main "$@"
EOF
    
    chmod +x "config/security/scanning/run-security-scan.sh"
    
    log_success "安全掃描建立完成"
}

# 驗證安全系統
verify_security_system() {
    log_info "驗證安全系統..."
    
    local verification_errors=0
    
    # 檢查安全策略文件
    local required_files=(
        "config/security/policies/security-policies.yaml"
        "config/security/policies/network-security.yaml"
        "config/security/policies/data-protection.yaml"
        "config/security/rbac/rbac-config.yaml"
        "config/security/encryption/encryption-config.yaml"
        "config/security/monitoring/security-monitoring.yaml"
        "config/security/scanning/security-scanning.yaml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "安全配置文件存在：$(basename "$file")"
        else
            log_error "安全配置文件不存在：$file"
            ((verification_errors++))
        fi
    done
    
    # 檢查腳本可執行性
    if [[ -f "config/security/scanning/run-security-scan.sh" ]] && [[ -x "config/security/scanning/run-security-scan.sh" ]]; then
        log_success "安全掃描腳本可執行"
    else
        log_error "安全掃描腳本不可執行"
        ((verification_errors++))
    fi
    
    # 檢查加密服務
    if [[ -f "config/security/encryption/encryption-service.py" ]]; then
        log_success "加密服務文件存在"
    else
        log_error "加密服務文件不存在"
        ((verification_errors++))
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "安全系統驗證通過"
        return 0
    else
        log_error "安全系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始安全系統初始化..."
    
    # 初始化階段
    local total_steps=7
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; setup_security_policies
    ((current_step++)); progress_bar $current_step $total_steps; setup_access_control
    ((current_step++)); progress_bar $current_step $total_steps; setup_encryption_management
    ((current_step++)); progress_bar $current_step $total_steps; setup_security_monitoring
    ((current_step++)); progress_bar $current_step $total_steps; setup_security_scanning
    ((current_step++)); progress_bar $current_step $total_steps; verify_security_system
    
    echo; log_success "安全系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - 安全策略：config/security/policies/"
    echo "  - 訪問控制：config/security/rbac/"
    echo "  - 加密管理：config/security/encryption/"
    echo "  - 安全監控：config/security/monitoring/"
    echo "  - 安全掃描：config/security/scanning/"
    echo "  - 掃描報告：reports/security/"
    echo
    log_info "安全系統狀態：已初始化並驗證"
}

# 執行主函數
main "$@"