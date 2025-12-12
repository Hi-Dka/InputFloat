//
//  FloatingWindow.swift
//  InputFloat
//

import SwiftUI
import AppKit

class FloatingWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 50),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        
        self.level = .floating
        
        self.hasShadow = true
        
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .fullScreenPrimary,
            .transient,
            .ignoresCycle
        ]
        
      
        self.isMovableByWindowBackground = true
        self.isMovable = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        
       
        self.ignoresMouseEvents = false
        
        
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = false
        self.worksWhenModal = true
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}


class FloatingWindowController: NSWindowController {
    private var monitor: InputMethodMonitor
    private var config: FloatWindowConfig
    
    init(monitor: InputMethodMonitor, config: FloatWindowConfig) {
        self.monitor = monitor
        self.config = config
        
        let window = FloatingWindow()
        super.init(window: window)
        
        let contentView = FloatingWindowView(monitor: monitor, config: config)
        window.contentView = NSHostingView(rootView: contentView)
        
        updateWindowFrame()
        
        setupConfigObservers()
        
        setupWindowMoveObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConfigObservers() {
        config.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowFrame()
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var saveWorkItem: DispatchWorkItem?
    
    private func setupWindowMoveObserver() {
        guard let window = window else { return }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.handleWindowMoved()
        }
    }
    
    private func handleWindowMoved() {
        guard let window = window else { return }
        
        saveWorkItem?.cancel()
        
        // 创建新的保存任务，延迟 0.5 秒执行
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let origin = window.frame.origin
            self.config.windowX = origin.x
            self.config.windowY = origin.y
        }
        
        saveWorkItem = workItem
        
        // 延迟 0.5 秒后保存（防抖）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func updateWindowFrame() {
        guard let window = window else { return }
        
        let newFrame = NSRect(
            x: config.windowX,
            y: config.windowY,
            width: config.windowWidth,
            height: config.windowHeight
        )
        
        window.setFrame(newFrame, display: true)
    }
    
    func show() {
        guard let window = window else { return }
        
        window.orderFrontRegardless()
        
        window.level = .popUpMenu
        
        var behavior = window.collectionBehavior
        behavior.insert(.fullScreenAuxiliary)
        behavior.insert(.fullScreenPrimary)
        behavior.insert(.canJoinAllSpaces)
        behavior.insert(.stationary)
        window.collectionBehavior = behavior
    }
}

import Combine

struct FloatingWindowView: View {
    @ObservedObject var monitor: InputMethodMonitor
    @ObservedObject var config: FloatWindowConfig
    
    var body: some View {
        let size = config.fontSize * 1.8
        let innerPadding: CGFloat = 3.3
        let outerRadius = size * 0.3
        let innerRadius = size * 0.2
        let isASpecialCase = (monitor.currentInputSource == "a")
        ZStack {
            RoundedRectangle(cornerRadius: outerRadius)
                .fill(config.backgroundColor)
                .opacity(config.opacity)
                .frame(width: size, height: size)
            
            RoundedRectangle(cornerRadius: innerRadius)
                .fill(config.textColor)
                .opacity(config.opacity)
                .frame(width: size - innerPadding * 2, height: size - innerPadding * 2)
            
            Text(monitor.currentInputSource)
                .font(.system(size: config.fontSize * 1.3, weight: .light))
                .opacity(config.opacity)
                .foregroundColor(config.backgroundColor)
                .offset(y: isASpecialCase ? -3 : 0)
        }
    }
}

struct FloatingWindowView_Previews: PreviewProvider {
    static var previews: some View {
        let monitor = InputMethodMonitor()
        let config = FloatWindowConfig.shared 
        FloatingWindowView(monitor: monitor, config: config)
            .frame(width: 200, height: 200)
            .background(Color.gray.opacity(0.2))
    }
}
