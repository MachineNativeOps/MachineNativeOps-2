#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Microservices Initialization
# =============================================================================
# 微服務系統初始化腳本
# 職責：建立微服務架構、服務發現、負載均衡、服務網格
# 依賴：12-api-gateway-init.sh
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
    log_info "載入微服務系統配置..."
    
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    log_success "微服務系統配置載入完成"
}

# 建立微服務架構配置
setup_microservices_architecture() {
    log_info "建立微服務架構配置..."
    
    mkdir -p "config/microservices"
    
    # 微服務架構主配置
    cat > "config/microservices/microservices-architecture.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: MicroservicesArchitecture
metadata:
  name: microservices-architecture
  namespace: machinenativeops
spec:
  architecture:
    pattern: "api-gateway + microservices"
    communicationStyle: "synchronous + asynchronous"
    dataManagement: "database-per-service"
    deploymentPattern: "containerized"
  
  services:
    - name: "auth-service"
      version: "1.0.0"
      description: "Authentication and authorization service"
      port: 8001
      healthCheck: "/health"
      database: "auth_db"
      dependencies: ["redis", "postgresql"]
      responsibilities:
        - "User authentication"
        - "JWT token management"
        - "OAuth2 integration"
        - "Password management"
    
    - name: "user-service"
      version: "1.0.0"
      description: "User management service"
      port: 8002
      healthCheck: "/health"
      database: "users_db"
      dependencies: ["postgresql", "redis"]
      responsibilities:
        - "User profile management"
        - "User roles and permissions"
        - "User preferences"
        - "User search"
    
    - name: "project-service"
      version: "1.0.0"
      description: "Project management service"
      port: 8003
      healthCheck: "/health"
      database: "projects_db"
      dependencies: ["postgresql", "elasticsearch", "redis"]
      responsibilities:
        - "Project CRUD operations"
        - "Project member management"
        - "Project search and filtering"
        - "Project analytics"
    
    - name: "file-service"
      version: "1.0.0"
      description: "File storage and management service"
      port: 8004
      healthCheck: "/health"
      database: "files_db"
      dependencies: ["minio", "postgresql", "redis"]
      responsibilities:
        - "File upload and download"
        - "File metadata management"
        - "File versioning"
        - "File sharing and permissions"
    
    - name: "notification-service"
      version: "1.0.0"
      description: "Notification and messaging service"
      port: 8005
      healthCheck: "/health"
      database: "notifications_db"
      dependencies: ["postgresql", "redis", "rabbitmq", "sendgrid"]
      responsibilities:
        - "Email notifications"
        - "Push notifications"
        - "In-app notifications"
        - "Webhook management"
    
    - name: "analytics-service"
      version: "1.0.0"
      description: "Analytics and reporting service"
      port: 8006
      healthCheck: "/health"
      database: "analytics_db"
      dependencies: ["clickhouse", "postgresql", "redis"]
      responsibilities:
        - "Usage analytics"
        - "Performance metrics"
        - "Business intelligence"
        - "Custom reports"
    
    - name: "audit-service"
      version: "1.0.0"
      description: "Audit and compliance service"
      port: 8007
      healthCheck: "/health"
      database: "audit_db"
      dependencies: ["postgresql", "elasticsearch"]
      responsibilities:
        - "Audit trail management"
        - "Compliance reporting"
        - "Security event logging"
        - "Data lineage tracking"
  
  communication:
    synchronous:
      protocol: "HTTP/REST"
      serviceDiscovery: "consul"
      loadBalancing: "round_robin"
      circuitBreaker: "hystrix"
    
    asynchronous:
      messageBroker: "rabbitmq"
      patterns: ["publish-subscribe", "request-reply", "event-sourcing"]
      eventBus: "rabbitmq"
  
  dataManagement:
    strategy: "database-per-service"
    consistency: "eventual_consistency"
    transactions: "saga_pattern"
    
  deployment:
    platform: "kubernetes"
    orchestrator: "docker-swarm"
    serviceMesh: "istio"
    
  monitoring:
    tracing: "jaeger"
    metrics: "prometheus"
    logging: "elk-stack"
    healthChecks: "kubernetes-probes"

status:
  phase: designed
  services: 8
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "微服務架構配置建立完成"
}

