//
//  WatchBLEModel.swift
//  CoreBluetoothTest
//
//  Created by sun on 5/24/26.
//

import Foundation
import Observation

@Observable
final class WatchBLEModel {
    var status: String = "Idle"
    var logs: [String] = []

    func addLog(_ text: String) {
        logs.insert(text, at: 0)
    }
}
