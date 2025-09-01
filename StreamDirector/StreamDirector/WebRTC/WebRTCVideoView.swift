//
//  WebRTCVideoView.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import SwiftUI
import WebRTC

struct WebRTCVideoView: UIViewRepresentable {
    let videoTrack: RTCVideoTrack?
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        videoTrack?.add(view)
        return view
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {}
}
