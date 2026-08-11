# App Store 提交准备 - Rêverie

## 已完成的工作

### 1. iOS 应用更新 ✅
- **Added AboutView**: 添加了"关于"页面，包含以下内容：
  - 应用信息展示
  - 技术支持链接
  - 官方网站链接
  - 隐私政策链接
  - 使用条款链接
  - 版本信息

- **Updated MainView**: 在主页面标题栏添加了信息按钮(i)
- **Added Config.swift**: 统一的URL配置管理文件

### 2. App Store 必需的 URL ✅
以下URL已配置在应用中，用于App Store提交：

| URL类型 | URL | 用途 |
|---------|-----|------|
| **技术支持URL** | `https://reverie-app.com/support` | 用户获取技术支持 |
| **营销网址URL** | `https://reverie-app.com` | 应用官方网站 |
| **隐私政策URL** | `https://reverie-app.com/privacy` | 隐私政策页面 |
| **使用条款URL** | `https://reverie-app.com/terms` | 使用条款页面 |

### 3. Vercel 网站部署 ✅
创建了完整的Next.js网站，包含以下页面：
- `/` - 首页（营销页面）
- `/support` - 技术支持页面
- `/privacy` - 隐私政策页面  
- `/terms` - 使用条款页面

## 部署步骤

### 步骤1: 部署网站到Vercel
1. 将 `AppStoreWebsite/` 文件夹推送到GitHub仓库
2. 在 [Vercel](https://vercel.com) 导入项目
3. 配置自定义域名（如 `reverie-app.com`）
4. 部署网站

### 步骤2: 更新iOS应用中的URL
部署网站后，更新 `HauntedFilter/Config.swift` 文件中的URL：

```swift
// 更新为你的实际域名
static let supportURL = "https://YOUR_DOMAIN/support"
static let marketingURL = "https://YOUR_DOMAIN"
static let privacyPolicyURL = "https://YOUR_DOMAIN/privacy"
static let termsOfUseURL = "https://YOUR_DOMAIN/terms"
```

### 步骤3: App Store Connect 配置
在提交应用到App Store时，需要提供以下信息：

1. **技术支持网址**: `https://YOUR_DOMAIN/support`
2. **营销网址**: `https://YOUR_DOMAIN`
3. **隐私政策网址**: `https://YOUR_DOMAIN/privacy`

## 文件说明

### iOS 应用文件
- `HauntedFilter/Views/AboutView.swift` - 关于/支持页面
- `HauntedFilter/Views/MainView.swift` - 已添加信息按钮
- `HauntedFilter/Config.swift` - URL配置管理

### 网站文件 (Vercel部署)
- `AppStoreWebsite/` - 完整的Next.js网站
  - `package.json` - 依赖配置
  - `pages/index.tsx` - 首页
  - `pages/support.tsx` - 技术支持页面
  - `pages/privacy.tsx` - 隐私政策页面
  - `pages/terms.tsx` - 使用条款页面

## 测试验证

### 测试项目
- [ ] 在iOS模拟器中测试AboutView打开
- [ ] 验证所有链接在应用中可点击
- [ ] 部署网站并测试所有页面
- [ ] 更新Config.swift中的URL为实际域名
- [ ] 在App Store Connect中填写正确的URL

## 下一步行动

1. **立即行动**: 部署网站到Vercel
2. **应用测试**: 测试更新后的应用功能
3. **URL更新**: 将Config.swift中的URL更新为部署后的实际域名
4. **App Store提交**: 使用正确的URL提交应用到App Store

## 联系方式配置

网站中已配置以下联系方式，可根据需要修改：

- 技术支持邮箱: `support@reverie-app.com`
- 隐私相关邮箱: `privacy@reverie-app.com`
- 法律相关邮箱: `legal@reverie-app.com`

这些邮箱地址可以在 `AppStoreWebsite/pages/` 各页面中更新。