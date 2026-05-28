//
//  WatchCentralManager.swift
//  CoreBluetoothTest
//
//  Created by sun on 5/24/26.
//

import Foundation
import CoreBluetooth

final class WatchCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager?
    private var targetPeripheral: CBPeripheral?
    private var answerCharacteristic: CBCharacteristic?
    
    private let model: WatchBLEModel
    private var pendingAnswer: BLEAnswer?
    
    init(model: WatchBLEModel) {
        self.model = model
        super.init()
        
        self.centralManager = CBCentralManager(
            delegate: self,
            queue: nil
        )
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            model.status = "Powered On"
            model.addLog("블루투스 활성화")
            
        case .poweredOff:
            model.status = "Powered Off"
            model.addLog("블루투스 비활성화")
            
        case .unauthorized:
            model.status = "Unauthorized"
            model.addLog("블루투스 비활성화")
            
        case .unsupported:
            model.status = "Unspported"
            model.addLog("이 기기는 블루투스를 지원하지 않음")
            
        case .resetting:
            model.status = "Resetting"
            
        case .unknown:
            model.status = "Unknown"
        default:
            model.status = "Bluetooth not ready"
        }
    }
    
    func scan() {
        guard centralManager?.state == .poweredOn else {
            model.logs.append("블루투스 상태가 올바르지 않음")
            return
        }
        
        model.logs.append("Scanning...")
        
        centralManager?.scanForPeripherals(
            withServices: [BLEUUID.service],
            options: nil)
    }
    
    func disconnect() {
            if let peripheral = targetPeripheral {
                centralManager?.cancelPeripheralConnection(peripheral)
            }

            targetPeripheral = nil
            answerCharacteristic = nil
            model.status = "Disconnected"
            model.addLog("Disconnected")
        }

        func send(_ answer: BLEAnswer) {
            guard let peripheral = targetPeripheral,
                  let characteristic = answerCharacteristic
            else {
                pendingAnswer = answer
                model.addLog("다시 검색합니다")
                scan()
                return
            }

            let data = Data([answer.rawValue])

            peripheral.writeValue(
                data,
                for: characteristic,
                type: .withResponse
            )

            model.status = "Sent \(answer == .yes ? "동의" : "비동의")"
            model.addLog("Sent \(answer == .yes ? "동의" : "비동의")")
        }

        func centralManager(
            _ central: CBCentralManager,
            didDiscover peripheral: CBPeripheral,
            advertisementData: [String : Any],
            rssi RSSI: NSNumber
        ) {
            model.status = "iPhone 발견"
            model.addLog("Found: \(peripheral.name ?? "Unknown")")

            targetPeripheral = peripheral
            targetPeripheral?.delegate = self

            centralManager?.stopScan()
            centralManager?.connect(peripheral, options: nil)
        }

        func centralManager(
            _ central: CBCentralManager,
            didConnect peripheral: CBPeripheral
        ) {
            model.status = "Connected"
            model.addLog("iPhone과 연결")

            peripheral.discoverServices([BLEUUID.service])
        }

        func centralManager(
            _ central: CBCentralManager,
            didFailToConnect peripheral: CBPeripheral,
            error: Error?
        ) {
            model.status = "Connect failed"
            model.addLog("Connect failed: \(error?.localizedDescription ?? "unknown")")
        }

        func centralManager(
            _ central: CBCentralManager,
            didDisconnectPeripheral peripheral: CBPeripheral,
            error: Error?
        ) {
            model.status = "Disconnected"
            model.addLog("Disconnected")

            targetPeripheral = nil
            answerCharacteristic = nil
        }

        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverServices error: Error?
        ) {
            if let error {
                model.addLog("Discover services error: \(error.localizedDescription)")
                return
            }

            guard let services = peripheral.services else { return }

            for service in services where service.uuid == BLEUUID.service {
                peripheral.discoverCharacteristics(
                    [BLEUUID.answer],
                    for: service
                )
            }
        }

        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverCharacteristicsFor service: CBService,
            error: Error?
        ) {
            if let error {
                model.addLog("Discover characteristics error: \(error.localizedDescription)")
                return
            }

            guard let characteristics = service.characteristics else { return }

            for characteristic in characteristics where characteristic.uuid == BLEUUID.answer {
                answerCharacteristic = characteristic
                model.status = "Ready"
                model.addLog("Ready to send")

                if let pendingAnswer {
                    self.pendingAnswer = nil
                    send(pendingAnswer)
                }
            }
        }

        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor characteristic: CBCharacteristic,
            error: Error?
        ) {
            if let error {
                model.status = "Write failed"
                model.addLog("Write failed: \(error.localizedDescription)")
            } else {
                model.status = "Write success"
                model.addLog("쓰기 성공")
            }
        }
}
