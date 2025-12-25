#!/bin/bash

# =============================================================================
# MachineNativeOps Root Architecture - Multi-Platform System Initialization
# =============================================================================
# 多端架構初始化腳本
# 職責：建立 Web/Mobile/Desktop/API 統一架構、跨平台共用核心
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
    log_info "載入多端架構配置..."
    
    if [[ ! -f ".root.config.yaml" ]]; then
        log_error "根配置文件不存在：.root.config.yaml"
        exit 1
    fi
    
    log_success "多端架構配置載入完成"
}

# 建立共用核心架構
setup_shared_core_architecture() {
    log_info "建立共用核心架構..."
    
    mkdir -p "src/shared/{core,api,utils,types,hooks,components}"
    
    # 共用核心配置
    cat > "src/shared/core/shared-core.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: SharedCoreArchitecture
metadata:
  name: shared-core
  namespace: machinenativeops
spec:
  architecture: "single-core-multi-shell"
  coreComponents:
    - name: authentication
      description: "Unified authentication system"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop", "api"]
    - name: authorization
      description: "Role-based access control"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop", "api"]
    - name: data_models
      description: "Shared data models and validation"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop", "api"]
    - name: api_client
      description: "Unified API client"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop"]
    - name: state_management
      description: "Cross-platform state management"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop"]
    - name: error_handling
      description: "Unified error handling"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop", "api"]
    - name: logging
      description: "Structured logging system"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop", "api"]
    - name: caching
      description: "Multi-level caching system"
      version: "1.0.0"
      platforms: ["web", "mobile", "desktop", "api"]
  
  sharedTypes:
    - User
    - Organization
    - Project
    - File
    - Notification
    - ApiResponse
    - Error
  
  sharedUtils:
    - validation
    - formatting
    - encryption
    - date_time
    - file_operations
    - network_utils

status:
  phase: designed
  coreComponents: 8
  sharedTypes: 7
  sharedUtils: 6
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # 建立共用型別定義
    cat > "src/shared/types/index.ts" << 'EOF'
// Shared Type Definitions for Multi-Platform Architecture

export interface User {
  id: string;
  username: string;
  email: string;
  firstName?: string;
  lastName?: string;
  avatarUrl?: string;
  status: 'active' | 'inactive' | 'suspended';
  roles: Role[];
  preferences: UserPreferences;
  createdAt: string;
  updatedAt: string;
  lastLogin?: string;
}

export interface Role {
  id: string;
  name: string;
  description?: string;
  permissions: Permission[];
}

export interface Permission {
  id: string;
  resource: string;
  action: string;
  conditions?: Record<string, any>;
}

export interface Organization {
  id: string;
  name: string;
  slug: string;
  description?: string;
  logoUrl?: string;
  status: 'active' | 'inactive';
  createdAt: string;
  updatedAt: string;
  members: OrganizationMember[];
}

export interface OrganizationMember {
  id: string;
  userId: string;
  organizationId: string;
  role: string;
  joinedAt: string;
  invitedBy?: string;
  user?: User;
}

export interface Project {
  id: string;
  name: string;
  slug: string;
  description?: string;
  organizationId?: string;
  ownerId: string;
  status: 'active' | 'archived' | 'deleted';
  visibility: 'public' | 'private';
  createdAt: string;
  updatedAt: string;
  members: ProjectMember[];
}

export interface ProjectMember {
  id: string;
  projectId: string;
  userId: string;
  role: string;
  joinedAt: string;
  invitedBy?: string;
  user?: User;
}

export interface File {
  id: string;
  name: string;
  originalName: string;
  path: string;
  size: number;
  mimeType: string;
  hash: string;
  uploadedBy: string;
  projectId?: string;
  platformType?: 'web' | 'mobile' | 'desktop';
  metadata: Record<string, any>;
  createdAt: string;
}

export interface Notification {
  id: string;
  userId: string;
  type: string;
  title: string;
  message: string;
  data?: Record<string, any>;
  readAt?: string;
  createdAt: string;
  expiresAt?: string;
  platformTargets: PlatformType[];
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: ApiError;
  meta?: {
    pagination?: PaginationMeta;
    timestamp: string;
    requestId: string;
  };
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, any>;
  stack?: string;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface UserPreferences {
  theme: 'light' | 'dark' | 'auto';
  language: string;
  timezone: string;
  notifications: NotificationPreferences;
  platform?: PlatformSpecificPreferences;
}

export interface NotificationPreferences {
  email: boolean;
  push: boolean;
  inApp: boolean;
  types: Record<string, boolean>;
}

export interface PlatformSpecificPreferences {
  web?: WebPreferences;
  mobile?: MobilePreferences;
  desktop?: DesktopPreferences;
}

export interface WebPreferences {
  sidebarCollapsed: boolean;
  defaultDashboard: string;
}

export interface MobilePreferences {
  biometricEnabled: boolean;
  autoSync: boolean;
  offlineMode: boolean;
}

export interface DesktopPreferences {
  autoStart: boolean;
  minimizeToTray: boolean;
  notificationsEnabled: boolean;
}

export type PlatformType = 'web' | 'mobile' | 'desktop' | 'api';

export interface PlatformInstance {
  id: string;
  platformType: PlatformType;
  version: string;
  buildNumber: string;
  deviceInfo: Record<string, any>;
  lastActive: string;
  createdAt: string;
  status: 'active' | 'inactive';
}

export interface CrossPlatformSession {
  id: string;
  userId: string;
  sessionToken: string;
  createdAt: string;
  expiresAt: string;
  lastActivity: string;
  platformInstances: PlatformInstance[];
  metadata: Record<string, any>;
}

// Authentication types
export interface LoginCredentials {
  email: string;
  password: string;
  rememberMe?: boolean;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
  tokenType: string;
}

export interface AuthUser {
  user: User;
  tokens: AuthTokens;
}

// Search and filtering
export interface SearchParams {
  query?: string;
  filters?: Record<string, any>;
  sort?: string;
  order?: 'asc' | 'desc';
  page?: number;
  limit?: number;
}

export interface SearchResult<T = any> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  facets?: Record<string, any>;
}

// Webhook types
export interface Webhook {
  id: string;
  name: string;
  url: string;
  events: string[];
  secret?: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface WebhookEvent {
  id: string;
  webhookId: string;
  event: string;
  data: Record<string, any>;
  attempts: number;
  status: 'pending' | 'delivered' | 'failed';
  createdAt: string;
  deliveredAt?: string;
}
EOF
    
    log_success "共用核心架構建立完成"
}

# 建立 Web 平台
setup_web_platform() {
    log_info "建立 Web 平台..."
    
    mkdir -p "src/web/{components,pages,hooks,utils,services,styles}"
    
    # Web 平台配置
    cat > "src/web/platform-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: WebPlatform
metadata:
  name: web-platform
  namespace: machinenativeops
spec:
  framework: "react"
  version: "18.2.0"
  bundler: "vite"
  styling: "tailwindcss"
  
  features:
    responsive: true
    pwa: true
    ssr: false
    i18n: true
    
  pages:
    - name: dashboard
      path: "/dashboard"
      component: "Dashboard"
      protected: true
    - name: projects
      path: "/projects"
      component: "Projects"
      protected: true
    - name: settings
      path: "/settings"
      component: "Settings"
      protected: true
    - name: auth
      path: "/auth"
      component: "Auth"
      protected: false
  
  sharedComponents:
    - Layout
    - Navigation
    - Header
    - Sidebar
    - Footer
    - Loading
    - ErrorBoundary
    - Modal
    - Button
    - Input
    - Card
  
  hooks:
    - useAuth
    - useApi
    - useLocalStorage
    - useWebSocket
    - useDebounce
    - useInfiniteScroll
  
  services:
    - AuthService
    - ApiService
    - StorageService
    - NotificationService
    - ThemeService

status:
  phase: configured
  pages: 4
  sharedComponents: 11
  hooks: 6
  services: 5
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # Web 應用程式入口
    cat > "src/web/App.tsx" << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './contexts/ThemeContext';
import { AuthProvider } from './contexts/AuthContext';
import { NotificationProvider } from './contexts/NotificationContext';
import { ErrorBoundary } from './components/ErrorBoundary';
import { Layout } from './components/Layout';
import { ProtectedRoute } from './components/ProtectedRoute';

// Pages
import { Dashboard } from './pages/Dashboard';
import { Projects } from './pages/Projects';
import { Settings } from './pages/Settings';
import { Auth } from './pages/Auth';

// Shared components
import { Loading } from './components/Loading';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 3,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

export const App: React.FC = () => {
  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <AuthProvider>
            <NotificationProvider>
              <Router>
                <Routes>
                  <Route path="/auth/*" element={<Auth />} />
                  <Route
                    path="/*"
                    element={
                      <ProtectedRoute>
                        <Layout>
                          <Routes>
                            <Route path="/" element={<Dashboard />} />
                            <Route path="/dashboard" element={<Dashboard />} />
                            <Route path="/projects" element={<Projects />} />
                            <Route path="/settings" element={<Settings />} />
                          </Routes>
                        </Layout>
                      </ProtectedRoute>
                    }
                  />
                </Routes>
              </Router>
            </NotificationProvider>
          </AuthProvider>
        </ThemeProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  );
};

export default App;
EOF
    
    # Web 封裝配置
    cat > "src/web/package.json" << 'EOF'
{
  "name": "@machinenativeops/web",
  "version": "1.0.0",
  "description": "MachineNativeOps Web Application",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "@tanstack/react-query": "^4.24.0",
    "axios": "^1.3.0",
    "zustand": "^4.3.0",
    "clsx": "^1.2.0",
    "tailwindcss": "^3.2.0",
    "@headlessui/react": "^1.7.0",
    "@heroicons/react": "^2.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "@types/react-dom": "^18.0.0",
    "@vitejs/plugin-react": "^3.1.0",
    "typescript": "^4.9.0",
    "vite": "^4.1.0",
    "vitest": "^0.28.0",
    "@vitest/ui": "^0.28.0",
    "eslint": "^8.35.0",
    "@typescript-eslint/eslint-plugin": "^5.54.0",
    "@typescript-eslint/parser": "^5.54.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.3.4",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF
    
    log_success "Web 平台建立完成"
}

# 建立 Mobile 平台
setup_mobile_platform() {
    log_info "建立 Mobile 平台..."
    
    mkdir -p "src/mobile/{components,screens,hooks,utils,services,navigation}"
    
    # Mobile 平台配置
    cat > "src/mobile/platform-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: MobilePlatform
metadata:
  name: mobile-platform
  namespace: machinenativeops
spec:
  framework: "react-native"
  version: "0.72.0"
  
  platforms:
    - ios
    - android
  
  features:
    offline: true
    biometric: true
    push: true
    backgroundSync: true
    deepLinking: true
    
  screens:
    - name: splash
      component: "SplashScreen"
      protected: false
    - name: auth
      component: "AuthScreen"
      protected: false
    - name: dashboard
      component: "DashboardScreen"
      protected: true
    - name: projects
      component: "ProjectsScreen"
      protected: true
    - name: settings
      component: "SettingsScreen"
      protected: true
  
  sharedComponents:
    - Button
    - Input
    - Card
    - Loading
    - ErrorBoundary
    - Modal
    - SafeAreaWrapper
    - KeyboardAwareView
  
  hooks:
    - useAuth
    - useApi
    - useOffline
    - useBiometric
    - usePushNotifications
    - useCamera
  
  services:
    - AuthService
    - ApiService
    - StorageService
    - BiometricService
    - PushNotificationService
    - OfflineService

status:
  phase: configured
  screens: 5
  sharedComponents: 9
  hooks: 6
  services: 6
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # Mobile 應用程式入口
    cat > "src/mobile/App.tsx" << 'EOF'
import React, { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { NavigationContainer } from '@react-navigation/native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './contexts/ThemeContext';
import { AuthProvider } from './contexts/AuthContext';
import { NotificationProvider } from './contexts/NotificationContext';
import { OfflineProvider } from './contexts/OfflineContext';
import { BiometricProvider } from './contexts/BiometricContext';
import { ErrorBoundary } from './components/ErrorBoundary';
import { AppNavigator } from './navigation/AppNavigator';
import { Loading } from './components/Loading';
import { useAuthStore } from './stores/authStore';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 3,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

export const App: React.FC = () => {
  const { initialize } = useAuthStore();

  useEffect(() => {
    initialize();
  }, [initialize]);

  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <AuthProvider>
            <NotificationProvider>
              <OfflineProvider>
                <BiometricProvider>
                  <NavigationContainer>
                    <StatusBar style="auto" />
                    <AppNavigator />
                    <Loading />
                  </NavigationContainer>
                </BiometricProvider>
              </OfflineProvider>
            </NotificationProvider>
          </AuthProvider>
        </ThemeProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  );
};

export default App;
EOF
    
    # Mobile 封裝配置
    cat > "src/mobile/package.json" << 'EOF'
{
  "name": "@machinenativeops/mobile",
  "version": "1.0.0",
  "description": "MachineNativeOps Mobile Application",
  "main": "index.js",
  "scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "start": "react-native start",
    "test": "jest",
    "lint": "eslint . --ext .js,.jsx,.ts,.tsx",
    "build:android": "cd android && ./gradlew assembleRelease",
    "build:ios": "xcodebuild -workspace ios/MachineNativeOps.xcworkspace -scheme MachineNativeOps -configuration Release archive"
  },
  "dependencies": {
    "react": "18.2.0",
    "react-native": "0.72.0",
    "@react-navigation/native": "^6.1.0",
    "@react-navigation/stack": "^6.3.0",
    "@react-navigation/bottom-tabs": "^6.5.0",
    "@tanstack/react-query": "^4.24.0",
    "axios": "^1.3.0",
    "zustand": "^4.3.0",
    "react-native-mmkv": "^2.8.0",
    "react-native-keychain": "^8.1.0",
    "react-native-biometrics": "^3.0.0",
    "@react-native-async-storage/async-storage": "^1.17.0",
    "react-native-push-notification": "^8.1.0",
    "react-native-permissions": "^3.6.0",
    "react-native-device-info": "^10.7.0",
    "react-native-fast-image": "^8.6.0",
    "react-native-gesture-handler": "^2.9.0",
    "react-native-reanimated": "^3.0.0",
    "react-native-safe-area-context": "^4.5.0"
  },
  "devDependencies": {
    "@babel/core": "^7.20.0",
    "@babel/preset-env": "^7.20.0",
    "@babel/runtime": "^7.20.0",
    "@react-native/metro-config": "^0.72.0",
    "@types/react": "^18.0.0",
    "@types/react-native": "^0.71.0",
    "metro-react-native-babel-preset": "0.76.0",
    "typescript": "^4.9.0",
    "eslint": "^8.35.0",
    "@typescript-eslint/eslint-plugin": "^5.54.0",
    "@typescript-eslint/parser": "^5.54.0",
    "jest": "^29.4.0",
    "@testing-library/react-native": "^11.5.0"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF
    
    log_success "Mobile 平台建立完成"
}

# 建立 Desktop 平台
setup_desktop_platform() {
    log_info "建立 Desktop 平台..."
    
    mkdir -p "src/desktop/{components,windows,hooks,utils,services,ipc}"
    
    # Desktop 平台配置
    cat > "src/desktop/platform-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: DesktopPlatform
metadata:
  name: desktop-platform
  namespace: machinenativeops
spec:
  framework: "electron"
  version: "23.0.0"
  
  platforms:
    - windows
    - macos
    - linux
  
  features:
    autoUpdate: true
    tray: true
    notifications: true
    fileSystem: true
    globalShortcuts: true
    
  windows:
    - name: main
      component: "MainWindow"
      width: 1200
      height: 800
      resizable: true
      frame: true
    - name: settings
      component: "SettingsWindow"
      width: 600
      height: 400
      resizable: false
      frame: true
      modal: true
  
  sharedComponents:
    - TitleBar
    - MenuBar
    - TrayIcon
    - Notification
    - FileDialog
    - ShortcutHandler
  
  ipcChannels:
    - "app:quit"
    - "app:minimize"
    - "app:toggle-devtools"
    - "file:open"
    - "file:save"
    - "settings:get"
    - "settings:set"
  
  services:
    - AppService
    - FileService
    - SettingsService
    - UpdateService
    - NotificationService
    - ShortcutService

status:
  phase: configured
  windows: 2
  sharedComponents: 6
  ipcChannels: 7
  services: 6
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # Desktop 主進程
    cat > "src/desktop/main.ts" << 'EOF'
import { app, BrowserWindow, ipcMain, Menu, Tray, nativeImage } from 'electron';
import { autoUpdater } from 'electron-updater';
import * as path from 'path';
import { AppService } from './services/AppService';
import { FileService } from './services/FileService';
import { SettingsService } from './services/SettingsService';
import { UpdateService } from './services/UpdateService';

class DesktopApp {
  private mainWindow: BrowserWindow | null = null;
  private settingsWindow: BrowserWindow | null = null;
  private tray: Tray | null = null;
  private appService: AppService;
  private fileService: FileService;
  private settingsService: SettingsService;
  private updateService: UpdateService;

  constructor() {
    this.appService = new AppService();
    this.fileService = new FileService();
    this.settingsService = new SettingsService();
    this.updateService = new UpdateService();
    
    this.initializeApp();
  }

  private initializeApp(): void {
    // Set application user model id for Windows
    if (process.platform === 'win32') {
      app.setAppUserModelId('com.machinenativeops.desktop');
    }

    // App event handlers
    app.whenReady().then(() => {
      this.createMainWindow();
      this.setupTray();
      this.setupMenu();
      this.setupIpcHandlers();
      this.setupAutoUpdater();
    });

    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        this.createMainWindow();
      }
    });

    app.on('before-quit', () => {
      this.appService.cleanup();
    });
  }

  private createMainWindow(): void {
    this.mainWindow = new BrowserWindow({
      width: 1200,
      height: 800,
      minWidth: 800,
      minHeight: 600,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        enableRemoteModule: false,
        preload: path.join(__dirname, 'preload.js'),
      },
      icon: path.join(__dirname, 'assets/icon.png'),
      show: false,
    });

    // Load the app
    if (process.env.NODE_ENV === 'development') {
      this.mainWindow.loadURL('http://localhost:3000');
      this.mainWindow.webContents.openDevTools();
    } else {
      this.mainWindow.loadFile(path.join(__dirname, 'renderer/index.html'));
    }

    this.mainWindow.once('ready-to-show', () => {
      this.mainWindow?.show();
    });

    this.mainWindow.on('closed', () => {
      this.mainWindow = null;
    });
  }

  private createSettingsWindow(): void {
    if (this.settingsWindow) {
      this.settingsWindow.focus();
      return;
    }

    this.settingsWindow = new BrowserWindow({
      width: 600,
      height: 400,
      resizable: false,
      parent: this.mainWindow || undefined,
      modal: true,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, 'preload.js'),
      },
    });

    if (process.env.NODE_ENV === 'development') {
      this.settingsWindow.loadURL('http://localhost:3000/settings');
    } else {
      this.settingsWindow.loadFile(path.join(__dirname, 'renderer/index.html'), {
        query: { route: 'settings' },
      });
    }

    this.settingsWindow.on('closed', () => {
      this.settingsWindow = null;
    });
  }

  private setupTray(): void {
    const iconPath = path.join(__dirname, 'assets/tray-icon.png');
    const icon = nativeImage.createFromPath(iconPath);
    this.tray = new Tray(icon.resize({ width: 16, height: 16 }));

    const contextMenu = Menu.buildFromTemplate([
      {
        label: 'Show App',
        click: () => {
          this.mainWindow?.show();
        },
      },
      {
        label: 'Settings',
        click: () => {
          this.createSettingsWindow();
        },
      },
      { type: 'separator' },
      {
        label: 'Quit',
        click: () => {
          app.quit();
        },
      },
    ]);

    this.tray.setToolTip('MachineNativeOps');
    this.tray.setContextMenu(contextMenu);

    this.tray.on('click', () => {
      this.mainWindow?.show();
    });
  }

  private setupMenu(): void {
    if (process.platform === 'darwin') {
      const template = [
        {
          label: 'MachineNativeOps',
          submenu: [
            { role: 'about' },
            { type: 'separator' },
            { role: 'services' },
            { type: 'separator' },
            { role: 'hide' },
            { role: 'hideothers' },
            { role: 'unhide' },
            { type: 'separator' },
            { role: 'quit' },
          ],
        },
        {
          label: 'Edit',
          submenu: [
            { role: 'undo' },
            { role: 'redo' },
            { type: 'separator' },
            { role: 'cut' },
            { role: 'copy' },
            { role: 'paste' },
            { role: 'selectall' },
          ],
        },
        {
          label: 'Window',
          submenu: [
            { role: 'minimize' },
            { role: 'close' },
            { role: 'front' },
            { type: 'separator' },
            { role: 'window' },
          ],
        },
      ];

      Menu.setApplicationMenu(Menu.buildFromTemplate(template as any));
    } else {
      Menu.setApplicationMenu(null);
    }
  }

  private setupIpcHandlers(): void {
    // App controls
    ipcMain.handle('app:quit', () => {
      app.quit();
    });

    ipcMain.handle('app:minimize', () => {
      this.mainWindow?.minimize();
    });

    ipcMain.handle('app:toggle-devtools', () => {
      this.mainWindow?.webContents.toggleDevTools();
    });

    // File operations
    ipcMain.handle('file:open', async () => {
      return this.fileService.openFile();
    });

    ipcMain.handle('file:save', async (_, data: string, defaultPath?: string) => {
      return this.fileService.saveFile(data, defaultPath);
    });

    // Settings
    ipcMain.handle('settings:get', async (event, key?: string) => {
      return this.settingsService.get(key);
    });

    ipcMain.handle('settings:set', async (event, key: string, value: any) => {
      return this.settingsService.set(key, value);
    });

    // Window controls
    ipcMain.handle('window:show-settings', () => {
      this.createSettingsWindow();
    });
  }

  private setupAutoUpdater(): void {
    autoUpdater.checkForUpdatesAndNotify();

    autoUpdater.on('update-available', () => {
      this.mainWindow?.webContents.send('update-available');
    });

    autoUpdater.on('update-downloaded', () => {
      this.mainWindow?.webContents.send('update-downloaded');
    });
  }
}

