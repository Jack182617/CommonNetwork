//
//  NetManager.swift
//  SpeedR_Network
//
//  Created by 袁杰 on 2022/9/30.
//

import Foundation
import Moya
import HandyJSON
import ProgressHUD
import Toast_Swift

let scenes = UIApplication.shared.connectedScenes
let windowScene = scenes.first as? UIWindowScene
let rootWindow = windowScene?.windows.last

public func g_showHUD(_ string: String) {
    ProgressHUD.show(string, interaction: false)
}

public func g_dismissHUD() {
    ProgressHUD.dismiss()
}

public func g_showInfo(_ string: String?) {
    DispatchQueue.main.async {
        rootWindow?.makeToast(string, duration: 1.0, position: .center)
    }
}


// Moya 配置
public protocol TargetHudProtocol {
    var showLoadHud: Bool { get }
}

extension TargetHudProtocol {
    var showLoadHud: Bool { false }
}

public typealias DefultMoyaType = TargetType & TargetHudProtocol

typealias DefultDict = [String: Any]

public typealias DefultProgressBlock = (Double) -> Void
public typealias DefultModelBlock<T> = (T?) -> Void
public typealias DefultArrayBlock<T> = ([T?]?) -> Void
public typealias DefultAnyBlock = (Any?) -> Void
public typealias DefultNetworkErrorBlock = (PublicNetError) -> Void

fileprivate let noTipCode = [140001, 140002, 10011, 12023, 150301]

public struct NetWorkManager<R: DefultMoyaType, T: HandyJSON> {
    @discardableResult
    public static func requestDataToDict(_ type: R,
                                         dictCompletion: DefultAnyBlock?,
                                         errorBlock: DefultNetworkErrorBlock? = nil) -> Cancellable {
        return request(type, dictCompletion: dictCompletion, errorBlock: errorBlock)
    }

    @discardableResult
    public static func requestDataToModel(_ type: R,
                                          progressBlock: DefultProgressBlock? = nil,
                                          completionBlock: DefultModelBlock<T>?,
                                          errorBlock: DefultNetworkErrorBlock? = nil) -> Cancellable {
        return request(type, progressBlock: progressBlock, modelCompletion: completionBlock, errorBlock: errorBlock)
    }

    @discardableResult
    public static func requestDataToArray(_ type: R,
                                          progressBlock: DefultProgressBlock? = nil,
                                          completionBlock: DefultArrayBlock<T?>?,
                                          errorBlock: DefultNetworkErrorBlock? = nil) -> Cancellable {
        return request(type, progressBlock: progressBlock, arrayCompletion: completionBlock, errorBlock: errorBlock)
    }

    @discardableResult
    static func request(_ type: R,
                        progressBlock: DefultProgressBlock? = nil,
                        dictCompletion: DefultAnyBlock? = nil,
                        modelCompletion: DefultModelBlock<T>? = nil,
                        arrayCompletion: DefultArrayBlock<T?>? = nil,
                        errorBlock: DefultNetworkErrorBlock? = nil) -> Cancellable {
        let provider = createRequestProvider(type: type)
        let cancellable = provider.request(type, callbackQueue: DispatchQueue.global(), progress: { moyaProgress in
            DispatchQueue.main.async {
                progressBlock?(moyaProgress.progress)
            }
        }) { result in

            switch result {
            case let .success(moyaResponse):
                DispatchQueue.main.async {
                    if let temp = dictCompletion {
                        self.handleSuccess(type, response: moyaResponse, dictCompletion: temp, errorBlock: errorBlock)
                    }
                    if let temp = modelCompletion {
                        self.handleSuccess(type, response: moyaResponse, modelCompletion: temp, errorBlock: errorBlock)
                    }
                    if let temp = arrayCompletion {
                        self.handleSuccess(type, response: moyaResponse, arrayCompletion: temp, errorBlock: errorBlock)
                    }
                }

            case let .failure(moyaError):
                DispatchQueue.main.async {
                    guard let error = errorBlock else { return }
                    error(PublicNetError.resError(code: moyaError.errorCode, data: nil, message: moyaError.errorDescription))

                }
            }
        }
        return cancellable
    }
}
extension NetWorkManager{
    /// 创建一个请求
    static func createRequestProvider<R: DefultMoyaType>(type: R, test _: Bool = false) -> MoyaProvider<R> {
        let activityPlugin = NetworkActivityPlugin { change, _ in
            switch change {
            case .began:
                DispatchQueue.main.async {
                    if type.showLoadHud {
                        //                        g_showHUD()
                    }
                }

            case .ended:
                DispatchQueue.main.async {
                    if type.showLoadHud {
                        //                        g_hideHUD()
                    }
                }
            }
        }
        let requestClosure = { (endpoint: Endpoint, done: @escaping MoyaProvider<R>.RequestResultClosure) in
            do {
                var request = try endpoint.urlRequest()
                request.timeoutInterval = 30
                done(.success(request))
            } catch {
                return
            }
        }
        let provider = MoyaProvider<R>(requestClosure: requestClosure, plugins: [activityPlugin])
        return provider
    }

