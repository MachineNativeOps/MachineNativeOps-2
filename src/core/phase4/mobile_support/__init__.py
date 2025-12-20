"""
Mobile Application Support Module
移動應用支持模塊

實現跨平台移動開發、PWA支持、移動UI組件、設備適配
"""

import asyncio
import logging
import json
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
from dataclasses import dataclass
from enum import Enum

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MobilePlatform(Enum):
    """移動平台枚舉"""
    IOS = "ios"
    ANDROID = "android"
    REACT_NATIVE = "react_native"
    FLUTTER = "flutter"
    IONIC = "ionic"
    XAMARIN = "xamarin"
    CORDOVA = "cordova"

class DeviceType(Enum):
    """設備類型枚舉"""
    PHONE = "phone"
    TABLET = "tablet"
    WEARABLE = "wearable"
    TV = "tv"

class ScreenOrientation(Enum):
    """屏幕方向枚舉"""
    PORTRAIT = "portrait"
    LANDSCAPE = "landscape"
    AUTO = "auto"

@dataclass
class MobileAppSpec:
    """移動應用規格"""
    app_name: str
    platforms: List[MobilePlatform]
    target_devices: List[DeviceType]
    orientations: List[ScreenOrientation]
    min_sdk_version: Dict[str, str]
    features: List[str]
    permissions: List[str]
    bundle_id: str
    version: str

@dataclass
class UIComponent:
    """UI組件"""
    name: str
    platform: MobilePlatform
    component_type: str
    props: Dict[str, Any]
    styles: Dict[str, Any]
    responsive_config: Dict[str, Any]

@dataclass
class MobileGenerationResult:
    """移動應用生成結果"""
    platform: MobilePlatform
    framework: str
    code: str
    assets: Dict[str, str]
    configuration: Dict[str, Any]
    build_commands: List[str]
    screen_count: int
    component_count: int

