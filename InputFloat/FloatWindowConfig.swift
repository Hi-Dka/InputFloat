//
//  FloatWindowConfig.swift
//  InputFloat
//

import SwiftUI
import Combine

enum FontSizeOption: String, CaseIterable, Identifiable {
    case small = "小"
    case medium = "中"
    case large = "大"
    
    var id: String { rawValue }
    
    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        }
    }
}

struct InputColorScheme: Identifiable, Equatable {
    let id = UUID()
    let foreground: Color
    let background: Color
    let name: String
    
    static let presets: [InputColorScheme] = [
        InputColorScheme(foreground: Color(hex: "#FFF"), background: Color(hex: "#000"), name: "经典黑白"),
        InputColorScheme(foreground: Color(hex: "#FFF"), background: Color(hex: "#ef233c"), name: "活力红"),
        InputColorScheme(foreground: Color(hex: "#FFF"), background: Color(hex: "#f77f00"), name: "热情橙"),
        InputColorScheme(foreground: Color(hex: "#000"), background: Color(hex: "#F6CB56"), name: "明亮黄"),
        InputColorScheme(foreground: Color(hex: "#FFF"), background: Color(hex: "#2c6e49"), name: "自然绿"),
        InputColorScheme(foreground: Color(hex: "#FFF"), background: Color(hex: "#0c7489"), name: "清新蓝"),
        InputColorScheme(foreground: Color(hex: "#FFF"), background: Color(hex: "#023e8a"), name: "深海蓝"),
        InputColorScheme(foreground: Color(hex: "#FFF"), background: Color(hex: "#7209b7"), name: "神秘紫"),
    ]
}

/// Color 扩展：从 Hex 创建颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// 配置存储模块 - 使用 UserDefaults 保存用户偏好
class FloatWindowConfig: ObservableObject {
    static let shared = FloatWindowConfig()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let windowX = "windowX"
        static let windowY = "windowY"
        static let windowWidth = "windowWidth"
        static let windowHeight = "windowHeight"
        static let fontSize = "fontSize"
        static let textColor = "textColor"
        static let backgroundColor = "backgroundColor"
        static let opacity = "opacity"
        static let autoStart = "autoStart"
        static let cornerRadius = "cornerRadius"
    }
    
    @Published var windowX: CGFloat {
        didSet { defaults.set(Double(windowX), forKey: Keys.windowX) }
    }
    
    @Published var windowY: CGFloat {
        didSet { defaults.set(Double(windowY), forKey: Keys.windowY) }
    }
    
    @Published var windowWidth: CGFloat {
        didSet { defaults.set(Double(windowWidth), forKey: Keys.windowWidth) }
    }
    
    @Published var windowHeight: CGFloat {
        didSet { defaults.set(Double(windowHeight), forKey: Keys.windowHeight) }
    }
    
    @Published var fontSize: CGFloat {
        didSet {
            defaults.set(Double(fontSize), forKey: Keys.fontSize)
            let padding: CGFloat = 10
            let newSize = fontSize + padding * 2
            windowWidth = newSize
            windowHeight = newSize
        }
    }
    
    @Published var textColor: Color {
        didSet { saveColor(textColor, forKey: Keys.textColor) }
    }
    
    @Published var backgroundColor: Color {
        didSet { saveColor(backgroundColor, forKey: Keys.backgroundColor) }
    }
    
    @Published var opacity: Double {
        didSet { defaults.set(opacity, forKey: Keys.opacity) }
    }
    
    var cornerRadius: CGFloat {
        switch fontSize {
        case 0..<20:
            return 3
        case 20..<30:
            return 4
        case 30..<50:
            return 6
        default:
            return 8
        }
    }
    
    @Published var autoStart: Bool {
        didSet {
            defaults.set(autoStart, forKey: Keys.autoStart)
            toggleLoginItem(enabled: autoStart)
        }
    }
    
    private init() {
        let loadedWindowX = CGFloat(defaults.double(forKey: Keys.windowX) != 0 ? defaults.double(forKey: Keys.windowX) : 100)
        let loadedWindowY = CGFloat(defaults.double(forKey: Keys.windowY) != 0 ? defaults.double(forKey: Keys.windowY) : 100)
        let loadedWindowWidth = CGFloat(defaults.double(forKey: Keys.windowWidth) != 0 ? defaults.double(forKey: Keys.windowWidth) : 200)
        let loadedWindowHeight = CGFloat(defaults.double(forKey: Keys.windowHeight) != 0 ? defaults.double(forKey: Keys.windowHeight) : 50)
        let loadedFontSize = CGFloat(defaults.double(forKey: Keys.fontSize) != 0 ? defaults.double(forKey: Keys.fontSize) : 26)
        let loadedOpacity = defaults.double(forKey: Keys.opacity) != 0 ? defaults.double(forKey: Keys.opacity) : 0.9
        let loadedAutoStart = defaults.bool(forKey: Keys.autoStart)
        
        let loadedTextColor: Color
        let loadedBackgroundColor: Color
        
        #if os(macOS)
        if let colorData = defaults.data(forKey: Keys.textColor),
           let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            loadedTextColor = Color(nsColor)
        } else {
            loadedTextColor = .white
        }
        
        if let colorData = defaults.data(forKey: Keys.backgroundColor),
           let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            loadedBackgroundColor = Color(nsColor)
        } else {
            loadedBackgroundColor = .black
        }
        #else
        loadedTextColor = .white
        loadedBackgroundColor = .black
        #endif
        
        self.windowX = loadedWindowX
        self.windowY = loadedWindowY
        self.windowWidth = loadedWindowWidth
        self.windowHeight = loadedWindowHeight
        self.fontSize = loadedFontSize
        self.opacity = loadedOpacity
        // cornerRadius 现在是计算属性，不需要初始化
        self.autoStart = loadedAutoStart
        self.textColor = loadedTextColor
        self.backgroundColor = loadedBackgroundColor
    }
    
    private func saveColor(_ color: Color, forKey key: String) {
        #if os(macOS)
        let nsColor = NSColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            defaults.set(colorData, forKey: key)
        }
        #endif
    }
    
    private func loadColor(forKey key: String, default defaultColor: Color) -> Color {
        #if os(macOS)
        guard let colorData = defaults.data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
            return defaultColor
        }
        return Color(nsColor)
        #else
        return defaultColor
        #endif
    }
    
    private func toggleLoginItem(enabled: Bool) {
        #if os(macOS)
        if #available(macOS 13.0, *) {
            // Login Item
        }
        #endif
    }
    
    func resetToDefaults() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let defaultFontSize: CGFloat = 18
        let padding: CGFloat = 20
        let defaultSize = defaultFontSize + padding * 2
        let margin: CGFloat = 20
        
        windowX = screenFrame.maxX - defaultSize - margin
        windowY = screenFrame.minY + margin
        fontSize = defaultFontSize
        textColor = .white
        backgroundColor = .black
        opacity = 1
        autoStart = false
    }
}
