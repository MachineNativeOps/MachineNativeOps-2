#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Database System Initialization
# =============================================================================
# 資料庫系統初始化腳本（多端共用核心）
# 職責：建立共用資料庫、初始化 schema、設定連接池、建立複製
# 依賴：05-provenance-init.sh
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
    log_info "載入資料庫系統配置..."
    
    # 建立資料庫配置檔案
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    # 載入資料庫配置
    cat > "config/database.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: DatabaseConfiguration
metadata:
  name: shared-database-cluster
  namespace: machinenativeops
spec:
  cluster:
    name: machinenativeops-cluster
    version: "15"
    engine: postgresql
    architecture: "primary-replica"
    nodes:
      primary: 1
      replicas: 2
      readReplicas: 2
  resources:
    primary:
      cpu: "2"
      memory: "8Gi"
      storage: "100Gi"
    replicas:
      cpu: "1"
      memory: "4Gi"
      storage: "100Gi"
  networking:
    port: 5432
    ssl: true
    connections:
      max: 200
      idle: 20
  backup:
    enabled: true
    retention: 30d
    schedule: "0 2 * * *"
    storage: "s3://machinenativeops-backups"
  monitoring:
    enabled: true
    metrics: ["connections", "performance", "replication"]
  databases:
    - name: machinenativeops_core
      owner: machinenativeops_user
      extensions: ["uuid-ossp", "pgcrypto", "pg_stat_statements"]
    - name: machinenativeops_provenance
      owner: provenance_user
      extensions: ["uuid-ossp", "pgcrypto"]
    - name: machinenativeops_auth
      owner: auth_user
      extensions: ["uuid-ossp", "pgcrypto"]
    - name: machinenativeops_analytics
      owner: analytics_user
      extensions: ["uuid-ossp", "timescaledb"]
status:
  phase: configured
  databases: 4
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "資料庫系統配置載入完成"
}

# 檢查依賴
check_dependencies() {
    log_info "檢查資料庫依賴..."
    
    local deps=("psql" "docker" "docker-compose")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "缺少依賴項：${missing_deps[*]}"
        log_info "請安裝必要的資料庫工具"
        
        if command -v apt-get &> /dev/null; then
            log_info "嘗試安裝 PostgreSQL 客戶端工具..."
            apt-get update && apt-get install -y postgresql-client
        fi
    fi
    
    log_success "依賴檢查完成"
}