class MobileAppGenerator:
    """移動應用生成器"""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.logger = logging.getLogger(__name__)
        self.supported_platforms = self._initialize_platforms()
        self.ui_component_library = UIComponentLibrary()
        self.device_adapter = DeviceAdapter()
        self.pwa_generator = PWAGenerator()
        
    def _initialize_platforms(self) -> Dict[MobilePlatform, Dict[str, Any]]:
        """初始化支持的移動平台"""
        return {
            MobilePlatform.IOS: {
                "language": "Swift",
                "frameworks": ["SwiftUI", "UIKit"],
                "ide": "Xcode",
                "package_manager": "Swift Package Manager",
                "build_tools": ["xcodebuild"],
                "min_sdk": "iOS 13.0"
            },
            MobilePlatform.ANDROID: {
                "language": "Kotlin",
                "frameworks": ["Jetpack Compose", "Android Views"],
                "ide": "Android Studio",
                "package_manager": "Gradle",
                "build_tools": ["gradle"],
                "min_sdk": "API 21"
            },
            MobilePlatform.REACT_NATIVE: {
                "language": "JavaScript/TypeScript",
                "frameworks": ["React Native", "Expo"],
                "ide": "VS Code",
                "package_manager": "npm/yarn",
                "build_tools": ["react-native-cli", "expo"],
                "min_sdk": "React Native 0.70"
            },
            MobilePlatform.FLUTTER: {
                "language": "Dart",
                "frameworks": ["Flutter"],
                "ide": "VS Code/Android Studio",
                "package_manager": "pub",
                "build_tools": ["flutter"],
                "min_sdk": "Flutter 3.0"
            },
            MobilePlatform.IONIC: {
                "language": "TypeScript",
                "frameworks": ["Ionic", "Angular", "React", "Vue"],
                "ide": "VS Code",
                "package_manager": "npm",
                "build_tools": ["ionic-cli"],
                "min_sdk": "Ionic 6"
            },
            MobilePlatform.XAMARIN: {
                "language": "C#",
                "frameworks": ["Xamarin.Forms", ".NET MAUI"],
                "ide": "Visual Studio",
                "package_manager": "NuGet",
                "build_tools": ["dotnet"],
                "min_sdk": ".NET 6"
            },
            MobilePlatform.CORDOVA: {
                "language": "JavaScript",
                "frameworks": ["Apache Cordova", "PhoneGap"],
                "ide": "VS Code",
                "package_manager": "npm",
                "build_tools": ["cordova-cli"],
                "min_sdk": "Cordova 11"
            }
        }
    
    async def initialize(self) -> None:
        """初始化移動應用生成器"""
        try:
            self.logger.info("Initializing Mobile App Generator...")
            
            # 初始化UI組件庫
            await self.ui_component_library.initialize()
            
            # 初始化設備適配器
            await self.device_adapter.initialize()
            
            # 初始化PWA生成器
            await self.pwa_generator.initialize()
            
            self.logger.info("Mobile App Generator initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize Mobile App Generator: {e}")
            raise
    
    async def analyze_mobile_requirements(self, user_input: str) -> Dict[str, Any]:
        """分析移動應用需求"""
        try:
            self.logger.info(f"Analyzing mobile requirements: {user_input[:100]}...")
            
            # 應用類型分析
            app_type = self._analyze_app_type(user_input)
            
            # 目標平台分析
            target_platforms = self._analyze_platforms(user_input)
            
            # 功能需求分析
            feature_requirements = self._analyze_features(user_input)
            
            # 設備適配需求
            device_requirements = self._analyze_device_requirements(user_input)
            
            return {
                "user_input": user_input,
                "app_type": app_type,
                "target_platforms": target_platforms,
                "feature_requirements": feature_requirements,
                "device_requirements": device_requirements,
                "analysis_timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Mobile requirements analysis failed: {e}")
            return {"error": str(e)}
    
    def suggest_platforms(self, analysis: Dict[str, Any]) -> List[MobilePlatform]:
        """根據分析結果建議平台"""
        try:
            app_type = analysis.get("app_type", "general")
            feature_requirements = analysis.get("feature_requirements", {})
            
            # 基於應用類型的平台推薦
            if app_type == "game":
                candidates = [MobilePlatform.FLUTTER, MobilePlatform.REACT_NATIVE, 
                            MobilePlatform.IOS, MobilePlatform.ANDROID]
            elif app_type == "business":
                candidates = [MobilePlatform.FLUTTER, MobilePlatform.REACT_NATIVE,
                            MobilePlatform.IONIC, MobilePlatform.XAMARIN]
            elif app_type == "media":
                candidates = [MobilePlatform.IOS, MobilePlatform.ANDROID,
                            MobilePlatform.REACT_NATIVE, MobilePlatform.FLUTTER]
            elif app_type == "simple":
                candidates = [MobilePlatform.FLUTTER, MobilePlatform.IONIC,
                            MobilePlatform.REACT_NATIVE]
            else:
                candidates = [MobilePlatform.FLUTTER, MobilePlatform.REACT_NATIVE,
                            MobilePlatform.IOS, MobilePlatform.ANDROID]
            
            # 根據功能需求調整
            if feature_requirements.get("native_performance", False):
                candidates = [MobilePlatform.IOS, MobilePlatform.ANDROID] + [
                    p for p in candidates if p not in [MobilePlatform.IOS, MobilePlatform.ANDROID]
                ]
            
            if feature_requirements.get("cross_platform", True):
                candidates = [p for p in candidates if p in 
                            [MobilePlatform.FLUTTER, MobilePlatform.REACT_NATIVE, 
                             MobilePlatform.IONIC, MobilePlatform.XAMARIN]]
            
            return candidates[:4]  # 返回前4個推薦平台
            
        except Exception as e:
            self.logger.error(f"Platform suggestion failed: {e}")
            return [MobilePlatform.FLUTTER, MobilePlatform.REACT_NATIVE]
    
    async def generate_mobile_app(self, user_input: str, 
                                platform: MobilePlatform,
                                framework: str = None) -> Dict[str, Any]:
        """生成移動應用"""
        try:
            self.logger.info(f"Generating mobile app for {platform.value}")
            
            if platform not in self.supported_platforms:
                raise ValueError(f"Unsupported platform: {platform}")
            
            # 獲取平台信息
            platform_info = self.supported_platforms[platform]
            
            # 選擇框架
            selected_framework = framework or platform_info["frameworks"][0]
            
            # 創建應用規格
            app_spec = await self._create_app_spec(user_input, platform, selected_framework)
            
            # 生成應用代碼
            generation_result = await self._generate_app_code(app_spec, platform, selected_framework)
            
            # 生成UI組件
            ui_components = await self.ui_component_library.generate_components(
                app_spec, platform
            )
            
            # 生成配置文件
            configuration = await self._generate_configuration(app_spec, platform)
            
            # 生成資源文件
            assets = await self._generate_assets(app_spec, platform)
            
            return {
                "success": True,
                "platform": platform.value,
                "framework": selected_framework,
                "app_spec": app_spec,
                "generation_result": generation_result,
                "ui_components": ui_components,
                "configuration": configuration,
                "assets": assets,
                "screen_count": generation_result.screen_count,
                "component_count": len(ui_components)
            }
            
        except Exception as e:
            self.logger.error(f"Mobile app generation failed for {platform}: {e}")
            return {"success": False, "error": str(e)}
    
    async def generate_pwa_support(self, user_input: str) -> Dict[str, Any]:
        """生成PWA支持"""
        try:
            self.logger.info("Generating PWA support...")
            
            # 分析PWA需求
            pwa_requirements = await self.pwa_generator.analyze_requirements(user_input)
            
            # 生成Service Worker
            service_worker = await self.pwa_generator.generate_service_worker()
            
            # 生成Manifest文件
            manifest = await self.pwa_generator.generate_manifest(pwa_requirements)
            
            # 生成離線支持
            offline_support = await self.pwa_generator.generate_offline_support()
            
            # 生成推送通知
            push_notifications = await self.pwa_generator.generate_push_notifications()
            
            return {
                "success": True,
                "pwa_requirements": pwa_requirements,
                "service_worker": service_worker,
                "manifest": manifest,
                "offline_support": offline_support,
                "push_notifications": push_notifications,
                "pwa_features": ["offline", "installable", "push_notifications"]
            }
            
        except Exception as e:
            self.logger.error(f"PWA support generation failed: {e}")
            return {"success": False, "error": str(e)}
    
    async def create_device_adaptation(self, app_results: Dict[str, Any]) -> Dict[str, Any]:
        """創建設備適配"""
        try:
            self.logger.info("Creating device adaptation...")
            
            # 分析設備需求
            device_analysis = await self.device_adapter.analyze_devices(app_results)
            
            # 生成響應式布局
            responsive_layouts = await self.device_adapter.generate_responsive_layouts()
            
            # 生成設備特定樣式
            device_styles = await self.device_adapter.generate_device_styles()
            
            # 生成交互適配
            interaction_adaptation = await self.device_adapter.generate_interaction_adaptation()
            
            return {
                "success": True,
                "device_analysis": device_analysis,
                "responsive_layouts": responsive_layouts,
                "device_styles": device_styles,
                "interaction_adaptation": interaction_adaptation,
                "supported_devices": list(device_analysis.keys())
            }
            
        except Exception as e:
            self.logger.error(f"Device adaptation creation failed: {e}")
            return {"success": False, "error": str(e)}
    
    def _analyze_app_type(self, user_input: str) -> str:
        """分析應用類型"""
        user_input_lower = user_input.lower()
        
        # 應用類型關鍵詞
        type_keywords = {
            "game": ["game", "play", "gaming", "entertainment", "fun"],
            "business": ["business", "work", "productivity", "office", "enterprise"],
            "media": ["media", "video", "audio", "streaming", "photos", "gallery"],
            "social": ["social", "chat", "messaging", "community", "network"],
            "ecommerce": ["shop", "store", "buy", "sell", "commerce", "payment"],
            "education": ["education", "learning", "course", "tutorial", "school"],
            "health": ["health", "fitness", "medical", "wellness", "exercise"],
            "travel": ["travel", "navigation", "maps", "booking", "hotel"],
            "utility": ["tool", "utility", "calculator", "converter", "helper"]
        }
        
        # 計算各類型得分
        type_scores = {}
        for app_type, keywords in type_keywords.items():
            score = sum(1 for keyword in keywords if keyword in user_input_lower)
            type_scores[app_type] = score
        
        # 返回得分最高的類型
        if any(type_scores.values()):
            return max(type_scores.items(), key=lambda x: x[1])[0]
        
        return "general"
    
    def _analyze_platforms(self, user_input: str) -> List[MobilePlatform]:
        """分析目標平台"""
        user_input_lower = user_input.lower()
        
        # 平台關鍵詞
        platform_keywords = {
            MobilePlatform.IOS: ["ios", "iphone", "ipad", "apple"],
            MobilePlatform.ANDROID: ["android", "google", "samsung"],
            MobilePlatform.REACT_NATIVE: ["react native", "react-native", "rn"],
            MobilePlatform.FLUTTER: ["flutter"],
            MobilePlatform.IONIC: ["ionic"],
            MobilePlatform.XAMARIN: ["xamarin", "c#"],
            MobilePlatform.CORDOVA: ["cordova", "phonegap"]
        }
        
        # 檢測平台偏好
        mentioned_platforms = []
        for platform, keywords in platform_keywords.items():
            if any(keyword in user_input_lower for keyword in keywords):
                mentioned_platforms.append(platform)
        
        # 如果沒有特定偏好，返回推薦平台
        if not mentioned_platforms:
            return [MobilePlatform.FLUTTER, MobilePlatform.REACT_NATIVE]
        
        return mentioned_platforms
    
    def _analyze_features(self, user_input: str) -> Dict[str, bool]:
        """分析功能需求"""
        user_input_lower = user_input.lower()
        
        features = {
            "camera": any(word in user_input_lower for word in ["camera", "photo", "video"]),
            "gps": any(word in user_input_lower for word in ["gps", "location", "map", "navigation"]),
            "push_notifications": any(word in user_input_lower for word in ["push", "notification", "alert"]),
            "offline": any(word in user_input_lower for word in ["offline", "no internet", "cache"]),
            "authentication": any(word in user_input_lower for word in ["login", "auth", "security"]),
            "payment": any(word in user_input_lower for word in ["payment", "purchase", "buy", "shop"]),
            "social": any(word in user_input_lower for word in ["social", "share", "connect"]),
            "media": any(word in user_input_lower for word in ["media", "video", "audio", "streaming"]),
            "cloud": any(word in user_input_lower for word in ["cloud", "sync", "backup"]),
            "ar_vr": any(word in user_input_lower for word in ["ar", "vr", "augmented", "virtual"]),
            "wearable": any(word in user_input_lower for word in ["watch", "wearable", "fitness"]),
            "iot": any(word in user_input_lower for word in ["iot", "smart", "connected"])
        }
        
        return features
    
    def _analyze_device_requirements(self, user_input: str) -> Dict[str, Any]:
        """分析設備需求"""
        user_input_lower = user_input.lower()
        
        # 設備類型
        device_types = {
            DeviceType.PHONE: any(word in user_input_lower for word in ["phone", "mobile"]),
            DeviceType.TABLET: any(word in user_input_lower for word in ["tablet", "ipad"]),
            DeviceType.WEARABLE: any(word in user_input_lower for word in ["watch", "wearable"]),
            DeviceType.TV: any(word in user_input_lower for word in ["tv", "television"])
        }
        
        # 屏幕方向
        orientations = {
            ScreenOrientation.PORTRAIT: any(word in user_input_lower for word in ["portrait", "vertical"]),
            ScreenOrientation.LANDSCAPE: any(word in user_input_lower for word in ["landscape", "horizontal"]),
            ScreenOrientation.AUTO: "both" in user_input_lower or "any orientation" in user_input_lower
        }
        
        return {
            "device_types": [device for device, required in device_types.items() if required],
            "orientations": [orientation for orientation, required in orientations.items() if required],
            "responsive_design": any(word in user_input_lower for word in ["responsive", "adaptive", "flexible"])
        }
    
    async def _create_app_spec(self, user_input: str, platform: MobilePlatform, 
                             framework: str) -> MobileAppSpec:
        """創建應用規格"""
        # 提取應用名稱
        app_name = self._extract_app_name(user_input)
        
        # 獲取平台信息
        platform_info = self.supported_platforms[platform]
        
        # 生成bundle ID
        bundle_id = f"com.example.{app_name.lower().replace(' ', '')}"
        
        # 分析功能和權限
        features = self._analyze_features(user_input)
        permissions = self._generate_permissions(features, platform)
        
        return MobileAppSpec(
            app_name=app_name,
            platforms=[platform],
            target_devices=[DeviceType.PHONE, DeviceType.TABLET],
            orientations=[ScreenOrientation.PORTRAIT, ScreenOrientation.LANDSCAPE],
            min_sdk_version={platform.value: platform_info["min_sdk"]},
            features=[feature for feature, enabled in features.items() if enabled],
            permissions=permissions,
            bundle_id=bundle_id,
            version="1.0.0"
        )
    
    async def _generate_app_code(self, app_spec: MobileAppSpec, 
                               platform: MobilePlatform, 
                               framework: str) -> MobileGenerationResult:
        """生成應用代碼"""
        try:
            # 根據平台生成基礎代碼
            if platform == MobilePlatform.FLUTTER:
                code = await self._generate_flutter_code(app_spec)
            elif platform == MobilePlatform.REACT_NATIVE:
                code = await self._generate_react_native_code(app_spec)
            elif platform == MobilePlatform.IOS:
                code = await self._generate_swift_code(app_spec)
            elif platform == MobilePlatform.ANDROID:
                code = await self._generate_kotlin_code(app_spec)
            else:
                code = await self._generate_generic_code(app_spec, platform)
            
            # 生成構建命令
            build_commands = self._generate_build_commands(platform, framework)
            
            return MobileGenerationResult(
                platform=platform,
                framework=framework,
                code=code,
                assets={},
                configuration={},
                build_commands=build_commands,
                screen_count=5,  # 默認生成5個屏幕
                component_count=10  # 默認10個組件
            )
            
        except Exception as e:
            self.logger.error(f"App code generation failed: {e}")
            raise
    
    async def _generate_flutter_code(self, app_spec: MobileAppSpec) -> str:
        """生成Flutter代碼"""
        return """
import 'package:flutter/material.dart';

void main() {{
  runApp({app_spec.app_name.replace(' ', '')}App());
}}

class {app_spec.app_name.replace(' ', '')}App extends StatelessWidget {{
  @override
  Widget build(BuildContext context) {{
    return MaterialApp(
      title: '{app_spec.app_name}',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }}
}}

class HomeScreen extends StatefulWidget {{
  @override
  _HomeScreenState createState() => _HomeScreenState();
}}

class _HomeScreenState extends State<HomeScreen> {{
  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      appBar: AppBar(title: Text('{app_spec.app_name}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to {app_spec.app_name}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {{}},
              child: Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }}
}}
"""
    
    async def _generate_react_native_code(self, app_spec: MobileAppSpec) -> str:
        """生成React Native代碼"""
        return """
import React from 'react';
import {{ SafeAreaView, StyleSheet, Text, View, Button }} from 'react-native';

const App = () => {{
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}}>
        <Text style={styles.title}}>{app_spec.app_name}</Text>
        <Text style={styles.subtitle}>Welcome!</Text>
        <Button
          title="Get Started"
          onPress={() => {{}}
        />
      </View>
    </SafeAreaView>
  );
}};

const styles = StyleSheet.create({{
  container: {{
    flex: 1,
    backgroundColor: '#fff',
  }},
  content: {{
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  }},
  title: {{
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 10,
  }},
  subtitle: {{
    fontSize: 16,
    marginBottom: 20,
  }},
}});

export default App;
"""
    
    async def _generate_swift_code(self, app_spec: MobileAppSpec) -> str:
        """生成Swift代碼"""
        return """
import SwiftUI

@main
struct {app_spec.app_name.replace(' ', '')}App: App {{
    var body: some Scene {{
        WindowGroup {{
            ContentView()
        }}
    }}
}}

struct ContentView: View {{
    var body: some View {{
        NavigationView {{
            VStack(spacing: 20) {{
                Text("{app_spec.app_name}")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Button("Get Started") {{
                    // Button action
                }}
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }}
            .padding()
            .navigationTitle("Home")
        }}
    }}
}}

struct ContentView_Previews: PreviewProvider {{
    static var previews: some View {{
        ContentView()
    }}
}}
"""
    
    async def _generate_kotlin_code(self, app_spec: MobileAppSpec) -> str:
        """生成Kotlin代碼"""
        return """
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

class MainActivity : ComponentActivity() {{
    override fun onCreate(savedInstanceState: Bundle?) {{
        super.onCreate(savedInstanceState)
        setContent {{
            {app_spec.app_name.replace(' ', '')}Theme {{
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {{
                    HomeScreen()
                }}
            }}
        }}
    }}
}}

@Composable
fun HomeScreen() {{
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {{
        Text(
            text = "{app_spec.app_name}",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Text(
            text = "Welcome!",
            fontSize = 18.sp,
            modifier = Modifier.padding(bottom = 24.dp)
        )
        
        Button(
            onClick = {{ /* Handle button click */ }}
        ) {{
            Text("Get Started")
        }}
    }}
}}
"""
    
    async def _generate_generic_code(self, app_spec: MobileAppSpec, 
                                   platform: MobilePlatform) -> str:
        """生成通用代碼"""
        return """
// {app_spec.app_name} - {platform.value} Application
// Generated Mobile App Code

class {app_spec.app_name.replace(' ', '')}Application {{
    constructor() {{
        this.initialize();
    }}
    
    initialize() {{
        console.log('Initializing {app_spec.app_name} for {platform.value}');
    }}
    
    start() {{
        console.log('Starting {app_spec.app_name}');
    }}
    
    stop() {{
        console.log('Stopping {app_spec.app_name}');
    }}
}}

// Main entry point
const app = new {app_spec.app_name.replace(' ', '')}Application();
app.start();
"""
    
    def _generate_permissions(self, features: Dict[str, bool], 
                            platform: MobilePlatform) -> List[str]:
        """生成權限列表"""
        permissions = []
        
        if features.get("camera", False):
            if platform == MobilePlatform.IOS:
                permissions.append("NSCameraUsageDescription")
            elif platform == MobilePlatform.ANDROID:
                permissions.append("android.permission.CAMERA")
        
        if features.get("gps", False):
            if platform == MobilePlatform.IOS:
                permissions.extend(["NSLocationWhenInUseUsageDescription", 
                                  "NSLocationAlwaysAndWhenInUseUsageDescription"])
            elif platform == MobilePlatform.ANDROID:
                permissions.extend(["android.permission.ACCESS_FINE_LOCATION", 
                                  "android.permission.ACCESS_COARSE_LOCATION"])
        
        if features.get("push_notifications", False):
            if platform == MobilePlatform.IOS:
                permissions.append("UNUserNotificationCenter")
            elif platform == MobilePlatform.ANDROID:
                permissions.append("android.permission.POST_NOTIFICATIONS")
        
        return permissions
    
    def _generate_build_commands(self, platform: MobilePlatform, 
                               framework: str) -> List[str]:
        """生成構建命令"""
        commands = []
        
        if platform == MobilePlatform.FLUTTER:
            commands = [
                "flutter pub get",
                "flutter build apk",
                "flutter build ios"
            ]
        elif platform == MobilePlatform.REACT_NATIVE:
            commands = [
                "npm install",
                "npx react-native run-android",
                "npx react-native run-ios"
            ]
        elif platform == MobilePlatform.IOS:
            commands = [
                "xcodebuild -workspace MyApp.xcworkspace -scheme MyApp -configuration Debug build"
            ]
        elif platform == MobilePlatform.ANDROID:
            commands = [
                "./gradlew assembleDebug",
                "./gradlew assembleRelease"
            ]
        
        return commands
    
    async def _generate_configuration(self, app_spec: MobileAppSpec, 
                                    platform: MobilePlatform) -> Dict[str, Any]:
        """生成配置文件"""
        config = {
            "app_name": app_spec.app_name,
            "bundle_id": app_spec.bundle_id,
            "version": app_spec.version,
            "platform": platform.value,
            "min_sdk": app_spec.min_sdk_version,
            "features": app_spec.features,
            "permissions": app_spec.permissions
        }
        
        return config
    
    async def _generate_assets(self, app_spec: MobileAppSpec, 
                             platform: MobilePlatform) -> Dict[str, str]:
        """生成資源文件"""
        assets = {
            "icon.png": "# App Icon Placeholder",
            "splash.png": "# Splash Screen Placeholder",
            "README.md": f"# {app_spec.app_name}\n\nGenerated for {platform.value}"
        }
        
        return assets
    
    def _extract_app_name(self, user_input: str) -> str:
        """提取應用名稱"""
        import re
        words = re.findall(r'\b[a-zA-Z]+\b', user_input)
        if words:
            return words[0].title()
        return "MyMobileApp"
    
    async def health_check(self) -> Dict[str, Any]:
        """健康檢查"""
        return {
            "status": "healthy",
            "supported_platforms": len(self.supported_platforms),
            "components": {
                "ui_component_library": "active",
                "device_adapter": "active",
                "pwa_generator": "active"
            }
        }

