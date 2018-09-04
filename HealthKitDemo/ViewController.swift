//
//  ViewController.swift
//  HealthKitDemo
//
//  Created by 杜文庆 on 2018/9/4.
//  Copyright © 2018年 FanXing. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        HKCharacteristicType  HKQuantityType  HKCategoryType  HKCorrelationType  HKWorkoutType
        //检测当前HealthKit是否可以使用
        if HKHealthStore.isHealthDataAvailable() {
            print("HealthKit可以使用")
            let typestoRead = Set([HKObjectType.workoutType(),
                 HKObjectType.quantityType(forIdentifier: .stepCount)!,
                 HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                 HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
                 HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                 HKObjectType.quantityType(forIdentifier: .heartRate)!])  //步数
            
            let typestoShare = Set([
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .distanceCycling)!,  //活动能量
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                HKObjectType.quantityType(forIdentifier: .heartRate)!])
            
            healthStore.requestAuthorization(toShare: typestoShare, read: typestoRead, completion: { [weak self] (success, error) in
                
                if !success {
                    NSLog("Display not allowed")
                }else {
                    
                    //写入
                    let now = Date()
                    let startDate = Date(timeInterval: -10, since: now)
                    let countUnit = HKUnit.count()
                    let countUnitQuantity = HKQuantity.init(unit: countUnit, doubleValue: 1000)
                    let countUnitType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
                    let stepCountSample = HKQuantitySample.init(type: countUnitType!, quantity: countUnitQuantity, start: startDate, end: now)

                    self?.healthStore.save(stepCountSample) { (isSuccess, error) in
                        if isSuccess {
                            print("保存成功 ----> \(isSuccess)")
                        }else {
                            print("error -----> \(String(describing: error))")
                        }
                    }
                    
                    self?.readStep()
                }
            })
        }
    }
    
    func readStep() {
        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        //NSSortDescriptors用来告诉healthStore怎么样将结果排序
        let start = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let stop  = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let now = Date()
        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("*** This method should never fail ***")
        }
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var dataCom = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        let endDate = calendar.date(from: dataCom)
        dataCom.hour = 0
        dataCom.minute = 0
        dataCom.second = 0
        let startDate = calendar.date(from: dataCom)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: HKQueryOptions.strictStartDate)
        
        var localSum: Double = 0  //手机写入步数
        var currentDeviceSum: Double = 0  //软件写入步数
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [start, stop]) { (query, results, error) in
            
            guard (results as? [HKQuantitySample]) != nil else {
//                fatalError("An error occured fetching the user's tracked food. In your app, try to handle this error gracefully. The error was: \(String(describing: error?.localizedDescription))");
                print("获取步数error ---> \(String(describing: error?.localizedDescription))")
                return
            }
            for res in results! {
                // res.sourceRevision.source.bundleIdentifier  当前数据来源的BundleId
                // Bundle.main.bundleIdentifier  当前软件的BundleId
                if res.sourceRevision.source.bundleIdentifier == Bundle.main.bundleIdentifier {
                    print("app写入数据")
                    let _res = res as? HKQuantitySample
                    currentDeviceSum = currentDeviceSum + (_res?.quantity.doubleValue(for: HKUnit.count()))!
                }else {     //手机录入数据
                    let _res = res as? HKQuantitySample
                    localSum = localSum + (_res?.quantity.doubleValue(for: HKUnit.count()))!
                }
            }
            print("当前步数  -- \(currentDeviceSum)")
            print("当前步数  -- \(localSum)")
//            DispatchQueue.main.async { [weak self] in
//
//            }
        }
        healthStore.execute(query)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

