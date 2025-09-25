//
//  IceCandidate.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import WebRTC

/// This struct is a swift wrapper over `RTCIceCandidate` for easy encode and decode
struct IceCandidate: Codable {
    let candidate: String
    let sdpMLineIndex: Int32 // Stupid Unity returns either an int or a string
    let sdpMid: String? // Stupid Unity returns either an int or a string
    let connectionId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case candidate, sdpMLineIndex, sdpMid, connectionId
    }
    
    enum DecodeError: Error {
        case unsupportedType
    }
    
    init(from iceCandidate: RTCIceCandidate, id: UUID) {
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.candidate = iceCandidate.sdp
        self.connectionId = id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.candidate = try container.decode(String.self,forKey: .candidate)
        self.connectionId = try container.decodeIfPresent(UUID.self, forKey: .connectionId)
        
        
        if let value = try? container.decodeIfPresent(Int32.self, forKey: .sdpMid) {
            self.sdpMid = String(describing: value)
        } else if let value = try? container.decode(String.self, forKey: .sdpMid) {
            self.sdpMid = value
        } else {
            self.sdpMid = nil
        }
        
        if let value = try? container.decode(Int32.self, forKey: .sdpMLineIndex) {
            self.sdpMLineIndex = value
        } else if let value = try? container.decode(String.self, forKey: .sdpMLineIndex) {
            self.sdpMLineIndex = Int32(value)! // Fix this
        } else {
            throw DecodeError.unsupportedType
        }
    }
    
    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.candidate, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
    }
}
