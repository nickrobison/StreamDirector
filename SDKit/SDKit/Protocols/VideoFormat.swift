//
//  VideoFormat.swift
//  SDKit
//
//  Created by Nick Robison on 11/30/25.
//

import CoreMedia

public enum FrameLayout: Sendable {
    case progressive
    case interlacedUpper
    case interlacedLower
}

public struct VideoFormat: Sendable {
    public let dimensions: CMVideoDimensions
    public let frameRate: CMTime
    public let layout: FrameLayout
}

extension VideoFormat {
    
    public init (from description: CMVideoFormatDescription) {
        self.dimensions = description.dimensions
        self.frameRate = description.frameDuration
        // TODO: I have no idea how to get the frame information from the format description. What even is a .Value?
        self.layout = .progressive
    }
}

