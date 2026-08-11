# Vercel 部署指南 - werck it!- video degrader（压烂它！）App Store 网站

## ✅ 已完成的工作

我已创建了一个**干净的、Vercel-ready**的分支 `vercel-deploy-final`，并推送到GitHub。

### 项目结构
```
vercel-deploy-final/
├── package.json          # Next.js项目配置
├── next.config.js       # Next.js配置
├── tsconfig.json        # TypeScript配置
├── next-env.d.ts        # TypeScript环境声明
├── .gitignore          # 标准Next.js忽略文件
└── pages/              # 所有页面
    ├── index.tsx       # 首页 (营销网址)
    ├── support.tsx     # 技术支持页面
    ├── privacy.tsx     # 隐私政策页面
    └── terms.tsx       # 使用条款页面
```

### App Store 必需的 URL
- **主页/营销网址**: `https://你的域名.com/`
- **技术支持网址**: `https://你的域名.com/support`
- **隐私政策网址**: `https://你的域名.com/privacy`
- **使用条款网址**: `https://你的域名.com/terms`

## 🚀 Vercel 部署步骤

### 步骤 1: 访问 Vercel
1. 打开 [vercel.com](https://vercel.com)
2. 使用你的GitHub账号登录

### 步骤 2: 导入项目
1. 点击"New Project"
2. 选择你的GitHub仓库: `wakiwww/compressMM`
3. 在分支选择中，选择: `vercel-deploy-final`

### 步骤 3: 项目配置 (自动检测)
Vercel 会自动检测到这是 Next.js 项目：

| 配置项 | 自动值 | 说明 |
|--------|--------|------|
| **Framework Preset** | Next.js | 自动检测 |
| **Root Directory** | `/` | 根目录 |
| **Build Command** | `npm run build` | 自动 |
| **Output Directory** | `.next` | 自动 |
| **Install Command** | `npm install` | 自动 |

### 步骤 4: 部署
1. 点击 "Deploy"
2. 等待构建完成 (约1-2分钟)
3. 你会获得一个免费域名: `https://xxxxx.vercel.app`

### 步骤 5: 配置自定义域名 (可选但推荐)
1. 进入项目仪表板
2. 点击 "Settings" → "Domains"
3. 添加你的域名 (如 `werckit-app.com`)
4. 按照Vercel的指示配置DNS记录

## 🔧 技术验证

### Vercel 能正确检测吗？
**✅ 是的！** 原因：
1. `package.json` 包含正确的 Next.js 依赖
2. 有标准的 Next.js 项目结构
3. 没有混淆的 iOS 项目文件
4. 有 `next.config.js` 配置文件

### 本地测试 (可选)
```bash
# 安装依赖
npm install

# 开发模式运行
npm run dev

# 浏览器打开
open http://localhost:3000
```

## 📱 iOS 应用中的 URL 更新

部署网站后，需要更新 iOS 应用中的 URL：

### 更新 Config.swift
```swift
// 替换为你的实际域名
static let supportURL = "https://你的域名.com/support"
static let marketingURL = "https://你的域名.com"
static let privacyPolicyURL = "https://你的域名.com/privacy"
static let termsOfUseURL = "https://你的域名.com/terms"
```

### 文件位置
`HauntedFilter/HauntedFilter/Config.swift`

## 🎯 App Store Connect 配置

在提交应用到 App Store 时，填写以下信息：

| 字段 | URL |
|------|-----|
| **技术支持网址** | `https://你的域名.com/support` |
| **营销网址** | `https://你的域名.com` |
| **隐私政策网址** | `https://你的域名.com/privacy` |

## 🔍 故障排除

### 如果 Vercel 仍然显示 404:
1. **检查分支**: 确保选择的是 `vercel-deploy-final` 分支
2. **检查构建日志**: 查看 Vercel 的构建日志确认检测到 Next.js
3. **清除缓存**: 在 Vercel 项目设置中清除构建缓存
4. **重新部署**: 手动触发重新部署

### 如果页面无法访问:
1. **检查域名配置**: 确保域名已正确配置
2. **检查 SSL 证书**: Vercel 自动提供 SSL，但可能需要几分钟生效
3. **检查 DNS 传播**: 自定义域名更改可能需要 24-48 小时传播

## 📊 验证步骤

部署后，请验证以下页面可以正常访问：

1. [ ] 首页: `https://你的域名.com/`
2. [ ] 技术支持: `https://你的域名.com/support`
3. [ ] 隐私政策: `https://你的域名.com/privacy`
4. [ ] 使用条款: `https://你的域名.com/terms`

## 💡 额外建议

### 1. 预览部署
Vercel 为每个 Pull Request 创建预览部署，适合测试。

### 2. 环境变量
如果需要，可以在 Vercel 项目中添加环境变量。

### 3. 监控
Vercel 提供基本监控和日志查看。

### 4. 自动部署
默认配置下，`vercel-deploy-final` 分支的每次推送都会触发自动部署。

## 🎉 完成！

现在你可以：
1. 按照上述步骤在 Vercel 部署网站
2. 获取网站的 URL
3. 更新 iOS 应用中的 Config.swift
4. 在 App Store Connect 中填写正确的 URL
5. 提交应用到 App Store

**✅ 所有 App Store 提交必需的技术支持网址和营销网址都已准备就绪！**