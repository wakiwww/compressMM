# App Store 地区配置说明

## 📋 文件概述

本目录包含 App Store Connect 所需的地区配置文件，用于指定应用支持的区域、价格和语言。

## 📁 文件说明

### 1. `App_Territories_Simple.geojson` - 地区地理配置文件
**用途**: 在 App Store Connect 中定义应用支持的地理区域
**格式要求**: 
- 必须是 .geojson 格式
- 只能包含一个 MultiPolygon 元素
- 符合 GeoJSON 标准

**当前配置支持的地区**:
1. **北美地区**: 美国、加拿大
   - 坐标: `[-125.0, 49.0]` 到 `[-66.0, 25.0]`
2. **东亚地区**: 中国内地
   - 坐标: `[73.0, 53.0]` 到 `[135.0, 18.0]`
3. **西欧地区**: 英国
   - 坐标: `[-8.0, 60.0]` 到 `[2.0, 50.0]`
4. **日本韩国地区**: 日本、韩国
   - 坐标: `[128.0, 46.0]` 到 `[146.0, 31.0]`
5. **台湾地区**: 台湾
   - 坐标: `[120.0, 26.0]` 到 `[122.0, 21.0]`

### 2. `Regions_Config.csv` - 地区详细配置
**用途**: 内部参考，定义各地区价格、语言等信息

**配置详情**:
| 地区代码 | 地区名称 | 语言代码 | 显示语言 | 应用名称 | 阶段 | 价格层级 | 价格 | 状态 |
|----------|----------|----------|----------|----------|------|----------|------|------|
| US | 美国 | en | English | werck it! ... | Phase 1 | 3 | $2.99 | Active |
| CN | 中国 | zh-Hans | 简体中文 | werck it! ... | Phase 1 | 1 | ¥6 | Active |
| GB | 英国 | en | English | werck it! ... | Phase 1 | 3 | £2.99 | Active |
| JP | 日本 | ja | Japanese | werck it! ... | Phase 1 | 3 | ¥400 | Active |
| TW | 台湾 | zh-Hant | 繁体中文 | werck it! ... | Phase 1 | 2 | TWD 90 | Active |

## 🚀 App Store Connect 使用指南

### 步骤 1: 上传地区配置文件
1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择你的应用: "werck it!- video degrader（压烂它！）"
3. 进入 "价格与销售范围"
4. 点击 "管理地区"
5. 上传 `App_Territories_Simple.geojson` 文件

### 步骤 2: 验证地区配置
上传后，系统会显示支持的地区地图：
- ✅ 北美地区（美国、加拿大）
- ✅ 东亚地区（中国）
- ✅ 西欧地区（英国）
- ✅ 日本韩国地区
- ✅ 台湾地区

### 步骤 3: 价格配置
使用 CSV 文件中的价格信息配置各地区价格：
- **美国**: $2.99 (Tier 3)
- **中国**: ¥6 (Tier 1)  
- **英国**: £2.99 (Tier 3)
- **日本**: ¥400 (Tier 3)
- **台湾**: TWD 90 (Tier 2)

### 步骤 4: 语言本地化
根据 CSV 配置语言：
- **美国/英国**: 英语
- **中国**: 简体中文
- **日本**: 日语
- **台湾**: 繁体中文

## 🔧 文件验证

### GeoJSON 验证
确保文件符合 App Store Connect 要求：
```bash
# 验证文件包含 MultiPolygon
cat App_Territories_Simple.geojson | grep -q "MultiPolygon" && echo "✅ 包含 MultiPolygon" || echo "❌ 缺少 MultiPolygon"

# 验证文件格式
python3 -m json.tool App_Territories_Simple.geojson > /dev/null && echo "✅ JSON 格式正确" || echo "❌ JSON 格式错误"
```

### CSV 验证
确保价格信息正确：
```bash
# 验证价格配置
cat Regions_Config.csv | grep -c "werck it!" | grep -q "5" && echo "✅ 5个地区已配置" || echo "❌ 地区配置不完整"
```

## 📝 修改指南

### 添加新地区
1. **更新 GeoJSON**:
   - 在 `coordinates` 数组中添加新的多边形
   - 格式: `[[[经度1, 纬度1], [经度1, 纬度2], [经度2, 纬度2], [经度2, 纬度1], [经度1, 纬度1]]]`

2. **更新 CSV**:
   - 添加新行: `RegionCode,RegionName,LanguageCode,DisplayLanguage,AppName,Phase,PriceTier,Price,Status`

### 修改价格
1. 更新 CSV 文件中的 `PriceTier` 和 `Price` 列
2. 对应 App Store Connect 价格层级表

### 修改语言
1. 更新 CSV 文件中的 `LanguageCode` 和 `DisplayLanguage` 列
2. 使用标准语言代码 (ISO 639-1)

## ⚠️ 注意事项

1. **文件命名**: App Store Connect 要求 .geojson 扩展名
2. **文件大小**: 不要超过 10MB
3. **坐标精度**: 使用标准经纬度坐标
4. **多边形顺序**: 多边形必须是闭合的（首尾坐标相同）
5. **数据更新**: 修改后需重新上传到 App Store Connect

## 🔄 版本管理

- **v1.0** (当前): 支持5个主要市场
- **未来扩展**: 可添加更多地区，如欧盟、澳大利亚等

## 📞 支持

如果遇到地区配置问题：
1. 检查文件格式是否正确
2. 验证坐标范围是否合理
3. 确认价格层级是否正确
4. 查看 App Store Connect 错误信息

**🎯 现在你的应用已准备好配置全球市场支持！**