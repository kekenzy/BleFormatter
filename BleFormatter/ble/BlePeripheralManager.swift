//
//  BlePeripheralManager.swift
//  BleChatAdvance
//
//  Created by ADK114019 on 2015/12/10.
//  Copyright © 2015年 Kenji Nagai. All rights reserved.
//

import Foundation
import CoreBluetooth


class BlePeripheralManager: NSObject,CBPeripheralManagerDelegate {
    
    static let sharedInstance: BlePeripheralManager = BlePeripheralManager()
    var peripheralManager: CBPeripheralManager!
    var characteristic: CBMutableCharacteristic!
    var serviceUUID: CBUUID?
    var characteristicUUID: CBUUID?
    var ncMsg: String?
    
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // ペリフェラルマネージャ初期化
//        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    
    // =========================================================================
    // MARK: Private
    override fileprivate init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    
    func setInitData(serviceUUID:String, charUUID:String, ncMsg:String) {
        self.serviceUUID = CBUUID(string:serviceUUID)
        self.characteristicUUID = CBUUID(string:charUUID)
        self.ncMsg = ncMsg
    }
    
    func publishservice () {
        
        // サービスを作成
        let service = CBMutableService(type: serviceUUID!, primary: true)
        
        let properties: CBCharacteristicProperties =
        [CBCharacteristicProperties.notify, CBCharacteristicProperties.read, CBCharacteristicProperties.write]
        
        let permissions: CBAttributePermissions =
        [CBAttributePermissions.readable, CBAttributePermissions.writeable]
        
        self.characteristic = CBMutableCharacteristic(
            type: characteristicUUID!,
            properties: properties,
            value: nil,
            permissions: permissions)
        
        // キャラクタリスティックをサービスにセット
        service.characteristics = [self.characteristic]
        
        // サービスを Peripheral Manager にセット
        self.peripheralManager.add(service)
        
        // 値をセット
        let value = UInt8(arc4random() & 0xFF)
        let data = Data(bytes: UnsafePointer<UInt8>([value]), count: 1)
        self.characteristic.value = data;
    }
    
    // =========================================================================
    // MARK: Public
    func startAdvertise() {
        
        if self.peripheralManager.isAdvertising {
            return
        }
        
        let uuid = UUID().uuidString
        // アドバタイズメントデータを作成する
        let advertisementData = [
            CBAdvertisementDataLocalNameKey:uuid,
            CBAdvertisementDataServiceUUIDsKey: [self.serviceUUID]
        ] as [String : Any]
        
        // アドバタイズ開始
        self.peripheralManager.startAdvertising(advertisementData as [String : AnyObject])
        
    }
    
    func stopAdvertise () {
        // アドバタイズ停止
        self.peripheralManager.stopAdvertising()
        
    }
    
    
    // =========================================================================
    // MARK: CBPeripheralManagerDelegate
    
    // ペリフェラルマネージャの状態が変化すると呼ばれる
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        DLOG(LogKind.PE,message: "state: \(peripheral.state)")
        
        if #available(iOS 10.0, *) {
            switch peripheral.state {
                
            case CBManagerState.poweredOn:
                // サービス登録開始
                self.publishservice()
                break
                
            default:
                break
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    // サービス追加処理が完了すると呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        
        if (error != nil) {
            DLOG(LogKind.PE,message:"サービス追加失敗！ error: \(error)")
            return
        }
        
        DLOG(LogKind.PE,message:"サービス追加成功！")
        
        // アドバタイズ開始
        self.startAdvertise()
    }
    
    // アドバタイズ開始処理が完了すると呼ばれる
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        
        if (error != nil) {
            DLOG(LogKind.PE,message:"アドバタイズ開始失敗！ error: \(error)")
            return
        }
        
        DLOG(LogKind.PE,message:"アドバタイズ開始成功！")
    }
    
    // Readリクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
        var value:NSString? = nil
        if request.characteristic.value != nil {
            value = NSString(data: request.characteristic.value!, encoding: String.Encoding.utf8.rawValue)
            
        }
        DLOG(LogKind.PE,message:"Readリクエスト受信！ requested service uuid:\(request.characteristic.service.uuid) characteristic uuid:\(request.characteristic.uuid) value:\(value)")
        
        // プロパティで保持しているキャラクタリスティックへのReadリクエストかどうかを判定
        if request.characteristic.uuid.isEqual(self.characteristic.uuid) {
            
            // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
            request.value = self.characteristic.value;
            
            // リクエストに応答
            self.peripheralManager.respond(to: request, withResult: CBATTError.Code.success)
        }
    }
    
//    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
//    }
    
    // Writeリクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {

        DLOG(LogKind.PE,message:"\(requests.count) 件のWriteリクエストを受信！")

        for request in requests {
            
            DLOG(LogKind.PE,message:"Requested service uuid:\(request.characteristic.service.uuid) characteristic uuid:\(request.characteristic.uuid)")
            
            if request.characteristic.uuid.isEqual(self.characteristic.uuid) {
                
                // CBMutableCharacteristicのvalueに、CBATTRequestのvalueをセット
                self.characteristic.value = request.value;
                DLOG(LogKind.PE,message:"\(requests.count) 件のWriteリクエストを受信！")
                let nc = NotificationCenter.default
                if self.characteristic.value != nil {
                    let value = NSString(data: self.characteristic.value!, encoding: String.Encoding.utf8.rawValue)
                    nc.post(name: Notification.Name(rawValue: self.ncMsg!), object: nil, userInfo: ["message" : value!.description])
                }
                
            }
        }

        // リクエストに応答
        self.peripheralManager.respond(to: requests[0] , withResult: CBATTError.Code.success)
    }
    
    
    // Notify開始要求
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        DLOG(LogKind.PE,message:"Notify開始要求受信！")
    }
    
    // Notify開始要求
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        DLOG(LogKind.PE,message:"Notify停止要求受信！")
    }
    
}

