//
//  SignalingClient.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//
import Foundation
import WebRTC
import SDKit
import OSLog

fileprivate let signalingServerUrl = URL(string: "ws://localhost")!
fileprivate let logger = Logger.init(subsystem: "com.nickrobison.ShotSimKit.SignalingClient", category: "shotSimKit.webrtc")

protocol SignalClientDelegate: AnyObject {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingClient {
    
    public static let defaultClient: SignalingClient = {
        let webSocketProvider: WebSocketProvider
        
        if #available(iOS 13.0, *) {
            webSocketProvider = NativeWebSocket(url: signalingServerUrl)
        } else {
            webSocketProvider = StarscreamWebSocket(url: signalingServerUrl)
        }
        return SignalingClient(webSocket: webSocketProvider)
    }()
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let webSocket: WebSocketProvider
    private let connectionId: UUID = UUID()
    weak var delegate: SignalClientDelegate?
    
    init(webSocket: WebSocketProvider) {
        self.webSocket = webSocket
    }
    
    func connect() {
        logger.info("Calling connect to server: \(signalingServerUrl)")
        self.webSocket.delegate = self
        self.webSocket.connect()
    }
    
    func send(sdp rtcSdp: RTCSessionDescription, type: String) {
        let payload = Message.sdp(SessionDescription(from: rtcSdp, id: connectionId))
        // FIXME: Convenience constructor?
        let message = SignalingMessage(from: connectionId, to: nil, data: payload, type: type)
        do {
            let dataMessage = try self.encoder.encode(message)
            
            self.webSocket.send(data: dataMessage)
        } catch {
            logger.error("Could not encode sdp: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        let payload = Message.candidate(IceCandidate.init(from: rtcIceCandidate, id: connectionId))
        let message = SignalingMessage(from: connectionId, to: nil, data: payload, type: "candidate")
        logger.trace("Sending candidate: \(message)")
        do {
            let dataMessage = try self.encoder.encode(message)
            self.webSocket.send(data: dataMessage)
        } catch {
            logger.error("Could not encode candidate: \(error)")
        }
    }
}

extension SignalingClient: WebSocketProviderDelegate {
    
    func webSocketDidConnect(_ webSocket: WebSocketProvider) {
        logger.debug("webSocketDidConnect")
        self.delegate?.signalClientDidConnect(self)
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider) {
        logger.debug("webSocketDidDisconnect")
        self.delegate?.signalClientDidDisconnect(self)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            logger.debug("Trying to reconnet to signalling client")
            self.webSocket.connect()
        }
    }
    
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data) {
        logger.debug("webSocket did receive data")
        let message: SignalingMessage
        do {
            message = try self.decoder.decode(SignalingMessage.self, from: data)
        } catch {
            logger.error("Could not decode incoming message: \(error)")
            return
        }
        
        switch message.data {
        case .sdp(let sessionDescription):
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
        case .candidate(let iceCandidate):
            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
        }
    }
    
    func webSocket(_ webSocket: WebSocketProvider, didReceiveMessage msg: String) {
        let message: SignalingMessage
        do {
            let jsonData = msg.data(using: .utf8)!
            message = try self.decoder.decode(SignalingMessage.self, from: jsonData)
        } catch {
            logger.error("Warning: Could not decode incoming message: \(error)")
            return
        }
        
        switch message.data {
        case .sdp(let sessionDescription) where sessionDescription.type == .answer:
            logger.debug("I have an answer: \(message)")
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
        case .sdp(_): break
            
        case .candidate(let iceCandidate):
            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
        }
    }
    
    
}
