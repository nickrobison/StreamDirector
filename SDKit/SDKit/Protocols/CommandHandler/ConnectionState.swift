//
//  ConnectionState.swift
//  SDKit
//
//  Created by Nick Robison on 11/16/25.
//


enum ConnectionState: Equatable {
    case connected
    case disconnected
    case connecting
    case failed(String)
    case reconnecting(Int, Duration)
}
