import Flutter
import HealthKit
import UIKit

public class PedometerHealthPlugin: NSObject, FlutterPlugin {
  private let healthStore = HKHealthStore()
  private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "pedometer_health",
      binaryMessenger: registrar.messenger()
    )
    let instance = PedometerHealthPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(isAppleHealth(call) && HKHealthStore.isHealthDataAvailable())
    case "requestAuthorization":
      requestAuthorization(call, result: result)
    case "fetchDailySummaries":
      fetchDailySummaries(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestAuthorization(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard isAppleHealth(call) else {
      result(false)
      return
    }

    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    let readTypes = Set(quantityTypes(from: call))
    guard !readTypes.isEmpty else {
      result(FlutterError(code: "no_types", message: "No supported HealthKit data types requested", details: nil))
      return
    }

    healthStore.requestAuthorization(toShare: nil, read: readTypes) { granted, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "authorization_failed", message: error.localizedDescription, details: nil))
          return
        }
        result(granted)
      }
    }
  }

  private func fetchDailySummaries(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard isAppleHealth(call) else {
      result(FlutterError(code: "unsupported_source", message: "Health Connect is not available on iOS", details: nil))
      return
    }

    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "healthkit_unavailable", message: "HealthKit is not available on this device", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let startText = arguments["startDate"] as? String,
          let endText = arguments["endDate"] as? String,
          let startDate = formatter.date(from: startText),
          let endDate = formatter.date(from: endText) else {
      result(FlutterError(code: "bad_arguments", message: "Missing startDate or endDate", details: nil))
      return
    }

    let selectedNames = Set((arguments["types"] as? [String]) ?? defaultTypeNames())
    let calendar = Calendar.current
    let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
    var rows: [[String: Any]] = []
    var queryError: FlutterError?
    let group = DispatchGroup()
    let lock = NSLock()
    var current = startDate

    while current < endExclusive {
      let dayStart = current
      let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
      group.enter()
      fetchDay(start: dayStart, end: dayEnd, selectedNames: selectedNames) { row, error in
        lock.lock()
        if let error = error, queryError == nil {
          queryError = error
        }
        if let row = row {
          rows.append(row)
        }
        lock.unlock()
        group.leave()
      }
      current = dayEnd
    }

    group.notify(queue: .main) {
      if let queryError = queryError {
        result(queryError)
        return
      }
      result(rows.sorted { lhs, rhs in
        (lhs["date"] as? String ?? "") < (rhs["date"] as? String ?? "")
      })
    }
  }

  private func fetchDay(
    start: Date,
    end: Date,
    selectedNames: Set<String>,
    completion: @escaping ([String: Any]?, FlutterError?) -> Void
  ) {
    let group = DispatchGroup()
    var steps = 0.0
    var distanceMeters = 0.0
    var calories = 0.0
    var minutes = 0.0
    var queryError: FlutterError?
    let lock = NSLock()

    if selectedNames.contains("steps") {
      group.enter()
      sum(.stepCount, unit: .count(), start: start, end: end) { result in
        switch result {
        case .success(let value):
          steps = value
        case .failure(let error):
          lock.lock()
          queryError = queryError ?? self.flutterError(error, code: "steps_query_failed")
          lock.unlock()
        }
        group.leave()
      }
    }
    if selectedNames.contains("distance") {
      group.enter()
      sum(.distanceWalkingRunning, unit: .meter(), start: start, end: end) { result in
        switch result {
        case .success(let value):
          distanceMeters = value
        case .failure(let error):
          lock.lock()
          queryError = queryError ?? self.flutterError(error, code: "distance_query_failed")
          lock.unlock()
        }
        group.leave()
      }
    }
    if selectedNames.contains("calories") {
      group.enter()
      sum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end) { result in
        switch result {
        case .success(let value):
          calories = value
        case .failure(let error):
          lock.lock()
          queryError = queryError ?? self.flutterError(error, code: "calories_query_failed")
          lock.unlock()
        }
        group.leave()
      }
    }
    if selectedNames.contains("activeMinutes") {
      group.enter()
      sum(.appleExerciseTime, unit: .minute(), start: start, end: end) { result in
        switch result {
        case .success(let value):
          minutes = value
        case .failure(let error):
          lock.lock()
          queryError = queryError ?? self.flutterError(error, code: "active_minutes_query_failed")
          lock.unlock()
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      if let queryError = queryError {
        completion(nil, queryError)
        return
      }
      completion([
        "date": self.formatter.string(from: start),
        "steps": Int(steps.rounded()),
        "distanceKm": distanceMeters / 1000.0,
        "caloriesKcal": calories,
        "activeMinutes": Int(minutes.rounded()),
        "source": "appleHealth",
      ], nil)
    }
  }

  private func sum(
    _ identifier: HKQuantityTypeIdentifier,
    unit: HKUnit,
    start: Date,
    end: Date,
    completion: @escaping (Result<Double, Error>) -> Void
  ) {
    guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
      completion(.success(0))
      return
    }

    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) {
      _, statistics, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      completion(.success(statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0))
    }
    healthStore.execute(query)
  }

  private func isAppleHealth(_ call: FlutterMethodCall) -> Bool {
    guard let arguments = call.arguments as? [String: Any],
          let source = arguments["source"] as? String else {
      return true
    }
    return source == "appleHealth"
  }

  private func defaultTypeNames() -> [String] {
    return ["steps", "distance", "calories", "activeMinutes"]
  }

  private func flutterError(_ error: Error, code: String) -> FlutterError {
    return FlutterError(code: code, message: error.localizedDescription, details: nil)
  }

  private func quantityTypes(from call: FlutterMethodCall) -> [HKQuantityType] {
    guard let arguments = call.arguments as? [String: Any],
          let names = arguments["types"] as? [String] else {
      return defaultQuantityTypes()
    }

    let identifiers = names.compactMap { name -> HKQuantityTypeIdentifier? in
      switch name {
      case "steps": return .stepCount
      case "distance": return .distanceWalkingRunning
      case "calories": return .activeEnergyBurned
      case "activeMinutes": return .appleExerciseTime
      default: return nil
      }
    }

    return identifiers.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
  }

  private func defaultQuantityTypes() -> [HKQuantityType] {
    return [
      .stepCount,
      .distanceWalkingRunning,
      .activeEnergyBurned,
      .appleExerciseTime,
    ].compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
  }
}
