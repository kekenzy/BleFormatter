//
//  BleCentralManager.swift
//  BleChatAdvance
//
//  Created by ADK114019 on 2015/12/10.
//  Copyright © 2015年 Kenji Nagai. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



class BleCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let sharedInstance: BleCentralManager = BleCentralManager()
    var centralManager: CBCentralManager!
    var peripheralDict:Dictionary<String, CBPeripheral> = [String:CBPeripheral]()
    var msgText:String?
    
    var serviceUUID: [CBUUID]?
    var characteristicUUID: CBUUID?
    var ncMsg: String?
    var statusDidWrite: String?
    
    // =========================================================================
    // MARK: Private
    override fileprivate init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func setInitData(serviceUUID:String, charUUID:String, ncMsg:String) {
        self.serviceUUID = [CBUUID(string:serviceUUID)]
        self.characteristicUUID = CBUUID(string:charUUID)
        self.ncMsg = ncMsg
    }
    
    // =========================================================================
    // MARK: Public
    
    
    func startScan() {
//        var peripherarls = self.centralManager.retrieveConnectedPeripheralsWithServices(<#T##serviceUUIDs: [CBUUID]##[CBUUID]#>)
        // peripherarl側でCBAdvertisementDataServiceUUIDsKeyをアドバタイズしないと検出できない
        // アドバダタイズを１回にまとめるかかどうか、NOはまとめる(iOSのみ有効)
        DLOG(LogKind.CE,message:"スキャン開始")
        let OPTION:Dictionary = [CBCentralManagerScanOptionAllowDuplicatesKey:false]
        self.centralManager!.scanForPeripherals(withServices: serviceUUID, options:OPTION)
        
//        self.centralManager!.scanForPeripheralsWithServices(serviceUUID, options:nil)
//        self.centralManager!.scanForPeripheralsWithServices(nil, options:OPTION)
    }
    
    func stopScan() {
        self.centralManager.stopScan()
        self.peripheralDict.removeAll()
    }
    
    func writeMsg(_ msg:String?, statusDidWrite:String?) {
//        if centralManager.isScanning {
//            DLOG(LogKind.CE,message:"スキャン中....")
//            return
//        }
        
        self.statusDidWrite = statusDidWrite
        self.msgText = msg
        DLOG(LogKind.CE, message:"msg:\(msg)")
        self.startScan()
    }
    // =========================================================================
    // MARK: CBCentralManagerDelegate
    
    // セントラルマネージャの状態が変化すると呼ばれる
    // CBCentralManagerの状態変化を取得
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DLOG(LogKind.CE,message:"state: \(central.state.rawValue)")
        
        if #available(iOS 10.0, *) {
            switch(central.state){
            case CBManagerState.poweredOn:
                //            self.startScan()
                break
                
            case CBManagerState.poweredOff:
                DLOG(LogKind.CE,message:"電源が入っていないようです。")
                break
                
            case CBManagerState.unknown:
                DLOG(LogKind.CE,message:"unknown")
                break
                
            case CBManagerState.unauthorized:
                DLOG(LogKind.CE,message:"Unauthorized")
                break
                
            case CBManagerState.unsupported:
                DLOG(LogKind.CE,message:"Unsupported")
                break
                
            default:
                break
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    // ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let uuid = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey]
        let localName  = advertisementData[CBAdvertisementDataLocalNameKey]
        DLOG(LogKind.CE,message:"発見したBLEデバイス: \(peripheral) localName: \(localName) uuid: \(uuid)")
        
        let value = self.peripheralDict[peripheral.name!]
        if value == nil {
            self.peripheralDict[peripheral.name!] =  peripheral
        
            if peripheral.state == CBPeripheralState.disconnected {
                self.centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DLOG(LogKind.CE,message:"接続成功！")
        
        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        
        // サービス探索開始
        peripheral.discoverServices(serviceUUID)
    }
    
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DLOG(LogKind.CE,message:"接続失敗・・・")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DLOG(LogKind.CE,message:"切断完了")
        // TODO 暫定
        self.peripheralDict.removeValue(forKey: peripheral.name!)
    }
    
    
    // =========================================================================
    // MARK:CBPeripheralDelegate
    
    // サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if (error != nil) {
            DLOG(LogKind.CE,message:"エラー: \(error)")
            return
        }
        
        if !(peripheral.services?.count > 0) {
            DLOG(LogKind.CE,message:"no services")
            return
        }
        
        let services = peripheral.services!
        DLOG(LogKind.CE,message:"\(services.count) 個のサービスを発見！ \(services)")
        
        for service in services {
            // キャラクタリスティック探索開始
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            DLOG(LogKind.CE,message:"エラー: \(error)")
            return
        }
        
        if !(service.characteristics?.count > 0) {
            DLOG(LogKind.CE,message:"no characteristics")
            return
        }
        
        let characteristics = service.characteristics!
        DLOG(LogKind.CE,message:"\(characteristics.count) 個のキャラクタリスティックを発見！ \(characteristics)")
        
        for characteristic in characteristics {
            
            if characteristic.uuid.isEqual(self.characteristicUUID) {
                
                
                DLOG(LogKind.CE,message:"SAME UUID")
                characteristic.properties
                if characteristic.properties.contains(CBCharacteristicProperties.notify) {
                    DLOG(LogKind.CE,message:"Notify On ")
//                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
                if characteristic.properties.contains(CBCharacteristicProperties.read) {
                    DLOG(LogKind.CE,message:"Read On ")
//                    peripheral.readValueForCharacteristic(characteristic)
                }
                if characteristic.properties.contains(CBCharacteristicProperties.write) {
                    var name = UIDevice.current.name;
                    var msg = self.msgText! + " from " + name
                    let data = msg.data(using: String.Encoding.utf8)
                    DLOG(LogKind.CE,message:"Write On :\(msg)")
                    peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                }
                if characteristic.properties.contains(CBCharacteristicProperties.writeWithoutResponse) {
                    DLOG(LogKind.CE,message:"WriteWithResopnse On ")
//                    let data = self.msgText?.dataUsingEncoding(NSUTF8StringEncoding)
//                    peripheral.writeValue(data!, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
                }
            }
        }
    }
    
    // データ読み込みが完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            DLOG(LogKind.CE,message:"読み込み失敗...error: \(error), characteristic uuid: \(characteristic.uuid)")
            return
        }
        var value:NSString? = nil
        if characteristic.value != nil {
            value = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
            
        }
        DLOG(LogKind.CE,message:"読み込み成功！value: \(value) service uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid)")
    }
    
    // Notify受付が完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            DLOG(LogKind.CE,message:"Notify受付失敗...error: \(error), characteristic uuid: \(characteristic.uuid)")
            return
        }
        var value:NSString? = nil
        if characteristic.value != nil {
            value = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
            
        }
        DLOG(LogKind.CE,message:"Notify受付成功！value: \(value) service uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid)")
        
    }
    
    // データ書き込みが完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            DLOG(LogKind.CE,message:"書き込み失敗...error: \(error), characteristic uuid: \(characteristic.uuid)")
            return
        }
        var value:NSString? = nil
        if characteristic.value != nil {
            value = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
            
        }
        DLOG(LogKind.CE,message:"書き込み成功！characteristic: \(characteristic)value: \(value) service uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid)")
        
        self.centralManager.cancelPeripheralConnection(peripheral)
//        self.stopScan()
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: self.ncMsg!), object: nil, userInfo: ["message" : self.statusDidWrite])
    }
    
}
