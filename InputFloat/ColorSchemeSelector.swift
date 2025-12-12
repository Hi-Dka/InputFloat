//
//  ColorSchemeSelector.swift
//  InputFloat
//

import SwiftUI

struct ColorSchemeSelector: View {
    @ObservedObject var config: FloatWindowConfig
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                ForEach(0..<8) { index in
                    ColorSchemeBlock(scheme: InputColorScheme.presets[index], config: config)
                    if index != 7{
                        Spacer()
                    }
                }
            }
        }
    }
}

struct ColorSchemeBlock: View {
    let scheme: InputColorScheme
    @ObservedObject var config: FloatWindowConfig
    
    var isSelected: Bool {
        config.textColor.description == scheme.foreground.description &&
        config.backgroundColor.description == scheme.background.description
    }
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(scheme.background)
                .overlay(
                    Image(systemName: "textformat")
                        .foregroundColor(scheme.foreground)
                        .font(.system(size: 14, weight: .semibold))
                )
                .frame(width: 40, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
                .onTapGesture {
                    config.textColor = scheme.foreground
                    config.backgroundColor = scheme.background
                }
            
            Text(scheme.name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ColorSchemeSelector(config: FloatWindowConfig.shared)
        .padding()
}
