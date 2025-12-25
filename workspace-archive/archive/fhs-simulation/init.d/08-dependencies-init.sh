#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Dependencies System Initialization
# =============================================================================
# 依賴項檢查與安裝腳本
# 職責：檢查系統依賴、安裝運行時環境、驗證版本兼容性
# 依賴：07-config-init.sh
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
    log_info "載入依賴系統配置..."
    
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    log_success "依賴系統配置載入完成"
}

# 檢查系統依賴
check_system_dependencies() {
    log_info "檢查系統級依賴..."
    
    local system_deps=("curl" "wget" "git" "docker" "docker-compose" "node" "npm" "python3" "pip" "java")
    local missing_deps=()
    local version_info=()
    
    for dep in "${system_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            local version=$("$dep" --version 2>/dev/null | head -n1 || echo "unknown")
            version_info+=("$dep: $version")
            log_success "✓ $dep - $version"
        else
            missing_deps+=("$dep")
            log_error "✗ $dep - 未安裝"
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "缺少系統依賴：${missing_deps[*]}"
        log_info "正在嘗試自動安裝..."
        
        # 根據系統類型安裝依賴
        if command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y curl wget git docker.io docker-compose nodejs npm python3 python3-pip default-jre
        elif command -v yum &> /dev/null; then
            yum install -y curl wget git docker docker-compose nodejs npm python3 python3-pip java-1.8.0-openjdk
        elif command -v brew &> /dev/null; then
            brew install curl wget git docker docker-compose node npm python3 java
        else
            log_error "無法自動安裝依賴，請手動安裝：${missing_deps[*]}"
            return 1
        fi
        
        log_success "系統依賴安裝完成"
    fi
    
    # 建立依賴報告
    mkdir -p "reports"
    {
        echo "# System Dependencies Report"
        echo "Generated: $(date)"
        echo ""
        echo "## Installed Dependencies"
        for info in "${version_info[@]}"; do
            echo "- $info"
        done
        
        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            echo ""
            echo "## Missing Dependencies"
            for dep in "${missing_deps[@]}"; do
                echo "- $dep"
            done
        fi
    } > "reports/system-dependencies.md"
    
    log_success "系統依賴檢查完成"
}

# 安裝 Python 依賴
install_python_dependencies() {
    log_info "安裝 Python 依賴..."
    
    # 檢查 Python 版本
    local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    local required_version="3.9"
    
    if ! python3 -c "import sys; exit(0 if sys.version_info >= tuple(map(int, '$required_version'.split('.'))) else 1)" 2>/dev/null; then
        log_error "需要 Python $required_version 或更高版本，當前版本：$python_version"
        return 1
    fi
    
    log_success "Python 版本檢查通過：$python_version"
    
    # 建立虛擬環境
    if [[ ! -d "venv" ]]; then
        log_info "建立 Python 虛擬環境..."
        python3 -m venv venv
    fi
    
    # 啟動虛擬環境並安裝依賴
    source venv/bin/activate
    
    # 更新 pip
    pip install --upgrade pip setuptools wheel
    
    # 安裝核心依賴
    local python_deps=(
        "fastapi>=0.95.0"
        "uvicorn[standard]>=0.20.0"
        "pydantic>=1.10.0"
        "sqlalchemy>=2.0.0"
        "alembic>=1.10.0"
        "psycopg2-binary>=2.9.0"
        "redis>=4.5.0"
        "celery>=5.2.0"
        "pyjwt>=2.8.0"
        "bcrypt>=4.0.0"
        "python-multipart>=0.0.6"
        "python-jose[cryptography]>=3.3.0"
        "passlib[bcrypt]>=1.7.4"
        "aiofiles>=23.1.0"
        "httpx>=0.24.0"
        "prometheus-client>=0.16.0"
        "structlog>=23.1.0"
        "click>=8.1.0"
        "rich>=13.3.0"
        "pyyaml>=6.0"
        "jinja2>=3.1.0"
        "python-dotenv>=1.0.0"
        "cryptography>=40.0.0"
        "clickhouse-driver>=0.2.6"
        "elasticsearch>=8.6.0"
        "kafka-python>=2.0.2"
        "pytest>=7.2.0"
        "pytest-asyncio>=0.21.0"
        "pytest-cov>=4.0.0"
        "black>=23.3.0"
        "flake8>=6.0.0"
        "mypy>=1.2.0"
        "pre-commit>=3.2.0"
    )
    
    for dep in "${python_deps[@]}"; do
        log_info "安裝 $dep..."
        pip install "$dep"
    done
    
    # 建立 requirements.txt
    pip freeze > requirements.txt
    
    log_success "Python 依賴安裝完成"
}

