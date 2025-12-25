#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - API Gateway Initialization
# =============================================================================
# API Gateway 初始化腳本
# 職責：建立 API Gateway、路由管理、負載均衡、限流、監控
# 依賴：10-security-init.sh
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
    log_info "載入 API Gateway 配置..."
    
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    log_success "API Gateway 配置載入完成"
}

# 建立 API Gateway 核心配置
setup_api_gateway_core() {
    log_info "建立 API Gateway 核心配置..."
    
    mkdir -p "config/gateway/{routes,middleware,services,plugins}"
    
    # API Gateway 主配置
    cat > "config/gateway/gateway-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: APIGatewayConfiguration
metadata:
  name: api-gateway
  namespace: machinenativeops
spec:
  gateway:
    name: "machinenativeops-gateway"
    version: "1.0.0"
    framework: "fastapi"
    instanceCount: 3
    resources:
      cpu: "1000m"
      memory: "2Gi"
      storage: "10Gi"
  
  networking:
    port: 8000
    host: "0.0.0.0"
    ssl:
      enabled: true
      certPath: "/etc/ssl/certs/gateway.crt"
      keyPath: "/etc/ssl/private/gateway.key"
    loadBalancer:
      type: "round_robin"
      healthCheck:
        path: "/health"
        interval: "30s"
        timeout: "5s"
        retries: 3
  
  middleware:
    order:
      - "cors"
      - "security"
      - "rate_limiting"
      - "authentication"
      - "authorization"
      - "logging"
      - "metrics"
      - "caching"
      - "compression"
    
    enabled:
      - name: "cors"
        config:
          allowOrigins: ["*"]
          allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
          allowHeaders: ["*"]
          exposeHeaders: ["X-Total-Count", "X-Rate-Limit-Remaining"]
      - name: "security"
        config:
          headers:
            - "X-Content-Type-Options: nosniff"
            - "X-Frame-Options: DENY"
            - "X-XSS-Protection: 1; mode=block"
            - "Strict-Transport-Security: max-age=31536000; includeSubDomains"
      - name: "rate_limiting"
        config:
          global: 10000
          perIP: 1000
          perUser: 500
          window: "1m"
      - name: "authentication"
        config:
          jwt:
            secret: "\${JWT_SECRET}"
            algorithm: "HS256"
            expiresIn: "24h"
      - name: "logging"
        config:
          level: "info"
          format: "json"
      - name: "metrics"
        config:
          enabled: true
          path: "/metrics"
      - name: "caching"
        config:
          ttl: "300s"
          maxSize: 1000
  
  services:
    - name: "auth-service"
      url: "http://auth-service:8001"
      healthCheck: "/health"
      timeout: "30s"
      retries: 3
      circuitBreaker:
        enabled: true
        threshold: 5
        timeout: "60s"
      rateLimit:
        enabled: true
        requests: 1000
        window: "1m"
    
    - name: "user-service"
      url: "http://user-service:8002"
      healthCheck: "/health"
      timeout: "30s"
      retries: 3
      circuitBreaker:
        enabled: true
        threshold: 5
        timeout: "60s"
      rateLimit:
        enabled: true
        requests: 2000
        window: "1m"
    
    - name: "project-service"
      url: "http://project-service:8003"
      healthCheck: "/health"
      timeout: "30s"
      retries: 3
      circuitBreaker:
        enabled: true
        threshold: 5
        timeout: "60s"
      rateLimit:
        enabled: true
        requests: 1500
        window: "1m"
    
    - name: "file-service"
      url: "http://file-service:8004"
      healthCheck: "/health"
      timeout: "60s"
      retries: 2
      circuitBreaker:
        enabled: true
        threshold: 3
        timeout: "90s"
      rateLimit:
        enabled: true
        requests: 500
        window: "1m"
    
    - name: "notification-service"
      url: "http://notification-service:8005"
      healthCheck: "/health"
      timeout: "30s"
      retries: 3
      circuitBreaker:
        enabled: true
        threshold: 5
        timeout: "60s"
      rateLimit:
        enabled: true
        requests: 3000
        window: "1m"

status:
  phase: configured
  services: 5
  middleware: 9
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "API Gateway 核心配置建立完成"
}

