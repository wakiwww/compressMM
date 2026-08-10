import SwiftUI

/// BGM选择器组件
struct BGMSelectorView: View {
    @ObservedObject var bgmManager = BGMManager.shared
    @Binding var selectedBGM: BGM?
    @Binding var isBGMEnabled: Bool
    @Binding var bgmVolume: Float
    @Binding var isLoading: Bool

    @State private var showBGMList = false

    var body: some View {
        VStack(spacing: 16) {
            // BGM启用开关
            HStack {
                Image(systemName: isBGMEnabled ? "music.note" : "music.note.slash")
                    .foregroundColor(isBGMEnabled ? .blue : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("背景音乐")
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .padding(.leading, 4)
                        } else if isBGMEnabled {
                            Text("已启用")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    if let bgm = selectedBGM {
                        Text("\(bgm.displayName) (\(bgm.formattedDuration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("未选择BGM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: $isBGMEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }

            // 如果BGM启用，显示音量控制和选择器
            if isBGMEnabled && !isLoading {
                // 音量控制
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: bgmVolume == 0 ? "speaker.slash" : "speaker.wave.2")
                            .foregroundColor(.gray)
                            .frame(width: 24)

                        Slider(value: $bgmVolume, in: 0...1, step: 0.05)
                            .accentColor(.blue)

                        Text("\(Int(bgmVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                // BGM选择按钮
                Button(action: {
                    showBGMList.toggle()
                }) {
                    HStack {
                        Image(systemName: "music.note.list")
                            .foregroundColor(.blue)

                        Text("选择背景音乐")
                            .foregroundColor(.blue)

                        Spacer()

                        if let selectedBGM = selectedBGM {
                            Text(selectedBGM.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }

                // BGM加载状态
                if bgmManager.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("加载BGM中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let error = bgmManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            } else if isBGMEnabled && isLoading {
                // 正在加载音频数据
                HStack {
                    ProgressView()
                    Text("正在处理音频...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .sheet(isPresented: $showBGMList) {
            BGMListView(
                availableBGM: bgmManager.availableBGM,
                selectedBGM: $selectedBGM,
                isPresented: $showBGMList
            )
        }
        .onAppear {
            // 初次加载时获取BGM
            if bgmManager.availableBGM.isEmpty && !bgmManager.isLoading {
                Task {
                    await bgmManager.loadAvailableBGM()
                }
            }
        }
    }
}

/// BGM列表视图
struct BGMListView: View {
    let availableBGM: [BGM]
    @Binding var selectedBGM: BGM?
    @Binding var isPresented: Bool

    @State private var searchText = ""

    var filteredBGM: [BGM] {
        if searchText.isEmpty {
            return availableBGM
        } else {
            return availableBGM.filter { bgm in
                bgm.displayName.localizedCaseInsensitiveContains(searchText) ||
                bgm.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                if availableBGM.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("没有可用的BGM")
                            .foregroundColor(.secondary)
                        Text("请将音频文件放置在 bgm 文件夹中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if filteredBGM.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("未找到匹配的BGM")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(filteredBGM) { bgm in
                        BGMListRowView(
                            bgm: bgm,
                            isSelected: selectedBGM?.id == bgm.id,
                            onSelect: {
                                selectedBGM = bgm
                                isPresented = false
                            }
                        )
                    }
                }
            }
            .navigationTitle("选择背景音乐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索BGM")
        }
    }
}

/// BGM列表行视图
struct BGMListRowView: View {
    let bgm: BGM
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 左侧图标
                VStack {
                    Image(systemName: "music.note")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title3)
                }
                .frame(width: 36)

                // BGM信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(bgm.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("时长: \(bgm.formattedDuration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 选择标记
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct BGMSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BGMSelectorView(
                selectedBGM: .constant(BGM(
                    name: "bgm1",
                    displayName: "背景音乐1",
                    url: URL(fileURLWithPath: "/tmp/bgm1.mp3"),
                    duration: 120
                )),
                isBGMEnabled: .constant(true),
                bgmVolume: .constant(0.7),
                isLoading: .constant(false)
            )

            BGMSelectorView(
                selectedBGM: .constant(nil),
                isBGMEnabled: .constant(false),
                bgmVolume: .constant(0),
                isLoading: .constant(false)
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif