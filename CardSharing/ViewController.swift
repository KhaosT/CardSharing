//
//  ViewController.swift
//  CardSharing
//
//  Created by Khaos Tian on 11/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import AddressBookUI

class ViewController: UIViewController, ABPeoplePickerNavigationControllerDelegate, BluetoothCoreProtocol {

    var peoplePicker: ABPeoplePickerNavigationController?
    var bluetoothCore: BluetoothCore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bluetoothCore = BluetoothCore(delegate: self)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func pickupCard(sender: AnyObject) {
        self.peoplePicker = ABPeoplePickerNavigationController()
        self.peoplePicker!.peoplePickerDelegate = self
        self.presentViewController(self.peoplePicker!, animated: true, completion: nil)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecord!) {
        let card = Card(person: person)
        var data = card.vCardData()
        self.bluetoothCore?.startBroadcastingCardData(data)
        self.dismissViewControllerAnimated(true, completion: {
            self.didGetNewCard(card)
        })
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, shouldContinueAfterSelectingPerson person: ABRecord!) -> Bool {
        return false
    }
    
    func stopBroadcasting() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.bluetoothCore?.stopAdvertising()
        self.bluetoothCore?.startScan()
    }
    
    func didGetNewCard(card: Card) {
        self.bluetoothCore?.stopScan()
        let cardVC = self.storyboard?.instantiateViewControllerWithIdentifier("CardViewController") as CardViewController
        cardVC.infoCard = card
        cardVC.callback = self
        self.presentViewController(cardVC, animated: true, completion: nil)
    }

}