# 建立路由配置
setup_routing_configuration() {
    log_info "建立路由配置..."
    
    # 路由定義
    cat > "config/gateway/routes/routes.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: APIRoutes
metadata:
  name: api-routes
  namespace: machinenativeops
spec:
  routes:
    # Authentication routes
    - name: "auth-login"
      path: "/api/v1/auth/login"
      method: "POST"
      service: "auth-service"
      target: "/login"
      authentication: false
      rateLimit: 100
      timeout: "10s"
      cache:
        enabled: false
    
    - name: "auth-logout"
      path: "/api/v1/auth/logout"
      method: "POST"
      service: "auth-service"
      target: "/logout"
      authentication: true
      rateLimit: 100
      timeout: "10s"
    
    - name: "auth-refresh"
      path: "/api/v1/auth/refresh"
      method: "POST"
      service: "auth-service"
      target: "/refresh"
      authentication: false
      rateLimit: 200
      timeout: "10s"
    
    # User management routes
    - name: "users-list"
      path: "/api/v1/users"
      method: "GET"
      service: "user-service"
      target: "/users"
      authentication: true
      authorization: "users:read"
      rateLimit: 1000
      timeout: "30s"
      cache:
        enabled: true
        ttl: "300s"
    
    - name: "users-create"
      path: "/api/v1/users"
      method: "POST"
      service: "user-service"
      target: "/users"
      authentication: true
      authorization: "users:create"
      rateLimit: 100
      timeout: "30s"
    
    - name: "user-detail"
      path: "/api/v1/users/{user_id}"
      method: "GET"
      service: "user-service"
      target: "/users/{user_id}"
      authentication: true
      authorization: "users:read"
      rateLimit: 1000
      timeout: "10s"
      cache:
        enabled: true
        ttl: "600s"
    
    - name: "user-update"
      path: "/api/v1/users/{user_id}"
      method: "PUT"
      service: "user-service"
      target: "/users/{user_id}"
      authentication: true
      authorization: "users:update"
      rateLimit: 500
      timeout: "30s"
    
    - name: "user-delete"
      path: "/api/v1/users/{user_id}"
      method: "DELETE"
      service: "user-service"
      target: "/users/{user_id}"
      authentication: true
      authorization: "users:delete"
      rateLimit: 100
      timeout: "30s"
    
    # Project management routes
    - name: "projects-list"
      path: "/api/v1/projects"
      method: "GET"
      service: "project-service"
      target: "/projects"
      authentication: true
      authorization: "projects:read"
      rateLimit: 2000
      timeout: "30s"
      cache:
        enabled: true
        ttl: "300s"
    
    - name: "projects-create"
      path: "/api/v1/projects"
      method: "POST"
      service: "project-service"
      target: "/projects"
      authentication: true
      authorization: "projects:create"
      rateLimit: 500
      timeout: "60s"
    
    - name: "project-detail"
      path: "/api/v1/projects/{project_id}"
      method: "GET"
      service: "project-service"
      target: "/projects/{project_id}"
      authentication: true
      authorization: "projects:read"
      rateLimit: 2000
      timeout: "10s"
      cache:
        enabled: true
        ttl: "600s"
    
    - name: "project-update"
      path: "/api/v1/projects/{project_id}"
      method: "PUT"
      service: "project-service"
      target: "/projects/{project_id}"
      authentication: true
      authorization: "projects:update"
      rateLimit: 1000
      timeout: "60s"
    
    - name: "project-delete"
      path: "/api/v1/projects/{project_id}"
      method: "DELETE"
      service: "project-service"
      target: "/projects/{project_id}"
      authentication: true
      authorization: "projects:delete"
      rateLimit: 100
      timeout: "60s"
    
    # File management routes
    - name: "files-upload"
      path: "/api/v1/files"
      method: "POST"
      service: "file-service"
      target: "/files"
      authentication: true
      authorization: "files:create"
      rateLimit: 100
      timeout: "300s"
      maxFileSize: "100MB"
    
    - name: "files-list"
      path: "/api/v1/files"
      method: "GET"
      service: "file-service"
      target: "/files"
      authentication: true
      authorization: "files:read"
      rateLimit: 2000
      timeout: "30s"
      cache:
        enabled: true
        ttl: "300s"
    
    - name: "file-detail"
      path: "/api/v1/files/{file_id}"
      method: "GET"
      service: "file-service"
      target: "/files/{file_id}"
      authentication: true
      authorization: "files:read"
      rateLimit: 2000
      timeout: "10s"
      cache:
        enabled: true
        ttl: "1800s"
    
    - name: "file-download"
      path: "/api/v1/files/{file_id}/download"
      method: "GET"
      service: "file-service"
      target: "/files/{file_id}/download"
      authentication: true
      authorization: "files:read"
      rateLimit: 1000
      timeout: "300s"
      stream: true
    
    # Notification routes
    - name: "notifications-list"
      path: "/api/v1/notifications"
      method: "GET"
      service: "notification-service"
      target: "/notifications"
      authentication: true
      authorization: "notifications:read"
      rateLimit: 3000
      timeout: "30s"
    
    - name: "notification-mark-read"
      path: "/api/v1/notifications/{notification_id}/read"
      method: "POST"
      service: "notification-service"
      target: "/notifications/{notification_id}/read"
      authentication: true
      authorization: "notifications:update"
      rateLimit: 2000
      timeout: "10s"
    
    # Health and metrics routes
    - name: "health-check"
      path: "/health"
      method: "GET"
      service: "gateway"
      target: "/health"
      authentication: false
      rateLimit: 1000
      timeout: "5s"
    
    - name: "metrics"
      path: "/metrics"
      method: "GET"
      service: "gateway"
      target: "/metrics"
      authentication: true
      authorization: "metrics:read"
      rateLimit: 100
      timeout: "10s"
    
    - name: "api-docs"
      path: "/docs"
      method: "GET"
      service: "gateway"
      target: "/docs"
      authentication: false
      rateLimit: 1000
      timeout: "10s"
      cache:
        enabled: true
        ttl: "3600s"

status:
  phase: configured
  routes: 25
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "路由配置建立完成"
}

