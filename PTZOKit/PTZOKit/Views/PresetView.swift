//
//  PresetView.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/24/25.
//

import OSLog
import SDKit
import SwiftUI

struct PresetView<P: PresetHandler>: View {

    var vm: PresetView.ViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(vm.presets) { preset in
                PresetButton(
                    preset,
                    preset == vm.activePreset,
                    handler: self.handleClick
                )
            }
        }
        .task {
            await vm.fetchPresets()
        }
    }

    func handleClick(preset: CameraPreset) {
        debugPrint("Setting active preset: \(preset)")
        Task {
            await vm.activatePreset(preset)
        }
    }
}

#if DEBUG
fileprivate struct PreviewData {
    static let presets = [
        CameraPreset(name: "Home", value: .presetID("1")),
        CameraPreset(name: "Lectern", value: .presetID("2")),
        CameraPreset(name: "Alter", value: .presetID("3")),
        CameraPreset(name: "Entry", value: .presetID("4")),
    ]
    
    static func makeHandler(_ active: CameraPreset? = nil) -> PresetHandlerMock {
        let h = PresetHandlerMock()
        h._getActivePreset.implementation = .returns(active)
        h._getPresets.implementation = .returns(presets)
        h._set.implementation = .returns(())

        return h
    }
}
#endif

#Preview("No active presets") {
    PresetView<PresetHandlerMock>(vm: PresetView.ViewModel(PreviewData.makeHandler()))
}

#Preview("Active preset") {
    PresetView<PresetHandlerMock>(vm: PresetView.ViewModel(PreviewData.makeHandler(PreviewData.presets[2])))
}

extension PresetView {

    @Observable
    @MainActor
    class ViewModel {
        var presets: [CameraPreset] = []
        var activePreset: CameraPreset? = nil

        private let handler: P

        init(_ handler: P) {
            self.handler = handler
        }

        func fetchPresets() async {
            do {
                self.presets = try await handler.getPresets()
                self.activePreset = try await handler.getActivePreset()
            } catch {
                debugPrint("Failed??")
            }
        }
        
        func activatePreset(_ preset: CameraPreset) async {
            do {
                try await self.handler.set(preset: preset)
                self.activePreset = preset
            } catch {
                debugPrint("Failed??")
            }
        }
    }
}

extension PresetView {
    
    init(handler: P) {
        self.init(vm: ViewModel(handler))
    }
}
