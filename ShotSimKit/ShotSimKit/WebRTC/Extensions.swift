//
//  Extensions.swift
//  ShotSimKit
//
//  Created by Nick Robison on 10/27/25.
//

import Foundation
import WebRTC

extension RTCIceGatheringState {
    var stringValue: String {
        switch self {
        case .new:
            "new"
        case .gathering:
            "gathering"
        case .complete:
            "complete"
        @unknown default:
            "Unknown \(self.rawValue)"
        }
    }
}

extension RTCSignalingState {
    var stringValue: String {
        switch self {
            
        case .stable:
            "stable"
        case .haveLocalOffer:
            "haveLocalOffer"
        case .haveLocalPrAnswer:
            "haveLocalPrAnswer"
        case .haveRemoteOffer:
            "haveRemoteOffer"
        case .haveRemotePrAnswer:
            "haveRemotePrAnswer"
        case .closed:
            "closed"
        @unknown default:
            "Unknown: \(self.rawValue)"
        }
    }
}

extension RTCIceConnectionState {
    var stringValue: String {
        switch self {
            
        case .new:
            "new"
        case .checking:
            "checking"
        case .connected:
            "connected"
        case .completed:
            "completed"
        case .failed:
            "failed"
        case .disconnected:
            "disconnected"
        case .closed:
            "closed"
        case .count:
            "count"
        @unknown default:
            " Unknown: \(self.rawValue)"
        }
    }
}

extension RTCRtpMediaType: @retroactive CustomDebugStringConvertible, @retroactive CustomStringConvertible {
    public var debugDescription: String {
        switch self {
        case .video: "video"
        case .audio: "audio"
        case .data:
            "data"
        case .unsupported:
            "unsupported"
        @unknown default:
            "unknown"
        }
    }
    
    public var description: String {
        debugDescription
    }
}

extension RTCSourceState: @retroactive CustomDebugStringConvertible, @retroactive CustomStringConvertible {
    public var debugDescription: String {
        switch self {
        case .initializing:
            "initializing"
        case .live:
            "live"
        case .ended:
            "ended"
        case .muted:
            "muted"
        @unknown default:
            "unknown"
        }
    }
    
    public var description: String {
        debugDescription
    }
}

extension RTCMediaStreamTrackState: @retroactive CustomDebugStringConvertible, @retroactive CustomStringConvertible {
    public var debugDescription: String {
        switch self {
        case .live:
            "live"
        case .ended:
            "ended"
        @unknown default:
            "unknown"
        }
    }
    
    public var description: String {
        debugDescription
    }
    
}

extension RTCRtpTransceiverDirection {
    var stringValue: String {
        switch self {
        case .sendRecv:
            "sendAndReceive"
        case .sendOnly:
            "sendOnly"
        case .recvOnly:
            "recvOnly"
        case .inactive:
            "inactive"
        case .stopped:
            "stopped"
        @unknown default:
            "Unknown \(self.rawValue)"
        }
    }
}
