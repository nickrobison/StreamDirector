//
//  CommandHandlerConfig.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//

public struct CommandHandlerConfig: Sendable {
    let healthCheckInterval: Duration = Duration.seconds(1)
    let retryCount: Int = 5
    
    public init() {}
}
