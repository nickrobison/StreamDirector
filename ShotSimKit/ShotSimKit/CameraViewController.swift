//
//  CameraViewController.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import Foundation
import WebRTC
import Combine

// TODO: Observable macro
public class CameraViewController: ObservableObject {
    
    public static func factory() -> CameraViewController {
        
        // Debug logging?
        RTCSetMinDebugLogLevel(.info)
        RTCEnableMetrics()
        
        return CameraViewController.init(signalClient: SignalingClient.defaultClient, webRTCClient: WebRTCClient.defaultClient)
    }
    
    @Published public var isConnected: Bool = false
    @Published public var hasRemoteSdp: Bool = false
    @Published public var remoteVideoTrack: RTCVideoTrack?
    
    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    private var remoteConnections = 0
    
    init(signalClient: SignalingClient, webRTCClient: WebRTCClient) {
        self.signalClient = signalClient
        self.webRTCClient = webRTCClient
        
        self.signalClient.delegate = self
        self.webRTCClient.delegate = self
        self.signalClient.connect()
    }
    
    public func listStreams() {
        self.webRTCClient.listStreams()
    }
}

extension CameraViewController: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        debugPrint("I'm connected!")
        DispatchQueue.main.async {
            self.isConnected = true
            self.webRTCClient.offer { session in
                self.signalClient.send(sdp: session, type: "offer")
            }
        }
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        debugPrint("Received remote sdp: \(sdp.sdp)")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            debugPrint("signalClient did received sdp: \(String(describing: error))")
            DispatchQueue.main.async {
                self.hasRemoteSdp = true
                self.webRTCClient.setupConnection()
                self.webRTCClient.startVideo()
                self.remoteVideoTrack = self.webRTCClient.remoteVideoTrack
                
            }
            
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        debugPrint("I have a remote candidate, I think?")
        self.webRTCClient.set(remoteCandidate: candidate) { error in
            debugPrint("Ok, remote set. Now what?. erro: \(error)")
            // Do the offer
            self.webRTCClient.offer { session in
                debugPrint("Here's my offer: \(session)")
                self.signalClient.send(sdp: session, type: "offer")
            }
        }
        
    }
}

extension CameraViewController: WebRTCClientDelegate {

    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        debugPrint("discovered local candidate: \(candidate)")
        self.signalClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        debugPrint("WebRTCDelegate state changed: \(state.stringValue)")
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes"
        debugPrint("Received data: \(message)")
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceive track: RTCVideoTrack) {
        DispatchQueue.main.async {
            self.remoteVideoTrack = track
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didCreateOffer offer: RTCSessionDescription) {
        self.signalClient.send(sdp: offer, type: "offer")
    }
    
    func webRTCClient(_ client: WebRTCClient, didCreateAnswer answer: RTCSessionDescription) {
        self.signalClient.send(sdp: answer, type: "answer")
    }
}
