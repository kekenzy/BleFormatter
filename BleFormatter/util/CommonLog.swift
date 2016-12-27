//
//  CommonLog.swift
//  BleChatAdvance
//
//  Created by USER on 2015/12/11.
//  Copyright © 2015年 Kenji Nagai. All rights reserved.
//

import Foundation

enum LogKind:String {
    case COM, BM, CE, PE
    func logText()-> String {
        switch(self){
        case .COM:
            return "[COM]"
        case .BM:
            return "[BM]"
        case .CE:
            return "[CE]"
        case .PE:
            return "[PE]"
        }
    }
}

func DLOG(_ id:LogKind, message: String) {
    LOG(id.logText() + message)
}

func LOG(_ message: String,
    file: String = #file,
    line: Int = #line) {
        
        #if DEBUG
//            print("\(message) (File: \(file), Line: \(line))")
            print("\(message)")
//            let nc = NSNotificationCenter.defaultCenter()
//            nc.postNotificationName(NC_MSG, object: nil, userInfo: ["message" : message])
        #endif
}
