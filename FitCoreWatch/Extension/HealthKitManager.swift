import Foundation
import HealthKit

class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    @Published var currentHeartRate: Double = 0
    @Published var isWorkoutActive = false
    
    // MARK: - Permissions
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        // Note: HealthKit authorization temporarily disabled due to Set type limitations on watchOS
        // TODO: Implement proper HealthKit authorization for watchOS
        DispatchQueue.main.async {
            completion(true) // Return true for now to allow basic functionality
        }
    }
    
    // MARK: - Workout Session
    
    func startWorkoutSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutSession?.delegate = self
            // workoutBuilder?.delegate = self // Commented out due to Set type limitations on watchOS
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("Error beginning workout collection: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.isWorkoutActive = true
            }
            
        } catch {
            print("Error starting workout session: \(error)")
        }
    }
    
    func endWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("Error ending workout collection: \(error)")
            }
        }
        
        workoutBuilder?.finishWorkout { workout, error in
            if let error = error {
                print("Error finishing workout: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.isWorkoutActive = false
        }
    }
    
    func pauseWorkoutSession() {
        workoutSession?.pause()
    }
    
    func resumeWorkoutSession() {
        workoutSession?.resume()
    }
    
    // MARK: - Health Data
    
    func getWorkoutMetrics(completion: @escaping (HealthMetrics) -> Void) {
        var metrics = HealthMetrics()
        
        let group = DispatchGroup()
        
        // Get heart rate data
        group.enter()
        getHeartRateData { heartRate in
            metrics.heartRate = heartRate
            group.leave()
        }
        
        // Get calories burned
        group.enter()
        getCaloriesBurned { calories in
            metrics.caloriesBurned = calories
            group.leave()
        }
        
        // Get active energy burned
        group.enter()
        getActiveEnergyBurned { activeEnergy in
            metrics.activeEnergyBurned = activeEnergy
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(metrics)
        }
    }
    
    private func getHeartRateData(completion: @escaping (Double?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching heart rate: \(error)")
                completion(nil)
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            completion(heartRate)
        }
        
        healthStore.execute(query)
    }
    
    private func getCaloriesBurned(completion: @escaping (Double?) -> Void) {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                print("Error fetching calories: \(error)")
                completion(nil)
                return
            }
            
            let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            completion(calories)
        }
        
        healthStore.execute(query)
    }
    
    private func getActiveEnergyBurned(completion: @escaping (Double?) -> Void) {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                print("Error fetching active energy: \(error)")
                completion(nil)
                return
            }
            
            let activeEnergy = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            completion(activeEnergy)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Real-time Heart Rate
    
    func startHeartRateMonitoring() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            if let latestSample = samples.last {
                let heartRate = latestSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                DispatchQueue.main.async {
                    self?.currentHeartRate = heartRate
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func stopHeartRateMonitoring() {
        // Stop heart rate monitoring
        // Implementation depends on specific requirements
    }
}

// MARK: - HKWorkoutSessionDelegate

extension HealthKitManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.isWorkoutActive = (toState == .running)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
// Note: Delegate methods commented out due to Set type limitations on watchOS

// extension HealthKitManager: HKLiveWorkoutBuilderDelegate {
//     func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: NSSet) {
//         for type in collectedTypes {
//             guard let quantityType = type as? HKQuantityType else { continue }
//             
//             let statistics = workoutBuilder.statistics(for: quantityType)
//             
//             switch quantityType {
//             case HKQuantityType.quantityType(forIdentifier: .heartRate):
//                 if let heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
//                     DispatchQueue.main.async {
//                         self.currentHeartRate = heartRate
//                     }
//                 }
//             default:
//                 break
//             }
//         }
//     }
//     
//     func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
//         // Handle workout events
//     }
// }