# 建立 Docker Compose 配置
setup_docker_compose() {
    log_info "建立 Docker Compose 資料庫配置..."
    
    mkdir -p "docker/database"
    
    cat > "docker/database/docker-compose.yml" << EOF
version: '3.8'

services:
  postgres-primary:
    image: postgres:15-alpine
    container_name: machinenativeops-db-primary
    environment:
      POSTGRES_DB: machinenativeops
      POSTGRES_USER: machinenativeops_admin
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_MULTIPLE_DATABASES: machinenativeops_core,machinenativeops_provenance,machinenativeops_auth,machinenativeops_analytics
    volumes:
      - postgres_primary_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./config/postgresql.conf:/etc/postgresql/postgresql.conf
      - ./config/pg_hba.conf:/etc/postgresql/pg_hba.conf
    ports:
      - "5432:5432"
    networks:
      - machinenativeops-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U machinenativeops_admin -d machinenativeops"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres-replica1:
    image: postgres:15-alpine
    container_name: machinenativeops-db-replica1
    environment:
      POSTGRES_DB: machinenativeops
      POSTGRES_USER: machinenativeops_admin
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      PGUSER: postgres
      POSTGRES_MASTER_SERVICE: postgres-primary
    volumes:
      - postgres_replica1_data:/var/lib/postgresql/data
    ports:
      - "5433:5432"
    networks:
      - machinenativeops-net
    restart: unless-stopped
    depends_on:
      postgres-primary:
        condition: service_healthy

  postgres-replica2:
    image: postgres:15-alpine
    container_name: machinenativeops-db-replica2
    environment:
      POSTGRES_DB: machinenativeops
      POSTGRES_USER: machinenativeops_admin
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      PGUSER: postgres
      POSTGRES_MASTER_SERVICE: postgres-primary
    volumes:
      - postgres_replica2_data:/var/lib/postgresql/data
    ports:
      - "5434:5432"
    networks:
      - machinenativeops-net
    restart: unless-stopped
    depends_on:
      postgres-primary:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    container_name: machinenativeops-redis
    volumes:
      - redis_data:/data
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf
    ports:
      - "6379:6379"
    networks:
      - machinenativeops-net
    restart: unless-stopped
    command: redis-server /usr/local/etc/redis/redis.conf

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: machinenativeops-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: \${PGADMIN_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: \${PGADMIN_PASSWORD}
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    ports:
      - "8080:80"
    networks:
      - machinenativeops-net
    restart: unless-stopped

volumes:
  postgres_primary_data:
  postgres_replica1_data:
  postgres_replica2_data:
  redis_data:
  pgadmin_data:

networks:
  machinenativeops-net:
    driver: bridge
EOF
    
    # 建立 PostgreSQL 配置
    cat > "docker/database/config/postgresql.conf" << EOF
# PostgreSQL Configuration for MachineNativeOps

# Connection Settings
listen_addresses = '*'
port = 5432
max_connections = 200

# Memory Settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL Settings
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB
checkpoint_completion_target = 0.9

# Replication Settings
max_wal_senders = 3
wal_keep_segments = 32
hot_standby = on

# Logging Settings
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'all'
log_min_duration_statement = 1000

# Performance Settings
random_page_cost = 1.1
effective_io_concurrency = 200
EOF
    
    # 建立 pg_hba.conf
    cat > "docker/database/config/pg_hba.conf" << EOF
# PostgreSQL Client Authentication Configuration

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             postgres                                peer
local   all             all                                     md5

# IPv4 local connections
host    all             all             127.0.0.1/32            md5
host    all             all             0.0.0.0/0               md5

# IPv6 local connections
host    all             all             ::1/128                 md5

# Replication connections
host    replication     replicator      0.0.0.0/0               md5
EOF
    
    # 建立 Redis 配置
    cat > "docker/database/config/redis.conf" << EOF
# Redis Configuration for MachineNativeOps

bind 0.0.0.0
port 6379
timeout 0
keepalive 300

# Memory
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Security
requirepass your_redis_password_here

# Logging
loglevel notice
logfile ""

# Performance
tcp-keepalive 60
tcp-backlog 511
EOF
    
    # 建立環境變數檔案
    cat > "docker/database/.env" << EOF
# Database Environment Variables
POSTGRES_PASSWORD=your_secure_password_here
PGADMIN_EMAIL=admin@machinenativeops.local
PGADMIN_PASSWORD=your_pgadmin_password_here
EOF
    
    log_success "Docker Compose 資料庫配置建立完成"
}

# 建立多資料庫初始化腳本
setup_multi_database_init() {
    log_info "建立多資料庫初始化腳本..."
    
    mkdir -p "docker/database/init-scripts"
    
    cat > "docker/database/init-scripts/create-multiple-databases.sh" << 'EOF'
#!/bin/bash
set -e

# Function to create a new database and user
create_database() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE USER $db_user WITH PASSWORD '$db_password';
        CREATE DATABASE $db_name;
        GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;
        ALTER USER $db_user CREATEDB;
EOSQL
}

# Create core databases
create_database "machinenativeops_core" "machinenativeops_user" "secure_password_core"
create_database "machinenativeops_provenance" "provenance_user" "secure_password_provenance"
create_database "machinenativeops_auth" "auth_user" "secure_password_auth"
create_database "machinenativeops_analytics" "analytics_user" "secure_password_analytics"

echo "Multiple databases created successfully!"
EOF
    
    chmod +x "docker/database/init-scripts/create-multiple-databases.sh"
    
    log_success "多資料庫初始化腳本建立完成"
}

