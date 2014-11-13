//
//  CardViewController.swift
//  CardSharing
//
//  Created by Khaos Tian on 11/12/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit

class CardViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subtextLabel1: UILabel!
    @IBOutlet weak var subtextLabel2: UILabel!
    
    weak var callback: ViewController?
    
    var infoCard: Card? {
        didSet {
            if self.nameLabel != nil {
                self.updateTexts()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let info = self.infoCard {
            self.updateTexts()
        }
    }
    
    func updateTexts() {
        let font = UIFont(name: "HelveticaNeue-Bold", size: 60)!
        let textColor = UIColor.orangeColor()
        let attrs = [NSForegroundColorAttributeName : textColor, NSFontAttributeName : font, NSTextEffectAttributeName : NSTextEffectLetterpressStyle]
        var attrString = NSAttributedString(string: self.infoCard!.name!, attributes: attrs)
        self.nameLabel.attributedText = attrString
        
        if let phone = infoCard!.phone {
            self.subtextLabel1.text = "TEL: \(phone)"
        }
        
        if let email = infoCard!.email {
            self.subtextLabel2.text = "EMAIL: \(email)"
        }
    }
    
    @IBAction func stopBroadcasting(sender: AnyObject) {
        self.callback?.stopBroadcasting()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
