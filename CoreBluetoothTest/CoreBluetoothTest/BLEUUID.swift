//
//  BLEUUID.swift
//  CoreBluetoothTest
//
//  Created by sun on 5/24/26.
//

import CoreBluetooth

enum BLEUUID {
    static let service = CBUUID(string: "A1B2C3D4-1111-2222-3333-123456789ABC")
    static let answer = CBUUID(string: "A1B2C3D4-1111-2222-3333-123456789ABD")
}

enum BLEAnswer: UInt8 {
    case no = 0
    case yes = 1
}
