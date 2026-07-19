# BGM背景音乐功能说明

## 功能概述

此iOS应用现在支持为视频添加背景音乐（BGM）功能。用户可以选择BGM，系统会自动处理BGM时长以适应视频长度。

## 主要功能特点

### 1. BGM自动时长适配
- **BGM比视频短**：自动循环播放直到视频结束
- **BGM比视频长**：自动裁剪到视频长度
- **BGM与视频等长**：直接使用，无需处理

### 2. BGM管理
- 自动扫描 `bgm` 文件夹中的所有音频文件
- 支持常见音频格式（MP3、WAV、M4A等）
- 显示BGM时长信息
- 可以根据BGM文件名创建友好显示名

### 3. 音量控制
- 支持0-100%音量调节
- 启用/禁用BGM切换开关

### 4. 预览功能
- 预览页面可以切换播放模式：
  - 带BGM的视频
  - 可选的原始视频预览
  - 播放控制（播放/暂停/快进/快退）

### 5. 处理状态显示
- 显示BGM处理进度
- 显示时长适配信息
- 错误提示

## 使用方法

### 1. 添加BGM文件
将音频文件放置在项目的 `bgm` 文件夹中：
- 路径：`HauntedFilter/HauntedFilter/bgm/`
- 支持的格式：MP3、WAV、M4A、AAC等

### 2. 命名建议
建议使用有意义的文件名，系统会自动转换为友好的显示名称：
- `epic_bgm.mp3` → "Epic Bgm"
- `sad_music.m4a` → "Sad Music"

### 3. 使用流程
1. 导入视频文件
2. 在"背景音乐"部分启用BGM功能
3. 选择要添加的BGM
4. 调整音量（可选）
5. 点击"开始处理（带BGM）"按钮
6. 在预览页面查看效果

## 技术实现

### 文件结构
```
HauntedFilter/
├── Audio/
│   ├── AudioProcessor.swift     # 基础音频处理
│   └── BGMManager.swift         # BGM管理器
├── Engine/
│   ├── VideoProcessor.swift     # 视频处理器
│   └── VideoProcessor+BGM.swift # BGM合并处理器
├── Models/
│   └── BGM.swift                # BGM数据模型
├── Views/
│   ├── BGMSelectorView.swift    # BGM选择器UI
│   ├── MainViewEx.swift         # 主界面（扩展）
│   ├── PlayerViewEx.swift       # 播放器（扩展）
│   └── ProcessingProgressViewEx.swift # 进度视图
└── ViewModels/
    └── ProcessingViewModelEx.swift # 扩展的ViewModel
```

### 主要类说明

#### BGM.swift
- `BGM` 结构体：表示一个BGM配乐
- `adaptedBGM(for:)` 方法：根据视频时长适配BGM
- `cutBGM(from:to:)` 私有方法：裁剪BGM
- `loopBGM(from:for:)` 私有方法：循环BGM

#### BGMManager.swift
- `BGMManager` 类：单例管理器
- 加载和扫描BGM文件夹
- 管理可用BGM列表
- 提供默认BGM选择

#### VideoProcessor+BGM.swift
- `BGMMergeProcessor` 类：视频与BGM合并处理器
- 使用AVFoundation进行音视频合成
- 处理时长适配逻辑
- 导出最终视频

#### BGMSelectorView.swift
- BGM选择UI组件
- 音量控制滑块
- BGM列表选择器
- 启用/禁用开关

### 音频处理流程
1. **用户选择视频和BGM**
2. **系统获取视频时长**
3. **检查需要：循环或裁剪**
4. **创建临时适配后的BGM文件**
5. **处理视频滤镜效果**
6. **合并视频与BGM**
7. **生成最终输出文件**

## 注意事项

### 性能考虑
- 大型音频文件可能需要较长时间处理
- 建议BGM时长在10秒到5分钟之间
- 长视频（超过1分钟）处理时间会增加

### 内存使用
- BGM处理会创建临时文件
- 自动清理临时文件
- 处理完成后删除中间文件

### 兼容性
- 支持系统版本：iOS 16.0+
- 需要访问相册权限
- 需要访问文件系统权限

### 扩展可能性
1. 支持在线BGM库
2. 添加BGM淡入淡出效果
3. 多轨音频混合
4. 音频效果处理（均衡器、混响等）

## 故障排除

### BGM无法加载
1. 检查文件路径：`bgm`文件夹是否正确
2. 检查文件格式：确保是支持的音频格式
3. 检查文件大小：确保文件完整

### 处理失败
1. 检查视频文件是否完整
2. 确保有足够的存储空间
3. 检查权限设置

### 音视频不同步
1. 确保BGM文件格式正确
2. 检查视频编解码器兼容性
3. 可能需要调整音频采样率

## 更新日志

### 版本 1.0
- 初始BGM功能实现
- 自动时长适配
- 音量控制
- 预览切换功能

---

**提示**：测试前请确保BGM文件放置在正确位置，并具有合适的音频参数（采样率、比特率等）。