# 建立服務發現
setup_service_discovery() {
    log_info "建立服務發現..."
    
    mkdir -p "config/service-discovery"
    
    # Consul 配置
    cat > "config/service-discovery/consul.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ServiceDiscovery
metadata:
  name: consul
  namespace: machinenativeops
spec:
  provider: "consul"
  version: "1.15.0"
  
  consul:
    datacenter: "dc1"
    dataDir: "/opt/consul/data"
    logLevel: "INFO"
    server: true
    bootstrapExpect: 3
    ui: true
    clientAddr: "0.0.0.0"
    bindAddr: "0.0.0.0"
    
    connect:
      enabled: true
      caProvider: "consul"
    
    acl:
      enabled: true
      defaultPolicy: "deny"
      downPolicy: "extend-cache"
    
    tls:
      enabled: true
      verifyIncoming: true
      verifyOutgoing: true
      verifyServerHostname: true
      caCertFile: "/etc/consul/tls/ca.pem"
      certFile: "/etc/consul/tls/consul.pem"
      keyFile: "/etc/consul/tls/consul-key.pem"
    
    autoEncrypt:
      tls: true
    
    gossip:
      encryptionKey: "\${CONSUL_GOSSIP_KEY}"
  
  services:
    - name: "auth-service"
      id: "auth-service-1"
      tags: ["auth", "v1"]
      address: "auth-service"
      port: 8001
      check:
        http: "http://auth-service:8001/health"
        interval: "10s"
        timeout: "3s"
        deregisterCriticalServiceAfter: "30s"
      meta:
        version: "1.0.0"
        environment: "production"
    
    - name: "user-service"
      id: "user-service-1"
      tags: ["users", "v1"]
      address: "user-service"
      port: 8002
      check:
        http: "http://user-service:8002/health"
        interval: "10s"
        timeout: "3s"
        deregisterCriticalServiceAfter: "30s"
      meta:
        version: "1.0.0"
        environment: "production"
    
    - name: "project-service"
      id: "project-service-1"
      tags: ["projects", "v1"]
      address: "project-service"
      port: 8003
      check:
        http: "http://project-service:8003/health"
        interval: "10s"
        timeout: "3s"
        deregisterCriticalServiceAfter: "30s"
      meta:
        version: "1.0.0"
        environment: "production"
    
    - name: "file-service"
      id: "file-service-1"
      tags: ["files", "v1"]
      address: "file-service"
      port: 8004
      check:
        http: "http://file-service:8004/health"
        interval: "10s"
        timeout: "3s"
        deregisterCriticalServiceAfter: "30s"
      meta:
        version: "1.0.0"
        environment: "production"
    
    - name: "notification-service"
      id: "notification-service-1"
      tags: ["notifications", "v1"]
      address: "notification-service"
      port: 8005
      check:
        http: "http://notification-service:8005/health"
        interval: "10s"
        timeout: "3s"
        deregisterCriticalServiceAfter: "30s"
      meta:
        version: "1.0.0"
        environment: "production"
  
  keyValueStore:
    enabled: true
    path: "machinenativeops/config"
    
  serviceMesh:
    enabled: true
    provider: "consul-connect"
    
  loadBalancing:
    algorithm: "round_robin"
    healthCheckThreshold: 3

status:
  phase: configured
  services: 5
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # Docker Compose for Consul
    cat > "config/service-discovery/docker-compose.yml" << EOF
version: '3.8'

services:
  consul-server1:
    image: consul:1.15.0
    container_name: consul-server1
    hostname: consul-server1
    command: agent -server -bootstrap-expect=3 -ui -bind=0.0.0.0 -client=0.0.0.0 -datacenter=dc1
    environment:
      CONSUL_BIND_INTERFACE: eth0
    volumes:
      - consul_server1_data:/consul/data
      - ./consul-server1.json:/consul/config/consul.json
    ports:
      - "8500:8500"
      - "8600:8600/udp"
    networks:
      - consul-net

  consul-server2:
    image: consul:1.15.0
    container_name: consul-server2
    hostname: consul-server2
    command: agent -server -retry-join=consul-server1 -bind=0.0.0.0 -client=0.0.0.0 -datacenter=dc1
    environment:
      CONSUL_BIND_INTERFACE: eth0
    volumes:
      - consul_server2_data:/consul/data
      - ./consul-server2.json:/consul/config/consul.json
    networks:
      - consul-net
    depends_on:
      - consul-server1

  consul-server3:
    image: consul:1.15.0
    container_name: consul-server3
    hostname: consul-server3
    command: agent -server -retry-join=consul-server1 -bind=0.0.0.0 -client=0.0.0.0 -datacenter=dc1
    environment:
      CONSUL_BIND_INTERFACE: eth0
    volumes:
      - consul_server3_data:/consul/data
      - ./consul-server3.json:/consul/config/consul.json
    networks:
      - consul-net
    depends_on:
      - consul-server1

  consul-client:
    image: consul:1.15.0
    container_name: consul-client
    hostname: consul-client
    command: agent -retry-join=consul-server1 -bind=0.0.0.0 -client=0.0.0.0 -datacenter=dc1
    environment:
      CONSUL_BIND_INTERFACE: eth0
    volumes:
      - ./consul-client.json:/consul/config/consul.json
    networks:
      - consul-net
    depends_on:
      - consul-server1

volumes:
  consul_server1_data:
  consul_server2_data:
  consul_server3_data:

networks:
  consul-net:
    driver: bridge
EOF
    
    log_success "服務發現建立完成"
}

