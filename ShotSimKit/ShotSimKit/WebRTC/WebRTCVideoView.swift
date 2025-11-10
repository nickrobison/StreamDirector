//
//  WebRTCVideoView.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import SwiftUI
import WebRTC
import OSLog

fileprivate let logger = Logger.init(subsystem: "com.nickrobison.ShotSimKit.WebRTCVideoView", category: "ShotSimKit.view")

#if os(iOS)
typealias ViewRepresentable = UIViewRepresentable
#else
typealias ViewRepresentable = NSViewRepresentable
#endif

public struct WebRTCVideoView: ViewRepresentable {
    public let videoTrack: RTCVideoTrack
    
    public init(_ videoTrack: RTCVideoTrack) {
        self.videoTrack = videoTrack
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    #if os(iOS)
    public func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .zero)
        view.videoContentMode = .scaleAspectFill
        logger.debug("What track? \(self.videoTrack)")
        videoTrack.add(view)
        context.coordinator.videoTrack = videoTrack
        return view
    }
    
    public func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        logger.debug("View did update")
        context.coordinator.videoTrack?.remove(uiView)
        videoTrack.add(uiView)
        context.coordinator.videoTrack = videoTrack
    }
    #else
    public func makeNSView(context: Context) -> RTCMTLNSVideoView {
        let view = RTCMTLNSVideoView()
//        view.backgroundColor = .black
//        view.videoContentMode = .scaleAspectFill
        videoTrack.add(view)
        return view
    }
    
    public func updateNSView(_ nsView: RTCMTLNSVideoView, context: Context) {}
    #endif
    
    public class Coordinator: NSObject {
        var parent: WebRTCVideoView
        var videoTrack: RTCVideoTrack?

        init(_ parent: WebRTCVideoView) {
            self.parent = parent
        }
    }
}
