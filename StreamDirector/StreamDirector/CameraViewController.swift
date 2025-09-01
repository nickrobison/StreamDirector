//
//  CameraViewController.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import Foundation
import WebRTC

class CameraViewController: ObservableObject {
    
    @Published var isConnected: Bool = false
    @Published var hasRemoteSdp: Bool = false
    @Published var remoteVideoTrack: RTCVideoTrack?
    
    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    
    init(signalClient: SignalingClient, webRTCClient: WebRTCClient) {
        self.signalClient = signalClient
        self.webRTCClient = webRTCClient
        
        self.signalClient.delegate = self
        self.webRTCClient.delegate = self
        self.signalClient.connect()
    }
}

extension CameraViewController: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        debugPrint("I'm connected!")
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            debugPrint("signalClient did received sdp")
            DispatchQueue.main.async {
                self.hasRemoteSdp = true
            }
            
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        print("Received remote candidate. What do I do with this?")
    }
}

extension CameraViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        debugPrint("discovered local candidate: \(candidate)")
        self.signalClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        debugPrint("Connection state changed: \(state)")
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes"
        debugPrint("Received data: \(message)")
    }
    
    
}
