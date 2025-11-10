//
//  Switcher.swift
//  SDKit
//
//  Created by Nick Robison on 11/9/25.
//

public protocol Switcher: Actor {
    var tracks: [any VideoTrack] { get }
    var previewBus: any VideoTrack { get }
    var programBus: any VideoTrack { get }
    func setPreview(track: any VideoTrack)
    func setProgram(track: any VideoTrack)
    func cut()
    func transition(duration: Int)
}