# 建立服務網格
setup_service_mesh() {
    log_info "建立服務網格..."
    
    mkdir -p "config/service-mesh"
    
    # Istio 配置
    cat > "config/service-mesh/istio.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ServiceMesh
metadata:
  name: istio
  namespace: machinenativeops
spec:
  provider: "istio"
  version: "1.18.0"
  
  meshConfig:
    defaultConfig:
      discoveryAddress: "istiod.istio-system.svc:15012"
      meshId: "mesh1"
      trustDomain: "cluster.local"
      sdsUdsPath: "unix:/var/run/istio/sds"
      proxyMetadata:
        DNS_AGENT: ""
    
    enablePrometheusMerge: true
    defaultServiceExportTo: ["*"]
    defaultVirtualServiceExportTo: ["*"]
    defaultDestinationRuleExportTo: ["*"]
    defaultPolicyExportTo: ["*"]
    resolvers: ["k8s"]
    
  trafficManagement:
    virtualServices:
      - name: "auth-service"
        hosts: ["auth-service"]
        http:
          - match:
            - uri:
                prefix: "/api/v1/auth"
            route:
              - destination:
                  host: auth-service
                  port: number 8001
            timeout: 30s
            retries:
              attempts: 3
              perTryTimeout: 10s
      
      - name: "user-service"
        hosts: ["user-service"]
        http:
          - match:
            - uri:
                prefix: "/api/v1/users"
            route:
              - destination:
                  host: user-service
                  port: number 8002
            timeout: 30s
            retries:
              attempts: 3
              perTryTimeout: 10s
    
    destinationRules:
      - name: "auth-service"
        host: "auth-service"
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          connectionPool:
            tcp:
              maxConnections: 100
            http:
              http1MaxPendingRequests: 50
              maxRequestsPerConnection: 10
          circuitBreaker:
            consecutiveErrors: 3
            interval: 30s
            baseEjectionTime: 30s
      
      - name: "user-service"
        host: "user-service"
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          connectionPool:
            tcp:
              maxConnections: 100
            http:
              http1MaxPendingRequests: 50
              maxRequestsPerConnection: 10
          circuitBreaker:
            consecutiveErrors: 3
            interval: 30s
            baseEjectionTime: 30s
  
  security:
    authentication:
      - name: "default"
        mtls:
          mode: STRICT
    
    authorization:
      - name: "auth-service-policy"
        selector:
          matchLabels:
            app: auth-service
        rules:
          - from:
            - source:
                principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
          - to:
            - operation:
                methods: ["GET", "POST", "PUT", "DELETE"]
  
  observability:
    tracing:
      sampling: 100.0
      custom_tags:
        service_name:
          environment: "SERVICE_NAME"
        version:
          environment: "SERVICE_VERSION"
    
    metrics:
      prometheus:
        enabled: true
        workloadEntries: true
    
    accessLogging:
      enabled: true
      providers:
        - name: "envoy"
          envoy:
            logName: "access.log"
            filter:
              responseFlagsFilter:
                notMatch:
                  values: ["NR"]
    
    kiali:
      enabled: true
      dashboards:
        - name: "auth-service"
          title: "Auth Service Dashboard"
          url: "https://grafana.istio-system.svc/d/auth-service"
    
  telemetry:
    v2:
      prometheus:
        enabled: true
        config_override:
          inbound:
            disable_host_header: true
          outbound:
            disable_host_header: true
      
      accessLogging:
        enabled: true
        providers:
          - name: "envoy"
            envoy:
              logName: "access.log"
              formatting:
                json:
                  timestamp_format: "%Y-%m-%dT%H:%M:%S.%fZ"
                  skip_empty_fields: true
EOF
    
    # Kiali 配置
    cat > "config/service-mesh/kiali.yaml" << EOF
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
  namespace: istio-system
spec:
  auth:
    strategy: "anonymous"
  deployment:
    namespace: istio-system
    image_name: "quay.io/kiali/kiali"
    image_version: "v1.66.0"
    view_only_mode: false
    ingress:
      enabled: true
  external_services:
    enabled: true
    istio:
      component_status:
        components:
          - "pilot"
          - "policy"
          - "telemetry"
          - "citadel"
        app_label: "istio"
      config_map_name: "istio"
      root_namespace: "istio-system"
      url_service_version: ""
    prometheus:
      url: "http://prometheus.istio-system:9090"
    grafana:
      url: "http://grafana.istio-system:3000"
  server:
    port: 20001
    web_root: "/kiali"
  identity:
    cert_file: ""
    private_key_file: ""
  log_level: "info"
  metrics_enabled: true
  metrics_port: 9090
EOF
    
    log_success "服務網格建立完成"
}

