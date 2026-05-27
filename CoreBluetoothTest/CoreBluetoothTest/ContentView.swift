//
//  ContentView.swift
//  CoreBluetoothTest
//
//  Created by sun on 5/24/26.
//

import SwiftUI

struct ContentView: View {

    @State private var model = BLEModel()
    @State private var bleManager: iPhoneBLEPeripheralManager?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bluetooth State: \(model.bluetoothStateText)")
                    Text("Advertising: \(model.isAdvertising ? "ON" : "OFF")")
                }

                Divider()

                Text("워치 응답")
                    .font(.headline)

                if model.answers.isEmpty {
                    Text("아직 응답 없음")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        ForEach(Array(model.answers.keys), id: \.self) { id in
                            HStack {
                                Text(String(id.uuidString.prefix(8)))
                                Spacer()
                                Text(model.answers[id] == true ? "동의" : "비동의")
                                    .bold()
                            }
                        }
                    }
                }

                Divider()

                Text("Logs")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(model.logs, id: \.self) { log in
                            Text(log)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .navigationTitle("iPhone Peripheral")
            .onAppear {
                if bleManager == nil {
                    bleManager = iPhoneBLEPeripheralManager(model: model)
                }
            }
        }
    }
}
