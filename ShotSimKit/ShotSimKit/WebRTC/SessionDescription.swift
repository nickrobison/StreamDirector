//
//  SessionDescription.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import WebRTC

/// This enum is a swift wrapper over `RTCSdpType` for easy encode and decode
enum SdpType: String, Codable {
    case offer, prAnswer, answer, rollback
    
    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:    return .offer
        case .answer:   return .answer
        case .prAnswer: return .prAnswer
        case .rollback: return .rollback
        }
    }
}

/// This struct is a swift wrapper over `RTCSessionDescription` for easy encode and decode
struct SessionDescription {
    let sdp: String
    let connectionId: UUID?
    let type: SdpType

    
    init(from rtcSessionDescription: RTCSessionDescription, id: UUID) {
        self.sdp = rtcSessionDescription.sdp
        self.connectionId = id
        
        switch rtcSessionDescription.type {
        case .offer:    self.type = .offer
        case .prAnswer: self.type = .prAnswer
        case .answer:   self.type = .answer
        case .rollback: self.type = .rollback
        @unknown default:
            fatalError("Unknown RTCSessionDescription type: \(rtcSessionDescription.type.rawValue)")
        }
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
    }
}

struct SessionDescriptionConfiguration {
    let type: SdpType
}

extension SessionDescription: Encodable, DecodableWithConfiguration {
    
    init(from decoder: any Decoder, configuration: SessionDescriptionConfiguration) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.connectionId = try container.decodeIfPresent(UUID.self, forKey: .connectionId)
        self.sdp = try container.decode(String.self, forKey: .sdp)
        self.type = configuration.type
    }
    
    enum CodingKeys: String, CodingKey {
        case sdp, connectionId, type
    }
}