# 建立事件驅動架構
setup_event_driven_architecture() {
    log_info "建立事件驅動架構..."
    
    mkdir -p "config/events"
    
    # 事件架構配置
    cat > "config/events/event-architecture.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: EventDrivenArchitecture
metadata:
  name: event-architecture
  namespace: machinenativeops
spec:
  messageBroker:
    provider: "rabbitmq"
    version: "3.11.0"
    clusterMode: true
    highAvailability: true
  
  events:
    # User events
    - name: "user.created"
      source: "user-service"
      version: "1.0"
      schema: "events/schemas/user-created.json"
      routingKey: "user.created"
      exchange: "users"
      destinations: ["auth-service", "notification-service"]
    
    - name: "user.updated"
      source: "user-service"
      version: "1.0"
      schema: "events/schemas/user-updated.json"
      routingKey: "user.updated"
      exchange: "users"
      destinations: ["auth-service", "notification-service"]
    
    - name: "user.deleted"
      source: "user-service"
      version: "1.0"
      schema: "events/schemas/user-deleted.json"
      routingKey: "user.deleted"
      exchange: "users"
      destinations: ["auth-service", "notification-service", "audit-service"]
    
    # Authentication events
    - name: "auth.login.succeeded"
      source: "auth-service"
      version: "1.0"
      schema: "events/schemas/auth-login-succeeded.json"
      routingKey: "auth.login.succeeded"
      exchange: "auth"
      destinations: ["user-service", "audit-service"]
    
    - name: "auth.login.failed"
      source: "auth-service"
      version: "1.0"
      schema: "events/schemas/auth-login-failed.json"
      routingKey: "auth.login.failed"
      exchange: "auth"
      destinations: ["audit-service", "notification-service"]
    
    - name: "auth.password.reset"
      source: "auth-service"
      version: "1.0"
      schema: "events/schemas/auth-password-reset.json"
      routingKey: "auth.password.reset"
      exchange: "auth"
      destinations: ["user-service", "notification-service"]
    
    # Project events
    - name: "project.created"
      source: "project-service"
      version: "1.0"
      schema: "events/schemas/project-created.json"
      routingKey: "project.created"
      exchange: "projects"
      destinations: ["user-service", "notification-service", "audit-service"]
    
    - name: "project.updated"
      source: "project-service"
      version: "1.0"
      schema: "events/schemas/project-updated.json"
      routingKey: "project.updated"
      exchange: "projects"
      destinations: ["user-service", "notification-service", "audit-service"]
    
    - name: "project.deleted"
      source: "project-service"
      version: "1.0"
      schema: "events/schemas/project-deleted.json"
      routingKey: "project.deleted"
      exchange: "projects"
      destinations: ["user-service", "notification-service", "audit-service", "file-service"]
    
    # File events
    - name: "file.uploaded"
      source: "file-service"
      version: "1.0"
      schema: "events/schemas/file-uploaded.json"
      routingKey: "file.uploaded"
      exchange: "files"
      destinations: ["notification-service", "audit-service"]
    
    - name: "file.shared"
      source: "file-service"
      version: "1.0"
      schema: "events/schemas/file-shared.json"
      routingKey: "file.shared"
      exchange: "files"
      destinations: ["notification-service", "audit-service"]
    
    - name: "file.deleted"
      source: "file-service"
      version: "1.0"
      schema: "events/schemas/file-deleted.json"
      routingKey: "file.deleted"
      exchange: "files"
      destinations: ["audit-service"]
  
  exchanges:
    - name: "users"
      type: "topic"
      durable: true
      autoDelete: false
    
    - name: "auth"
      type: "topic"
      durable: true
      autoDelete: false
    
    - name: "projects"
      type: "topic"
      durable: true
      autoDelete: false
    
    - name: "files"
      type: "topic"
      durable: true
      autoDelete: false
    
    - name: "notifications"
      type: "topic"
      durable: true
      autoDelete: false
  
  queues:
    - name: "auth-service-queue"
      durable: true
      autoDelete: false
      bindings:
        - exchange: "users"
          routingKey: "user.*"
        - exchange: "auth"
          routingKey: "auth.*"
    
    - name: "user-service-queue"
      durable: true
      autoDelete: false
      bindings:
        - exchange: "users"
          routingKey: "user.*"
        - exchange: "auth"
          routingKey: "auth.login.succeeded"
    
    - name: "notification-service-queue"
      durable: true
      autoDelete: false
      bindings:
        - exchange: "users"
          routingKey: "user.*"
        - exchange: "auth"
          routingKey: "auth.*"
        - exchange: "projects"
          routingKey: "project.*"
        - exchange: "files"
          routingKey: "file.*"
    
    - name: "audit-service-queue"
      durable: true
      autoDelete: false
      bindings:
        - exchange: "users"
          routingKey: "user.*"
        - exchange: "auth"
          routingKey: "auth.*"
        - exchange: "projects"
          routingKey: "project.*"
        - exchange: "files"
          routingKey: "file.*"
  
  deadLetterQueue:
    enabled: true
    name: "dead-letter-queue"
    exchange: "dead-letter-exchange"
    routingKey: "dead.letter"
  
  messagePatterns:
    - name: "event_sourcing"
      enabled: true
      services: ["project-service", "user-service"]
    - name: "saga_pattern"
      enabled: true
      services: ["user-service", "auth-service"]
    - name: "compensating_transaction"
      enabled: true
      services: ["file-service", "project-service"]

status:
  phase: configured
  events: 13
  exchanges: 5
  queues: 4
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # RabbitMQ 配置
    cat > "config/events/rabbitmq.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: MessageBroker
metadata:
  name: rabbitmq
  namespace: machinenativeops
spec:
  provider: "rabbitmq"
  version: "3.11.0"
  
  cluster:
    nodes: 3
    memory: "2Gi"
    cpu: "1000m"
    disk: "20Gi"
  
  networking:
    port: 5672
    managementPort: 15672
    host: "0.0.0.0"
  
  authentication:
    type: "username_password"
    users:
      - username: "admin"
        password: "admin_password"
        tags: ["administrator"]
      - username: "app_user"
        password: "app_password"
        tags: ["management"]
  
  policies:
    - name: "ha-policy"
      pattern: "^(?!amq\\.).*"
      definition:
        ha-mode: "all"
        ha-sync-mode: "automatic"
        ha-sync-batch-size: 10
    
    - name: "queue-length-limit"
      pattern: ".*"
      definition:
        max-length: 10000
        overflow: "drop-head"
  
  plugins:
    enabled:
      - "rabbitmq_management"
      - "rabbitmq_prometheus"
      - "rabbitmq_event_exchange"
      - "rabbitmq_shovel"
      - "rabbitmq_federation"
  
  monitoring:
    prometheus:
      enabled: true
      port: 9419
    
    management:
      enabled: true
      port: 15672

status:
  phase: configured
  clusterNodes: 3
  plugins: 5
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "事件驅動架構建立完成"
}

