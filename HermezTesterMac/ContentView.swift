//  ContentView.swift
//  Created by Nicholas Gustilo on 3/23/21.

import SwiftUI
import Hermez_Mac
import Combine

class UserSettings: ObservableObject {
    @Published var deviceName: String {
        didSet {
            UserDefaults.standard.set(deviceName, forKey: "device_name")
            UserDefaults.standard.synchronize()
        }
    }
    
    init() {
        self.deviceName = UserDefaults.standard.object(forKey: "device_name") as? String ?? ""
        print(deviceName)
    }
    
    func update() {
        self.deviceName = UserDefaults.standard.object(forKey: "device_name") as? String ?? ""
    }
}

class DevicesModel: ObservableObject {
    @Published var devices = [HermezDevice]()
    private var cancellable = Set<AnyCancellable>()

    func update() {
        HermezWithCombine.shared.devicesObservable.sink { devices in
            self.devices = devices
        }
        .store(in: &cancellable)
    }
    
    deinit {
        for currentCancellable in cancellable {
            currentCancellable.cancel()
        }
    }
}

class ExtendedHermezMessage: Equatable, Identifiable {
    var hermezMessage: HermezMessage
    
    init(hermezMessage: HermezMessage) {
        self.hermezMessage = hermezMessage
    }
    
    static func == (lhs: ExtendedHermezMessage, rhs: ExtendedHermezMessage) -> Bool {
        return lhs === rhs
    }
}

class MessagesModel: ObservableObject {
    @Published var messages = [ExtendedHermezMessage]()
    private var cancellable = Set<AnyCancellable>()

    func update() {
        HermezWithCombine.shared.messageObservable.sink { message in
            let extendedHermezMessage = ExtendedHermezMessage(hermezMessage: message)
            if !self.messages.contains(extendedHermezMessage) {
                self.messages.insert(extendedHermezMessage, at: 0)
            }
        }
        .store(in: &cancellable)
    }
    
    deinit {
        for currentCancellable in cancellable {
            currentCancellable.cancel()
        }
    }
}

struct ContentView: View {
    @ObservedObject var devicesModel = DevicesModel()
    @ObservedObject var messagesModel = MessagesModel()
    @ObservedObject var userSettings = UserSettings()
    
    @State var message = ""
    @State var deviceName = ""
    
    init() {
        devicesModel.update()
        messagesModel.update()
    }
    
    var body: some View {
        if userSettings.deviceName.lengthOfBytes(using: .utf8) > 0 {
            ScrollView {
                VStack {
                    Text(userSettings.deviceName)
                        .bold()
                        .font(.title3)
                        .padding()
                    
                    TextField(
                                "type something...",
                                text: $message,
                                onEditingChanged: {
                                    _ in print("changed")
                                    
                                },
                                onCommit: {
                                    print("commit")
                                    Hermez.shared.sendMessageToDevices(message: message, json: nil, devices: devicesModel.devices, messageID: UUID().uuidString)
                                    message = ""
                                }
                            )
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                    
                    ForEach(messagesModel.messages) { message in
                        HStack {
                            VStack (alignment: .leading) {
                                Text(message.hermezMessage.sendingDevice.name)
                                    .bold()
                                Text(message.hermezMessage.message ?? "no message")
                            }
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            
                            Spacer()
                        }
                    }
                    Spacer()
                }
            }
        } else {
            VStack {
                Text("Set Device Name")
                    .bold()
                    .font(.title3)
                    .padding()
                TextField(
                            "device name",
                            text: $deviceName,
                            onEditingChanged: {
                                _ in print("changed")
                                
                            },
                            onCommit: {
                                print("commit")
                                self.userSettings.deviceName = deviceName
                                if Hermez.shared.setServiceAndDeviceName(serviceName: "blah", deviceName: deviceName, deviceJson: nil) {
                                    Hermez.shared.findAvailableDevices()
                                }
                            }
                        )
                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