# 建立共用 Schema
setup_shared_schemas() {
    log_info "建立共用資料庫 Schema..."
    
    mkdir -p "database/schemas"
    
    # 核心資料庫 Schema
    cat > "database/schemas/core_schema.sql" << 'EOF'
-- MachineNativeOps Core Database Schema

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (shared across all services)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'
);

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User roles mapping
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    UNIQUE(user_id, role_id)
);

-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    logo_url TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Organization members
CREATE TABLE IF NOT EXISTS organization_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(100) NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    invited_by UUID REFERENCES users(id),
    UNIQUE(organization_id, user_id)
);

-- Projects table (shared for multi-platform)
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    organization_id UUID REFERENCES organizations(id),
    owner_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'active',
    visibility VARCHAR(50) DEFAULT 'private',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Project members
CREATE TABLE IF NOT EXISTS project_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(100) NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    invited_by UUID REFERENCES users(id),
    UNIQUE(project_id, user_id)
);

-- API Keys for multi-platform access
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    permissions JSONB DEFAULT '[]',
    last_used TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'active'
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);
CREATE INDEX IF NOT EXISTS idx_projects_slug ON projects(slug);
CREATE INDEX IF NOT EXISTS idx_projects_organization ON projects(organization_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_user ON api_keys(user_id);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF
    
    # 多端專用表
    cat > "database/schemas/multiplatform_schema.sql" << 'EOF'
-- Multi-Platform Schema Extensions

-- Platforms table
CREATE TABLE IF NOT EXISTS platforms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL, -- web, mobile, desktop, api
    version VARCHAR(50),
    build_number VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active',
    config JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Platform instances
CREATE TABLE IF NOT EXISTS platform_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform_id UUID NOT NULL REFERENCES platforms(id) ON DELETE CASCADE,
    instance_id VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES users(id),
    device_info JSONB DEFAULT '{}',
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'active',
    UNIQUE(platform_id, instance_id)
);

-- Cross-platform sessions
CREATE TABLE IF NOT EXISTS cross_platform_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    platform_instances JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}'
);

-- Shared preferences
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform_type VARCHAR(50), -- null for global
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, platform_type)
);

-- Notifications (cross-platform)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    platform_targets JSONB DEFAULT '[]'
);

-- File storage (shared across platforms)
CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    path TEXT NOT NULL,
    size BIGINT NOT NULL,
    mime_type VARCHAR(255),
    hash VARCHAR(255) NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    project_id UUID REFERENCES projects(id),
    platform_type VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default platforms
INSERT INTO platforms (name, type, version, config) VALUES
('Web Platform', 'web', '1.0.0', '{"framework": "react", "responsive": true}'),
('Mobile Platform', 'mobile', '1.0.0', '{"framework": "react-native", "platforms": ["ios", "android"]}'),
('Desktop Platform', 'desktop', '1.0.0', '{"framework": "electron", "platforms": ["windows", "macos", "linux"]}')
ON CONFLICT DO NOTHING;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_platform_instances_user ON platform_instances(user_id);
CREATE INDEX IF NOT EXISTS idx_platform_instances_platform ON platform_instances(platform_id);
CREATE INDEX IF NOT EXISTS idx_cross_platform_sessions_user ON cross_platform_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_cross_platform_sessions_token ON cross_platform_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read_at);
CREATE INDEX IF NOT EXISTS idx_files_user ON files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_files_project ON files(project_id);

-- Trigger for platform instances updated_at
CREATE TRIGGER update_platform_instances_updated_at BEFORE UPDATE ON platform_instances FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cross_platform_sessions_updated_at BEFORE UPDATE ON cross_platform_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF
    
    log_success "共用資料庫 Schema 建立完成"
}