# 建立 Docker 部署配置
setup_microservices_deployment() {
    log_info "建立微服務 Docker 部署配置..."
    
    mkdir -p "docker/microservices"
    
    # Docker Compose for all services
    cat > "docker/microservices/docker-compose.yml" << EOF
version: '3.8'

services:
  # API Gateway
  api-gateway:
    build:
      context: ../../src/api
      dockerfile: Dockerfile
    container_name: machinenativeops-api-gateway
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=production
      - JWT_SECRET=\${JWT_SECRET}
      - CONSUL_HOST=consul
      - CONSUL_PORT=8500
    networks:
      - machinenativeops-net
    depends_on:
      - consul
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Auth Service
  auth-service:
    build:
      context: ../../src/services/auth
      dockerfile: Dockerfile
    container_name: machinenativeops-auth-service
    ports:
      - "8001:8001"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/auth_db
      - REDIS_URL=redis://redis:6379/0
      - JWT_SECRET=\${JWT_SECRET}
      - CONSUL_HOST=consul
      - CONSUL_PORT=8500
    networks:
      - machinenativeops-net
    depends_on:
      - postgres
      - redis
      - consul
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # User Service
  user-service:
    build:
      context: ../../src/services/users
      dockerfile: Dockerfile
    container_name: machinenativeops-user-service
    ports:
      - "8002:8002"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/users_db
      - REDIS_URL=redis://redis:6379/0
      - CONSUL_HOST=consul
      - CONSUL_PORT=8500
    networks:
      - machinenativeops-net
    depends_on:
      - postgres
      - redis
      - consul
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8002/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Project Service
  project-service:
    build:
      context: ../../src/services/projects
      dockerfile: Dockerfile
    container_name: machinenativeops-project-service
    ports:
      - "8003:8003"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/projects_db
      - REDIS_URL=redis://redis:6379/0
      - ELASTICSEARCH_URL=http://elasticsearch:9200
      - CONSUL_HOST=consul
      - CONSUL_PORT=8500
    networks:
      - machinenativeops-net
    depends_on:
      - postgres
      - redis
      - elasticsearch
      - consul
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8003/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # File Service
  file-service:
    build:
      context: ../../src/services/files
      dockerfile: Dockerfile
    container_name: machinenativeops-file-service
    ports:
      - "8004:8004"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/files_db
      - REDIS_URL=redis://redis:6379/0
      - MINIO_ENDPOINT=minio:9000
      - MINIO_ACCESS_KEY=\${MINIO_ACCESS_KEY}
      - MINIO_SECRET_KEY=\${MINIO_SECRET_KEY}
      - CONSUL_HOST=consul
      - CONSUL_PORT=8500
    networks:
      - machinenativeops-net
    depends_on:
      - postgres
      - redis
      - minio
      - consul
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8004/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Notification Service
  notification-service:
    build:
      context: ../../src/services/notifications
      dockerfile: Dockerfile
    container_name: machinenativeops-notification-service
    ports:
      - "8005:8005"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/notifications_db
      - REDIS_URL=redis://redis:6379/0
      - RABBITMQ_URL=amqp://app_user:app_password@rabbitmq:5672/
      - SENDGRID_API_KEY=\${SENDGRID_API_KEY}
      - CONSUL_HOST=consul
      - CONSUL_PORT=8500
    networks:
      - machinenativeops-net
    depends_on:
      - postgres
      - redis
      - rabbitmq
      - consul
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8005/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Infrastructure Services
  consul:
    image: consul:1.15.0
    container_name: machinenativeops-consul
    ports:
      - "8500:8500"
      - "8600:8600/udp"
    environment:
      CONSUL_BIND_INTERFACE: eth0
    command: agent -server -bootstrap -ui -bind=0.0.0.0 -client=0.0.0.0
    networks:
      - machinenativeops-net

  postgres:
    image: postgres:15-alpine
    container_name: machinenativeops-postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=machinenativeops
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-multiple-databases.sh:/docker-entrypoint-initdb.d/init-multiple-databases.sh
    networks:
      - machinenativeops-net

  redis:
    image: redis:7-alpine
    container_name: machinenativeops-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - machinenativeops-net

  rabbitmq:
    image: rabbitmq:3.11-management
    container_name: machinenativeops-rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=app_user
      - RABBITMQ_DEFAULT_PASS=app_password
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - machinenativeops-net

  elasticsearch:
    image: elasticsearch:8.6.0
    container_name: machinenativeops-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - machinenativeops-net

  minio:
    image: minio/minio:latest
    container_name: machinenativeops-minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ROOT_USER=\${MINIO_ACCESS_KEY}
      - MINIO_ROOT_PASSWORD=\${MINIO_SECRET_KEY}
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    networks:
      - machinenativeops-net

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
  elasticsearch_data:
  minio_data:

networks:
  machinenativeops-net:
    driver: bridge
EOF
    
    log_success "微服務 Docker 部署配置建立完成"
}

