//
//  ATEMSwitcher.swift
//  BMKit
//
//  Created by Nick Robison on 11/9/25.
//

import SDKit

actor ATEMSwitcher: Switcher {
    var tracks: [any VideoTrack]
    var previewBus: any VideoTrack
    var programBus: any VideoTrack
    
    

    init(preview: any VideoTrack, program: any VideoTrack, tracks: [any VideoTrack]) {
        self.tracks = tracks
        self.previewBus = preview
        self.programBus = program
    }
    
    func setPreview(track: any VideoTrack) {
        self.previewBus = track
    }
    
    func setProgram(track: any VideoTrack) {
        self.programBus = track
    }
    
    func cut() {
        let tempPreview = self.programBus
        self.programBus = self.previewBus
        self.previewBus = tempPreview
    }
    
    func transition(duration: Int) {
        self.cut()
    }
}