# 安裝 Node.js 依賴
install_nodejs_dependencies() {
    log_info "安裝 Node.js 依賴..."
    
    # 檢查 Node.js 版本
    local node_version=$(node --version 2>/dev/null | sed 's/v//')
    local required_version="16.0.0"
    
    if ! node -e "process.exit(require('semver').gte('$node_version', '$required_version') ? 0 : 1)" 2>/dev/null; then
        log_error "需要 Node.js $required_version 或更高版本，當前版本：$node_version"
        return 1
    fi
    
    log_success "Node.js 版本檢查通過：$node_version"
    
    # 檢查 npm 版本
    local npm_version=$(npm --version 2>/dev/null)
    log_success "npm 版本：$npm_version"
    
    # 安裝全域依賴
    local global_npm_deps=(
        "@typescript-eslint/cli"
        "@typescript-eslint/parser"
        "typescript"
        "ts-node"
        "nodemon"
        "pm2"
        "concurrently"
        "electron-builder"
        "react-native-cli"
        "expo-cli"
        "@vue/cli"
        "next"
        "vite"
        "eslint"
        "prettier"
        "husky"
        "lint-staged"
    )
    
    for dep in "${global_npm_deps[@]}"; do
        log_info "安裝全域依賴 $dep..."
        npm install -g "$dep"
    done
    
    # 為各平台安裝依賴
    if [[ -d "src/web" ]]; then
        log_info "安裝 Web 平台依賴..."
        cd src/web
        npm install
        cd - > /dev/null
    fi
    
    if [[ -d "src/mobile" ]]; then
        log_info "安裝 Mobile 平台依賴..."
        cd src/mobile
        npm install
        cd - > /dev/null
    fi
    
    if [[ -d "src/desktop" ]]; then
        log_info "安裝 Desktop 平台依賴..."
        cd src/desktop
        npm install
        cd - > /dev/null
    fi
    
    log_success "Node.js 依賴安裝完成"
}

# 安裝 Docker 依賴
install_docker_dependencies() {
    log_info "設定 Docker 依賴..."
    
    # 檢查 Docker 狀態
    if ! docker info &> /dev/null; then
        log_error "Docker 服務未運行，請啟動 Docker"
        return 1
    fi
    
    local docker_version=$(docker --version)
    local compose_version=$(docker-compose --version)
    
    log_success "Docker 版本：$docker_version"
    log_success "Docker Compose 版本：$compose_version"
    
    # 拉取必要的 Docker 映像
    local docker_images=(
        "postgres:15-alpine"
        "redis:7-alpine"
        "nginx:alpine"
        "prom/prometheus:latest"
        "grafana/grafana:latest"
        "elasticsearch:8.6.0"
        "kibana:8.6.0"
        "rabbitmq:3-management-alpine"
        "pgbouncer/pgbouncer:latest"
    )
    
    for image in "${docker_images[@]}"; do
        log_info "拉取 Docker 映像：$image"
        docker pull "$image"
    done
    
    # 建立 Docker 網路
    if ! docker network ls | grep -q "machinenativeops-net"; then
        docker network create machinenativeops-net
        log_success "建立 Docker 網路：machinenativeops-net"
    fi
    
    log_success "Docker 依賴設定完成"
}

# 安裝開發工具
install_development_tools() {
    log_info "安裝開發工具..."
    
    # 建立 .vscode 目錄和配置
    mkdir -p ".vscode"
    
    cat > ".vscode/settings.json" << 'EOF'
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "python.formatting.blackArgs": ["--line-length", "88"],
    "typescript.preferences.importModuleSpecifier": "relative",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.exclude": {
        "**/__pycache__": true,
        "**/node_modules": true,
        "**/dist": true,
        "**/build": true,
        "**/.git": true,
        "**/.DS_Store": true
    }
}
EOF
    
    cat > ".vscode/extensions.json" << 'EOF'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.black-formatter",
        "ms-python.flake8",
        "ms-python.mypy-type-checker",
        "bradlc.vscode-tailwindcss",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-typescript-next",
        "ms-vscode.vscode-json",
        "redhat.vscode-yaml",
        "ms-vscode-remote.remote-containers",
        "ms-azuretools.vscode-docker"
    ]
}
EOF
    
    # 建立 pre-commit 配置
    cat > ".pre-commit-config.yaml" << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: debug-statements

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        args: [--max-line-length=88, --extend-ignore=E203]

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: [--profile=black]

  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.0.0-alpha.4
    hooks:
      - id: prettier
        types_or: [javascript, jsx, ts, tsx, json, yaml, markdown]

  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.36.0
    hooks:
      - id: eslint
        files: \.(js|ts|tsx)$
        types: [file]
EOF
    
    # 安裝 pre-commit hooks
    if command -v pre-commit &> /dev/null; then
        pre-commit install
        log_success "Pre-commit hooks 安裝完成"
    fi
    
    log_success "開發工具安裝完成"
}