# 建立服務監控
setup_services_monitoring() {
    log_info "建立服務監控..."
    
    mkdir -p "config/services-monitoring"
    
    # 服務監控配置
    cat > "config/services-monitoring/services-monitoring.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: ServicesMonitoring
metadata:
  name: services-monitoring
  namespace: machinenativeops
spec:
  monitoringEnabled: true
  
  tracing:
    provider: "jaeger"
    version: "1.42.0"
    samplingRate: 0.1
    collectors:
      - host: "jaeger-collector"
        port: 14250
    agents:
      - host: "jaeger-agent"
        port: 6831
    ui:
      host: "jaeger-ui"
      port: 16686
  
  metrics:
    provider: "prometheus"
    version: "2.40.0"
    scrapeInterval: "15s"
    evaluationInterval: "15s"
    targets:
      - job: "api-gateway"
        static_configs:
          - targets: ["api-gateway:8000"]
        metrics_path: "/metrics"
        scrape_interval: "10s"
      
      - job: "auth-service"
        static_configs:
          - targets: ["auth-service:8001"]
        metrics_path: "/metrics"
        scrape_interval: "10s"
      
      - job: "user-service"
        static_configs:
          - targets: ["user-service:8002"]
        metrics_path: "/metrics"
        scrape_interval: "10s"
      
      - job: "project-service"
        static_configs:
          - targets: ["project-service:8003"]
        metrics_path: "/metrics"
        scrape_interval: "10s"
      
      - job: "file-service"
        static_configs:
          - targets: ["file-service:8004"]
        metrics_path: "/metrics"
        scrape_interval: "10s"
      
      - job: "notification-service"
        static_configs:
          - targets: ["notification-service:8005"]
        metrics_path: "/metrics"
        scrape_interval: "10s"
      
      - job: "infrastructure"
        static_configs:
          - targets: ["postgres:5432", "redis:6379", "rabbitmq:5672"]
        scrape_interval: "30s"
  
  logging:
    provider: "elk-stack"
    elasticsearch:
      host: "elasticsearch"
      port: 9200
    logstash:
      host: "logstash"
      port: 5044
    kibana:
      host: "kibana"
      port: 5601
  
  alerting:
    provider: "alertmanager"
    version: "0.25.0"
    rules:
      - name: "service-down"
        condition: "up == 0"
        duration: "30s"
        severity: "critical"
        annotations:
          summary: "Service {{\$labels.instance}} is down"
          description: "Service {{\$labels.instance}} has been down for more than 30 seconds."
      
      - name: "high-error-rate"
        condition: "rate(http_requests_total{status=~&quot;5..&quot;}[5m]) > 0.1"
        duration: "2m"
        severity: "warning"
        annotations:
          summary: "High error rate in {{\$labels.instance}}"
          description: "Error rate is {{\$value}} errors per second."
      
      - name: "high-response-time"
        condition: "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1"
        duration: "5m"
        severity: "warning"
        annotations:
          summary: "High response time in {{\$labels.instance}}"
          description: "95th percentile response time is {{\$value}} seconds."
  
  dashboards:
    - name: "services-overview"
      title: "Services Overview"
      panels:
        - title: "Service Status"
          type: "stat"
          targets:
            - expr: "up"
              legendFormat: "{{instance}}"
        
        - title: "Request Rate"
          type: "graph"
          targets:
            - expr: "sum(rate(http_requests_total[5m])) by (service)"
              legendFormat: "{{service}}"
        
        - title: "Error Rate"
          type: "graph"
          targets:
            - expr: "sum(rate(http_requests_total{status=~&quot;5..&quot;}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)"
              legendFormat: "{{service}}"
        
        - title: "Response Time"
          type: "graph"
          targets:
            - expr: "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))"
              legendFormat: "95th percentile - {{service}}"
            - expr: "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))"
              legendFormat: "50th percentile - {{service}}"

status:
  phase: configured
  services: 6
  dashboards: 1
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "服務監控建立完成"
}

