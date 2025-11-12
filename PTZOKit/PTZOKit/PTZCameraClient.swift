//
//  PTZCameraClient.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/11/25.
//

import OpenAPIURLSession

public struct PTZCameraClient {
    public init() {
        
    }
    
    public func getGreeting(name: String?) async throws -> String {
        let client = Client(serverURL: try Servers.Server1.url(), transport: URLSessionTransport())
        
        let tt = try await client.presetCall(query: .init(presetNumber: 0))
        return ""
       }
}

