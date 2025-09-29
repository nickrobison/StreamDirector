//
//  WebRTCVideoView.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import SwiftUI
import WebRTC

public struct WebRTCVideoView: UIViewRepresentable {
    public let videoTrack: RTCVideoTrack?
    
    public init(_ videoTrack: RTCVideoTrack?) {
        self.videoTrack = videoTrack
    }
    
    public func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFill
        videoTrack?.add(view)
        return view
    }
    
    public func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {}
}
