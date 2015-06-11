//
//  ViewController.swift
//  HealthkitWorkshop
//
//  Created by Mad Max on 11/06/15.
//  Copyright (c) 2015 HAN. All rights reserved.
//

import UIKit
import HealthKit

class MainViewController: UIViewController {
	let healthStore = HKHealthStore()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		authorizeHealthKit()
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "heartRateDisplay" {
			if let happinessViewController = segue.destinationViewController as? HappinessViewController {
				happinessViewController.healthStore = healthStore
			}
		}
	}
	func autorizationComplete(success: Bool,  error: NSError?) -> Void {
		if success {
			println("HealthKit authorization received.")
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.performSegueWithIdentifier("heartRateDisplay", sender: self)
			})
		} else {
			println("HealthKit authorization denied!")
			if error != nil {
				println("\(error)")
			}
		}
	}
	
	private func authorizeHealthKit() {
		// Bron: http://www.raywenderlich.com/86336/ios-8-healthkit-swift-getting-started
		// 1. Set the types you want to read from HK Store
		let healthKitTypesToRead: [HKObjectType] = [
			HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth),
			HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
		]
		
		// 2. Set the types you want to write to HK Store
		let healthKitTypesToWrite: [HKObjectType] = [
			/*HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)*/
		]
		
		// 3. If the store is not available (for instance, iPad) return an error and don't go on.
		if !HKHealthStore.isHealthDataAvailable() {
			let error = NSError(domain: "han.ica.mad.HealthKitWorkshop", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
			autorizationComplete(false, error:error)
			return;
		}
		
		// 4.  Request HealthKit authorization
		healthStore.requestAuthorizationToShareTypes(Set(healthKitTypesToWrite), readTypes: Set(healthKitTypesToRead), completion: autorizationComplete)
	}
	
}

