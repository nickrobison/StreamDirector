//
//  ConnectionState.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//


public enum ConnectionState: Equatable, Sendable {
    case connected
    case disconnected
    case connecting
    case failed(String)
    case reconnecting(Int, Duration)
}
