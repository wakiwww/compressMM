import SwiftUI

/// 单个预设卡片
struct PresetCardView: View {
    let preset: VideoPreset
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            // 图标
            Image(systemName: preset.iconName)
                .font(.system(size: 36))
                .foregroundColor(isSelected ? .red : .gray)
                .frame(height: 50)

            // 名称
            Text(preset.displayName)
                .font(.headline)
                .foregroundColor(.white)

            // 描述
            Text(preset.subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 130, height: 150)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    HStack {
        PresetCardView(preset: .oldPhone, isSelected: true)
        PresetCardView(preset: .vhs, isSelected: false)
        PresetCardView(preset: .cctv, isSelected: false)
    }
    .padding()
    .background(Color.black)
    .previewLayout(.sizeThatFits)
}