//
//  Updater.swift
//  Example
//
//  Created by VG on 18.12.2020.
//  Copyright © 2020 GORA Studio. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
import CoreVideo
#endif

final class Updater {
    
    #if canImport(UIKit)
    // iOS implementation using CADisplayLink
    private lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.isPaused = true
        displayLink.add(to: .main, forMode: .common)
        return displayLink
    }()
    
    var preferredUpdatesPerSecond: Int {
        get { displayLink.preferredFramesPerSecond }
        set { displayLink.preferredFramesPerSecond = newValue }
    }
    
    var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }
    
    func invalidate() { displayLink.invalidate() }
    
    @objc func update() { onUpdate?() }
    
    #elseif os(macOS)
    // macOS implementation using CVDisplayLink
    private var displayLink: CVDisplayLink?
    private var _isPaused: Bool = true
    private var _preferredUpdatesPerSecond: Int = 60
    
    var preferredUpdatesPerSecond: Int {
        get { _preferredUpdatesPerSecond }
        set { _preferredUpdatesPerSecond = newValue }
    }
    
    var isPaused: Bool {
        get { _isPaused }
        set {
            _isPaused = newValue
            if let displayLink = displayLink {
                if newValue {
                    CVDisplayLinkStop(displayLink)
                } else {
                    CVDisplayLinkStart(displayLink)
                }
            } else if !newValue {
                setupDisplayLink()
            }
        }
    }
    
    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        
        guard let displayLink = link else { return }
        self.displayLink = displayLink
        
        let opaquePointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext) -> CVReturn in
            let updater = Unmanaged<Updater>.fromOpaque(displayLinkContext!).takeUnretainedValue()
            DispatchQueue.main.async {
                updater.onUpdate?()
            }
            return kCVReturnSuccess
        }, opaquePointer)
        
        if !_isPaused {
            CVDisplayLinkStart(displayLink)
        }
    }
    
    func invalidate() {
        guard let displayLink = displayLink else { return }
        CVDisplayLinkStop(displayLink)
        self.displayLink = nil
    }
    #endif
    
    var onUpdate: (() -> Void)?
    
    deinit {
        invalidate()
    }
}
