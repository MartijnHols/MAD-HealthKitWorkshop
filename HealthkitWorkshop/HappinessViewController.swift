//
//  HappinessViewController.swift
//  Happiness
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit
import HealthKit

class HappinessViewController: UIViewController, FaceViewDataSource
{
	var healthStore: HKHealthStore?
	
	override func viewDidLoad() {
		refresh()
	}
	@IBAction func refresh_click(sender: UIButton) {
		refresh()
	}
	func refresh() {
		let age = getAge()
		println("Age: \(age)")
		updateHeartRate()
	}

    @IBOutlet weak var heartRateLabel: UILabel!
    
    var happiness: Int = 50 { // 0 = very sad, 100 = ecstatic
        didSet {
            happiness = min(max(happiness, 0), 100)
            updateUI()
        }
    }
    
    func updateUI() {
        // in L7, we discovered that we have to be careful here
        // we can't just unwrap the implicitly unwrapped optional faceView
        // that's because outlets are not set during segue preparation
        faceView?.setNeedsDisplay()
        // note that this MVC is setting its own title
        // often there is no one more suited to set an MVCs title than itself
        // but other times another MVC might want to set it (title is public)
        title = "\(happiness)"
    }
    
    func smilinessForFaceView(sender: FaceView) -> Double? {
        return Double(happiness)
    }

    @IBOutlet weak var faceView: FaceView! {
        didSet {
            faceView.dataSource = self
            faceView.addGestureRecognizer(UIPinchGestureRecognizer(target: faceView, action: "scale:"))
        }
	}
	
	func bpmToHappiness(dbpm: Double?) -> Double {
		if dbpm == nil {
			return 50
		} else {
			let bpm = dbpm!
			if bpm < 45 {
				return bpm / 40 * 15
			} else if bpm < 60.0 {
				return bpm / 60.0 * 40
			} else if bpm > 100.0 {
				// 0-40
				return (80.0 - (min(bpm, 180.0) - 100)) / 80.0 * 40.0
			} else {
				if bpm < 68.0 {
					return 50.0 + (bpm - 60.0) / 8.0 * 50.0
				} else {
					return 50.0 + (32 - (bpm - 68.0)) / 32.0 * 50.0
				}
			}
		}
	}
	
	func getAge() -> Int? {
		var error: NSError?
		var age: Int?
		
		// 1. Request birthday and calculate age
		if let birthDay = healthStore!.dateOfBirthWithError(&error) {
			let today = NSDate()
			let calendar = NSCalendar.currentCalendar()
			let differenceComponents = NSCalendar.currentCalendar().components(.CalendarUnitYear, fromDate: birthDay, toDate: today, options: NSCalendarOptions(0) )
			age = differenceComponents.year
		}
		if error != nil {
			println("Error reading Birthday: \(error)")
		}
		
		return age
	}
	func updateHeartRate() {
		// 1. Construct an HKSampleType for weight
		let sampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
		
		// 2. Call the method to read the most recent weight sample
		readMostRecentSample(sampleType, completion: { (mostRecentHeartRate, error) -> Void in
			if error != nil {
				println("Error reading HeartRate from HealthKit Store: \(error.localizedDescription)")
				return
			}
			
			let heartRate = mostRecentHeartRate as? HKQuantitySample
			let bpm = heartRate?.quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()))
			
			println("bpm=\(bpm)")
			
			// 4. Update UI in the main thread
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.happiness = Int(self.bpmToHappiness(bpm))
				println("self.happiness=\(self.happiness)")
				if bpm != nil {
					self.heartRateLabel.text = "\(Int(bpm!))"
				} else {
					self.heartRateLabel.text = "?"
				}
			});
		});
	}
	
	private func readMostRecentSample(sampleType: HKSampleType, completion: ((HKSample!, NSError!) -> Void)!) {
		// 1. Build the Predicate
		let past = NSDate.distantPast() as! NSDate
		let now = NSDate()
		let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
		
		// 2. Build the sort descriptor to return the samples in descending order
		let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
		// 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
		let limit = 1
		
		// 4. Build samples query
		let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor], resultsHandler: { (sampleQuery, results, error ) -> Void in
			if let queryError = error {
				completion(nil,error)
				return
			}
			
			// Get the first sample
			let mostRecentSample = results.first as? HKQuantitySample
			
			// Execute the completion closure
			if completion != nil {
				completion(mostRecentSample, nil)
			}
		})
		// 5. Execute the Query
		healthStore!.executeQuery(sampleQuery)
	}
}