# 建立連接池配置
setup_connection_pooling() {
    log_info "建立資料庫連接池配置..."
    
    mkdir -p "database/pooling"
    
    # PgBouncer 配置
    cat > "database/pooling/pgbouncer.ini" << EOF
# PgBouncer Configuration for MachineNativeOps

[databases]
machinenativeops_core = host=localhost port=5432 dbname=machinenativeops_core
machinenativeops_provenance = host=localhost port=5432 dbname=machinenativeops_provenance
machinenativeops_auth = host=localhost port=5432 dbname=machinenativeops_auth
machinenativeops_analytics = host=localhost port=5432 dbname=machinenativeops_analytics

[pgbouncer]
listen_port = 6432
listen_addr = 127.0.0.1
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
admin_port = 6433
admin_users = postgres
stats_users = stats, postgres

# Connection pool settings
pool_mode = transaction
max_client_conn = 200
default_pool_size = 20
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 5
max_db_connections = 50
max_user_connections = 50

# Server settings
server_reset_query = DISCARD ALL
server_check_delay = 30
server_check_query = select 1
server_lifetime = 3600
server_idle_timeout = 600

# Logging
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
stats_period = 60
EOF
    
    # PgBouncer 使用者列表
    cat > "database/pooling/userlist.txt" << EOF
"machinenativeops_user" "secure_password_core"
"provenance_user" "secure_password_provenance"
"auth_user" "secure_password_auth"
"analytics_user" "secure_password_analytics"
"postgres" "your_secure_password_here"
EOF
    
    # 連接池 Docker 配置
    cat > "database/pooling/docker-compose.yml" << EOF
version: '3.8'

services:
  pgbouncer:
    image: pgbouncer/pgbouncer:latest
    container_name: machinenativeops-pgbouncer
    ports:
      - "6432:6432"  # Application connection
      - "6433:6433"  # Admin interface
    volumes:
      - ./pgbouncer.ini:/etc/pgbouncer/pgbouncer.ini
      - ./userlist.txt:/etc/pgbouncer/userlist.txt
    environment:
      - DATABASES_HOST=postgres-primary
    networks:
      - machinenativeops-net
    restart: unless-stopped
    depends_on:
      - postgres-primary
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h localhost -p 6432"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  machinenativeops-net:
    external: true
EOF
    
    log_success "資料庫連接池配置建立完成"
}

# 建立備份策略
setup_backup_strategy() {
    log_info "建立資料庫備份策略..."
    
    mkdir -p "database/backup"
    
    # 備份腳本
    cat > "database/backup/backup.sh" << 'EOF'
#!/bin/bash

# Database Backup Script for MachineNativeOps

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup function
backup_database() {
    local db_name=$1
    local db_user=$2
    local backup_file="$BACKUP_DIR/${db_name}_backup_$DATE.sql"
    
    pg_dump -h localhost -p 5432 -U "$db_user" -d "$db_name" > "$backup_file"
    
    if [[ $? -eq 0 ]]; then
        gzip "$backup_file"
        echo "Backup completed: ${backup_file}.gz"
    else
        echo "Backup failed for database: $db_name"
        return 1
    fi
}

# Backup all databases
backup_database "machinenativeops_core" "machinenativeops_user"
backup_database "machinenativeops_provenance" "provenance_user"
backup_database "machinenativeops_auth" "auth_user"
backup_database "machinenativeops_analytics" "analytics_user"

# Clean old backups
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup process completed at $(date)"
EOF
    
    chmod +x "database/backup/backup.sh"
    
    # 還原腳本
    cat > "database/backup/restore.sh" << 'EOF'
#!/bin/bash

# Database Restore Script for MachineNativeOps

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <database_name> <backup_file>"
    echo "Example: $0 machinenativeops_core /backups/machinenativeops_core_backup_20231201_120000.sql.gz"
    exit 1
fi

DB_NAME=$1
BACKUP_FILE=$2

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Extract backup if compressed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | psql -h localhost -p 5432 -U "machinenativeops_user" -d "$DB_NAME"
else
    psql -h localhost -p 5432 -U "machinenativeops_user" -d "$DB_NAME" < "$BACKUP_FILE"
fi

echo "Database restore completed for: $DB_NAME"
EOF
    
    chmod +x "database/backup/restore.sh"
    
    # 備份排程配置
    cat > "database/backup/backup-cron.conf" << EOF
# Database Backup Cron Configuration
# Run backup daily at 2 AM

0 2 * * * /app/database/backup/backup.sh >> /var/log/database-backup.log 2>&1

# Run backup verification weekly on Sunday at 3 AM
0 3 * * 0 /app/database/backup/verify-backups.sh >> /var/log/database-backup.log 2>&1
EOF
    
    log_success "資料庫備份策略建立完成"
}