# 建立中間件配置
setup_middleware_configuration() {
    log_info "建立中間件配置..."
    
    # CORS 中間件
    cat > "config/gateway/middleware/cors.py" << 'EOF'
"""
CORS Middleware for API Gateway
"""

from fastapi.middleware.cors import CORSMiddleware
from fastapi import Request, Response
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

class CustomCORSMiddleware:
    def __init__(
        self,
        app,
        allow_origins: List[str] = ["*"],
        allow_methods: List[str] = ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers: List[str] = ["*"],
        expose_headers: List[str] = [],
        max_age: int = 600,
        allow_credentials: bool = True
    ):
        self.app = app
        self.allow_origins = allow_origins
        self.allow_methods = allow_methods
        self.allow_headers = allow_headers
        self.expose_headers = expose_headers
        self.max_age = max_age
        self.allow_credentials = allow_credentials

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            request = Request(scope, receive)
            
            # Handle preflight requests
            if request.method == "OPTIONS":
                response = Response()
                self._add_cors_headers(response, request)
                await response(scope, receive, send)
                return
        
        await self.app(scope, receive, send)

    def _add_cors_headers(self, response: Response, request: Request):
        origin = request.headers.get("origin")
        
        if origin and (self.allow_origins == ["*"] or origin in self.allow_origins):
            response.headers["Access-Control-Allow-Origin"] = origin
        
        response.headers["Access-Control-Allow-Methods"] = ", ".join(self.allow_methods)
        response.headers["Access-Control-Allow-Headers"] = ", ".join(self.allow_headers)
        
        if self.expose_headers:
            response.headers["Access-Control-Expose-Headers"] = ", ".join(self.expose_headers)
        
        response.headers["Access-Control-Max-Age"] = str(self.max_age)
        
        if self.allow_credentials:
            response.headers["Access-Control-Allow-Credentials"] = "true"
EOF
    
    # 限流中間件
    cat > "config/gateway/middleware/rate_limiting.py" << 'EOF'
"""
Rate Limiting Middleware for API Gateway
"""

import time
import asyncio
from collections import defaultdict, deque
from fastapi import Request, Response, HTTPException
from typing import Dict, Tuple
import redis.asyncio as redis
import logging

logger = logging.getLogger(__name__)

class RateLimiter:
    def __init__(
        self,
        redis_client: Optional[redis.Redis] = None,
        global_limit: int = 10000,
        per_ip_limit: int = 1000,
        per_user_limit: int = 500,
        window_seconds: int = 60
    ):
        self.redis_client = redis_client
        self.global_limit = global_limit
        self.per_ip_limit = per_ip_limit
        self.per_user_limit = per_user_limit
        self.window_seconds = window_seconds
        
        # In-memory fallback
        self.memory_storage = defaultdict(lambda: deque())
    
    async def is_allowed(
        self,
        key: str,
        limit: int,
        window_seconds: int = None
    ) -> Tuple[bool, Dict[str, int]]:
        """Check if request is allowed based on rate limit"""
        window_seconds = window_seconds or self.window_seconds
        current_time = time.time()
        
        if self.redis_client:
            return await self._check_redis(key, limit, window_seconds)
        else:
            return self._check_memory(key, limit, window_seconds)
    
    async def _check_redis(
        self,
        key: str,
        limit: int,
        window_seconds: int
    ) -> Tuple[bool, Dict[str, int]]:
        """Check rate limit using Redis"""
        current_time = int(time.time())
        window_start = current_time - window_seconds
        
        # Clean old entries
        await self.redis_client.zremrangebyscore(key, 0, window_start)
        
        # Count current requests
        current_requests = await self.redis_client.zcard(key)
        
        if current_requests >= limit:
            ttl = await self.redis_client.ttl(key)
            return False, {
                "limit": limit,
                "remaining": 0,
                "reset_time": current_time + ttl
            }
        
        # Add current request
        await self.redis_client.zadd(key, {str(current_time): current_time})
        await self.redis_client.expire(key, window_seconds)
        
        return True, {
            "limit": limit,
            "remaining": limit - current_requests - 1,
            "reset_time": current_time + window_seconds
        }
    
    def _check_memory(
        self,
        key: str,
        limit: int,
        window_seconds: int
    ) -> Tuple[bool, Dict[str, int]]:
        """Check rate limit using in-memory storage"""
        current_time = time.time()
        window_start = current_time - window_seconds
        
        # Clean old entries
        request_times = self.memory_storage[key]
        while request_times and request_times[0] < window_start:
            request_times.popleft()
        
        current_requests = len(request_times)
        
        if current_requests >= limit:
            return False, {
                "limit": limit,
                "remaining": 0,
                "reset_time": window_start + window_seconds
            }
        
        # Add current request
        request_times.append(current_time)
        
        return True, {
            "limit": limit,
            "remaining": limit - current_requests,
            "reset_time": window_start + window_seconds
        }

class RateLimitingMiddleware:
    def __init__(self, rate_limiter: RateLimiter):
        self.rate_limiter = rate_limiter
    
    async def __call__(self, request: Request, call_next):
        client_ip = self._get_client_ip(request)
        user_id = getattr(request.state, 'user_id', None)
        
        # Check global limit
        global_allowed, global_info = await self.rate_limiter.is_allowed(
            f"global", self.rate_limiter.global_limit
        )
        
        if not global_allowed:
            raise HTTPException(
                status_code=429,
                detail="Global rate limit exceeded",
                headers={
                    "X-RateLimit-Limit": str(global_info["limit"]),
                    "X-RateLimit-Remaining": str(global_info["remaining"]),
                    "X-RateLimit-Reset": str(int(global_info["reset_time"]))
                }
            )
        
        # Check per-IP limit
        ip_allowed, ip_info = await self.rate_limiter.is_allowed(
            f"ip:{client_ip}", self.rate_limiter.per_ip_limit
        )
        
        if not ip_allowed:
            raise HTTPException(
                status_code=429,
                detail="IP rate limit exceeded",
                headers={
                    "X-RateLimit-Limit": str(ip_info["limit"]),
                    "X-RateLimit-Remaining": str(ip_info["remaining"]),
                    "X-RateLimit-Reset": str(int(ip_info["reset_time"]))
                }
            )
        
        # Check per-user limit (if authenticated)
        if user_id:
            user_allowed, user_info = await self.rate_limiter.is_allowed(
                f"user:{user_id}", self.rate_limiter.per_user_limit
            )
            
            if not user_allowed:
                raise HTTPException(
                    status_code=429,
                    detail="User rate limit exceeded",
                    headers={
                        "X-RateLimit-Limit": str(user_info["limit"]),
                        "X-RateLimit-Remaining": str(user_info["remaining"]),
                        "X-RateLimit-Reset": str(int(user_info["reset_time"]))
                    }
                )
        
        response = await call_next(request)
        
        # Add rate limit headers
        response.headers["X-RateLimit-Limit"] = str(ip_info["limit"])
        response.headers["X-RateLimit-Remaining"] = str(ip_info["remaining"])
        response.headers["X-RateLimit-Reset"] = str(int(ip_info["reset_time"]))
        
        return response
    
    def _get_client_ip(self, request: Request) -> str:
        """Get client IP address"""
        # Check for forwarded headers
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        return request.client.host
EOF
    
    # 認證中間件
    cat > "config/gateway/middleware/authentication.py" << 'EOF'
"""
Authentication Middleware for API Gateway
"""

import jwt
import logging
from fastapi import Request, HTTPException, status
from typing import Optional, Dict, Any
import time

logger = logging.getLogger(__name__)

class AuthenticationMiddleware:
    def __init__(
        self,
        jwt_secret: str,
        jwt_algorithm: str = "HS256",
        jwt_expires_in: str = "24h",
        skip_paths: list = None
    ):
        self.jwt_secret = jwt_secret
        self.jwt_algorithm = jwt_algorithm
        self.jwt_expires_in = jwt_expires_in
        self.skip_paths = skip_paths or ["/health", "/metrics", "/docs", "/api/v1/auth/login", "/api/v1/auth/refresh"]
    
    async def __call__(self, request: Request, call_next):
        # Skip authentication for certain paths
        if request.url.path in self.skip_paths:
            return await call_next(request)
        
        # Extract token from Authorization header
        authorization = request.headers.get("Authorization")
        if not authorization:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization header missing",
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        try:
            scheme, token = authorization.split()
            if scheme.lower() != "bearer":
                raise ValueError("Invalid scheme")
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authorization header format",
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        # Verify and decode token
        try:
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
            )
            
            # Check token expiration
            if payload.get("exp", 0) < time.time():
                raise jwt.ExpiredSignatureError("Token has expired")
            
            # Store user info in request state
            request.state.user_id = payload.get("sub")
            request.state.user_roles = payload.get("roles", [])
            request.state.user_permissions = payload.get("permissions", [])
            request.state.token_payload = payload
            
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired",
                headers={"WWW-Authenticate": "Bearer"}
            )
        except jwt.InvalidTokenError as e:
            logger.warning(f"Invalid token: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        response = await call_next(request)
        return response

class JWTService:
    def __init__(self, jwt_secret: str, jwt_algorithm: str = "HS256", jwt_expires_in: str = "24h"):
        self.jwt_secret = jwt_secret
        self.jwt_algorithm = jwt_algorithm
        self.jwt_expires_in = jwt_expires_in
    
    def create_token(
        self,
        user_id: str,
        user_roles: list = None,
        user_permissions: list = None,
        additional_claims: dict = None
    ) -> str:
        """Create JWT token"""
        now = int(time.time())
        
        payload = {
            "sub": user_id,
            "iat": now,
            "exp": now + self._parse_expires_in(self.jwt_expires_in),
            "roles": user_roles or [],
            "permissions": user_permissions or [],
            **(additional_claims or {})
        }
        
        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)
    
    def verify_token(self, token: str) -> Dict[str, Any]:
        """Verify and decode JWT token"""
        try:
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
            )
            return payload
        except jwt.InvalidTokenError:
            raise ValueError("Invalid token")
    
    def refresh_token(self, token: str) -> str:
        """Refresh JWT token"""
        payload = self.verify_token(token)
        
        # Remove old timestamps
        payload.pop("iat", None)
        payload.pop("exp", None)
        
        # Create new token with same claims
        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)
    
    def _parse_expires_in(self, expires_in: str) -> int:
        """Parse expires in string to seconds"""
        if expires_in.endswith("h"):
            return int(expires_in[:-1]) * 3600
        elif expires_in.endswith("m"):
            return int(expires_in[:-1]) * 60
        elif expires_in.endswith("s"):
            return int(expires_in[:-1])
        else:
            return int(expires_in)
