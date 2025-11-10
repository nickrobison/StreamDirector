//
//  SwitcherView.swift
//  BMKit
//
//  Created by Nick Robison on 11/9/25.
//

import SDKit
import SwiftUI

struct SwitcherView: View {
    let vm: ViewModel
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(vm.tracks, id: \.name) { track in
//                Text(track.name)
                TrackView(track: track, trackState: vm.getState(for: track)) {
                    Task {
                        await self.vm.setPreview(to: track)
                    }
                    
                }
            }
        }
        .task {
            await self.vm.loadTracks()
        }
    }

}

extension SwitcherView {
    @Observable
    @MainActor
    class ViewModel {
        var tracks: [any VideoTrack] = []
        var program: (any VideoTrack)? = nil
        var preview: (any VideoTrack)? = nil
        //        var program: any VideoTrack
        let switcher: ATEMSwitcher

        init(_ switcher: ATEMSwitcher) {
            self.switcher = switcher
        }

        func loadTracks() async {
            self.tracks = await switcher.tracks
            self.program = await switcher.programBus
            self.preview = await switcher.previewBus
        }
        
        func getState(for track: any VideoTrack) -> TrackState {
            return if (program?.name == track.name) {
                .program
            } else if (preview?.name == track.name) {
                .preview
            } else {
                .none
            }
        }
        
        func setPreview(to track: any VideoTrack) async {
            await self.switcher.setPreview(track: track)
            self.preview = await self.switcher.previewBus
        }
    }
}

#Preview {
    let tracks: [MockTrack] = [
        MockTrack(name: "Track 1", input: nil),
        MockTrack(name: "Track 2", input: MockDevice(name: "Camera 1")),
        MockTrack(name: "Track 3", input: nil),
    ]
    SwitcherView(
        vm: SwitcherView.ViewModel(
            ATEMSwitcher(preview: tracks[0], program: tracks[1], tracks: tracks)
        )
    )
}