    /// 处理成功的响应
    static func handleSuccess(_ type: R, response: Response, dictCompletion: DefultAnyBlock? = nil, modelCompletion: DefultModelBlock<T>? = nil, arrayCompletion: DefultArrayBlock<T?>? = nil, errorBlock: DefultNetworkErrorBlock? = nil)
    {
        do {
            if let completion = dictCompletion {
                let data = try handleResponseData(type: type, isDecode: false, respond: response)
                completion(data.2)
            }
            if let completion = modelCompletion {
                let data = try handleResponseData(type: type, respond: response)
                completion(data.0)
            }
            if let completion = arrayCompletion {
                let data = try handleResponseData(type: type, isArray: true, respond: response)
                completion(data.1)
            }

        } catch let PublicNetError.DTMFailed(message) {
            g_showInfo(message)
            guard let error = errorBlock else { return }
            error(PublicNetError.DTMFailed(message))

        } catch let PublicNetError.DTAFailed(message) {
            g_showInfo(message)
            guard let error = errorBlock else { return }
            error(PublicNetError.DTAFailed(message))

        } catch let PublicNetError.resError(code, data, message) {
            let text = message
            if !noTipCode.contains(code) {
                g_showInfo(text)
            }
            guard let error = errorBlock else { return }
            error(PublicNetError.resError(code: code, data: data, message: message))

        } catch let PublicNetError.custom(message) {
            g_showInfo(message)
            guard let error = errorBlock else { return }
            error(PublicNetError.custom(msg: message))

        } catch {
            g_showInfo(error.localizedDescription)
        }
    }

    /// 处理数据
    static func handleResponseData<R: DefultMoyaType>(type: R, isArray: Bool = false, isDecode: Bool = true, respond: Response) throws -> (T?, [T?]?, Any?) {
#if DEBUG
        print("""

            ========================   START    ========================
            URL      ===> \(respond.request?.url?.absoluteString ?? "没有req.url")
            method   ===> \(String(describing: respond.request?.method))
            headers  ===> \(String(describing: respond.request?.headers.dictionary))
            body     ===> \(String(data: respond.request?.httpBody ?? "没有req.httpBody".dataEncoded, encoding: .utf8) ?? "")
            返回结果   ===> \(String(data: respond.data, encoding: .utf8) ?? "💔💔respond.data => sting 为空💔💔")
            """)
#endif
        guard let dict = try? JSONSerialization.jsonObject(with: respond.data, options: []) as? DefultDict? else {
            throw type.path.isEmpty ? PublicNetError.resError(code: 0, data: nil, message: nil) : PublicNetError.custom(msg: "数据出现了小错误，请稍等片刻~")
        }

        guard let code = dict!["code"] as? Int, let message = dict!["message"] as? String, let data = dict!["data"] else {
            throw PublicNetError.custom(msg: "服务器出了点小错误，请稍等片刻~")
        }
        /// 不转模型
        if !isDecode {
            if code == 0 {
                return (nil, nil, data)
            } else {
                throw PublicNetError.resError(code: code, data: data, message: message)
            }
        }else{
            switch code {
            case 0:
                if !isArray {
                    let jsonStr = String(data: respond.data, encoding: String.Encoding.utf8)
                    let model = JSONDeserializer<T>.deserializeFrom(json: jsonStr, designatedPath: "data")

                    return (model, nil, nil)
                } else {
                    let jsonStr = String(data: respond.data, encoding: String.Encoding.utf8)
                    let model = JSONDeserializer<T>.deserializeModelArrayFrom(json: jsonStr, designatedPath: "data")

                    return (nil, model, nil)
                }

            default:
                throw PublicNetError.resError(code: code, data: data, message: message)
            }
        }


    }
}

public extension String {
    var dataEncoded: Data { data(using: .utf8)! }
}