EOF
    
    log_success "中間件配置建立完成"
}

# 建立插件系統
setup_plugin_system() {
    log_info "建立插件系統..."
    
    mkdir -p "config/gateway/plugins"
    
    # 插件配置
    cat > "config/gateway/plugins/plugins.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: GatewayPlugins
metadata:
  name: gateway-plugins
  namespace: machinenativeops
spec:
  plugins:
    - name: "request-transformer"
      enabled: true
      config:
        add:
          headers:
            "X-Gateway-Version": "1.0.0"
            "X-Request-ID": "\${request_id}"
        remove:
          headers: ["X-Internal-Token"]
    
    - name: "response-transformer"
      enabled: true
      config:
        add:
          headers:
            "X-Response-Time": "\${response_time}"
            "X-Cache-Status": "\${cache_status}"
    
    - name: "request-logger"
      enabled: true
      config:
        logHeaders: true
        logBody: false
        maxBodySize: 1024
        excludePaths: ["/health", "/metrics"]
    
    - name: "response-logger"
      enabled: true
      config:
        logHeaders: true
        logBody: false
        maxBodySize: 1024
        excludePaths: ["/health", "/metrics"]
    
    - name: "api-key-auth"
      enabled: false
      config:
        headerName: "X-API-Key"
        queryParam: "api_key"
    
    - name: "oauth2-auth"
      enabled: false
      config:
        provider: "github"
        clientId: "\${OAUTH_CLIENT_ID}"
        clientSecret: "\${OAUTH_CLIENT_SECRET}"
    
    - name: "request-validator"
      enabled: true
      config:
        validateBody: true
        validateHeaders: true
        validateQuery: true
        schemas:
          "/api/v1/users": "user-schema.json"
          "/api/v1/projects": "project-schema.json"
    
    - name: "cache-plugin"
      enabled: true
      config:
        ttl: 300
        maxSize: 1000
        varyHeaders: ["Authorization", "Accept-Language"]
        cacheableStatusCodes: [200, 301, 302]
    
    - name: "compression-plugin"
      enabled: true
      config:
        threshold: 1024
        encodings: ["gzip", "deflate", "br"]
    
    - name: "analytics-plugin"
      enabled: true
      config:
        trackRequests: true
        trackResponse: true
        trackErrors: true
        endpoint: "https://analytics.machinenativeops.com/events"

status:
  phase: configured
  plugins: 10
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 插件基類
    cat > "config/gateway/plugins/base_plugin.py" << 'EOF'
"""
Base Plugin System for API Gateway
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from fastapi import Request, Response
import logging
import time

logger = logging.getLogger(__name__)

class BasePlugin(ABC):
    """Base class for all gateway plugins"""
    
    def __init__(self, name: str, config: Dict[str, Any] = None):
        self.name = name
        self.config = config or {}
        self.enabled = self.config.get("enabled", True)
        self.logger = logging.getLogger(f"plugin.{name}")
    
    @abstractmethod
    async def process_request(self, request: Request) -> Optional[Request]:
        """Process incoming request"""
        pass
    
    @abstractmethod
    async def process_response(self, request: Request, response: Response) -> Optional[Response]:
        """Process outgoing response"""
        pass
    
    async def on_request_start(self, request: Request):
        """Called when request processing starts"""
        pass
    
    async def on_request_end(self, request: Request, response: Response):
        """Called when request processing ends"""
        pass
    
    def is_enabled(self) -> bool:
        """Check if plugin is enabled"""
        return self.enabled

class PluginManager:
    """Manages plugin lifecycle and execution"""
    
    def __init__(self):
        self.plugins: Dict[str, BasePlugin] = {}
        self.request_plugins: list = []
        self.response_plugins: list = []
    
    def register_plugin(self, plugin: BasePlugin):
        """Register a plugin"""
        self.plugins[plugin.name] = plugin
        
        if plugin.is_enabled():
            self.request_plugins.append(plugin)
            self.response_plugins.append(plugin)
    
    def unregister_plugin(self, name: str):
        """Unregister a plugin"""
        if name in self.plugins:
            plugin = self.plugins[name]
            self.request_plugins = [p for p in self.request_plugins if p != plugin]
            self.response_plugins = [p for p in self.response_plugins if p != plugin]
            del self.plugins[name]
    
    async def process_request(self, request: Request) -> Request:
        """Process request through all plugins"""
        for plugin in self.request_plugins:
            if plugin.is_enabled():
                try:
                    await plugin.on_request_start(request)
                    result = await plugin.process_request(request)
                    if result:
                        request = result
                except Exception as e:
                    plugin.logger.error(f"Error processing request: {str(e)}")
        
        return request
    
    async def process_response(self, request: Request, response: Response) -> Response:
        """Process response through all plugins"""
        for plugin in reversed(self.response_plugins):
            if plugin.is_enabled():
                try:
                    result = await plugin.process_response(request, response)
                    if result:
                        response = result
                    await plugin.on_request_end(request, response)
                except Exception as e:
                    plugin.logger.error(f"Error processing response: {str(e)}")
        
        return response

# Global plugin manager instance
plugin_manager = PluginManager()
EOF
    
    # 示例插件實現
    cat > "config/gateway/plugins/request_logger.py" << 'EOF'
"""
Request Logger Plugin
"""

import time
import json
from typing import Optional
from .base_plugin import BasePlugin
from fastapi import Request, Response

class RequestLoggerPlugin(BasePlugin):
    """Plugin to log incoming requests"""
    
    def __init__(self, config: dict = None):
        super().__init__("request-logger", config)
        self.log_headers = self.config.get("logHeaders", True)
        self.log_body = self.config.get("logBody", False)
        self.max_body_size = self.config.get("maxBodySize", 1024)
        self.exclude_paths = set(self.config.get("excludePaths", []))
    
    async def process_request(self, request: Request) -> Optional[Request]:
        """Log request details"""
        if request.url.path in self.exclude_paths:
            return None
        
        log_data = {
            "timestamp": time.time(),
            "method": request.method,
            "url": str(request.url),
            "path": request.url.path,
            "query_params": dict(request.query_params),
            "client_ip": self._get_client_ip(request),
            "user_agent": request.headers.get("user-agent"),
        }
        
        if self.log_headers:
            log_data["headers"] = dict(request.headers)
        
        if self.log_body and request.method in ["POST", "PUT", "PATCH"]:
            try:
                body = await request.body()
                if len(body) <= self.max_body_size:
                    log_data["body"] = body.decode("utf-8")
                else:
                    log_data["body"] = f"<truncated to {self.max_body_size} bytes>"
            except Exception:
                log_data["body"] = "<unable to read body>"
        
        self.logger.info(f"Request: {json.dumps(log_data)}")
        return None
    
    async def process_response(self, request: Request, response: Response) -> Optional[Response]:
        """Log response details"""
        if request.url.path in self.exclude_paths:
            return None
        
        log_data = {
            "timestamp": time.time(),
            "method": request.method,
            "url": str(request.url),
            "status_code": response.status_code,
            "content_length": response.headers.get("content-length"),
        }
        
        self.logger.info(f"Response: {json.dumps(log_data)}")
        return None
    
    def _get_client_ip(self, request: Request) -> str:
        """Get client IP address"""
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        return getattr(request.client, "host", "unknown")
EOF
    
    log_success "插件系統建立完成"
}

# 建立 Docker 部署配置
setup_docker_deployment() {
    log_info "建立 Docker 部署配置..."
    
    mkdir -p "docker/gateway"
    
    # Docker Compose 配置
    cat > "docker/gateway/docker-compose.yml" << EOF
version: '3.8'

services:
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
      - REDIS_URL=redis://redis:6379/0
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/machinenativeops
      - ELASTICSEARCH_URL=http://elasticsearch:9200
    volumes:
      - ./config:/app/config:ro
      - ../../logs:/app/logs
    networks:
      - machinenativeops-net
    restart: unless-stopped
    depends_on:
      - redis
      - postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G

  redis:
    image: redis:7-alpine
    container_name: machinenativeops-redis-gateway
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    networks:
      - machinenativeops-net
    restart: unless-stopped
    command: redis-server /usr/local/etc/redis/redis.conf

  postgres:
    image: postgres:15-alpine
    container_name: machinenativeops-postgres-gateway
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=machinenativeops
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - machinenativeops-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    container_name: machinenativeops-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ../../logs/nginx:/var/log/nginx
    networks:
      - machinenativeops-net
    restart: unless-stopped
    depends_on:
      - api-gateway

volumes:
  redis_data:
  postgres_data:

networks:
  machinenativeops-net:
    external: true
EOF
    
    # Nginx 配置
    cat > "docker/gateway/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream api_gateway {
        least_conn;
        server api-gateway:8000 max_fails=3 fail_timeout=30s;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/s;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    server {
        listen 80;
        server_name api.machinenativeops.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name api.machinenativeops.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        # API routes
        location /api/ {
            limit_req zone=api burst=200 nodelay;
            proxy_pass http://api_gateway;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }

        # Login endpoints with stricter rate limiting
        location /api/v1/auth/login {
            limit_req zone=login burst=10 nodelay;
            proxy_pass http://api_gateway;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            proxy_pass http://api_gateway;
            access_log off;
        }

        # Metrics
        location /metrics {
            proxy_pass http://api_gateway;
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            allow 192.168.0.0/16;
            deny all;
        }
    }
}
EOF
    
    # Redis 配置
    cat > "docker/gateway/redis.conf" << 'EOF'
bind 0.0.0.0
port 6379
timeout 0
keepalive 300
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
EOF
    
    log_success "Docker 部署配置建立完成"
}

# 驗證 API Gateway
verify_api_gateway() {
    log_info "驗證 API Gateway 系統..."
    
    local verification_errors=0
    
    # 檢查配置文件
    local required_files=(
        "config/gateway/gateway-config.yaml"
        "config/gateway/routes/routes.yaml"
        "config/gateway/plugins/plugins.yaml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Gateway 配置文件存在：$(basename "$file")"
        else
            log_error "Gateway 配置文件不存在：$file"
            ((verification_errors++))
        fi
    done
    
    # 檢查中間件
    local middleware_files=(
        "config/gateway/middleware/cors.py"
        "config/gateway/middleware/rate_limiting.py"
        "config/gateway/middleware/authentication.py"
    )
    
    for file in "${middleware_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "中間件文件存在：$(basename "$file")"
        else
            log_error "中間件文件不存在：$file"
            ((verification_errors++))
        fi
    done
    
    # 檢查插件系統
    if [[ -f "config/gateway/plugins/base_plugin.py" ]] && [[ -f "config/gateway/plugins/request_logger.py" ]]; then
        log_success "插件系統文件存在"
    else
        log_error "插件系統文件不完整"
        ((verification_errors++))
    fi
    
    # 檢查 Docker 配置
    if [[ -f "docker/gateway/docker-compose.yml" ]] && [[ -f "docker/gateway/nginx.conf" ]]; then
        log_success "Docker 部署配置存在"
    else
        log_error "Docker 部署配置不完整"
        ((verification_errors++))
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "API Gateway 系統驗證通過"
        return 0
    else
        log_error "API Gateway 系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始 API Gateway 初始化..."
    
    # 初始化階段
    local total_steps=6
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; setup_api_gateway_core
    ((current_step++)); progress_bar $current_step $total_steps; setup_routing_configuration
    ((current_step++)); progress_bar $current_step $total_steps; setup_middleware_configuration
    ((current_step++)); progress_bar $current_step $total_steps; setup_plugin_system
    ((current_step++)); progress_bar $current_step $total_steps; setup_docker_deployment
    ((current_step++)); progress_bar $current_step $total_steps; verify_api_gateway
    
    echo; log_success "API Gateway 初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - Gateway 配置：config/gateway/"
    echo "  - 路由定義：config/gateway/routes/"
    echo "  - 中間件：config/gateway/middleware/"
    echo "  - 插件系統：config/gateway/plugins/"
    echo "  - Docker 部署：docker/gateway/"
    echo
    log_info "API Gateway 狀態：已初始化並驗證"
}

# 執行主函數
main "$@"