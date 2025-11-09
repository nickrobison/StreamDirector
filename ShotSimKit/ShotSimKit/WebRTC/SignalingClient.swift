//
//  SignalingClient.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//
import Foundation
import WebRTC
import SDKit
// FIXME: Ok, this is nonsense.
import SDMacros

fileprivate let signalingServerUrl = Foundation.URL(string: "ws://localhost")!

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
        debugPrint("Calling connect to server: \(signalingServerUrl)")
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
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        let payload = Message.candidate(IceCandidate.init(from: rtcIceCandidate, id: connectionId))
        let message = SignalingMessage(from: connectionId, to: nil, data: payload, type: "candidate")
        debugPrint("Sending candidate: \(message)")
        do {
            let dataMessage = try self.encoder.encode(message)
            self.webSocket.send(data: dataMessage)
        } catch {
            debugPrint("Warning: Could not encode candidate: \(error)")
        }
    }
}

extension SignalingClient: WebSocketProviderDelegate {
    
    func webSocketDidConnect(_ webSocket: WebSocketProvider) {
        debugPrint("webSocketDidConnect")
        self.delegate?.signalClientDidConnect(self)
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider) {
        debugPrint("webSocketDidDisconnect")
        self.delegate?.signalClientDidDisconnect(self)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            debugPrint("Trying to reconnet to signalling client")
            self.webSocket.connect()
        }
    }
    
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data) {
        debugPrint("webSocket did receive data")
        let message: SignalingMessage
        do {
            message = try self.decoder.decode(SignalingMessage.self, from: data)
        } catch {
            debugPrint("Warning: Could not decode incoming message: \(error)")
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
            debugPrint("Warning: Could not decode incoming message: \(error)")
            return
        }
        
        switch message.data {
        case .sdp(let sessionDescription) where sessionDescription.type == .answer:
            debugPrint("I have an answer: \(message)")
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
        case .sdp(_): break
            
        case .candidate(let iceCandidate):
            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
        }
    }
    
    
}
