# 阴间录像滤镜 App — iOS 本地处理方案设计清单

## 一、产品定位
一键导入视频 → 选择"阴间预设" → 本地处理生成模糊/失真/老旧质感的视频，全程无需服务器。
核心卖点：**多种失真叠加 + 不规则抖动/丢帧**，而不是单纯降低分辨率。

---

## 二、技术路线选择

不使用云端 ffmpeg 方案，改为 iOS 本地处理。两条可选路线：

### 路线 A：纯原生（AVFoundation + Core Image）— 推荐优先尝试
- 优点：包体积小、利用硬件加速、处理快、无开源协议问题
- 缺点：滤镜效果需要重新实现，低码率"马赛克压缩感"不如 ffmpeg 精确可控

### 路线 B：集成 ffmpeg-kit（LGPL 版本）
- 优点：可以直接照搬已经调好的 ffmpeg 滤镜命令，效果最接近预期
- 缺点：包体积明显增大、纯软件处理速度较慢、需注意选 **LGPL** 而非 GPL 版本（避免闭源商业 app 的协议冲突）

**建议**：先用路线 A 做出 MVP，验证核心视觉效果是否满意；如果"马赛克压缩感"这块用原生框架做不出想要的效果，再引入 ffmpeg-kit 作为路线 B 的补充或替换。

---

## 三、MVP 功能清单

- [ ] 从相册/文件导入视频（限制时长，如 60s）
- [ ] 预设选择（至少 3 个，见下方参数设计）
- [ ] "阴间程度"强度滑块（0-100）
- [ ] 处理进度条
- [ ] 结果预览播放器（AVPlayer）
- [ ] 导出到相册 / 分享

暂不做（后续再加）：随机化按钮、多片段拼接、自定义时间戳文字。

---

## 四、路线 A 技术实现细节（AVFoundation + Core Image）

### 整体流程
```
AVAsset（原视频）
  → AVAssetReader 逐帧读取（输出 CVPixelBuffer / CMSampleBuffer）
  → 每帧转 CIImage，套用 CIFilter 链处理
  → 转回 CVPixelBuffer
  → AVAssetWriter 写入新文件（同时处理音频轨道）
  → 导出结果视频
```

### 各效果对应的实现方式

| 效果 | ffmpeg 里怎么做 | 原生框架怎么做 |
|---|---|---|
| 降分辨率+放大糊感 | scale 两次 | CIImage 缩小后用 `CILanczosScaleTransform` 放大回原尺寸 |
| 降帧率 | fps 滤镜 | 控制 AVAssetWriter 写入频率，跳过部分帧，或复制上一帧 |
| 偏色/降饱和度 | eq / colorbalance | `CIColorControls`（saturation/contrast/brightness）+ `CIColorMatrix`（通道偏移实现偏色） |
| 噪点颗粒感 | noise 滤镜 | `CIRandomGenerator` 生成噪点图，用 `CISourceOverCompositing` 或 `CIColorBlendMode` 叠加 |
| 扫描线（VHS） | overlay 叠加 png | 预先生成扫描线纹理图（半透明横线 PNG 或代码生成的 CIImage），叠加合成 |
| 色彩溢出（chroma bleeding） | chromashift | 用 `CIAffineTransform` 对某个颜色通道单独做像素位移，再合并回 RGB |
| 低码率压缩感/马赛克 | 极低 bitrate 编码 | 设置 `AVVideoAverageBitRateKey` 为很低的值（如 100kbps 以下），硬件编码器会自然产生块状伪影；效果没有 ffmpeg 精确但方向正确 |
| 时间戳水印（CCTV） | drawtext | 用 Core Animation 生成文字图层，通过 `AVVideoCompositionCoreAnimationTool` 叠加烧录进画面 |

### 音频处理
- `AVAudioEngine` + `AVAudioUnitEQ`：实现带通滤波（模拟电话音效果，只保留 300Hz-3400Hz）
- 降采样：音频轨道重新采样到低采样率（如 8kHz）再输出
- 加底噪：混入一段噪声音频素材，用 `AVAudioMixerNode` 混合

