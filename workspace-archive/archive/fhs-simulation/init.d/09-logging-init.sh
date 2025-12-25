#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Logging System Initialization
# =============================================================================
# 日誌系統初始化腳本
# 職責：建立結構化日誌、集中日誌管理、日誌聚合、日誌分析
# 依賴：08-dependencies-init.sh
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
    log_info "載入日誌系統配置..."
    
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    log_success "日誌系統配置載入完成"
}

# 建立日誌目錄結構
setup_logging_directory_structure() {
    log_info "建立日誌目錄結構..."
    
    # 主要日誌目錄
    local log_dirs=(
        "logs/application"
        "logs/access"
        "logs/error"
        "logs/audit"
        "logs/security"
        "logs/performance"
        "logs/infrastructure"
        "logs/business"
        "logs/debug"
        "logs/archive"
    )
    
    for dir in "${log_dirs[@]}"; do
        mkdir -p "$dir"
        # 建立年度和月份子目錄
        mkdir -p "$dir/$(date +%Y)/$(date +%m)"
    done
    
    # 平台特定日誌
    local platform_dirs=(
        "logs/web"
        "logs/mobile"
        "logs/desktop"
        "logs/api"
        "logs/database"
        "logs/cache"
    )
    
    for dir in "${platform_dirs[@]}"; do
        mkdir -p "$dir"
        mkdir -p "$dir/$(date +%Y)/$(date +%m)"
    done
    
    log_success "日誌目錄結構建立完成"
}

