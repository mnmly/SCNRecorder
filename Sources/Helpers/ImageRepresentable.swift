import SwiftUI

#if canImport(UIKit)
public typealias ImageRepresentable = UIImage
#elseif canImport(AppKit)
public typealias ImageRepresentable = NSImage
#endif