# 驗證微服務系統
verify_microservices_system() {
    log_info "驗證微服務系統..."
    
    local verification_errors=0
    
    # 檢查配置文件
    local required_files=(
        "config/microservices/microservices-architecture.yaml"
        "config/service-discovery/consul.yaml"
        "config/service-mesh/istio.yaml"
        "config/events/event-architecture.yaml"
        "config/services-monitoring/services-monitoring.yaml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "微服務配置文件存在：$(basename "$file")"
        else
            log_error "微服務配置文件不存在：$file"
            ((verification_errors++))
        fi
    done
    
    # 檢查 Docker 配置
    if [[ -f "docker/microservices/docker-compose.yml" ]]; then
        log_success "微服務 Docker 配置存在"
    else
        log_error "微服務 Docker 配置不存在"
        ((verification_errors++))
    fi
    
    # 檢查服務發現配置
    if [[ -f "config/service-discovery/docker-compose.yml" ]]; then
        log_success "服務發現 Docker 配置存在"
    else
        log_error "服務發現 Docker 配置不存在"
        ((verification_errors++))
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "微服務系統驗證通過"
        return 0
    else
        log_error "微服務系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始微服務系統初始化..."
    
    # 初始化階段
    local total_steps=7
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; setup_microservices_architecture
    ((current_step++)); progress_bar $current_step $total_steps; setup_service_discovery
    ((current_step++)); progress_bar $current_step $total_steps; setup_service_mesh
    ((current_step++)); progress_bar $current_step $total_steps; setup_event_driven_architecture
    ((current_step++)); progress_bar $current_step $total_steps; setup_microservices_deployment
    ((current_step++)); progress_bar $current_step $total_steps; setup_services_monitoring
    ((current_step++)); progress_bar $current_step $total_steps; verify_microservices_system
    
    echo; log_success "微服務系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - 微服務架構：config/microservices/"
    echo "  - 服務發現：config/service-discovery/"
    echo "  - 服務網格：config/service-mesh/"
    echo "  - 事件架構：config/events/"
    echo "  - 服務監控：config/services-monitoring/"
    echo "  - Docker 部署：docker/microservices/"
    echo
    log_info "微服務特色："
    echo "  - 8 個核心微服務"
    echo "  - Consul 服務發現"
    echo "  - Istio 服務網格"
    echo "  - RabbitMQ 事件驅動"
    echo "  - Prometheus + Grafana 監控"
    echo "  - Jaeger 分散式追蹤"
    echo
    log_info "微服務系統狀態：已初始化並驗證"
}

# 執行主函數
main "$@"