//
//  HermezService.swift
//
//  MIT license see,
//  https://github.com/Eli-Gustilo-Software/Hermez-iOS/blob/development/LICENSE
//
//  Created by Nicholas Gustilo on 2/26/21.
//

import Foundation
import CocoaAsyncSocket

enum PingTypes: String {
    case PING = "PING"
    case PING_CHECK = "PING CHECK"
}

protocol HermezServiceDataAvailable {
    func messageReceived(message: HermezMessage)
    func serviceStarted(serviceType: String, serviceName: String)
    func serviceStopped(serviceType: String, serviceName: String)
    func serviceFailed(serviceType: String, serviceName: String, error: HermezError)
}

class HermezService: NSObject {
    static let shared = HermezService()
    
    var serviceIsActive = false
    
    private var service = NetService()
    private var hostSocket = GCDAsyncSocket()
    private var connectSockets: [GCDAsyncSocket] = []
    private var dataDelegate: HermezServiceDataAvailable?
    private let ZC_DOMAIN = "local."
    private let ZC_PORT : UInt16 = 0// random
    private var device: HermezDevice? = nil
    
    func publishService(serviceType: String, name: String) -> Bool {
        hostSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        if let _ = try? hostSocket.accept(onPort: ZC_PORT) {
            self.service = NetService(domain: ZC_DOMAIN, type: serviceType, name: name, port: Int32(self.hostSocket.localPort))
            self.service.delegate = self
            self.service.publish()
            self.device = HermezDevice(name: name, jsonData: nil)
            return true
        } else {
            print("Unable to create socket.")
            return false
        }
    }
    
    func stopService() {
        self.service.stop()
        removeSocket()
        connectSockets.removeAll()
    }
    
    func setDataDelegate(newDelegate: HermezServiceDataAvailable) {
        self.dataDelegate = newDelegate
    }
    
    private func removeSocket() {
        hostSocket.delegate = nil
        hostSocket = GCDAsyncSocket()
    }
}

//MARK: - NetService Delegate
extension HermezService: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        let name = sender.name
        let type = sender.type
        print("Bonjour Service Published: domain'\(service.domain)' type'\(service.type)' name'\(service.name)' port'\(service.port)'")
        DispatchQueue.main.async {
            self.dataDelegate?.serviceStarted(serviceType: type, serviceName: name)
            self.serviceIsActive = true
        }
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
       print("Failed to Publish Service: domain'\(service.domain)' type'\(service.type)' name'\(service.name)' port'\(service.port)' error: \(errorDict)")
        let name = sender.name
        let type = sender.type
        DispatchQueue.main.async {
            self.dataDelegate?.serviceFailed(serviceType: type, serviceName: name, error: HermezError.SERVICE_FAILED)
            self.serviceIsActive = false
        }
    }
    
    func netServiceDidStop(_ sender: NetService) {
        let name = sender.name
        let type = sender.type
        DispatchQueue.main.async {
            self.dataDelegate?.serviceStopped(serviceType: type, serviceName: name)
            self.serviceIsActive = false
        }
    }
}

//MARK: - GCDAsyncSocket Delegate
extension HermezService: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        newSocket.delegate = self
        newSocket.delegateQueue = .main
        print("Accepted New Socket from \(String(describing: newSocket.connectedHost)):\(newSocket.connectedPort)", sock)
        newSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 2)
        connectSockets.append(newSocket)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let str = String(decoding: data, as: UTF8.self)
        print("DATA X Read HOST :", str, " aTag: \(tag), connected port : \(sock.connectedPort)")
        do {
            let message = try JSONDecoder().decode(HermezMessage.self, from: data)
            if(message.message != PingTypes.PING.rawValue) {
                if(message.message != PingTypes.PING_CHECK.rawValue) {
                    self.dataDelegate?.messageReceived(message: message)
                }
                let pingMessage = HermezMessage(message: PingTypes.PING.rawValue,
                                                jsonData: nil,
                                                messageID: message.messageID,
                                                receivingDevice: message.sendingDevice,
                                                sendingDevice: message.receivingDevice)
                if let messageAsJsonData = try? JSONEncoder().encode(pingMessage) {
                    let messageAsJsonString = String(data: messageAsJsonData, encoding: .utf8)!
                    let data = Data(messageAsJsonString.utf8) + GCDAsyncSocket.crlfData()
                    sock.write(data, withTimeout: -1.0, tag: 3)
                }
            }
        } catch {
            // TODO: reply with error could not parse
            //sendValue(str: "From ZerConfigService Test Send\r\n")
        }
        sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 2)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        let astr = "Host did write data on join port: \(sock.connectedPort)"
        print(astr)
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("\(sock) didConnectToHost \(host) ")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("Socket with port: \(sock.connectedPort) disconnected with error: \(err?.localizedDescription ?? "NULL")")
        self.connectSockets.removeAll{ $0 == sock }
    }
}

