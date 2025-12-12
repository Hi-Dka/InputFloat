//
//  InputMethodMonitor.swift
//  InputFloat
//

import Foundation
import Carbon
import Combine
import IOKit
import AppKit

class InputMethodMonitor: ObservableObject {
    @Published var currentInputSource: String = ""
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private let enableDebugLog = false
    
    init() {
        updateCurrentInputSource()
        setupInputSourceNotification()
        setupKeyboardEventMonitor()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func updateCurrentInputSource() {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            currentInputSource = "Unknown"
            return
        }
        
        var sourceID = ""
        if let id = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            sourceID = Unmanaged<CFString>.fromOpaque(id).takeUnretainedValue() as String
        }
        
        let isASCIIMode = checkASCIIMode(inputSource: inputSource)
        
        var displayName = ""
        if let localizedName = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) {
            displayName = Unmanaged<CFString>.fromOpaque(localizedName).takeUnretainedValue() as String
        } else {
            displayName = formatInputSourceID(sourceID)
        }
        
        if isChinese(sourceID: sourceID, name: displayName) {
            
            currentInputSource = isASCIIMode ? "英" : "中"
        } else {
           
            currentInputSource = isASCIIMode ? "A" : "a"
        }
        
       
        #if DEBUG
        if enableDebugLog {
            print("🔤 Input Source Changed:")
            print("  - ID: \(sourceID)")
            print("  - Name: \(displayName)")
            print("  - ASCII Mode: \(isASCIIMode)")
            print("  - Display: \(currentInputSource)")
        }
        #endif
    }
    
   
    private func formatInputSourceID(_ id: String) -> String {
        if id.contains("Pinyin") {
            return "中文（拼音）"
        } else if id.contains("Chinese") {
            return "中文"
        } else if id.contains("com.apple.keylayout.US") {
            return "英文（US）"
        } else if id.contains("ABC") {
            return "ABC"
        } else {
           
            if let lastComponent = id.components(separatedBy: ".").last {
                return lastComponent
            }
            return id
        }
    }
    
   
    private func setupInputSourceNotification() {
        let center = DistributedNotificationCenter.default()
        
        center.addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name("AppleSelectedInputSourcesChangedNotification"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        
        center.addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"),
            object: nil
        )
    }
    
    private var lastInputSourceID = ""
    private var lastCapsLockState = false
    
    private func setupKeyboardEventMonitor() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkAndUpdateIfNeeded()
        }
    }
    
    private func checkAndUpdateIfNeeded() {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return
        }
        
        var currentSourceID = ""
        if let id = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            currentSourceID = Unmanaged<CFString>.fromOpaque(id).takeUnretainedValue() as String
        }
        
        let currentCapsLockState = getCapsLockLEDState()
        
        if currentSourceID != lastInputSourceID || currentCapsLockState != lastCapsLockState {
            lastInputSourceID = currentSourceID
            lastCapsLockState = currentCapsLockState
            
            DispatchQueue.main.async {
                self.updateCurrentInputSource()
            }
        }
    }
    
    private func getCapsLockLEDState() -> Bool {
        let flags = NSEvent.modifierFlags
        let capsLockOn = flags.contains(.capsLock)
        return capsLockOn
    }
    
    @objc private func inputSourceChanged() {
        DispatchQueue.main.async {
            self.updateCurrentInputSource()
        }
    }
    
    func stopMonitoring() {
        DistributedNotificationCenter.default().removeObserver(self)
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
    }
    
    private func isChinese(sourceID: String, name: String) -> Bool {
        return sourceID.contains("Pinyin") ||
               sourceID.contains("Chinese") ||
               sourceID.contains("Wubi") ||
               sourceID.contains("Shuangpin") ||
               sourceID.contains("com.apple.inputmethod.SCIM") ||
               sourceID.contains("com.sogou") ||
               sourceID.contains("com.baidu") ||
               name.contains("拼音") ||
               name.contains("中文") ||
               name.contains("简体") ||
               name.contains("繁体")
    }
    
    private func checkASCIIMode(inputSource: TISInputSource) -> Bool {
        var sourceID = ""
        if let idRef = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            sourceID = Unmanaged<CFString>.fromOpaque(idRef).takeUnretainedValue() as String
        }

        if sourceID.contains("keylayout") && !sourceID.contains("inputmethod") {
            let capsLockOn = getCapsLockLEDState()
            return capsLockOn
        }

        if let typeRef = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceType) {
            let type = Unmanaged<CFString>.fromOpaque(typeRef).takeUnretainedValue() as String
            if type == (kTISTypeKeyboardLayout as String) {
                return true
            }
        }
        
        if sourceID.contains("SCIM") || sourceID.contains("Pinyin") || sourceID.contains("Chinese") {
            let capsLockOn = getCapsLockLEDState()
            return capsLockOn
        }
        
        return false
    }
    
    private func findInputSourceByID(_ id: String) -> TISInputSource? {
        let properties = [kTISPropertyInputSourceID: id] as CFDictionary
        if let sources = TISCreateInputSourceList(properties, false)?.takeRetainedValue() as? [TISInputSource],
           let first = sources.first {
            return first
        }
        return nil
    }
}
