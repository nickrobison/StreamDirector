//
//  NativeWebSocket.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import Foundation

class NativeWebSocket: NSObject, WebSocketProvider {
    
    public var delegate: WebSocketProviderDelegate?
    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private lazy var urlSession: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    public func connect() {
        debugPrint("Let's connect to \(url), maybe?")
        let socket = urlSession.webSocketTask(with: url)
        socket.resume()
        self.socket = socket
        self.readMessage()
    }
    
    public func send(data: Data) {
        self.socket?.send(.data(data)) { error in
            if let error {
                debugPrint("Error when sending: \(error)")
            }
        }
    }
    
    private func readMessage() {
        self.socket?.receive { [weak self] message in
            guard let self = self else { return}
            
            switch message {
            case .success(.data(let data)):
                self.delegate?.webSocket(self, didReceiveData: data)
                self.readMessage()
            case .success(.string(let msgString)):
                self.delegate?.webSocket(self, didReceiveMessage: msgString)
                self.readMessage()
            case .success:
                debugPrint("Should have received something intersting, but got \(message).")
            case .failure(let failure):
                debugPrint("I'm a failure: \(failure)")
                self.disconnect()
            }
        }
    }
    
    private func disconnect() {
        self.socket?.cancel()
        self.socket = nil
        self.delegate?.webSocketDidDisconnect(self)
    }
}

extension NativeWebSocket: URLSessionWebSocketDelegate, URLSessionDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
            self.delegate?.webSocketDidConnect(self)
        }
        
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            self.disconnect()
        }
}
