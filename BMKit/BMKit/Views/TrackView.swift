//
//  TrackView.swift
//  BMKit
//
//  Created by Nick Robison on 11/9/25.
//

import SwiftUI
import SDKit

struct TrackView: View {
    
    var track: any VideoTrack
    var trackState: TrackState = .none
    var handler: () -> Void
    
    var body: some View {
        VStack {
            if let input = track.input {
                // TODO: Does this make sense?
                // I think it does because we want to be able to show controllers for multiple device types
                AnyView(input.makeController())
            } else {
                Text("None")
            }
            Divider()
            Button(track.name, action: handler)
            .buttonStyle(.roundedRect)
            .tint(trackState.color)
        }
    }
}

#Preview {
    HStack {
        TrackView(track: MockTrack(name: "Track 1", input: nil), handler: {})
        TrackView(track: MockTrack(name: "Track 2", input: MockDevice(name: "Test Device")), handler: {})
    }
    
}
