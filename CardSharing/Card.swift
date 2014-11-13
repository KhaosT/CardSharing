//
//  Card.swift
//  CardSharing
//
//  Created by Khaos Tian on 11/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import Foundation
import AddressBook

class Card: Printable {
    var personInfo: ABRecord
    
    var name: String?
    var phone: String?
    var email: String?
    
    init(person: ABRecord) {
        self.personInfo = person
        self.processABRecord()
    }
    
    init(data: NSData) {
        let adressBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, nil).takeUnretainedValue()
        let source: ABRecord = ABAddressBookCopyDefaultSource(adressBook).takeUnretainedValue()
        let people: [ABRecord] = ABPersonCreatePeopleInSourceWithVCardRepresentation(source, data).takeUnretainedValue()
        self.personInfo = people[0]
        self.processABRecord()
    }
    
    func processABRecord() {
        self.name = "\(ABRecordCopyCompositeName(self.personInfo).takeUnretainedValue())"
        if let phoneValues = ABRecordCopyValue(self.personInfo,kABPersonPhoneProperty) {
            let phones = ABMultiValueCopyArrayOfAllValues(phoneValues.takeUnretainedValue()).takeUnretainedValue() as? [String]
            self.phone = phones?[0]
        }
        if let emailValues = ABRecordCopyValue(self.personInfo,kABPersonEmailProperty){
            let emails = ABMultiValueCopyArrayOfAllValues(emailValues.takeUnretainedValue()).takeUnretainedValue() as? [String]
            self.email = emails?[0]

        }
    }
    
    func vCardData() -> NSData {
        var newPerson: ABRecord = ABPersonCreate().takeUnretainedValue()
        
        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, self.name!, nil)
        
        if let phone = self.phone {
            let phones: ABMutableMultiValue = ABMultiValueCreateMutable(UInt32(kABMultiStringPropertyType)).takeUnretainedValue()
            ABMultiValueAddValueAndLabel(phones, phone, kABPersonPhoneMobileLabel, nil);
            ABRecordSetValue(newPerson, kABPersonPhoneProperty, phones, nil)
        }
        if let email = self.email {
            let emails: ABMutableMultiValue = ABMultiValueCreateMutable(UInt32(kABMultiStringPropertyType)).takeUnretainedValue()
            ABMultiValueAddValueAndLabel(emails, email, kABOtherLabel, nil);
            ABRecordSetValue(newPerson, kABPersonEmailProperty, emails, nil)
        }
        
        let peopleArray: CFArray = [newPerson]
        let vCardData: NSData = ABPersonCreateVCardRepresentationWithPeople(peopleArray).takeRetainedValue()
        return vCardData
    }
    
    var description: String {
        get{
            var desc = "<Card:"
            if let name = self.name {
                desc += "\(name)"
            }
            if let phone = self.phone {
                desc += ",\(phone)"
            }
            if let email = self.email {
                desc += ",\(email)"
            }
            desc += ">"
            return desc
        }
    }
}