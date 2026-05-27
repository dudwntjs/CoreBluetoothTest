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

    func receiveAnswer(from id: UUID, value: Bool) {
        answers[id] = value
        logs.insert("\(id.uuidString.prefix(8)) → \(value ? "동의" : "비동의")", at: 0)
    }

    func addLog(_ text: String) {
        logs.insert(text, at: 0)
    }
}