---

## 五、三套预设参数设计（原生框架版本）

### 预设 1：老式座机 / BB机摄像头
- 缩放：先缩小到宽度约 176px，再用最近邻/低质量插值放大回原尺寸（保留块状感，不要用平滑插值）
- 帧率：目标 10fps
- CIColorControls：saturation ≈ 0.4，contrast ≈ 1.1
- 偏色：绿色通道轻微增强，红蓝通道轻微减弱
- 噪点强度：中等
- 音频：带通 300Hz-3000Hz，采样率降到 8kHz

### 预设 2：VHS 录像带
- 缩放：宽度约 320px 再放大
- CIColorControls：saturation ≈ 0.6，contrast ≈ 1.15
- 色彩溢出：红/蓝通道做 2-3px 的水平位移
- 扫描线纹理叠加（透明度约 15%-25%）
- 噪点：轻微
- 音频：带通 100Hz-6000Hz，混入轻微底噪

### 预设 3：老式监控 CCTV
- 缩放：宽度约 240px 再放大
- CIColorControls：saturation ≈ 0.1（接近黑白），contrast ≈ 1.3，brightness 略降
- 帧率：目标 8fps（卡顿感明显）
- 时间戳水印：左上角叠加当前时间文字
- 音频：通常静音，或只保留环境底噪

> 注：以上数值是起点，需要用真实素材在 Xcode 里跑通后反复调参，尤其是噪点强度、色彩位移像素数、码率数值。

---

## 六、"阴间程度"滑块的参数映射建议

用 0-100 的强度值 `s` 线性插值各参数：

| 参数 | 强度低（s=20） | 强度高（s=90） |
|---|---|---|
| 目标缩放宽度 | 320px | 120px |
| 帧率 | 20fps | 6fps |
| 视频编码码率 | 800kbps | 80kbps |
| 噪点混合强度 | 0.05 | 0.35 |
| saturation | 0.9 | 0.2 |
| 音频采样率 | 22050Hz | 6000Hz |

先做线性映射跑通效果，体验不对再调成指数曲线。

---

## 七、路线 B 备选：ffmpeg-kit 集成要点

如果路线 A 的"马赛克压缩感"效果不理想，可以引入 ffmpeg-kit 做本地处理：

- 使用 `ffmpeg-kit-ios` 的 **LGPL** 版本（不要选 GPL，避免闭源商业 app 协议冲突）
- 通过 CocoaPods/SPM 集成
- 之前设计的 ffmpeg 滤镜命令（scale+fps+noise+colorbalance+低码率编码）可以直接复用，在 app 内部用 `FFmpegKit.execute()` 调用，输入输出路径指向 app 沙盒内的临时文件
- 注意：ffmpeg-kit 处理是纯 CPU 软件编解码，速度会比原生硬件加速慢，长视频处理时要做好进度提示，避免用户以为卡死

---

## 八、上架 App Store 注意事项
- 已有开发者账号（$99/年），上架流程与国内 ICP 备案完全无关，不需要国内服务器/域名备案
- 需准备隐私政策（Privacy Policy URL），因为涉及处理用户视频内容
- 美颜/滤镜类工具审核通常较宽松，只要不涉及生成违规内容即可
- 若用户视频来自相册，需要在 Info.plist 声明 `NSPhotoLibraryUsageDescription` 等权限说明文案

---

## 九、给 Claude Code 的实现建议顺序
1. 先跑通「导入视频 → AVAssetReader读帧 → 不做任何处理直接写回 → AVAssetWriter导出」的最简单闭环，确保读写链路没问题
2. 加入预设 1 的 CIFilter 链（缩放糊感 + 降帧率 + 基础调色），验证效果
3. 加入噪点、扫描线、色彩溢出等效果，逐个验证叠加后的观感
4. 补齐预设 2、3
5. 加入音频处理链
6. 加入强度滑块，把固定参数改成按滑块值插值
7. 最后做前端预览/进度条/导出分享打磨
8. 如果马赛克压缩感效果不满意，评估是否引入路线 B（ffmpeg-kit）
