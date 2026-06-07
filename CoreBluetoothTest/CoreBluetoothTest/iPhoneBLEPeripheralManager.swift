//
//  iPhoneBLEPeripheralManager.swift
//  CoreBluetoothTest
//
//  Created by sun on 5/24/26.
//

import Foundation
import CoreBluetooth

enum BLEPeripheralEvent {
    case bluetoothStateChanged(String, log: String?)
    case advertisingChanged(Bool, log: String)
    case answerReceived(id: UUID, value: Bool)
    case log(String)
}

final class iPhoneBLEPeripheralManager: NSObject, CBPeripheralManagerDelegate {

    private var peripheralManager: CBPeripheralManager?
    private var answerCharacteristic: CBMutableCharacteristic?

    let events: AsyncStream<BLEPeripheralEvent>
    private let continuation: AsyncStream<BLEPeripheralEvent>.Continuation

    override init() {
        let stream = AsyncStream.makeStream(of: BLEPeripheralEvent.self)

        self.events = stream.stream
        self.continuation = stream.continuation

        super.init()

        self.peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil
        )
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            continuation.yield(
                .bluetoothStateChanged(
                    "Powered On",
                    log: "블루투스가 활성화"
                )
            )
            setupService()
            startAdvertising()

        case .poweredOff:
            continuation.yield(
                .bluetoothStateChanged(
                    "Powered Off",
                    log: "블루투스가 비활성화"
                )
            )

        case .unauthorized:
            continuation.yield(
                .bluetoothStateChanged(
                    "Unauthorized",
                    log: "블루투스 권한 없음"
                )
            )

        case .unsupported:
            continuation.yield(
                .bluetoothStateChanged(
                    "Unsupported",
                    log: "이 기기는 블루투스를 지원하지 않음"
                )
            )

        case .resetting:
            continuation.yield(
                .bluetoothStateChanged("Resetting", log: nil)
            )

        case .unknown:
            continuation.yield(
                .bluetoothStateChanged("Unknown", log: nil)
            )

        @unknown default:
            continuation.yield(
                .bluetoothStateChanged("Unknown Default", log: nil)
            )
        }
    }

    private func setupService() {
        guard let peripheralManager else { return }

        let characteristic = CBMutableCharacteristic(
            type: BLEUUID.answer,
            properties: [.write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )

        self.answerCharacteristic = characteristic

        let service = CBMutableService(
            type: BLEUUID.service,
            primary: true
        )

        service.characteristics = [characteristic]

        peripheralManager.removeAllServices()
        peripheralManager.add(service)

        continuation.yield(.log("Service added"))
    }

    private func startAdvertising() {
        guard let peripheralManager else { return }

        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BLEUUID.service],
            CBAdvertisementDataLocalNameKey: "Answer-iPhone"
        ])

        continuation.yield(
            .advertisingChanged(
                true,
                log: "Advertising started"
            )
        )
    }

    func stopAdvertising() {
        peripheralManager?.stopAdvertising()

        continuation.yield(
            .advertisingChanged(
                false,
                log: "Advertising stopped"
            )
        )
    }

    func peripheralManagerDidStartAdvertising(
        _ peripheral: CBPeripheralManager,
        error: Error?
    ) {
        if let error {
            continuation.yield(
                .log("Advertising error: \(error.localizedDescription)")
            )
        } else {
            continuation.yield(.log("Advertising success"))
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests {
            guard request.characteristic.uuid == BLEUUID.answer else {
                peripheral.respond(to: request, withResult: .requestNotSupported)
                continue
            }

            guard let firstByte = request.value?.first else {
                peripheral.respond(to: request, withResult: .invalidAttributeValueLength)
                continue
            }

            let isYes = firstByte == BLEAnswer.yes.rawValue
            let centralID = request.central.identifier

            continuation.yield(
                .answerReceived(
                    id: centralID,
                    value: isYes
                )
            )

            peripheral.respond(to: request, withResult: .success)
        }
    }
}