# 驗證依賴安裝
verify_dependencies() {
    log_info "驗證依賴安裝..."
    
    local verification_errors=0
    
    # 驗證 Python 環境
    if [[ -d "venv" ]] && [[ -f "requirements.txt" ]]; then
        if source venv/bin/activate && python -c "import fastapi, uvicorn, sqlalchemy" 2>/dev/null; then
            log_success "Python 環境驗證通過"
        else
            log_error "Python 環境驗證失敗"
            ((verification_errors++))
        fi
    else
        log_error "Python 虛擬環境不存在"
        ((verification_errors++))
    fi
    
    # 驗證 Node.js 環境
    if [[ -f "src/web/package.json" ]] && [[ -d "src/web/node_modules" ]]; then
        log_success "Web 平台 Node.js 環境驗證通過"
    else
        log_error "Web 平台 Node.js 環境驗證失敗"
        ((verification_errors++))
    fi
    
    # 驗證 Docker 環境
    if docker network ls | grep -q "machinenativeops-net"; then
        log_success "Docker 環境驗證通過"
    else
        log_error "Docker 環境驗證失敗"
        ((verification_errors++))
    fi
    
    # 驗證開發工具
    if [[ -f ".vscode/settings.json" ]] && [[ -f ".pre-commit-config.yaml" ]]; then
        log_success "開發工具驗證通過"
    else
        log_error "開發工具驗證失敗"
        ((verification_errors++))
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "依賴系統驗證通過"
        return 0
    else
        log_error "依賴系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 建立依賴更新腳本
create_dependency_update_scripts() {
    log_info "建立依賴更新腳本..."
    
    mkdir -p "scripts/dependencies"
    
    # Python 依賴更新腳本
    cat > "scripts/dependencies/update-python-deps.sh" << 'EOF'
#!/bin/bash

echo "Updating Python dependencies..."

source venv/bin/activate

# Update pip
pip install --upgrade pip setuptools wheel

# Update all packages
pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U

# Generate new requirements.txt
pip freeze > requirements.txt

echo "Python dependencies updated successfully!"
EOF
    
    # Node.js 依賴更新腳本
    cat > "scripts/dependencies/update-nodejs-deps.sh" << 'EOF'
#!/bin/bash

echo "Updating Node.js dependencies..."

# Update global packages
npm update -g

# Update platform dependencies
for platform in web mobile desktop; do
    if [[ -d "src/$platform" ]]; then
        echo "Updating $platform platform dependencies..."
        cd "src/$platform"
        npm update
        npm audit fix
        cd - > /dev/null
    fi
done

echo "Node.js dependencies updated successfully!"
EOF
    
    # Docker 映像更新腳本
    cat > "scripts/dependencies/update-docker-images.sh" << 'EOF'
#!/bin/bash

echo "Updating Docker images..."

images=(
    "postgres:15-alpine"
    "redis:7-alpine"
    "nginx:alpine"
    "prom/prometheus:latest"
    "grafana/grafana:latest"
    "elasticsearch:8.6.0"
    "kibana:8.6.0"
    "rabbitmq:3-management-alpine"
    "pgbouncer/pgbouncer:latest"
)

for image in "${images[@]}"; do
    echo "Pulling latest version of $image..."
    docker pull "$image"
done

echo "Docker images updated successfully!"
EOF
    
    # 綜合更新腳本
    cat > "scripts/dependencies/update-all.sh" << 'EOF'
#!/bin/bash

echo "Updating all dependencies..."

# Update Python dependencies
./scripts/dependencies/update-python-deps.sh

# Update Node.js dependencies
./scripts/dependencies/update-nodejs-deps.sh

# Update Docker images
./scripts/dependencies/update-docker-images.sh

echo "All dependencies updated successfully!"
EOF
    
    chmod +x scripts/dependencies/*.sh
    
    log_success "依賴更新腳本建立完成"
}

# 主函數
main() {
    log_info "開始依賴系統初始化..."
    
    # 初始化階段
    local total_steps=8
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; check_system_dependencies
    ((current_step++)); progress_bar $current_step $total_steps; install_python_dependencies
    ((current_step++)); progress_bar $current_step $total_steps; install_nodejs_dependencies
    ((current_step++)); progress_bar $current_step $total_steps; install_docker_dependencies
    ((current_step++)); progress_bar $current_step $total_steps; install_development_tools
    ((current_step++)); progress_bar $current_step $total_steps; verify_dependencies
    ((current_step++)); progress_bar $current_step $total_steps; create_dependency_update_scripts
    
    echo; log_success "依賴系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - Python 虛擬環境：venv/"
    echo "  - Python 依賴：requirements.txt"
    echo "  - Node.js 依賴：各平台 package.json"
    echo "  - 開發工具配置：.vscode/"
    echo "  - 依賴更新腳本：scripts/dependencies/"
    echo "  - 系統依賴報告：reports/system-dependencies.md"
    echo
    log_info "依賴系統狀態：已初始化並驗證"
}

# 執行主函數
main "$@"