# 建立監控配置
setup_database_monitoring() {
    log_info "建立資料庫監控配置..."
    
    mkdir -p "monitoring/database"
    
    # PostgreSQL 監控配置
    cat > "monitoring/database/postgres-exporter.yml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-exporter-config
  namespace: machinenativeops
data:
  postgres-exporter.yml: |
    datasource:
      host: postgres-primary
      port: 5432
      user: postgres
      password: your_secure_password_here
      database: machinenativeops
    
    queries:
      - name: postgres_connections
        query: |
          SELECT 
            datname as database,
            numbackends as connections,
            xact_commit as transactions_committed,
            xact_rollback as transactions_rolled_back,
            blks_read as blocks_read,
            blks_hit as blocks_hit,
            tup_returned as tuples_returned,
            tup_fetched as tuples_fetched,
            tup_inserted as tuples_inserted,
            tup_updated as tuples_updated,
            tup_deleted as tuples_deleted
          FROM pg_stat_database
        metrics:
          - database:
              usage: "LABEL"
              description: "Database name"
          - connections:
              usage: "GAUGE"
              description: "Number of connections"
          - transactions_committed:
              usage: "COUNTER"
              description: "Number of transactions committed"
          - transactions_rolled_back:
              usage: "COUNTER"
              description: "Number of transactions rolled back"
    
      - name: postgres_table_stats
        query: |
          SELECT 
            schemaname as schema,
            tablename as table,
            seq_scan as sequential_scans,
            seq_tup_read as sequential_tuples_read,
            idx_scan as index_scans,
            idx_tup_fetch as index_tuples_fetch,
            n_tup_ins as tuples_inserted,
            n_tup_upd as tuples_updated,
            n_tup_del as tuples_deleted,
            n_live_tup as live_tuples,
            n_dead_tup as dead_tuples
          FROM pg_stat_user_tables
        metrics:
          - schema:
              usage: "LABEL"
              description: "Schema name"
          - table:
              usage: "LABEL"
              description: "Table name"
          - sequential_scans:
              usage: "COUNTER"
              description: "Number of sequential scans"
          - index_scans:
              usage: "COUNTER"
              description: "Number of index scans"
EOF
    
    # Grafana 儀表板配置
    cat > "monitoring/database/grafana-dashboard.json" << EOF
{
  "dashboard": {
    "id": null,
    "title": "MachineNativeOps Database Dashboard",
    "tags": ["machinenativeops", "database"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Database Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "postgres_connections{instance=&quot;postgres-primary:5432&quot;}",
            "legendFormat": "{{database}}"
          }
        ],
        "yAxes": [
          {
            "label": "Connections"
          }
        ]
      },
      {
        "id": 2,
        "title": "Transaction Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(postgres_transactions_committed{instance=&quot;postgres-primary:5432&quot;}[5m])",
            "legendFormat": "Committed/sec"
          },
          {
            "expr": "rate(postgres_transactions_rolled_back{instance=&quot;postgres-primary:5432&quot;}[5m])",
            "legendFormat": "Rolled Back/sec"
          }
        ]
      },
      {
        "id": 3,
        "title": "Replication Lag",
        "type": "singlestat",
        "targets": [
          {
            "expr": "pg_replication_lag{instance=&quot;postgres-primary:5432&quot;}",
            "legendFormat": "Replication Lag (seconds)"
          }
        ]
      }
    ]
  }
}
EOF
    
    log_success "資料庫監控配置建立完成"
}

