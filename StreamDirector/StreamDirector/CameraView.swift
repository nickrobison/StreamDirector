//
//  SwiftUIView.swift
//  StreamDirector
//
//  Created by Nick Robison on 8/31/25.
//

import SwiftUI
import ShotSimKit

struct CameraView: View {
    @StateObject var viewModel: CameraViewController
    
    init(viewModel: CameraViewController) {
        // Really? Is this how we're supposed to do things?
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        if (viewModel.isConnected) {
            Text("Connected!")
        } else {
            Text("Disconnected")
        }
        if ((viewModel.remoteVideoTrack) != nil) {
            VStack {
                WebRTCVideoView(viewModel.remoteVideoTrack)
                    .frame(width: 400, height: 400)
                    .border(.gray)
                Text("Content for me?")
            }
            
        } else {
            Text("No video yet")
        }
    }
}

//#Preview {
//    CameraView()
//}