// Create and start the app
new DesktopApp();
EOF
    
    # Desktop 封裝配置
    cat > "src/desktop/package.json" << 'EOF'
{
  "name": "@machinenativeops/desktop",
  "version": "1.0.0",
  "description": "MachineNativeOps Desktop Application",
  "main": "dist/main.js",
  "scripts": {
    "dev": "concurrently &quot;npm run dev:renderer&quot; &quot;npm run dev:main&quot;",
    "dev:renderer": "vite",
    "dev:main": "tsc -p tsconfig.main.json && electron dist/main.js",
    "build": "npm run build:renderer && npm run build:main",
    "build:renderer": "vite build",
    "build:main": "tsc -p tsconfig.main.json",
    "dist": "npm run build && electron-builder",
    "dist:win": "npm run build && electron-builder --win",
    "dist:mac": "npm run build && electron-builder --mac",
    "dist:linux": "npm run build && electron-builder --linux",
    "test": "vitest",
    "lint": "eslint . --ext .ts,.tsx"
  },
  "dependencies": {
    "electron-updater": "^5.3.0",
    "axios": "^1.3.0",
    "zustand": "^4.3.0"
  },
  "devDependencies": {
    "electron": "^23.0.0",
    "electron-builder": "^23.6.0",
    "typescript": "^4.9.0",
    "vite": "^4.1.0",
    "@vitejs/plugin-react": "^3.1.0",
    "concurrently": "^7.6.0",
    "eslint": "^8.35.0",
    "@typescript-eslint/eslint-plugin": "^5.54.0",
    "@typescript-eslint/parser": "^5.54.0"
  },
  "build": {
    "appId": "com.machinenativeops.desktop",
    "productName": "MachineNativeOps",
    "directories": {
      "output": "release"
    },
    "files": [
      "dist/**/*",
      "node_modules/**/*"
    ],
    "mac": {
      "category": "public.app-category.productivity"
    },
    "win": {
      "target": "nsis"
    },
    "linux": {
      "target": "AppImage"
    }
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF
    
    log_success "Desktop 平台建立完成"
}

# 建立 API Gateway
setup_api_gateway() {
    log_info "建立 API Gateway..."
    
    mkdir -p "src/api/{routes,middleware,services,utils,validators}"
    
    # API Gateway 配置
    cat > "src/api/gateway-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: APIGateway
metadata:
  name: api-gateway
  namespace: machinenativeops
spec:
  framework: "fastapi"
  version: "0.95.0"
  
  features:
    authentication: true
    authorization: true
    rateLimiting: true
    caching: true
    monitoring: true
    documentation: true
    
  routes:
    - path: "/api/v1/auth/*"
      service: "auth-service"
      auth: false
      rateLimit: 100
    - path: "/api/v1/users/*"
      service: "user-service"
      auth: true
      rateLimit: 1000
    - path: "/api/v1/projects/*"
      service: "project-service"
      auth: true
      rateLimit: 500
    - path: "/api/v1/files/*"
      service: "file-service"
      auth: true
      rateLimit: 200
    - path: "/api/v1/notifications/*"
      service: "notification-service"
      auth: true
      rateLimit: 1000
  
  middleware:
    - cors
    - authentication
    - authorization
    - rate_limiting
    - caching
    - logging
    - error_handling
    - request_validation
  
  services:
    - name: auth-service
      url: "http://localhost:8001"
      healthCheck: "/health"
      timeout: 30
    - name: user-service
      url: "http://localhost:8002"
      healthCheck: "/health"
      timeout: 30
    - name: project-service
      url: "http://localhost:8003"
      healthCheck: "/health"
      timeout: 30
    - name: file-service
      url: "http://localhost:8004"
      healthCheck: "/health"
      timeout: 60
    - name: notification-service
      url: "http://localhost:8005"
      healthCheck: "/health"
      timeout: 30

status:
  phase: configured
  routes: 5
  middleware: 8
  services: 5
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    # API Gateway 主應用
    cat > "src/api/main.py" << 'EOF'
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
import httpx
import time
import logging
from typing import Dict, Any

from middleware.auth import AuthMiddleware
from middleware.rate_limit import RateLimitMiddleware
from middleware.caching import CacheMiddleware
from middleware.logging import LoggingMiddleware
from utils.config import get_settings
from utils.health import health_check

settings = get_settings()

# Create FastAPI app
app = FastAPI(
    title="MachineNativeOps API Gateway",
    description="Multi-platform API Gateway for MachineNativeOps",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add middleware
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(AuthMiddleware)
app.add_middleware(RateLimitMiddleware)
app.add_middleware(CacheMiddleware)
app.add_middleware(LoggingMiddleware)

# Service registry
services = {
    "auth-service": {
        "url": settings.AUTH_SERVICE_URL,
        "timeout": 30.0,
    },
    "user-service": {
        "url": settings.USER_SERVICE_URL,
        "timeout": 30.0,
    },
    "project-service": {
        "url": settings.PROJECT_SERVICE_URL,
        "timeout": 30.0,
    },
    "file-service": {
        "url": settings.FILE_SERVICE_URL,
        "timeout": 60.0,
    },
    "notification-service": {
        "url": settings.NOTIFICATION_SERVICE_URL,
        "timeout": 30.0,
    },
}

async def proxy_request(service_name: str, path: str, request: Request) -> JSONResponse:
    """Proxy request to the appropriate service"""
    
    if service_name not in services:
        raise HTTPException(status_code=404, detail="Service not found")
    
    service_config = services[service_name]
    service_url = f"{service_config['url']}{path}"
    
    # Prepare headers
    headers = dict(request.headers)
    headers.pop("host", None)  # Remove host header
    
    # Get request body
    body = await request.body()
    
    try:
        async with httpx.AsyncClient(timeout=service_config['timeout']) as client:
            response = await client.request(
                method=request.method,
                url=service_url,
                headers=headers,
                content=body,
                params=request.query_params,
            )
        
        # Prepare response headers
        response_headers = dict(response.headers)
        response_headers.pop("content-length", None)
        response_headers.pop("transfer-encoding", None)
        
        return JSONResponse(
            content=response.json(),
            status_code=response.status_code,
            headers=response_headers,
        )
    
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Service timeout")
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Service unavailable")
    except Exception as e:
        logging.error(f"Proxy error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

# Health check
@app.get("/health")
async def health():
    return await health_check()

# Proxy routes
@app.api_route("/api/v1/auth/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def auth_proxy(path: str, request: Request):
    return await proxy_request("auth-service", f"/{path}", request)

@app.api_route("/api/v1/users/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def users_proxy(path: str, request: Request):
    return await proxy_request("user-service", f"/{path}", request)

@app.api_route("/api/v1/projects/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def projects_proxy(path: str, request: Request):
    return await proxy_request("project-service", f"/{path}", request)

@app.api_route("/api/v1/files/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def files_proxy(path: str, request: Request):
    return await proxy_request("file-service", f"/{path}", request)

@app.api_route("/api/v1/notifications/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def notifications_proxy(path: str, request: Request):
    return await proxy_request("notification-service", f"/{path}", request)

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logging.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )
EOF
    
    log_success "API Gateway 建立完成"
}

# 建立跨平台同步機制
setup_cross_platform_sync() {
    log_info "建立跨平台同步機制..."
    
    mkdir -p "src/sync/{services,events,conflicts,resolvers}"
    
    # 同步配置
    cat > "src/sync/sync-config.yaml" << EOF
apiVersion: machinenativeops.io/v2
kind: CrossPlatformSync
metadata:
  name: cross-platform-sync
  namespace: machinenativeops
spec:
  syncStrategy: "event-driven"
  conflictResolution: "last-writer-wins"
  
  events:
    - name: "user.created"
      platforms: ["web", "mobile", "desktop", "api"]
      realtime: true
    - name: "user.updated"
      platforms: ["web", "mobile", "desktop", "api"]
      realtime: true
    - name: "project.created"
      platforms: ["web", "mobile", "desktop", "api"]
      realtime: true
    - name: "project.updated"
      platforms: ["web", "mobile", "desktop", "api"]
      realtime: true
    - name: "file.uploaded"
      platforms: ["web", "mobile", "desktop"]
      realtime: false
    - name: "notification.created"
      platforms: ["web", "mobile", "desktop"]
      realtime: true
  
  conflictResolution:
    strategy: "operational-transform"
    fallback: "manual"
    timeout: 30
  
  offlineSupport:
    enabled: true
    platforms: ["mobile", "desktop"]
    maxQueueSize: 1000
    syncInterval: 60

status:
  phase: configured
  events: 6
  platforms: 4
  lastUpdated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
    
    log_success "跨平台同步機制建立完成"
}

# 驗證多端架構
verify_multiplatform_system() {
    log_info "驗證多端架構系統..."
    
    local verification_errors=0
    
    # 檢查平台目錄
    local platforms=("web" "mobile" "desktop" "api")
    for platform in "${platforms[@]}"; do
        if [[ -d "src/$platform" ]]; then
            log_success "$platform 平台目錄存在"
        else
            log_error "$platform 平台目錄不存在"
            ((verification_errors++))
        fi
    done
    
    # 檢查共用核心
    if [[ -d "src/shared" ]]; then
        log_success "共用核心目錄存在"
    else
        log_error "共用核心目錄不存在"
        ((verification_errors++))
    fi
    
    # 檢查平台配置文件
    local configs=("src/web/platform-config.yaml" "src/mobile/platform-config.yaml" "src/desktop/platform-config.yaml" "src/api/gateway-config.yaml")
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            log_success "平台配置文件存在: $(basename "$config")"
        else
            log_error "平台配置文件不存在: $config"
            ((verification_errors++))
        fi
    done
    
    # 檢查同步機制
    if [[ -d "src/sync" ]]; then
        log_success "跨平台同步機制存在"
    else
        log_error "跨平台同步機制不存在"
        ((verification_errors++))
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "多端架構系統驗證通過"
        return 0
    else
        log_error "多端架構系統驗證失敗，發現 $verification_errors 個錯誤"
        return 1
    fi
}

# 主函數
main() {
    log_info "開始多端架構系統初始化..."
    
    # 初始化階段
    local total_steps=8
    local current_step=0
    
    ((current_step++)); progress_bar $current_step $total_steps; load_config
    ((current_step++)); progress_bar $current_step $total_steps; setup_shared_core_architecture
    ((current_step++)); progress_bar $current_step $total_steps; setup_web_platform
    ((current_step++)); progress_bar $current_step $total_steps; setup_mobile_platform
    ((current_step++)); progress_bar $current_step $total_steps; setup_desktop_platform
    ((current_step++)); progress_bar $current_step $total_steps; setup_api_gateway
    ((current_step++)); progress_bar $current_step $total_steps; setup_cross_platform_sync
    ((current_step++)); progress_bar $current_step $total_steps; verify_multiplatform_system
    
    echo; log_success "多端架構系統初始化完成！"
    
    # 輸出重要資訊
    echo
    log_info "重要資訊："
    echo "  - 共用核心：src/shared/"
    echo "  - Web 平台：src/web/"
    echo "  - Mobile 平台：src/mobile/"
    echo "  - Desktop 平台：src/desktop/"
    echo "  - API Gateway：src/api/"
    echo "  - 跨平台同步：src/sync/"
    echo
    log_info "架構特色："
    echo "  - 單一核心多端外殼"
    echo "  - 共用業務邏輯和型別定義"
    echo "  - 統一 API 契約和認證"
    echo "  - 跨平台即時同步"
    echo "  - 離線支援和衝突解決"
    echo
    log_info "多端架構狀態：已初始化並驗證"
}

# 執行主函數
main "$@"