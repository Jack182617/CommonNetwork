//
//  NetError.swift
//  SpeedR_Network
//
//  Created by 袁杰 on 2022/9/30.
//

import Foundation

public enum PublicNetError: Error {
    //data-model
    case DTMFailed(_ msg: String)
    //data-array
    case DTAFailed(_ msg: String)
    //服务器error
    case resError(code: Int, data: Any?, message: String?)
    //自定义error
    case custom(msg: String)
}
extension PublicNetError {
    var code: Int? {
        switch self {
        case .DTMFailed:
            return nil
        case .DTAFailed:
            return nil
        case let .resError(code, _, _):
            return code
        case .custom:
            return nil
        }
    }
    var data: Any? {
        switch self {
        case .DTMFailed:
            return nil
        case .DTAFailed:
            return nil
        case let .resError(_, data, _):
            return data
        case .custom:
            return nil
        }
    }
    var message: String? {
        switch self {
        case let .DTMFailed(msg):
            return msg
        case let .DTAFailed(msg):
            return msg
        case let .resError(_, _, msg):
            return msg
        case let .custom(msg):
            return msg
        }
    }
}
