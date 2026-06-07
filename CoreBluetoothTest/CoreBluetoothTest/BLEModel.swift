//
//  BLEModel.swift
//  CoreBluetoothTest
//
//  Created by sun on 5/24/26.
//

import Foundation
import Observation

@Observable
final class BLEModel {
    var isAdvertising: Bool = false
    var bluetoothStateText: String = "Unknown"
    var answers: [UUID: Bool] = [:]
    var logs: [String] = []

    private let peripheralManager = iPhoneBLEPeripheralManager()
    private var eventTask: Task<Void, Never>?

    init() {
        observePeripheralEvents()
    }

    deinit {
        eventTask?.cancel()
    }

    func stopAdvertising() {
        peripheralManager.stopAdvertising()
    }

    private func observePeripheralEvents() {
        eventTask = Task {
            for await event in peripheralManager.events {
                await MainActor.run {
                    self.handle(event)
                }
            }
        }
    }

    private func handle(_ event: BLEPeripheralEvent) {
        switch event {
        case let .bluetoothStateChanged(stateText, log):
            bluetoothStateText = stateText

            if let log {
                addLog(log)
            }

        case let .advertisingChanged(isAdvertising, log):
            self.isAdvertising = isAdvertising
            addLog(log)

        case let .answerReceived(id, value):
            receiveAnswer(from: id, value: value)

        case let .log(text):
            addLog(text)
        }
    }

    private func receiveAnswer(from id: UUID, value: Bool) {
        answers[id] = value
        logs.insert("\(id.uuidString.prefix(8)) → \(value ? "동의" : "비동의")", at: 0)
    }

    private func addLog(_ text: String) {
        logs.insert(text, at: 0)
    }
}
