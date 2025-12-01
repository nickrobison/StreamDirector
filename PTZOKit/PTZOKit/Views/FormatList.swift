//
//  FormatList.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/30/25.
//

import SwiftUI
import CoreMedia
import SDKit
import Prefire


fileprivate struct FormatButton<Label: View>: View {
    @ViewBuilder var label: () -> Label
    
    var body: some View {
        Button(action: {}, label: label)
        .buttonStyle(.roundedRect)
    }
}


fileprivate struct ResolutionView: View {
    
    var dimensions: CMVideoDimensions
    var isProgressive: Bool
    
    private func suffix() -> String {
        return isProgressive ? "p" : "i"
    }
    
    
    var body: some View {
        FormatButton {
            Text(verbatim: "\(dimensions.height)\(suffix())")
        }
    }
}

fileprivate struct FramerateView: View {
    
    var duration: CMTime
    
    var body: some View {
        FormatButton {
            Text(verbatim: "\(duration.value)")
        }
    }
}

struct FormatList: View {
    
    // TODO: This should be configurable
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    
    
    var format: VideoFormat
    
    var body: some View {
        LazyVGrid(columns: columns) {
            ResolutionView(dimensions: format.dimensions, isProgressive: true)
            FramerateView(duration: format.frameRate)
        }
        
        
    }
}

struct FormatListPreview: PreviewProvider, PrefireProvider {
    
    static func format() -> VideoFormat {
        let cmFormat = try! CMFormatDescription.init(videoCodecType: .h264, width: 1920, height: 1080)
        
        return VideoFormat.init(from: cmFormat)
    }
    
    static var previews = FormatList(format: format())
}

