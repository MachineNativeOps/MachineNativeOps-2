#!/bin/bash
# MachineNativeOps FHS 目錄結構初始化腳本

set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "開始 MachineNativeOps FHS 目錄結構初始化..."

# 創建 FHS 標準目錄
fhs_dirs=("bin" "sbin" "etc" "lib" "var" "usr" "home" "tmp" "opt" "srv" "init.d")

for dir in "${fhs_dirs[@]}"; do
    if [[ ! -d "/$dir" ]]; then
        mkdir -p "/$dir"
        log "創建目錄: /$dir"
        chmod 0755 "/$dir"
    fi
done

log "✅ MachineNativeOps FHS 目錄結構初始化完成"
