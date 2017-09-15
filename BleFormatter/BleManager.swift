//
//  BleManager.swift
//  BleFormatter
//
//  Created by ADK114019 on 2016/12/22.
//  Copyright © 2016年 ADK114019. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

let MESSAGE_READ:String = "MESSAGE_READ"
let MESSAGE_WRITE:String = "MESSAGE_WRITE"

public class BleManager {
    public static let sharedInstance: BleManager = BleManager()
    
    // =========================================================================
    // MARK: Private
    var bleCentralManager:BleCentralManager!;
    var blePeripheralManager:BlePeripheralManager!;
    
    var _serviceUUID:String!
    var _charUUID:String!
    var _dataFormat:[BleDataFormat]!
    var _deviceName:String!
    
    fileprivate init() {
        self.bleCentralManager = BleCentralManager.sharedInstance;
        self.blePeripheralManager = BlePeripheralManager.sharedInstance
        self._deviceName = UIDevice.current.name;
    }
    
    // =========================================================================
    // MARK: Public
    
    public func setUUID(serviceUUID:String) {
        self._serviceUUID = serviceUUID
        self.bleCentralManager.setInitData(serviceUUID: serviceUUID)
        self.blePeripheralManager.setInitData(serviceUUID: serviceUUID)
    }
    
    public func setReadDataFormat(bleDataFormat:[BleDataFormat]) {
        self.blePeripheralManager.setDataFormat(bleFormat: bleDataFormat)
    }
    
    // =========================================================================
    // Observer 
    
    public func addObserver(_ viewCtrl:UIViewController, withRead completion:(Selector)) -> Void {
        let nc = NotificationCenter.default
        nc.addObserver(viewCtrl, selector: completion, name: NSNotification.Name(rawValue: BleStatus.DID_READ.description()), object: nil)
    }
    
    public func addObserver(_ viewCtrl:UIViewController, withWrite completion:(Selector)) -> Void {
        let nc = NotificationCenter.default
        nc.addObserver(viewCtrl, selector: completion, name: NSNotification.Name(rawValue: BleStatus.DID_WRITE.description()), object: nil)
    }
    
    
    // =========================================================================
    // Write Data
    
    public func write(withData data:Data, dataFormat dFormat:inout BleDataFormat) {
        DLOG(LogKind.BM, message:"write data:\(data)")
        dFormat.setData(data)
        bleCentralManager.writeMsg(withBleDataFormatter: dFormat)
    }
    
    public func write(withString data:String, dataFormat dFormat:inout BleDataFormat) {
        DLOG(LogKind.BM, message:"write data:\(data)")
        let tmpMsg = data + "," + self._deviceName
        let data = tmpMsg.data(using: String.Encoding.utf8)
        dFormat.setData(data!)
        bleCentralManager.writeMsg(withBleDataFormatter: dFormat)
    }
    
    public func write(withInt data:Int, dataFormat dFormat:inout BleDataFormat) {
        DLOG(LogKind.BM, message:"write data:\(data)")
        let tmpMsg = String(data) + "," + self._deviceName
        let data = tmpMsg.data(using: String.Encoding.utf8)
        dFormat.setData(data!)
        bleCentralManager.writeMsg(withBleDataFormatter: dFormat)
    }
    
    public func write(withDouble data:Double, dataFormat dFormat:inout BleDataFormat) {
        DLOG(LogKind.BM, message:"write data:\(data)")
        let tmpMsg = String(data) + "," + self._deviceName
        let data = tmpMsg.data(using: String.Encoding.utf8)
        dFormat.setData(data!)
        bleCentralManager.writeMsg(withBleDataFormatter: dFormat)
    }
}