class UIComponentLibrary:
    """UI組件庫"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self) -> None:
        """初始化UI組件庫"""
        self.logger.info("UI Component Library initialized")
    
    async def generate_components(self, app_spec: MobileAppSpec, 
                                platform: MobilePlatform) -> List[UIComponent]:
        """生成UI組件"""
        components = []
        
        # 基礎組件
        components.append(UIComponent(
            name="Header",
            platform=platform,
            component_type="layout",
            props={"title": app_spec.app_name},
            styles={"height": 60, "backgroundColor": "#007AFF"},
            responsive_config={"phone": {"height": 60}, "tablet": {"height": 80}}
        ))
        
        components.append(UIComponent(
            name="Button",
            platform=platform,
            component_type="interactive",
            props={"text": "Get Started"},
            styles={"padding": "16px", "borderRadius": "8px"},
            responsive_config={"phone": {"fontSize": 16}, "tablet": {"fontSize": 18}}
        ))
        
        return components

class DeviceAdapter:
    """設備適配器"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self) -> None:
        """初始化設備適配器"""
        self.logger.info("Device Adapter initialized")
    
    async def analyze_devices(self, app_results: Dict[str, Any]) -> Dict[str, Any]:
        """分析設備需求"""
        return {
            "phone": {"required": True, "features": ["touch", "portrait", "landscape"]},
            "tablet": {"required": False, "features": ["touch", "landscape"]},
            "wearable": {"required": False, "features": ["small_screen", "touch"]}
        }
    
    async def generate_responsive_layouts(self) -> Dict[str, Any]:
        """生成響應式布局"""
        return {
            "breakpoints": {"phone": 480, "tablet": 768, "desktop": 1024},
            "layouts": {
                "phone": {"columns": 1, "spacing": 16},
                "tablet": {"columns": 2, "spacing": 24},
                "desktop": {"columns": 3, "spacing": 32}
            }
        }
    
    async def generate_device_styles(self) -> Dict[str, Any]:
        """生成設備特定樣式"""
        return {
            "phone": {"fontSize": 14, "buttonSize": "large", "spacing": 16},
            "tablet": {"fontSize": 16, "buttonSize": "medium", "spacing": 24},
            "wearable": {"fontSize": 12, "buttonSize": "small", "spacing": 8}
        }
    
    async def generate_interaction_adaptation(self) -> Dict[str, Any]:
        """生成交互適配"""
        return {
            "touch": {"tap_threshold": 10, "swipe_threshold": 50},
            "keyboard": {"navigation": "tab", "submit": "enter"},
            "voice": {"commands": ["start", "stop", "help"]}
        }

