//
//  BluetoothCore.swift
//  CardSharing
//
//  Created by Khaos Tian on 11/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothCoreProtocol: class {
    func didGetNewCard(card: Card)
}

class TransmitSession {
    var pendingData: NSData
    var offset: Int = 0
    var maxSize: Int = 18
    
    init(data: NSData, maxSize: Int) {
        self.pendingData = data.copy() as NSData
        self.maxSize = maxSize
    }
    
    func nextChunck() -> NSData? {
        if offset < pendingData.length {
            let nextChunckSize = pendingData.length - offset > maxSize ? maxSize : pendingData.length - offset
            let transmitData = pendingData.subdataWithRange(NSRange(location: self.offset,length: nextChunckSize))
            return transmitData
        } else {
            return nil
        }
    }
    
    func updateOffset() {
        self.offset += self.maxSize
    }
}

class BluetoothCore: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    weak var delegate: BluetoothCoreProtocol?
    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    
    var readyToAdvertise: Bool = false
    var isAdvertising: Bool = false
    var isScanning: Bool = false
    
    var dataCharacteristic: CBMutableCharacteristic?
    var dataService: CBMutableService?
    
    var cardData: NSData?
    var transmitSession: TransmitSession?
    
    var targetPeripheral: CBPeripheral?
    
    var dataBuffer = NSMutableData()
    var endData = NSData(bytes: [0x45,0x4E,0x44,0x56,0x41,0x4C] as [Byte], length: 6)
    
    init(delegate: BluetoothCoreProtocol) {
        super.init()
        
        self.delegate = delegate
        self.centralManager = CBCentralManager(delegate: self, queue: dispatch_queue_create("org.oltica.centralQueue", DISPATCH_QUEUE_SERIAL))
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: dispatch_queue_create("org.oltica.peripheralQueue", DISPATCH_QUEUE_SERIAL))
    }
    
    func startBroadcastingCardData(data: NSData) {
        self.cardData = data.copy() as? NSData

        self.stopScan()
        self.startAdvertising()
        
    }
    
    func preparePeripheralSetup() {
        if !readyToAdvertise {
            self.dataCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "3D22"), properties: CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Readable)
            self.dataService = CBMutableService(type: CBUUID(string: "3D21"), primary: true)
            self.dataService!.characteristics = [self.dataCharacteristic!]
            self.peripheralManager?.addService(self.dataService!)
        }
    }
    
    func startAdvertising() {
        if readyToAdvertise && !isAdvertising {
            self.isAdvertising = true
            let dict = [CBAdvertisementDataServiceUUIDsKey:[CBUUID(string: "3D21")]]
            self.peripheralManager?.startAdvertising(dict)
        }
    }
    
    func stopAdvertising() {
        if isAdvertising {
            self.isAdvertising = false
            self.peripheralManager?.stopAdvertising()
        }
    }
    
    func startScan() {
        if !isScanning {
            self.isScanning = true
            self.stopAdvertising()
            self.centralManager?.scanForPeripheralsWithServices([CBUUID(string: "3D21")], options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        }
    }
    
    func stopScan() {
        if isScanning {
            self.isScanning = false
            self.centralManager?.stopScan()
        }
    }
    
    func writeData() {
        if let session = self.transmitSession {
            while let data = session.nextChunck() {
                if let peripheralManager = self.peripheralManager {
                    if peripheralManager.updateValue(data, forCharacteristic: self.dataCharacteristic!, onSubscribedCentrals: nil) {
                        session.updateOffset()
                    } else {
                        return
                    }
                }
            }
            if self.peripheralManager!.updateValue(self.endData, forCharacteristic: self.dataCharacteristic!, onSubscribedCentrals: nil) {
                self.transmitSession = nil
                NSLog("Finished Writing Data")
            }
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if central.state == CBCentralManagerState.PoweredOn {
            NSLog("Central Manager is ready!")
            self.startScan()
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        NSLog("Central Manager did discover peripheral: \(peripheral), advData: \(advertisementData), RSSI: \(RSSI)")
        if RSSI.floatValue >= -35.0 && RSSI.floatValue != 127 {
            NSLog("Peripheral is close to current device, start exchange data")
            self.stopScan()
            self.targetPeripheral = peripheral
            central.connectPeripheral(self.targetPeripheral!, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Central Manager did connect peripheral: \(peripheral)")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "3D21")])
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("Central Manager did fail to connect peripheral, error: \(error)")
        self.startScan()
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        NSLog("Peripheral did discover services")
        if error != nil {
            NSLog("Error: \(error)")
        } else {
            let targetUUID = CBUUID(string: "3D21")
            for service in peripheral.services as [CBService] {
                if service.UUID == targetUUID {
                    NSLog("Find Data Service")
                    peripheral.discoverCharacteristics([CBUUID(string: "3D22")], forService: service)
                    break
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        NSLog("Peripheral did discover characteristics for service: \(service)")
        if error != nil {
            NSLog("Error: \(error)")
        } else {
            let targetUUID = CBUUID(string: "3D22")
            for characteristic in service.characteristics as [CBCharacteristic] {
                if characteristic.UUID == targetUUID {
                    NSLog("Find Data Characteristic")
                    self.dataBuffer.length = 0
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    break
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error != nil {
            NSLog("An error encountered when updating value")
        } else {
            let newData = characteristic.value
            if newData == self.endData{
                NSLog("Finished receiving all data")
                self.centralManager?.cancelPeripheralConnection(peripheral)
                var card = Card(data: self.dataBuffer)
                dispatch_async(dispatch_get_main_queue(), {
                    self.delegate!.didGetNewCard(card)
                })
            } else {
                self.dataBuffer.appendData(newData)
            }
        }
    }
    
    // MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            NSLog("Peripheral Manager is ready!")
            self.preparePeripheralSetup()
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        if error == nil {
            NSLog("Peripheral Manager started advertising")
        } else {
            self.isAdvertising = false
            NSLog("Peripheral Manager failed advertising, error: \(error)")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!) {
        if error == nil {
            self.readyToAdvertise = true
            NSLog("Peripheral Manager did add service")
        } else {
            self.readyToAdvertise = false
            NSLog("Peripheral Manager failed adding service, error: \(error)")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didSubscribeToCharacteristic characteristic: CBCharacteristic!) {
        NSLog("New Central:\(central),MTU:\(central.maximumUpdateValueLength)")
        peripheral.setDesiredConnectionLatency(CBPeripheralManagerConnectionLatency.Low, forCentral: central)
        if let data = self.cardData {
            NSLog("Start sending data")
            transmitSession = TransmitSession(data: data, maxSize: central.maximumUpdateValueLength)
            self.writeData()
        }
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager!) {
        self.writeData()
    }
}
