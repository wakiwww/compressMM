import SwiftUI
import PhotosUI

/// 主页：DECAY 品牌 + 视频导入 + 模式选择 + 滑块 + 音频 + 输出设置
struct MainView: View {
    @ObservedObject var viewModel: ProcessingViewModel
    @Binding var showPicker: Bool

    @State private var showIntensityWarning = false
    @State private var showIntensityAlert = false
    @State private var showAboutView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题区
                titleSection

                // 视频导入区
                importSection

                // 视频信息（导入后显示）
                if viewModel.sourceVideoURL != nil {
                    videoInfoSection
                }

                // 实时预览（导入后显示，滑块拖动时动态更新）
                if viewModel.previewDegradedFrame != nil {
                    previewSection
                }

                // 模式选择
                presetSection

                // 阴间程度滑块
                decaySliderSection

                // 警告提示
                if showIntensityWarning {
                    warningBanner
                }

                // 输出设置
                outputSettingsSection

                // 编码安全警告（实时显示，防止用户拉到无法编码的程度）
                if let warning = viewModel.encodingWarning {
                    encodingWarningBanner(warning)
                }

                // 处理按钮
                processButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .overlay {
            if viewModel.isPreparing {
                preparingOverlay
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .alert("确定继续？", isPresented: $showIntensityAlert) {
            Button("继续压烂它", role: .destructive) {
                // 允许继续
            }
            Button("取消", role: .cancel) {
                viewModel.intensity = min(viewModel.intensity, 95)
            }
        } message: {
            Text("当前参数可能导致视频完全不可辨认，音频严重损坏。")
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .onChange(of: viewModel.intensity) { newVal in
            updateWarning(for: newVal)
        }
        .onAppear {
            updateWarning(for: viewModel.intensity)
        }
        .sheet(isPresented: $showAboutView) {
            AboutView()
        }
    }

    // MARK: - 标题区

    private var titleSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rêverie")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.white)
                Text("引领画质新潮流")
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .foregroundColor(Color(hex: "#888888"))
            }
            Spacer()
            Button(action: {
                showAboutView = true
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#888888"))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - 导入区

    private var importSection: some View {
        Group {
            if viewModel.isImporting {
                // 导入中 — 加载指示
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                    Text("正在导入视频...")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundColor(Color(hex: "#444444"))
                )
            } else if viewModel.sourceVideoURL != nil {
                // 已导入 — 显示重新选择按钮
                Button {
                    viewModel.reset()
                    showPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                        Text("重新选择视频")
                            .font(.system(size: 15, weight: .medium, design: .default))
                    }
                    .foregroundColor(Color(hex: "#888888"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundColor(Color(hex: "#333333"))
                    )
                }
            } else {
                // 未导入 — 导入按钮
                Button {
                    showPicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .thin))
                        Text("导入视频")
                            .font(.system(size: 17, weight: .medium, design: .default))
                        Text("点击或从相册选取")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(Color(hex: "#888888"))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundColor(Color(hex: "#444444"))
                    )
                }
            }
        }
    }

    // MARK: - 视频信息

    private var videoInfoSection: some View {
        HStack(spacing: 12) {
            // 缩略图占位
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#0A0A0A"))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#444444"))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("视频已导入")
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(.white)
                HStack(spacing: 12) {
                    Text(viewModel.sourceFileSizeFormatted)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#888888"))
                    if let duration = viewModel.videoDuration {
                        Text(duration)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(hex: "#888888"))
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#0A0A0A"))
        )
    }

    // MARK: - 实时预览

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("实时预览")
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundColor(Color(hex: "#888888"))

            if let degraded = viewModel.previewDegradedFrame {
                Image(uiImage: degraded)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#1C1C1C"), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#0A0A0A"))
                    .frame(height: 160)
                    .overlay(
                        ProgressView().tint(.white)
                    )
            }
        }
    }

    // MARK: - 模式选择

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("降质模式")
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(Color(hex: "#888888"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VideoPreset.allCases) { preset in
                        PresetCardView(
                            preset: preset,
                            isSelected: viewModel.selectedPreset == preset
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedPreset = preset
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 阴间程度滑块

    private var decaySliderSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("阴间程度")
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(viewModel.intensity))%")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.intensity > 80 ? Color(hex: "#FF3B30") : .white)
            }

            // 自定义滑块外观
            ZStack(alignment: .leading) {
                // 轨道
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#333333"))
                    .frame(height: 6)
                // 填充部分
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.intensity > 80 ? Color(hex: "#FF3B30") : .white)
                    .frame(width: max(24, CGFloat(viewModel.intensity) / 100.0 * (UIScreen.main.bounds.width - 40)), height: 6)

                // 滑块手柄
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .white.opacity(0.3), radius: 4)
                    .offset(x: max(0, CGFloat(viewModel.intensity) / 100.0 * (UIScreen.main.bounds.width - 64)))
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let sliderWidth = UIScreen.main.bounds.width - 40
                        let percent = max(0, min(1, value.location.x / sliderWidth))
                        viewModel.intensity = Float(percent * 100)
                    }
            )

            HStack {
                Text("轻度降质")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#888888"))
                Spacer()
                Text("极致崩坏")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#888888"))
            }

            // 原汁原味压缩量 — 一键设到当前模式的甜点位
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.intensity = viewModel.selectedPreset.sweetSpotIntensity
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 12))
                    Text("原汁原味压缩量")
                        .font(.system(size: 13, weight: .medium, design: .default))
                    Text("(\(Int(viewModel.selectedPreset.sweetSpotIntensity))%)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#888888"))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#0A0A0A"))
        )
    }

    // MARK: - 警告横幅

    private var warningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#FF3B30"))

            Text(viewModel.intensity > 95
                 ? "⚠ 压缩量过大，输出文件可能产生严重失真"
                 : "⚠ 压缩量较大，输出文件可能产生严重失真")
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#FF3B30").opacity(0.15))
        )
        .transition(
            .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            )
        )
    }

    // MARK: - 音频控制

    private var audioControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("音频处理")
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(.white)
                Spacer()
                Text(viewModel.audioMode.displayName)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#888888"))
                Image(systemName: viewModel.audioExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#888888"))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.audioExpanded.toggle()
                }
            }

            if viewModel.audioExpanded {
                Divider()
                    .background(Color(hex: "#1C1C1C"))

                VStack(spacing: 12) {
                    // 音频模式选择
                    VStack(spacing: 0) {
                        ForEach(AudioMode.allCases) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.audioMode = mode
                                }
                            } label: {
                                HStack {
                                    Text(mode.displayName)
                                        .font(.system(size: 15, weight: .regular, design: .default))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if viewModel.audioMode == mode {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.system(size: 8))
                                            .foregroundColor(Color(hex: "#444444"))
                                    }
                                    Text(mode.description)
                                        .font(.system(size: 12, weight: .regular, design: .default))
                                        .foregroundColor(Color(hex: "#888888"))
                                }
                                .padding(.vertical, 10)
                            }

                            if mode != AudioMode.allCases.last {
                                Divider()
                                    .background(Color(hex: "#1C1C1C"))
                            }
                        }
                    }

                    // 独立音频滑块
                    if viewModel.audioMode == .independent {
                        VStack(spacing: 8) {
                            HStack {
                                Text("音频降质程度")
                                    .font(.system(size: 13, weight: .regular, design: .default))
                                    .foregroundColor(Color(hex: "#888888"))
                                Spacer()
                                Text("\(Int(viewModel.audioIntensity))%")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }

                            Slider(value: $viewModel.audioIntensity, in: 0...100, step: 1)
                                .tint(.white)

                            HStack {
                                Text("轻微")
                                    .font(.system(size: 11, weight: .regular, design: .default))
                                    .foregroundColor(Color(hex: "#888888"))
                                Spacer()
                                Text("损毁")
                                    .font(.system(size: 11, weight: .regular, design: .default))
                                    .foregroundColor(Color(hex: "#888888"))
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#0A0A0A"))
        )
    }

    // MARK: - 输出设置

    private var outputSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("输出设置")
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(Color(hex: "#888888"))

            VStack(spacing: 0) {
                outputSettingRow(
                    label: "分辨率上限",
                    value: viewModel.outputResolution.displayName
                ) {
                    viewModel.outputResolution = viewModel.outputResolution.next()
                }

                Divider().background(Color(hex: "#1C1C1C"))

                outputSettingRow(
                    label: "帧率",
                    value: viewModel.outputFrameRate.displayName
                ) {
                    viewModel.outputFrameRate = viewModel.outputFrameRate.next()
                }

                Divider().background(Color(hex: "#1C1C1C"))

                outputSettingRow(
                    label: "格式",
                    value: "MP4 (H.264)",
                    isFixed: true
                ) { }

                Divider().background(Color(hex: "#1C1C1C"))

                outputSettingRow(
                    label: "保存位置",
                    value: viewModel.saveLocation.displayName
                ) {
                    viewModel.saveLocation = viewModel.saveLocation.next()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#0A0A0A"))
        )
    }

    private func outputSettingRow(label: String, value: String, isFixed: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(.white)
                Spacer()
                Text(value)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(isFixed ? Color(hex: "#555555") : Color(hex: "#888888"))
                if !isFixed {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#555555"))
                }
            }
            .padding(.vertical, 12)
        }
        .disabled(isFixed)
    }

    // MARK: - 处理按钮

    private var processButton: some View {
        Button {
            if viewModel.intensity > 95 {
                showIntensityAlert = true
            } else {
                viewModel.startProcessing()
            }
        } label: {
            HStack(spacing: 8) {
                Text("开始处理")
                    .font(.system(size: 17, weight: .semibold, design: .default))
            }
            .foregroundColor(viewModel.sourceVideoURL != nil ? .black : Color(hex: "#555555"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.sourceVideoURL != nil ? Color.white : Color(hex: "#1A1A1A"))
            )
        }
        .disabled(viewModel.sourceVideoURL == nil || viewModel.isProcessing || viewModel.isImporting || viewModel.isPreparing || viewModel.encodingWarning != nil)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    // MARK: - 准备覆盖层

    private var preparingOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)

                Text("准备中...")
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .foregroundColor(.white)

                Text("正在初始化处理管线")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#888888"))
            }
        }
        .transition(.opacity)
    }

    // MARK: - 编码安全警告

    private func encodingWarningBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#FF3B30"))

            Text(message)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#FF3B30").opacity(0.15))
        )
    }

    // MARK: - 警告逻辑

    private func updateWarning(for intensity: Float) {
        withAnimation(.easeInOut(duration: 0.25)) {
            showIntensityWarning = intensity > 80
        }
        viewModel.recalculateEstimation()
    }
}

