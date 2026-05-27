//
//  ContentView.swift
//  CoreBluetoothTestWatch Watch App
//
//  Created by sun on 5/24/26.
//

import SwiftUI

struct ContentView: View {

    @State private var model = WatchBLEModel()
    @State private var manager: WatchCentralManager?

    var body: some View {
        VStack(spacing: 10) {
            Text(model.status)
                .font(.caption)
                .multilineTextAlignment(.center)

            Button("동의") {
                manager?.send(.yes)
            }

            Button("비동의") {
                manager?.send(.no)
            }

            Button("Reconnect") {
                manager?.scan()
            }
        }
        .padding()
        .onAppear {
            if manager == nil {
                manager = WatchCentralManager(model: model)
            }
        }
    }
}
