"""
MachineNativeOps Security Framework
安全框架 - 認證、授權、加密
"""

import secrets
import hashlib
from typing import Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
import logging

logger = logging.getLogger(__name__)

class Permission(Enum):
    """權限枚舉"""
    READ = "read"
    WRITE = "write"
    DELETE = "delete"
    EXECUTE = "execute"
    ADMIN = "admin"

@dataclass
class User:
    """用戶定義"""
    id: str
    username: str
    email: str
    created_at: datetime
    is_active: bool = True
    password_hash: str = ""

class SecurityManager:
    """安全管理器主類"""
    
    def __init__(self):
        self.users: Dict[str, User] = {}
        self.is_initialized = False
        self.security_events: list = []
    
    @staticmethod
    def _hash_password(password: str) -> str:
        """使用 PBKDF2 對密碼進行哈希處理"""
        salt = secrets.token_bytes(32)
        pwdhash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 100000)
        return salt.hex() + ':' + pwdhash.hex()
    
    @staticmethod
    def _verify_password(stored_password: str, provided_password: str) -> bool:
        """驗證密碼"""
        try:
            salt_hex, pwdhash_hex = stored_password.split(':')
            salt = bytes.fromhex(salt_hex)
            stored_hash = bytes.fromhex(pwdhash_hex)
            pwdhash = hashlib.pbkdf2_hmac('sha256', provided_password.encode('utf-8'), salt, 100000)
            return pwdhash == stored_hash
        except (ValueError, AttributeError):
            return False
    
    async def initialize(self):
        """初始化安全管理器"""
        if self.is_initialized:
            return
        
        logger.info("🔒 初始化安全管理器")
        
        # 創建默認管理員用戶
        await self._create_default_admin()
        
        self.is_initialized = True
        logger.info("✅ 安全管理器初始化完成")
    
    async def authenticate_user(self, username: str, password: str) -> Optional[str]:
        """認證用戶"""
        user = None
        for u in self.users.values():
            if u.username == username and u.is_active:
                user = u
                break
        
        if not user:
            logger.warning(f"⚠️ 用戶不存在: {username}")
            return None
        
        # 使用密碼哈希驗證
        if user.password_hash and self._verify_password(user.password_hash, password):
            token = f"token_{secrets.token_hex(16)}"
            await self._log_security_event("user_authenticated", {
                "username": username,
                "token": token[:10]
            })
            return token
        
        logger.warning(f"⚠️ 密碼驗證失敗: {username}")
        return None
    
    async def _create_default_admin(self):
        """創建默認管理員"""
        if not self.users:
            # 生成安全的默認密碼（實際部署時應從環境變量或配置文件讀取）
            default_password = secrets.token_urlsafe(16)
            admin_user = User(
                id="admin_001",
                username="admin",
                email="admin@mynativeops.ai",
                created_at=datetime.now(),
                password_hash=self._hash_password(default_password)
            )
            self.users[admin_user.id] = admin_user
            logger.info("👑 創建默認管理員用戶")
            logger.warning(f"⚠️ 默認管理員密碼已生成，請妥善保管並立即修改: {default_password}")
    
    async def _log_security_event(self, event_type: str, details: Dict[str, Any]):
        """記錄安全事件"""
        event = {
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "details": details
        }
        
        self.security_events.append(event)
        logger.info(f"🛡️ 安全事件: {event_type}")

# 全局安全管理器實例
security_manager = SecurityManager()