# 啟動資料庫服務
start_database_services() {
    log_info "啟動資料庫服務..."
    
    cd docker/database
    
    # 檢查 Docker 是否運行
    if ! docker info &> /dev/null; then
        log_error "Docker 服務未運行，請先啟動 Docker"
        return 1
    fi
    
    # 啟動資料庫服務
    log_info "正在啟動 PostgreSQL 集群..."
    docker-compose up -d
    
    # 等待服務就緒
    log_info "等待資料庫服務就緒..."
    sleep 30
    
    # 檢查服務狀態
    if docker-compose ps | grep -q "Up"; then
        log_success "資料庫服務啟動成功"
        
        # 顯示連接資訊
        echo
        log_info "資料庫連接資訊："
        echo "  - Primary: localhost:5432"
        echo "  - Replica 1: localhost:5433"
        echo "  - Replica 2: localhost:5434"
        echo "  - Redis: localhost:6379"
        echo "  - PgAdmin: http://localhost:8080"
        echo
        log_info "連接池：localhost:6432"
        echo "  - 管理介面：localhost:6433"
    else
        log_error "資料庫服務啟動失敗"
        return 1
    fi
    
    cd - > /dev/null
}

# 驗證資料庫系統
verify_database_system() {
    log_info "驗證資料庫系統..."
    
    local verification_errors=0
    
    # 檢查 Docker 容器狀態
    cd docker/database
    
    local containers=("machinenativeops-db-primary" "machinenativeops-db-replica1" "machinenativeops-db-replica2" "machinenativeops-redis")
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$container"; then
            log_success "容器 $container 運行中"
        else
            log_error "容器 $container 未運行"
            ((verification_errors++))
        fi
    done
    
    # 檢查資料庫連接
    if PGPASSWORD="your_secure_password_here" psql -h localhost -p 5432 -U machinenativeops_admin -d machinenativeops -c "SELECT version();" &> /dev/null; then
        log_success "Primary 資料庫連接正常"
    else
        log_error "Primary 資料庫連接失敗"
        ((verification_errors++))
    fi
    
    # 檢查 Redis 連接
    if docker exec machinenativeops-redis redis-cli ping | grep -q "PONG"; then
        log_success "Redis 連接正常"
    else
        log_error "Redis 連接失敗"
        ((verification_errors++))
    fi
    
    cd - > /dev/null
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "資料庫系統驗證通過"
        return 0
    else
        log_error "資料庫系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始資料庫系統初始化..."
    
    # 初始化階段
    local total_steps=10
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; check_dependencies
    ((current_step++)); progress_bar $current_step $total_steps; setup_docker_compose
    ((current_step++)); progress_bar $current_step $total_steps; setup_multi_database_init
    ((current_step++)); progress_bar $current_step $total_steps; setup_shared_schemas
    ((current_step++)); progress_bar $current_step $total_steps; setup_connection_pooling
    ((current_step++)); progress_bar $current_step $total_steps; setup_backup_strategy
    ((current_step++)); progress_bar $current_step $total_steps; setup_database_monitoring
    ((current_step++)); progress_bar $current_step $total_steps; start_database_services
    ((current_step++)); progress_bar $current_step $total_steps; verify_database_system
    
    echo; log_success "資料庫系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - 資料庫配置：docker/database/docker-compose.yml"
    echo "  - Schema 文件：database/schemas/"
    echo "  - 連接池配置：database/pooling/"
    echo "  - 備份腳本：database/backup/"
    echo "  - 監控配置：monitoring/database/"
    echo
    log_info "資料庫狀態：已初始化並驗證"
}

# 執行主函數
main "$@"