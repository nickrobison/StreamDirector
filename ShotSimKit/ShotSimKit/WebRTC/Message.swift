//
//  Message.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import Foundation


enum Message {
    case sdp(SessionDescription)
    case candidate(IceCandidate)
}

extension Message: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case String("offer"):
            self = .sdp(try container.decode(SessionDescription.self, forKey: .data))
        case String(describing: IceCandidate.self):
            self = .candidate(try container.decode(IceCandidate.self, forKey: .data))
        default:
            debugPrint("What is this type: \(type)")
            throw DecodeError.unknownType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sdp(let sessionDescription):
            try container.encode(sessionDescription, forKey: .data)
            try container.encode(String(describing: SessionDescription.self), forKey: .type)
        case .candidate(let iceCandidate):
            try container.encode(iceCandidate, forKey: .data)
            try container.encode(String(describing: IceCandidate.self), forKey: .type)
        }
    }
    
    enum DecodeError: Error {
        case unknownType
    }
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
}
