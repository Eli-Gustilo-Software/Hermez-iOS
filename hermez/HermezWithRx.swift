//
//  HermesWithRx.swift
//
//  MIT license see,
//  https://github.com/Eli-Gustilo-Software/Hermez-iOS/blob/development/LICENSE
//
//  Created by Nicholas Gustilo on 3/17/21.
//

import Foundation
import RxSwift

//TODO: handle errors
public class HermezWithRx: NSObject {
    public static let shared = HermezWithRx()
    
    public var devicesObservable = BehaviorSubject(value: [HermezDevice]())
    public var messagesObservable = PublishSubject<HermezMessage>()
    
    private override init() {
        super.init()
        Hermez.shared.addDataDelegate(delegate: self)
    }
    
    public func setServiceAndDeviceName(serviceName: String, deviceName: String, deviceJson: String?) -> Bool {
        return Hermez.shared.setServiceAndDeviceName(serviceName: serviceName, deviceName: deviceName, deviceJson: deviceJson)
    }
    
    public func findAvailableDevices() {
        Hermez.shared.findAvailableDevices()
    }
    
    public func sendMessageToDevices(message: String?, json: String?, devices: [HermezDevice], messageID: String) {
        Hermez.shared.sendMessageToDevices(message: message, json: json, devices: devices, messageID: messageID)
    }
    
    public func stopService() {
        Hermez.shared.stopService()
    }
}

extension HermezWithRx: HermezDataProtocol {
    public func availableDevices(devices: [HermezDevice]) {
        self.devicesObservable.onNext(devices)
    }
    
    public func messageReceived(message: HermezMessage) {
        self.messagesObservable.onNext(message)
    }
}


