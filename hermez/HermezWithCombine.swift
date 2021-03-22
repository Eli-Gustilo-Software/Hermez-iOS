//
//  ZeroConfigWithCombine.swift
//  zeroconfig_test
//
//  Created by Nicholas Gustilo on 3/16/21.
//
import Foundation
import Combine

// TODO: handle errors

@available(iOS 13.0, *)
public class HermezWithCombine: NSObject {
    public static let shared = HermezWithCombine()
    
    public var messageObservable = PassthroughSubject<HermezMessage, Never>()
    public var devicesObservable = CurrentValueSubject<[HermezDevice], Never>([])
    
    private override init() {
        super.init()
        Hermez.shared.addDataDelegate(delegate: self)
        Hermez.shared.findAvailableDevices()
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

@available(iOS 13.0, *)
extension HermezWithCombine: HermezDataAvailable {
    public func availableDevices(devices: [HermezDevice]) {
        self.devicesObservable.send(devices)
    }
    
    public func messageReceived(message: HermezMessage) {
        self.messageObservable.send(message)
    }
}