# 建立結構化日誌配置
setup_structured_logging() {
    log_info "建立結構化日誌配置..."
    
    mkdir -p "config/logging"
    
    # Python 日誌配置
    cat > "config/logging/python-logging.yaml" << EOF
version: 1
disable_existing_loggers: false

formatters:
  standard:
    format: '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
  json:
    format: '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "logger": "%(name)s", "message": "%(message)s", "module": "%(module)s", "function": "%(funcName)s", "line": %(lineno)d}'
    class: pythonjsonlogger.jsonlogger.JsonFormatter
  detailed:
    format: '%(asctime)s [%(levelname)s] %(name)s [%(filename)s:%(lineno)d] - %(message)s'

handlers:
  console:
    class: logging.StreamHandler
    level: INFO
    formatter: standard
    stream: ext://sys.stdout

  file_application:
    class: logging.handlers.RotatingFileHandler
    level: INFO
    formatter: json
    filename: logs/application/application.log
    maxBytes: 10485760  # 10MB
    backupCount: 10

  file_error:
    class: logging.handlers.RotatingFileHandler
    level: ERROR
    formatter: detailed
    filename: logs/error/error.log
    maxBytes: 10485760  # 10MB
    backupCount: 10

  file_audit:
    class: logging.handlers.RotatingFileHandler
    level: INFO
    formatter: json
    filename: logs/audit/audit.log
    maxBytes: 52428800  # 50MB
    backupCount: 30

  file_security:
    class: logging.handlers.RotatingFileHandler
    level: INFO
    formatter: json
    filename: logs/security/security.log
    maxBytes: 52428800  # 50MB
    backupCount: 30

  file_performance:
    class: logging.handlers.RotatingFileHandler
    level: INFO
    formatter: json
    filename: logs/performance/performance.log
    maxBytes: 10485760  # 10MB
    backupCount: 10

  syslog:
    class: logging.handlers.SysLogHandler
    level: INFO
    formatter: standard
    address: localhost:514

  elasticsearch:
    class: cmreslogging.handlers.CMRESHandler
    level: INFO
    formatter: json
    hosts:
      - host: localhost
        port: 9200
    es_index_name: machinenativeops-logs
    es_doc_type: _doc
    use_ssl: false
    http_auth: elastic:changeme

loggers:
  machinenativeops:
    level: INFO
    handlers: [console, file_application, file_error]
    propagate: false

  machinenativeops.auth:
    level: INFO
    handlers: [file_audit, file_security]
    propagate: false

  machinenativeops.api:
    level: INFO
    handlers: [file_application, file_performance]
    propagate: false

  machinenativeops.database:
    level: WARNING
    handlers: [file_application]
    propagate: false

  machinenativeops.security:
    level: INFO
    handlers: [file_security, file_audit]
    propagate: false

  machinenativeops.performance:
    level: INFO
    handlers: [file_performance]
    propagate: false

  uvicorn:
    level: INFO
    handlers: [file_application]
    propagate: false

  uvicorn.error:
    level: INFO
    handlers: [file_error]
    propagate: false

  uvicorn.access:
    level: INFO
    handlers: [file_application]
    propagate: false

root:
  level: INFO
  handlers: [console, file_application]
EOF
    
    # Node.js 日誌配置
    cat > "config/logging/nodejs-logging.json" << EOF
{
  "version": 1,
  "disable_existing_loggers": false,
  "formatters": {
    "simple": {
      "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    },
    "detailed": {
      "format": "%(asctime)s - %(name)s - %(levelname)s - %(module)s - %(funcName)s - %(message)s"
    }
  },
  "handlers": {
    "console": {
      "class": "logging.StreamHandler",
      "level": "INFO",
      "formatter": "simple",
      "stream": "ext://sys.stdout"
    },
    "file": {
      "class": "logging.handlers.RotatingFileHandler",
      "level": "INFO",
      "formatter": "detailed",
      "filename": "logs/web/web.log",
      "maxBytes": 10485760,
      "backupCount": 5
    },
    "error_file": {
      "class": "logging.handlers.RotatingFileHandler",
      "level": "ERROR",
      "formatter": "detailed",
      "filename": "logs/web/web-error.log",
      "maxBytes": 10485760,
      "backupCount": 10
    }
  },
  "loggers": {
    "web": {
      "level": "INFO",
      "handlers": ["console", "file", "error_file"],
      "propagate": false
    }
  },
  "root": {
    "level": "INFO",
    "handlers": ["console", "file"]
  }
}
EOF
    
    # 統一日誌配置
    cat > "config/logging/unified-logging.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: UnifiedLoggingConfiguration
metadata:
  name: unified-logging
  namespace: machinenativeops
spec:
  globalSettings:
    level: info
    format: json
    enableStructuredLogging: true
    enableCorrelation: true
    enableTracePropagation: true
  
  logLevels:
    default: info
    development: debug
    testing: info
    staging: info
    production: warn
  
  outputs:
    - name: console
      type: console
      enabled: true
      format: colored
    - name: file
      type: file
      enabled: true
      path: logs/application/app.log
      rotation:
        enabled: true
        maxSize: 100MB
        maxFiles: 10
        compress: true
    - name: elasticsearch
      type: elasticsearch
      enabled: false
      hosts: ["localhost:9200"]
      index: "machinenativeops-logs"
      template: "logs-template"
    - name: loki
      type: loki
      enabled: false
      endpoint: "http://localhost:3100/loki/api/v1/push"
      labels:
        service: "machinenativeops"
        environment: "${ENVIRONMENT}"
    - name: syslog
      type: syslog
      enabled: false
      endpoint: "localhost:514"
      facility: "local0"
  
  categories:
    - name: application
      level: info
      outputs: ["console", "file"]
      includeMdc: true
    - name: access
      level: info
      outputs: ["file"]
      file: "logs/access/access.log"
      pattern: "%h %l %u %t &quot;%r&quot; %>s %b &quot;%{Referer}i&quot; &quot;%{User-Agent}i&quot; %{X-Request-ID}i"
    - name: audit
      level: info
      outputs: ["file"]
      file: "logs/audit/audit.log"
      includeUser: true
      includeAction: true
    - name: security
      level: warn
      outputs: ["file", "alert"]
      file: "logs/security/security.log"
      includeIp: true
      includeUserAgent: true
    - name: performance
      level: info
      outputs: ["file"]
      file: "logs/performance/performance.log"
      includeDuration: true
      includeMemory: true
    - name: error
      level: error
      outputs: ["file", "alert"]
      file: "logs/error/error.log"
      includeStackTrace: true
  
  enrichment:
    correlationId:
      enabled: true
      headerName: "X-Request-ID"
      generateIfMissing: true
    traceId:
      enabled: true
      headerName: "X-Trace-ID"
      generateIfMissing: true
    userId:
      enabled: true
      extractFromContext: true
    sessionId:
      enabled: true
      extractFromContext: true
    serviceInfo:
      enabled: true
      name: "machinenativeops"
      version: "1.0.0"
      environment: "${ENVIRONMENT}"

status:
  phase: configured
  outputs: 5
  categories: 6
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "結構化日誌配置建立完成"
}

# 建立 ELK Stack 配置
setup_elk_stack() {
    log_info "建立 ELK Stack 配置..."
    
    mkdir -p "docker/elk"
    
    # Docker Compose for ELK
    cat > "docker/elk/docker-compose.yml" << EOF
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.6.0
    container_name: machinenativeops-elasticsearch
    environment:
      - node.name=elasticsearch
      - cluster.name=machinenativeops-cluster
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
      - xpack.security.enabled=false
      - xpack.security.enrollment.enabled=false
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
      - ./elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml:ro
    ports:
      - "9200:9200"
      - "9300:9300"
    networks:
      - elk-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  kibana:
    image: docker.elastic.co/kibana/kibana:8.6.0
    container_name: machinenativeops-kibana
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
      SERVER_NAME: kibana.machinenativeops.local
      SERVER_HOST: "0.0.0.0"
    volumes:
      - ./kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml:ro
    ports:
      - "5601:5601"
    networks:
      - elk-net
    restart: unless-stopped
    depends_on:
      elasticsearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5601/api/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  logstash:
    image: docker.elastic.co/logstash/logstash:8.6.0
    container_name: machinenativeops-logstash
    volumes:
      - ./logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
      - ./logstash/pipeline:/usr/share/logstash/pipeline:ro
      - ../logs:/usr/share/logstash/logs:ro
    ports:
      - "5000:5000"
      - "5044:5044"
    networks:
      - elk-net
    restart: unless-stopped
    depends_on:
      elasticsearch:
        condition: service_healthy
    environment:
      LS_JAVA_OPTS: "-Xmx1g -Xms1g"

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.6.0
    container_name: machinenativeops-filebeat
    user: root
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - ../logs:/usr/share/filebeat/logs:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - output.elasticsearch.hosts=["elasticsearch:9200"]
    networks:
      - elk-net
    restart: unless-stopped
    depends_on:
      elasticsearch:
        condition: service_healthy

volumes:
  elasticsearch_data:
    driver: local

networks:
  elk-net:
    driver: bridge
EOF
    
    # Elasticsearch 配置
    mkdir -p "docker/elk/elasticsearch/config"
    cat > "docker/elk/elasticsearch/config/elasticsearch.yml" << EOF
cluster.name: machinenativeops-cluster
node.name: elasticsearch
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs
network.host: 0.0.0.0
discovery.type: single-node
bootstrap.memory_lock: true
xpack.security.enabled: false
xpack.monitoring.collection.enabled: true
EOF
    
    # Kibana 配置
    mkdir -p "docker/elk/kibana/config"
    cat > "docker/elk/kibana/config/kibana.yml" << EOF
server.name: kibana
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://elasticsearch:9200"]
monitoring.ui.container.elasticsearch.enabled: true
logging.silent: false
logging.quiet: false
logging.verbose: true
EOF
    
    # Logstash 配置
    mkdir -p "docker/elk/logstash/config"
    cat > "docker/elk/logstash/config/logstash.yml" << EOF
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: [ "http://elasticsearch:9200" ]
EOF
    
    mkdir -p "docker/elk/logstash/pipeline"
    cat > "docker/elk/logstash/pipeline/logstash.conf" << EOF
input {
  beats {
    port => 5044
  }
  tcp {
    port => 5000
    codec => json_lines
  }
}

filter {
  if [fields][service] {
    mutate {
      add_field => { "service_name" => "%{[fields][service]}" }
    }
  }
  
  if [fields][environment] {
    mutate {
      add_field => { "environment" => "%{[fields][environment]}" }
    }
  }
  
  date {
    match => [ "timestamp", "ISO8601" ]
  }
  
  if [level] == "ERROR" or [level] == "error" {
    mutate {
      add_tag => [ "error" ]
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "machinenativeops-logs-%{+YYYY.MM.dd}"
  }
  
  stdout {
    codec => rubydebug
  }
}
EOF
    
    # Filebeat 配置
    mkdir -p "docker/elk/filebeat"
    cat > "docker/elk/filebeat/filebeat.yml" << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /usr/share/filebeat/logs/**/*.log
  fields:
    service: machinenativeops
    environment: production
  fields_under_root: true
  multiline.pattern: '^\d{4}-\d{2}-\d{2}'
  multiline.negate: true
  multiline.match: after

- type: container
  enabled: true
  paths:
    - '/var/lib/docker/containers/*/*.log'
  processors:
    - add_docker_metadata:
        host: "unix:///var/run/docker.sock"

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "machinenativeops-logs-%{+yyyy.MM.dd}"

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
EOF
    
    log_success "ELK Stack 配置建立完成"
}

# 建立日誌聚合和路由
setup_log_aggregation() {
    log_info "建立日誌聚合和路由..."
    
    mkdir -p "config/aggregation"
    
    # 日誌聚合配置
    cat > "config/aggregation/log-aggregation.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: LogAggregationConfiguration
metadata:
  name: log-aggregation
  namespace: machinenativeops
spec:
  aggregationStrategy: centralized
  bufferSize: 10000
  flushInterval: 5s
  compression: gzip
  
  sources:
    - name: application_logs
      type: file
      paths:
        - "logs/application/**/*.log"
      format: json
      fields:
        service: application
        component: core
    - name: web_logs
      type: file
      paths:
        - "logs/web/**/*.log"
      format: json
      fields:
        service: web
        component: frontend
    - name: api_logs
      type: file
      paths:
        - "logs/api/**/*.log"
      format: json
      fields:
        service: api
        component: backend
    - name: database_logs
      type: database
      connection: "postgresql://localhost:5432/machinenativeops"
      query: "SELECT * FROM audit_log WHERE created_at > NOW() - INTERVAL '1 hour'"
      fields:
        service: database
        component: storage
  
  processors:
    - name: add_timestamp
      type: timestamp
      field: "@timestamp"
      format: iso8601
    - name: parse_json
      type: json
      field: "message"
    - name: add_service_info
      type: add_fields
      fields:
        cluster: machinenativeops
        region: local
    - name: filter_sensitive_data
      type: script
      script: |
        function process(event) {
          var sensitiveFields = ['password', 'token', 'secret', 'key'];
          for (var field of sensitiveFields) {
            if (event.Get(field)) {
              event.Put(field, '***REDACTED***');
            }
          }
        }
  
  outputs:
    - name: elasticsearch
      type: elasticsearch
      enabled: true
      hosts: ["localhost:9200"]
      index: "machinenativeops-logs-%{+yyyy.MM.dd}"
      template: "machinenativeops-logs-template"
    - name: loki
      type: loki
      enabled: false
      endpoint: "http://localhost:3100/loki/api/v1/push"
      labels:
        job: "machinenativeops"
    - name: s3
      type: s3
      enabled: false
      bucket: "machinenativeops-logs-archive"
      region: "us-east-1"
      prefix: "logs/"
      format: "json"
  
  routing:
    - condition: "level == 'ERROR'"
      outputs: ["elasticsearch", "alert"]
      priority: high
    - condition: "service == 'security'"
      outputs: ["elasticsearch", "siem"]
      priority: high
    - condition: "contains(message, 'performance')"
      outputs: ["elasticsearch", "metrics"]
      priority: medium
    - condition: "default"
      outputs: ["elasticsearch"]
      priority: low

status:
  phase: configured
  sources: 4
  processors: 4
  outputs: 3
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "日誌聚合和路由建立完成"
}

# 建立日誌監控和告警
setup_log_monitoring() {
    log_info "建立日誌監控和告警..."
    
    mkdir -p "config/monitoring"
    
    # 日誌監控配置
    cat > "config/monitoring/log-monitoring.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: LogMonitoringConfiguration
metadata:
  name: log-monitoring
  namespace: machinenativeops
spec:
  monitoringEnabled: true
  realTimeAnalysis: true
  alertingEnabled: true
  
  metrics:
    - name: log_volume
      description: "Total log volume per service"
      query: "count by (service) (over_time(log_count[5m]))"
      interval: 1m
      aggregation: sum
    - name: error_rate
      description: "Error rate per service"
      query: "rate(log_count{level=&quot;error&quot;}[5m]) / rate(log_count[5m])"
      interval: 1m
      aggregation: avg
    - name: response_time_p99
      description: "99th percentile response time from logs"
      query: "histogram_quantile(0.99, rate(log_duration_bucket[5m]))"
      interval: 1m
      aggregation: histogram_quantile
  
  alerts:
    - name: high_error_rate
      description: "High error rate detected"
      condition: "error_rate > 0.05"
      severity: critical
      for: 2m
      labels:
        team: platform
        service: "{{service}}"
      annotations:
        summary: "High error rate in {{service}}"
        description: "Error rate is {{value | humanizePercentage}} for service {{service}}"
    
    - name: log_volume_spike
      description: "Unusual log volume spike"
      condition: "log_volume > 1000"
      severity: warning
      for: 5m
      labels:
        team: platform
      annotations:
        summary: "Log volume spike detected"
        description: "Log volume is {{value}} logs/minute, threshold is 1000"
    
    - name: security_event
      description: "Security event detected in logs"
      condition: 'log_message =~ "authentication.*failed|unauthorized.*access|security.*violation"'
      severity: critical
      for: 0m
      labels:
        team: security
      annotations:
        summary: "Security event detected"
        description: "Security event: {{log_message}}"
    
    - name: service_down
      description: "Service appears to be down"
      condition: "absent(log_count{service=~&quot;.+'})"
      severity: critical
      for: 5m
      labels:
        team: platform
      annotations:
        summary: "Service {{service}} appears to be down"
        description: "No logs received from {{service}} in the last 5 minutes"
  
  dashboards:
    - name: log_overview
      title: "Log Overview"
      panels:
        - title: "Log Volume"
          type: graph
          targets:
            - expr: "sum(rate(log_count[5m])) by (service)"
              legendFormat: "{{service}}"
        - title: "Error Rate"
          type: graph
          targets:
            - expr: "sum(rate(log_count{level=&quot;error&quot;}[5m])) by (service) / sum(rate(log_count[5m])) by (service)"
              legendFormat: "{{service}}"
        - title: "Top Error Messages"
          type: table
          targets:
            - expr: "topk(10, sum by (message) (log_count{level=&quot;error&quot;}))"
    
    - name: security_dashboard
      title: "Security Events"
      panels:
        - title: "Security Events"
          type: graph
          targets:
            - expr: "sum(rate(log_count{category=&quot;security&quot;}[5m]))"
        - title: "Failed Logins"
          type: table
          targets:
            - expr: "sum by (ip, user) (log_count{message=~&quot;login.*failed&quot;})"
    
    - name: performance_dashboard
      title: "Performance Metrics"
      panels:
        - title: "Response Time Distribution"
          type: graph
          targets:
            - expr: "histogram_quantile(0.50, rate(log_duration_bucket[5m]))"
              legendFormat: "50th percentile"
            - expr: "histogram_quantile(0.95, rate(log_duration_bucket[5m]))"
              legendFormat: "95th percentile"
            - expr: "histogram_quantile(0.99, rate(log_duration_bucket[5m]))"
              legendFormat: "99th percentile"

status:
  phase: configured
  metrics: 3
  alerts: 4
  dashboards: 3
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "日誌監控和告警建立完成"
}

# 建立日誌輪換和歸檔
setup_log_rotation_archival() {
    log_info "建立日誌輪換和歸檔..."
    
    mkdir -p "scripts/logging"
    
    # 日誌輪換腳本
    cat > "scripts/logging/rotate-logs.sh" << 'EOF'
#!/bin/bash

# Log rotation script

LOG_DIR="logs"
RETENTION_DAYS=30
ARCHIVE_DIR="logs/archive"

# Create archive directory if it doesn't exist
mkdir -p "$ARCHIVE_DIR"

# Rotate application logs
rotate_application_logs() {
    local app_dirs=("application" "access" "error" "security" "performance" "audit")
    
    for dir in "${app_dirs[@]}"; do
        if [[ -d "$LOG_DIR/$dir" ]]; then
            echo "Rotating $dir logs..."
            
            # Find logs older than 1 day and compress them
            find "$LOG_DIR/$dir" -name "*.log" -mtime +1 -type f -exec gzip {} \;
            
            # Move compressed logs to archive
            find "$LOG_DIR/$dir" -name "*.log.gz" -mtime +7 -exec mv {} "$ARCHIVE_DIR/$dir/" \;
            
            # Remove old archives
            find "$ARCHIVE_DIR/$dir" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete
        fi
    done
}

# Rotate platform logs
rotate_platform_logs() {
    local platform_dirs=("web" "mobile" "desktop" "api" "database" "cache")
    
    for dir in "${platform_dirs[@]}"; do
        if [[ -d "$LOG_DIR/$dir" ]]; then
            echo "Rotating $dir platform logs..."
            
            # Find logs older than 1 day and compress them
            find "$LOG_DIR/$dir" -name "*.log" -mtime +1 -type f -exec gzip {} \;
            
            # Move compressed logs to archive
            find "$LOG_DIR/$dir" -name "*.log.gz" -mtime +7 -exec mv {} "$ARCHIVE_DIR/$dir/" \;
            
            # Remove old archives
            find "$ARCHIVE_DIR/$dir" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete
        fi
    done
}

# Clean up empty directories
cleanup_empty_directories() {
    find "$LOG_DIR" -type d -empty -delete
    find "$ARCHIVE_DIR" -type d -empty -delete
}

# Generate rotation report
generate_report() {
    local report_file="reports/log-rotation-$(date +%Y%m%d).txt"
    
    {
        echo "Log Rotation Report"
        echo "Generated: $(date)"
        echo ""
        echo "Current log sizes:"
        du -sh "$LOG_DIR"/* 2>/dev/null || echo "No log directories found"
        echo ""
        echo "Archive sizes:"
        du -sh "$ARCHIVE_DIR"/* 2>/dev/null || echo "No archive directories found"
        echo ""
        echo "Total disk usage:"
        du -sh "$LOG_DIR" "$ARCHIVE_DIR"
    } > "$report_file"
    
    echo "Log rotation report generated: $report_file"
}

# Main execution
main() {
    echo "Starting log rotation..."
    
    rotate_application_logs
    rotate_platform_logs
    cleanup_empty_directories
    generate_report
    
    echo "Log rotation completed successfully!"
}

main "$@"
EOF
    
    # 歸檔腳本
    cat > "scripts/logging/archive-logs.sh" << 'EOF'
#!/bin/bash

# Log archival script

LOG_DIR="logs"
ARCHIVE_DIR="logs/archive"
S3_BUCKET="machinenativeops-logs-archive"
RETENTION_DAYS=2555  # 7 years

# Archive to S3
archive_to_s3() {
    if command -v aws &> /dev/null; then
        echo "Archiving logs to S3..."
        
        # Archive current year's logs
        local current_year=$(date +%Y)
        aws s3 sync "$ARCHIVE_DIR/$current_year" "s3://$S3_BUCKET/logs/$current_year/" --delete
        
        # Archive previous years' logs
        for year_dir in "$ARCHIVE_DIR"/*; do
            if [[ -d "$year_dir" ]]; then
                local year=$(basename "$year_dir")
                if [[ "$year" != "$current_year" ]]; then
                    aws s3 sync "$year_dir" "s3://$S3_BUCKET/logs/$year/" --delete
                fi
            fi
        done
        
        echo "Logs archived to S3 successfully!"
    else
        echo "AWS CLI not found, skipping S3 archive"
    fi
}

# Local cleanup
cleanup_local_archives() {
    echo "Cleaning up local archives..."
    
    # Remove local archives older than retention period
    find "$ARCHIVE_DIR" -name "*.log.gz" -mtime +$RETENTION_DAYS -delete
    
    echo "Local archive cleanup completed"
}

# Generate archive report
generate_archive_report() {
    local report_file="reports/log-archive-$(date +%Y%m%d).txt"
    
    {
        echo "Log Archive Report"
        echo "Generated: $(date)"
        echo ""
        echo "Archive directory sizes:"
        du -sh "$ARCHIVE_DIR"/* 2>/dev/null || echo "No archive directories found"
        echo ""
        echo "S3 bucket usage:"
        if command -v aws &> /dev/null; then
            aws s3 ls "s3://$S3_BUCKET/logs/" --recursive --human-readable --summarize
        else
            echo "AWS CLI not available"
        fi
    } > "$report_file"
    
    echo "Archive report generated: $report_file"
}

# Main execution
main() {
    echo "Starting log archival..."
    
    archive_to_s3
    cleanup_local_archives
    generate_archive_report
    
    echo "Log archival completed successfully!"
}

main "$@"
EOF
    
    # 設定 cron 任務
    cat > "scripts/logging/setup-log-cron.sh" << 'EOF'
#!/bin/bash

# Setup log rotation and archival cron jobs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add log rotation cron job (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * $SCRIPT_DIR/rotate-logs.sh >> /var/log/log-rotation.log 2>&1") | crontab -

# Add log archival cron job (weekly on Sunday at 3 AM)
(crontab -l 2>/dev/null; echo "0 3 * * 0 $SCRIPT_DIR/archive-logs.sh >> /var/log/log-archive.log 2>&1") | crontab -

echo "Cron jobs setup completed!"
echo "Log rotation: Daily at 2 AM"
echo "Log archival: Weekly on Sunday at 3 AM"
EOF
    
    chmod +x scripts/logging/*.sh
    
    log_success "日誌輪換和歸檔建立完成"
}

# 啟動日誌服務
start_logging_services() {
    log_info "啟動日誌服務..."
    
    cd docker/elk
    
    # 檢查 Docker 是否運行
    if ! docker info &> /dev/null; then
        log_error "Docker 服務未運行，請先啟動 Docker"
        return 1
    fi
    
    # 啟動 ELK Stack
    log_info "正在啟動 ELK Stack..."
    docker-compose up -d
    
    # 等待服務就緒
    log_info "等待 ELK 服務就緒..."
    sleep 60
    
    # 檢查服務狀態
    if docker-compose ps | grep -q "Up"; then
        log_success "ELK Stack 啟動成功"
        
        # 顯示服務資訊
        echo
        log_info "日誌服務資訊："
        echo "  - Elasticsearch: http://localhost:9200"
        echo "  - Kibana: http://localhost:5601"
        echo "  - Logstash: tcp://localhost:5000"
        echo "  - Filebeat: beats://localhost:5044"
    else
        log_error "ELK Stack 啟動失敗"
        return 1
    fi
    
    cd - > /dev/null
}

# 驗證日誌系統
verify_logging_system() {
    log_info "驗證日誌系統..."
    
    local verification_errors=0
    
    # 檢查日誌目錄
    local required_dirs=("logs/application" "logs/access" "logs/error" "logs/audit" "logs/security" "logs/performance")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "日誌目錄存在：$dir"
        else
            log_error "日誌目錄不存在：$dir"
            ((verification_errors++))
        fi
    done
    
    # 檢查配置文件
    local required_files=("config/logging/python-logging.yaml" "config/logging/unified-logging.yaml" "config/aggregation/log-aggregation.yaml")
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "日誌配置文件存在：$(basename "$file")"
        else
            log_error "日誌配置文件不存在：$file"
            ((verification_errors++))
        fi
    done
    
    # 檢查腳本可執行性
    if [[ -f "scripts/logging/rotate-logs.sh" ]] && [[ -x "scripts/logging/rotate-logs.sh" ]]; then
        log_success "日誌輪換腳本可執行"
    else
        log_error "日誌輪換腳本不可執行"
        ((verification_errors++))
    fi
    
    # 檢查 ELK Stack
    if docker ps --format "table {{.Names}}" | grep -q "machinenativeops-elasticsearch"; then
        log_success "Elasticsearch 容器運行中"
    else
        log_warning "Elasticsearch 容器未運行"
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "日誌系統驗證通過"
        return 0
    else
        log_error "日誌系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始日誌系統初始化..."
    
    # 初始化階段
    local total_steps=8
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; setup_logging_directory_structure
    ((current_step++)); progress_bar $current_step $total_steps; setup_structured_logging
    ((current_step++)); progress_bar $current_step $total_steps; setup_elk_stack
    ((current_step++)); progress_bar $current_step $total_steps; setup_log_aggregation
    ((current_step++)); progress_bar $current_step $total_steps; setup_log_monitoring
    ((current_step++)); progress_bar $current_step $total_steps; setup_log_rotation_archival
    ((current_step++)); progress_bar $current_step $total_steps; verify_logging_system
    
    echo; log_success "日誌系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - 日誌配置：config/logging/"
    echo "  - ELK Stack：docker/elk/"
    echo "  - 日誌聚合：config/aggregation/"
    echo "  - 日誌監控：config/monitoring/"
    echo "  - 管理腳本：scripts/logging/"
    echo
    log_info "日誌服務狀態：已初始化並驗證"
}

# 執行主函數
main "$@"