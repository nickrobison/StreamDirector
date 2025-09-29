//
//  WebRTCClient.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import Foundation
import WebRTC

fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302"]

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
        func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
        func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    }

final class WebRTCClient: NSObject {
    
    public static let defaultClient: WebRTCClient = {
        return WebRTCClient(iceServers: defaultIceServers)
    }()
    
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        // Do we really need this?
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private let mediaConstraints = [kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
                                    kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue]
    private var videoCapturer: RTCVideoCapturer?
    // FIXME: Shouldn't just leak this out
    var remoteVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    required init(iceServers: [String]) {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]
        
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        
        // Define media constraints. DtlsSrtpKeyAgreement is required to be true to be able to connect with web browsers.
                let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                                      optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
                
                guard let peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
                    fatalError("Could not create new RTCPeerConnection")
                }
        self.peerConnection = peerConnection
        super.init()
        self.setupConnection()
        self.peerConnection.delegate = self
    }
    
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        debugPrint("This should be an answer, right? \(remoteSdp)")
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func doTheVideoThings() {
        debugPrint("Remote? \(String(describing: self.peerConnection.remoteDescription))")
        for tran in self.peerConnection.transceivers {
            debugPrint("One tran, two tran \(String(describing: tran.receiver.track))")
        }
        // Remote video
        self.remoteVideoTrack = self.peerConnection.transceivers.first { $0.mediaType == .video}?.receiver.track as? RTCVideoTrack
        
        debugPrint("Track? \(String(describing: self.remoteVideoTrack))")
    }
    
    func set(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> ()) {
        debugPrint("remoteSdp add remote candidate")
        self.peerConnection.add(remoteCandidate, completionHandler: completion)
    }
    
    public func offer(completion: @escaping (_ sdp: RTCSessionDescription)-> Void) -> Void {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints, optionalConstraints: nil)
        debugPrint("Offering: \(constraints)")
        self.peerConnection.offer(for: constraints) { (sdp, error) in
            guard let sdp else {
                return
            }
            
            debugPrint("Setting local description to \(sdp)")
            
            self.peerConnection.setLocalDescription(sdp, completionHandler: { error in
                debugPrint("Done setting local")
                if let error {
                    debugPrint("Hmm.... \(error) on set local description")
                }
                completion(sdp)
            })
        }
    }
    
    public func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
        debugPrint("I have an answer, right?")
    }
    
    private func setupConnection() -> Void {
        // Remote video
        self.remoteVideoTrack = self.peerConnection.transceivers.first { $0.mediaType == .video}?.receiver.track as? RTCVideoTrack
        
        debugPrint("Track? \(String(describing: self.remoteVideoTrack))")
        
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }
    
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "webRtc", configuration: config) else {
            debugPrint("Couldn't create data channel. Awesome")
            return nil
        }
        return dataChannel
        
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remove stream")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        debugPrint("peerConnection did start receiving")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        debugPrint("peerConnection new ice candidate: \(candidate)")
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
        self.remoteDataChannel = dataChannel
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }
    
    
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        debugPrint("dataChannel did receive data")
    }
}

extension WebRTCClient {
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection.transceivers.compactMap {
            return $0.sender.track as? T
        }
        .forEach{ $0.isEnabled = isEnabled}
    }
    
    func startVideo() {
        debugPrint("Remote desc: \(String(describing: self.peerConnection.remoteDescription))")
        self.setVideoEnabled(true)
    }
    
    func stopVideo() {
        self.setVideoEnabled(false)
    }
    
    private func setVideoEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCVideoTrack.self, isEnabled: isEnabled)
    }
}
