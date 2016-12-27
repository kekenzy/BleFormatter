//
//  BleDataFormat.swift
//  BleFormatter
//
//  Created by ADK114019 on 2016/12/26.
//  Copyright © 2016年 ADK114019. All rights reserved.
//

import Foundation
import CoreBluetooth


public struct BleDataFormat {
    public var characteristicUUID:CBUUID!
    public var dataType:BleDataType
    public var value:Data
    
//    fileprivate init() {
//    }
    
    public init(uuid:String, dataType dType:BleDataType) {
        self.characteristicUUID = CBUUID(string:uuid)
        self.dataType = dType
        self.value = Data()
    }
    
    public mutating func setData(_ data:Data) {
        self.value = data
    }
    
    public func getStringFromValue() -> String {
        let str = NSString(data: self.value, encoding: String.Encoding.utf8.rawValue)!
        let values:[String] = str.components(separatedBy: ",")
        if values.count < 1 {
            return ""
        }
        return values[0]
    }
    
    public func getIntFromValue() -> Int {
        let str = NSString(data: self.value, encoding: String.Encoding.utf8.rawValue)!
        let values:[String] = str.components(separatedBy: ",")
        if values.count < 1 {
            return Int(0)
        }
        return Int(values[0] as String)!
    }
    
    public func getDoubleFromValue() -> Double {
        let str = NSString(data: self.value, encoding: String.Encoding.utf8.rawValue)!
        let values:[String] = str.components(separatedBy: ",")
        if values.count < 1 {
            return Double(0)
        }
        return Double(values[0] as String)!
    }
    
    public func getPostName() -> String {
        let str = NSString(data: self.value, encoding: String.Encoding.utf8.rawValue)!
        let values:[String] = str.components(separatedBy: ",")
        if values.count < 2 {
            return ""
        }
        return values[1]
    }
    
    public func getDataFromValue() -> Data {
        return self.value
    }
}

public enum BleDataType {
    case Double, Int, String, Data
}

public enum BleDataKey {
    case NOTIFY_WRITE, NOTIFY_READ, VALUE
    public func description() -> String {
        switch  self {
        case .NOTIFY_WRITE:
            return "NOTIFY_WRITE"
        case .NOTIFY_READ:
            return "NOTIFY_READ"
        case .VALUE:
            return "VALUE"
        }
    }
}

enum BleStatus {
    case DID_WRITE
    case DID_READ
    func description() -> String {
        switch  self {
        case .DID_WRITE:
            return "DID_WRITE"
        case .DID_READ:
            return "DID_READ"
        }
        
    }
}
