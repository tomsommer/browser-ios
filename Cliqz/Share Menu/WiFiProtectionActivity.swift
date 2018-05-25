//
//  WiFiProtectionActivity.swift
//  Client
//
//  Created by Sahakyan on 5/24/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation

let ShowWifiProtectionNotification = NSNotification.Name(rawValue: "ShareMenu.ShowWifiProtection")

class WiFiProtectionActivity : UIActivity {
	
	override var activityTitle : String? {
		return NSLocalizedString("Wifi Protection", tableName: "Cliqz", comment: "Sharing activity for opening Settings")
	}
	
	override var activityImage : UIImage? {
		return UIImage(named: "settings")
	}
	
	override var activityType: UIActivityType? {
		return UIActivityType("com.cliqz.settings")
	}
	
	override func perform() {
		NotificationCenter.default.post(name: ShowWifiProtectionNotification, object: nil)
		activityDidFinish(true)
	}
	
	override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
		return true
	}
}
