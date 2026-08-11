# Vercel 部署验证说明

## ✅ 问题已解决

**原来问题**：Vercel只能看到`main`分支，而且`main`分支根目录是iOS项目文件，导致Vercel无法检测到Next.js网站。

**解决方案**：在`main`分支的`website/`子目录中创建网站文件，并通过`vercel.json`配置文件告诉Vercel正确的项目位置。

## 📁 当前项目结构
```
main分支根目录/
├── vercel.json          # Vercel配置文件（关键！）
├── website/            # 网站文件目录
│   ├── package.json    # Next.js项目配置
│   ├── next.config.js  # Next.js配置
│   ├── pages/          # 所有页面
│   │   ├── index.tsx   # 首页
│   │   ├── support.tsx # 技术支持
│   │   ├── privacy.tsx # 隐私政策
│   │   └── terms.tsx   # 使用条款
│   └── ...其他配置文件
├── HauntedFilter/      # iOS应用文件（保持不变）
└── ...其他iOS项目文件
```

## 🚀 现在部署步骤（非常简单！）

### 第1步：打开Vercel
1. 访问 [vercel.com](https://vercel.com)
2. 使用GitHub登录
3. 点击 "New Project"

### 第2步：导入项目
1. 选择你的仓库: `wakiwww/compressMM`
2. **Vercel会自动选择`main`分支** ✅
3. 点击 "Import"

### 第3步：Vercel会自动配置
由于有`vercel.json`文件，Vercel会自动：
- ✅ 检测到在`website/`子目录中的Next.js项目
- ✅ 使用正确的构建命令
- ✅ 配置输出目录

### 第4步：立即部署
1. 点击 "Deploy"
2. 等待1-2分钟构建完成
3. 获得免费域名: `https://xxxxx.vercel.app`

## 🔧 Vercel配置详解

`vercel.json`文件内容：
```json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev", 
  "installCommand": "npm install",
  "framework": "nextjs",
  "outputDirectory": "website/.next",
  "rootDirectory": "website",      // 关键！告诉Vercel项目在website目录
  "github": {
    "silent": true
  }
}
```

## ✅ 验证Vercel能正确检测

在Vercel导入项目时，检查以下配置是否自动填充：

| 配置项 | 期望值 | 说明 |
|--------|--------|------|
| **Framework** | Next.js | 自动检测 |
| **Root Directory** | `website` | 从vercel.json读取 |
| **Build Command** | `npm run build` | 自动 |
| **Output Directory** | `website/.next` | 自动 |

## 🌐 App Store URL配置

网站部署后，获得以下URL（将`xxxxx`替换为你的Vercel域名）：

| 页面 | URL格式 |
|------|---------|
| **首页（营销网址）** | `https://xxxxx.vercel.app/` |
| **技术支持** | `https://xxxxx.vercel.app/support` |
| **隐私政策** | `https://xxxxx.vercel.app/privacy` |
| **使用条款** | `https://xxxxx.vercel.app/terms` |

## 📱 iOS应用更新

部署后，更新iOS应用中的URL：
```swift
// 在Config.swift中更新
static let supportURL = "https://xxxxx.vercel.app/support"
static let marketingURL = "https://xxxxx.vercel.app"
```

## 🔍 快速测试

如果你想在本地测试网站：
```bash
cd website
npm install
npm run dev
# 打开 http://localhost:3000
```

## 🎉 完成！

现在Vercel部署应该100%正常工作，因为：

1. ✅ 网站文件在`main`分支中（Vercel能看到）
2. ✅ 有`vercel.json`配置文件（告诉Vercel项目位置）
3. ✅ 所有App Store必需页面都已创建
4. ✅ iOS项目文件保持不变

**立即去Vercel部署吧！**