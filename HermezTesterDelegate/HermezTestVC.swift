//  HermezTextVC.swift
//  Created by Nicholas Gustilo on 2/26/21.

import UIKit
import Foundation
import Hermez

class HermezTestVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTF: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    
    private var data: [HermezMessage] = []
    private var devices: [HermezDevice] = []
    private var savedName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Hermez.shared.addDataDelegate(delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.checkForSavedName()
        if let deviceName = self.checkForSavedName() {
            self.nameLabel.text = deviceName
        }
    }
    
    @IBAction func sendMessage(sender: UIButton) {
        print("sendMessage")
        //ZeroConfigService.shared.publishService()
        if let message = inputTF.text {
            let identifier = UUID().uuidString
            Hermez.shared.sendMessageToDevices(message: message, json: nil, devices: self.devices, messageID: identifier)
            inputTF.text = nil
            inputTF.endEditing(true)
        }
    }
    
    private func checkForSavedName() -> String? {
        if let name = UserDefaults.standard.string(forKey: "saved_device_name") {
            return name
        } else {
            let alert = UIAlertController(title: "Name", message: "Enter name", preferredStyle: .alert)

            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.placeholder = "your name"
            }

            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                print("Text field: \(textField?.text)")
                if let name = textField?.text {
                    UserDefaults.standard.set(name, forKey: "saved_device_name")
                    UserDefaults.standard.synchronize()
                    self.nameLabel.text = name
                    if !Hermez.shared.setServiceAndDeviceName(serviceName: "blah", deviceName: name, deviceJson: nil) {
                        print("ERROR setServiceAndDeviceName FAILED!!!!")
                    } else {
                        Hermez.shared.findAvailableDevices()
                    }
                }
            }))

            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        return nil
    }
}

extension HermezTestVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = self.data[indexPath.row]
        if let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") {
            cell.textLabel?.text = message.sendingDevice.name
            cell.detailTextLabel?.text = message.message
            return cell
        } else {
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
            cell.textLabel?.text = message.sendingDevice.name
            cell.detailTextLabel?.text = message.message
            return cell
        }
        //return cell
    }
}

extension HermezTestVC: HermezDataProtocol {
    func serviceStarted(serviceType: String, serviceName: String) {
        print("serviceStarted type = \(serviceType), name: \(serviceName)")
        Hermez.shared.findAvailableDevices()
    }
    
    func serviceStopped(serviceType: String, serviceName: String) {
        print("serviceStopped type = \(serviceType), name: \(serviceName)")
    }
    
    func availableDevices(devices: [HermezDevice]) {
        for device in devices {
            print("availableDevice = \(device.name)")
            if isNewDevice(device: device) {
                self.devices.append(device)
            }
        }
    }
    
    func messageReceived(message: HermezMessage) {
        self.data.insert(message, at: 0)
        self.tableView.reloadData()
    }
    
    private func isNewDevice(device: HermezDevice) -> Bool {
        for currentDevice in devices {
            if currentDevice.name == device.name {
                return false
            }
        }
        return true
    }
}