// MARK: - 辅助枚举

enum AudioMode: String, CaseIterable, Identifiable {
    case followVideo
    case independent
    case keepOriginal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .followVideo: return "跟随视频"
        case .independent: return "独立调节"
        case .keepOriginal: return "保留原始"
        }
    }

    var description: String {
        switch self {
        case .followVideo: return "跟随视频模式"
        case .independent: return "独立调节"
        case .keepOriginal: return "保留原始音频"
        }
    }
}

enum OutputResolution: String, CaseIterable {
    case followMode
    case res720p
    case res480p
    case res360p

    var displayName: String {
        switch self {
        case .followMode: return "跟随模式"
        case .res720p:    return "720p"
        case .res480p:    return "480p"
        case .res360p:    return "360p"
        }
    }

    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self) ?? 0
        return all[(idx + 1) % all.count]
    }
}

enum OutputFrameRate: String, CaseIterable {
    case followMode
    case fps24
    case fps12
    case fpsOriginal

    var displayName: String {
        switch self {
        case .followMode: return "跟随模式"
        case .fps24:      return "24 fps"
        case .fps12:      return "12 fps"
        case .fpsOriginal: return "原始"
        }
    }

    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self) ?? 0
        return all[(idx + 1) % all.count]
    }
}

enum SaveLocation: String, CaseIterable {
    case photoLibrary
    case files

    var displayName: String {
        switch self {
        case .photoLibrary: return "相册"
        case .files:        return "文件 App"
        }
    }

    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self) ?? 0
        return all[(idx + 1) % all.count]
    }
}

#Preview {
    MainView(
        viewModel: ProcessingViewModel(),
        showPicker: .constant(false)
    )
    .preferredColorScheme(.dark)
}