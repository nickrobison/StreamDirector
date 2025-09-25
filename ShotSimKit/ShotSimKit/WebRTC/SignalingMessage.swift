//
//  SignalingMessage.swift
//  ShotSimKit
//
//  Created by Nick Robison on 9/24/25.
//

import Foundation

struct SignalingMessage {
    let from: UUID
    let to: String?
    let data: Message
    let type: String
}

extension SignalingMessage: Codable {
    init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.from = try container.decode(UUID.self, forKey: .from)
        self.to = try container.decodeIfPresent(String.self, forKey: .to)
        self.type = try container.decode(String.self, forKey: .type)
        
        // TODO: Wow, this is horrible
        switch self.type {
        case "candidate":
            let p = try container.decode(IceCandidate.self, forKey: .data)
            self.data = .candidate(p)
        case "offer":
            let p = try container.decode(SessionDescription.self, forKey: .data, configuration: SessionDescriptionConfiguration(type: .offer))
            self.data = .sdp(p)
        case "answer":
            let p = try container.decode(SessionDescription.self, forKey: .data, configuration: SessionDescriptionConfiguration(type: .answer))
            self.data = .sdp(p)
        default:
            throw DecodeError.unsupportedMessage(self.type)
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from, forKey: .from)
        try container.encodeIfPresent(to, forKey: .to)
        
        switch data {
        case .sdp(let description):
            try container.encode(description, forKey: .data)
            try container.encode("offer", forKey: .type)
        case .candidate(let candidate):
            try container.encode(candidate, forKey: .data)
            try container.encode("candidate", forKey: .type)
        }
    }
    
    enum DecodeError: Error {
        case unsupportedMessage(String)
    }
    
    enum CodingKeys: String, CodingKey {
        case from, to, type, data
    }
}

extension Decoder {
    func getContext(forKey key: String) -> Any? {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        return userInfo[infoKey]
    }
}

extension JSONDecoder {
    func setContext(context: Any?, forKey key: String) {
        let infoKey = CodingUserInfoKey(rawValue: key)!
        userInfo[infoKey] = context
    }
}
