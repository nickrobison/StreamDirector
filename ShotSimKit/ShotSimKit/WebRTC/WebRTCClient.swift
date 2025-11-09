//
//  WebRTCClient.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import Foundation
import WebRTC

private let defaultIceServers = ["stun:stun.l.google.com:19302"]

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(
        _ client: WebRTCClient,
        didDiscoverLocalCandidate candidate: RTCIceCandidate
    )
    func webRTCClient(
        _ client: WebRTCClient,
        didChangeConnectionState state: RTCIceConnectionState
    )
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, didReceive track: RTCVideoTrack)
    func webRTCClient(
        _ client: WebRTCClient,
        didCreateOffer offer: RTCSessionDescription
    )
    func webRTCClient(
        _ client: WebRTCClient,
        didCreateAnswer answer: RTCSessionDescription
    )
    //    func webRTCClient(_ client: WebRTCClient, shouldNegotiate: String)
}

final class WebRTCClient: NSObject {

    public static let defaultClient: WebRTCClient = {
        return WebRTCClient(iceServers: defaultIceServers)
    }()

    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        // Do we really need this?
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        videoEncoderFactory.preferredCodec = RTCVideoCodecInfo(
            name: kRTCVideoCodecH264Name
        )
        videoEncoderFactory.preferredCodec = RTCVideoCodecInfo(
            name: kRTCVideoCodecVp9Name
        )
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }()

    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private let mediaConstraints = [
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueFalse,
    ]
    private var videoCapturer: RTCVideoCapturer?
    // FIXME: Shouldn't just leak this out
    var remoteVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    private var signalingState: RTCSignalingState = .closed

    required init(iceServers: [String]) {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]

        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        // Define media constraints. DtlsSrtpKeyAgreement is required to be true to be able to connect with web browsers.
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
            ]
        )

        guard
            let peerConnection = WebRTCClient.factory.peerConnection(
                with: config,
                constraints: constraints,
                delegate: nil
            )
        else {
            fatalError("Could not create new RTCPeerConnection")
        }
        self.peerConnection = peerConnection
        super.init()
        self.createMediaSenders()
        self.setupConnection()
        self.peerConnection.delegate = self
    }

    private func createMediaSenders() {
        //        let transceiverInit = RTCRtpTransceiverInit()
        //        transceiverInit.direction = .recvOnly
        //        self.peerConnection.addTransceiver(of: .video, init: transceiverInit)
    }

    func set(
        remoteSdp: RTCSessionDescription,
        completion: @escaping (Error?) -> Void
    ) {
        if remoteSdp.type == .offer {
            debugPrint("WebRTC received offer sdp")
            //            self.signalingState = .haveRemoteOffer
            self.peerConnection.setRemoteDescription(remoteSdp) { error in
                if error == nil {
                    self.createAnswer()
                }
                completion(error)
            }
        } else if remoteSdp.type == .answer {
            debugPrint("WebRTC received answer sdp")
            self.peerConnection.setRemoteDescription(
                remoteSdp,
                completionHandler: completion
            )
            //            self.signalingState = .stable
        }
    }

    private func createAnswer() {
        // FIXME: Get rid of this, I think.
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
            ]
        )
        self.peerConnection.answer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(
                sdp,
                completionHandler: { error in
                    self.delegate?.webRTCClient(self, didCreateAnswer: sdp)
                }
            )
        }
    }

    public func listStreams() {
        self.peerConnection.statistics { (stats) in
            debugPrint("I have stats: \(stats.description)")
            for stat in stats.statistics {
                debugPrint("Stat: \(stat.value.type)")
                if stat.value.type == "peer-connection" {
                    debugPrint("Peers: \(stat.value.values)")
                }
                if stat.value.type == "transport" {
                    debugPrint("Transport: \(stat.value.values)")
                }
                if stat.value.type == "candidate-pair" {
                    debugPrint("Pairs: \(stat.value.values)")
                }
            }
        }

        for rcvr in self.peerConnection.receivers {
            debugPrint("Peer receiver: \(rcvr)")
            let tsend = rcvr.track as! RTCVideoTrack
            debugPrint("Rcvr track: \(rcvr.track)")
            debugPrint(
                "Receiver state!!: \(tsend.readyState) -> \(tsend.source.state)"
            )
        }

        debugPrint("Listing active streams?")
        for txcvr in self.peerConnection.transceivers {
            debugPrint(
                "Track: \(txcvr.description). Direction: \(txcvr.direction.stringValue)"
            )
            debugPrint("MID: \(txcvr.mid)")
            debugPrint("rec: \(txcvr.receiver)")
            debugPrint("send: \(txcvr.sender)")
            debugPrint("Track media type: \(txcvr.mediaType)")
            if txcvr.mediaType == .video {
                let vtc = txcvr.receiver.track as! RTCVideoTrack
                self.peerConnection.stats(
                    for: vtc,
                    statsOutputLevel: .debug,
                    completionHandler: { (stats) -> Void in
                        for s in stats {
                            debugPrint(
                                "Steam id \(s.reportId). \(s.description). \(s.type)"
                            )
                            for v in s.values {
                                debugPrint("Stream stat: \(v)")
                            }

                        }
                    }
                )
                debugPrint("What's going on? \(vtc.trackId)")
                debugPrint("Enabled? \(vtc.isEnabled)")
                debugPrint("State: \(vtc.readyState) -> \(vtc.source.state)")
            }

            let tracks = self.peerConnection.transceivers.compactMap {
                $0.receiver.track
            }

            for t in tracks {
                debugPrint("Transceiver track: \(t)")
            }

            // Probably bad
            self.remoteVideoTrack =
                self.peerConnection.transceivers.first {
                    $0.mediaType == .video
                }?.receiver.track as? RTCVideoTrack
            debugPrint("Did it work? \(self.remoteVideoTrack)")

        }
    }

    func set(
        remoteCandidate: RTCIceCandidate,
        completion: @escaping (Error?) -> Void
    ) {
        debugPrint("remoteSdp add remote candidate \(remoteCandidate)")
        if (self.signalingState == .stable || self.signalingState == .haveRemoteOffer) {
                    self.peerConnection.add(remoteCandidate, completionHandler: completion)
        } else {
            completion(nil)
        }
        

    }

    public func offer(
        completion: @escaping (_ sdp: RTCSessionDescription) -> Void
    ) {

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: self.mediaConstraints,
            optionalConstraints: nil
        )

        debugPrint("Offering: \(constraints)")

        self.peerConnection.offer(for: constraints) { (sdp, error) in

            guard let sdp else {

                return

            }

            debugPrint("Setting local description to \(sdp)")

            self.peerConnection.setLocalDescription(
                sdp,
                completionHandler: { error in

                    debugPrint("Done setting local")

                    if let error {

                        debugPrint("Hmm.... \(error) on set local description")

                    }

                    completion(sdp)

                }
            )

        }

    }

    public func answer(
        completion: @escaping (_ sdp: RTCSessionDescription) -> Void
    ) {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: self.mediaConstraints,
            optionalConstraints: nil
        )
        debugPrint("Creating answer")
        self.peerConnection.answer(for: constraints) { (sdp, error) in
            guard let sdp else {
                return
            }

            debugPrint("Setting local description to \(sdp)")

            self.peerConnection.setLocalDescription(
                sdp,
                completionHandler: { error in
                    debugPrint("Done setting local")
                    if let error {
                        debugPrint("Hmm.... \(error) on set local description")
                    }
                    completion(sdp)
                }
            )
        }
    }

    public func setupConnection() {
        // Remote video
        self.remoteVideoTrack =
            self.peerConnection.transceivers.first { $0.mediaType == .video }?
            .receiver.track as? RTCVideoTrack

        debugPrint("Track? \(String(describing: self.remoteVideoTrack))")

        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }

    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard
            let dataChannel = self.peerConnection.dataChannel(
                forLabel: "webRtc",
                configuration: config
            )
        else {
            debugPrint("Couldn't create data channel. Awesome")
            return nil
        }
        return dataChannel

    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange stateChanged: RTCSignalingState
    ) {
        debugPrint(
            "peerConnection new signaling state: \(stateChanged.stringValue) from \(self.signalingState.stringValue)"
        )
        self.signalingState = stateChanged
    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd stream: RTCMediaStream
    ) {
        debugPrint("peerConnection did add stream")
    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove stream: RTCMediaStream
    ) {
        debugPrint("peerConnection did remove stream")
    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceConnectionState
    ) {
        debugPrint(
            "peerConnection new connection state: \(newState.stringValue)"
        )
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didStartReceivingOn transceiver: RTCRtpTransceiver
    ) {
        debugPrint("WebRTCClient: didStartReceivingOn")
        if transceiver.mediaType == .video {
            guard let track = transceiver.receiver.track as? RTCVideoTrack
            else {
                debugPrint("Cannot get video track")
                return
            }
            self.delegate?.webRTCClient(self, didReceive: track)
        }
    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceGatheringState
    ) {
        debugPrint("peerConnection new gathering state: \(newState.stringValue)")
    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    ) {
        debugPrint("peerConnection new ice candidate: \(candidate)")
        if self.signalingState == .closed {
            debugPrint("Acknowledge new candidate")
            self.delegate?.webRTCClient(
                self,
                didDiscoverLocalCandidate: candidate
            )
        }

    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove candidates: [RTCIceCandidate]
    ) {
        debugPrint("peerConnection did remove candidate(s)")
    }

    public func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didOpen dataChannel: RTCDataChannel
    ) {
        debugPrint("peerConnection did open data channel")
        self.remoteDataChannel = dataChannel
    }

    public func peerConnectionShouldNegotiate(
        _ peerConnection: RTCPeerConnection
    ) {
        debugPrint(
            "peerConnection should negotiate in state: \(self.signalingState.stringValue)"
        )
        //        if self.signalingState == .stable {
        self.createOffer()
        //        }
    }

    private func createOffer() {
        //        self.signalingState = .haveLocalOffer
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: self.mediaConstraints,
            optionalConstraints: nil
        )
        self.peerConnection.offer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(
                sdp,
                completionHandler: { error in
                    self.delegate?.webRTCClient(self, didCreateOffer: sdp)
                }
            )
        }
    }

}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.label)")
    }

    func dataChannel(
        _ dataChannel: RTCDataChannel,
        didReceiveMessageWith buffer: RTCDataBuffer
    ) {
        debugPrint("dataChannel did receive data")
    }
}

extension WebRTCClient {
    private func setTrackEnabled<T: RTCMediaStreamTrack>(
        _ type: T.Type,
        isEnabled: Bool
    ) {

        peerConnection.transceivers.compactMap {
            return $0.sender.track as? T
        }
        .forEach { $0.isEnabled = isEnabled }
    }

    func startVideo() {
        debugPrint(
            "Remote desc: \(String(describing: self.peerConnection.remoteDescription))"
        )
        self.setVideoEnabled(true)
    }

    func stopVideo() {
        self.setVideoEnabled(false)
    }

    private func setVideoEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCVideoTrack.self, isEnabled: isEnabled)
    }
}