class PWAGenerator:
    """PWA生成器"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self) -> None:
        """初始化PWA生成器"""
        self.logger.info("PWA Generator initialized")
    
    async def analyze_requirements(self, user_input: str) -> Dict[str, Any]:
        """分析PWA需求"""
        return {
            "offline_support": True,
            "installable": True,
            "push_notifications": True,
            "responsive_design": True
        }
    
    async def generate_service_worker(self) -> str:
        """生成Service Worker"""
        return """
// Service Worker for PWA
const CACHE_NAME = 'app-v1';
const urlsToCache = [
  '/',
  '/static/js/main.js',
  '/static/css/main.css'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        return response || fetch(event.request);
      })
  );
});
"""
    
    async def generate_manifest(self, requirements: Dict[str, Any]) -> Dict[str, Any]:
        """生成Manifest文件"""
        return {
            "name": "My PWA App",
            "short_name": "PWA App",
            "start_url": "/",
            "display": "standalone",
            "background_color": "#ffffff",
            "theme_color": "#007AFF",
            "icons": [
                {"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},
                {"src": "icon-512.png", "sizes": "512x512", "type": "image/png"}
            ]
        }
    
    async def generate_offline_support(self) -> Dict[str, Any]:
        """生成離線支持"""
        return {
            "cache_strategy": "cache_first",
            "offline_page": "/offline.html",
            "sync_when_online": True
        }
    
    async def generate_push_notifications(self) -> Dict[str, Any]:
        """生成推送通知"""
        return {
            "vapid_keys": {"public": "public_key", "private": "private_key"},
            "notification_types": ["alert", "badge", "sound"],
            "subscription_endpoint": "/api/subscribe"
        }

__all__ = [
    "MobileAppGenerator",
    "MobilePlatform",
    "DeviceType",
    "ScreenOrientation",
    "MobileAppSpec",
    "UIComponent",
    "MobileGenerationResult",
    "UIComponentLibrary",
    "DeviceAdapter",
    "PWAGenerator"
]