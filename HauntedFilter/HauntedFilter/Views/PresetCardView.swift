import SwiftUI

/// 单个预设卡片 — 设计规格：140×180pt，黑白科技感
struct PresetCardView: View {
    let preset: VideoPreset
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 14) {
            // 顶部：英文名 SF Mono
            Text(preset.englishName)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(Color(hex: "#888888"))
                .padding(.top, 16)

            // 中间：图标
            Image(systemName: preset.iconName)
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(isSelected ? .white : Color(hex: "#555555"))
                .frame(height: 50)

            // 底部：中文名
            Text(preset.displayName)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(isSelected ? .white : Color(hex: "#888888"))
                .padding(.bottom, 16)
        }
        .frame(width: 140, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#0A0A0A"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.white : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .opacity(isSelected ? 1.0 : 0.5)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    HStack(spacing: 12) {
        PresetCardView(preset: .basement, isSelected: true)
        PresetCardView(preset: .vhs, isSelected: false)
        PresetCardView(preset: .signal, isSelected: false)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}