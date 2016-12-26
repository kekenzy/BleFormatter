//
//  BleManager.swift
//  BleFormatter
//
//  Created by ADK114019 on 2016/12/22.
//  Copyright © 2016年 ADK114019. All rights reserved.
//

import Foundation


public class BleManager {
    public static let sharedInstance: BleManager = BleManager()
    var bleCentralManager:BleCentralManager!;
    var blePeripheralManager:BlePeripheralManager!;
    
    var _serviceUUID:String!
    var _charUUID:String!
    var _ncMsg:String!
    
//    public var serviceUUID:String {
//        get {
//            return _serviceUUID
//        }
//        set {
//            _serviceUUID = newValue
//        }
//    }
//    
//    public var charUUID:String {
//        get {
//            return _charUUID
//        }
//        set {
//            _charUUID = newValue
//        }
//    }
//    
//    public var ncMsg:String {
//        get {
//            return _ncMsg
//        }
//        set {
//            _ncMsg = newValue
//        }
//    }
    
    
    
    
    fileprivate init() {
        self.bleCentralManager = BleCentralManager.sharedInstance;
        self.blePeripheralManager = BlePeripheralManager.sharedInstance
    }
    
    public func setUUID(serviceUUID:String, charUUID:String, ncMsg:String) {
        self._serviceUUID = serviceUUID
        self._charUUID = charUUID
        self._ncMsg = ncMsg
        self.bleCentralManager.setInitData(serviceUUID: serviceUUID, charUUID: charUUID, ncMsg: ncMsg)
        self.blePeripheralManager.setInitData(serviceUUID: serviceUUID, charUUID: charUUID, ncMsg: ncMsg)
    }
    
    public func write(msg:String?, statusDidWrite:String?) {
        bleCentralManager.writeMsg(msg, statusDidWrite: statusDidWrite)
    }
    
    
    public func read() {
        
    }
}

public class BleDataFormat {
    var dataType:CharacterType = .None
    var notificationMsg:String = ""
    
}

public enum CharacterType {
    case Float, Double, Int, String, Data, None
}
