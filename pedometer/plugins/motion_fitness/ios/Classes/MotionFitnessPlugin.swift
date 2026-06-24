import CoreMotion
import Flutter
import UIKit

public final class MotionFitnessPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let pedometer = CMPedometer()
  private var eventSink: FlutterEventSink?
  private var streamStartOfDay = Calendar.current.startOfDay(for: Date())

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MotionFitnessPlugin()
    let methodChannel = FlutterMethodChannel(
      name: "pedometer/motion_fitness",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "pedometer/motion_fitness_steps",
      binaryMessenger: registrar.messenger()
    )
    let paceEventChannel = FlutterEventChannel(
      name: "pedometer/motion_fitness_pace",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
    paceEventChannel.setStreamHandler(MotionFitnessPaceStreamHandler())
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      requestAuthorization(result: result)
    case "authorizationStatus":
      result(authorizationStatusString())
    case "isStepCountingAvailable":
      result(CMPedometer.isStepCountingAvailable())
    case "isPaceAvailable":
      result(CMPedometer.isPaceAvailable())
    case "todaySteps":
      queryTodaySteps(result: result)
    case "todayHourlySteps":
      queryTodayHourlySteps(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CMPedometer.isStepCountingAvailable() else {
      events(
        FlutterError(
          code: "unsupported",
          message: "Step counting is not available on this device.",
          details: nil
        )
      )
      return nil
    }

    eventSink = events
    startStepUpdates()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pedometer.stopUpdates()
    eventSink = nil
    return nil
  }

  private func requestAuthorization(result: @escaping FlutterResult) {
    guard CMPedometer.isStepCountingAvailable() else {
      result("unsupported")
      return
    }

    if authorizationStatusString() == "authorized" {
      result("authorized")
      return
    }

    let now = Date()
    let start = Calendar.current.startOfDay(for: now)
    pedometer.queryPedometerData(from: start, to: now) { [weak self] data, error in
      DispatchQueue.main.async {
        if data != nil && error == nil {
          result("authorized")
          return
        }
        result(self?.authorizationStatusString() ?? "unknown")
      }
    }
  }

  private func queryTodaySteps(result: @escaping FlutterResult) {
    guard CMPedometer.isStepCountingAvailable() else {
      result(
        FlutterError(
          code: "unsupported",
          message: "Step counting is not available on this device.",
          details: nil
        )
      )
      return
    }

    let startOfDay = Calendar.current.startOfDay(for: Date())
    pedometer.queryPedometerData(from: startOfDay, to: Date()) { data, error in
      DispatchQueue.main.async {
        if let error = error as NSError? {
          result(
            FlutterError(
              code: "motion_error",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }
        result(data?.numberOfSteps.intValue ?? 0)
      }
    }
  }

  private func queryTodayHourlySteps(result: @escaping FlutterResult) {
    guard CMPedometer.isStepCountingAvailable() else {
      result(
        FlutterError(
          code: "unsupported",
          message: "Step counting is not available on this device.",
          details: nil
        )
      )
      return
    }

    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)
    var hourlySteps = Array(repeating: 0, count: 24)
    var completedQueries = 0
    var firstError: NSError?
    let hoursToQuery = max(0, min(24, calendar.component(.hour, from: now) + 1))

    if hoursToQuery == 0 {
      result(hourlySteps)
      return
    }

    for hour in 0..<hoursToQuery {
      guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
            let nextHourStart = calendar.date(byAdding: .hour, value: hour + 1, to: startOfDay) else {
        completedQueries += 1
        continue
      }
      let hourEnd = min(nextHourStart, now)
      if hourEnd <= hourStart {
        completedQueries += 1
        continue
      }

      pedometer.queryPedometerData(from: hourStart, to: hourEnd) { data, error in
        DispatchQueue.main.async {
          if let error = error as NSError? {
            if firstError == nil {
              firstError = error
            }
          } else {
            hourlySteps[hour] = data?.numberOfSteps.intValue ?? 0
          }

          completedQueries += 1
          if completedQueries == hoursToQuery {
            if hourlySteps.contains(where: { $0 > 0 }) || firstError == nil {
              result(hourlySteps)
              return
            }
            result(
              FlutterError(
                code: "motion_error",
                message: firstError?.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private func startStepUpdates() {
    streamStartOfDay = Calendar.current.startOfDay(for: Date())
    pedometer.startUpdates(from: streamStartOfDay) { [weak self] data, error in
      guard let self else { return }
      DispatchQueue.main.async {
        let today = Calendar.current.startOfDay(for: Date())
        if today != self.streamStartOfDay {
          self.pedometer.stopUpdates()
          self.startStepUpdates()
          return
        }

        if let error = error as NSError? {
          self.eventSink?(
            FlutterError(
              code: "motion_error",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }
        self.eventSink?(data?.numberOfSteps.intValue ?? 0)
      }
    }
  }

  private func authorizationStatusString() -> String {
    if !CMPedometer.isStepCountingAvailable() {
      return "unsupported"
    }

    if #available(iOS 11.0, *) {
      switch CMPedometer.authorizationStatus() {
      case .authorized:
        return "authorized"
      case .denied:
        return "denied"
      case .restricted:
        return "restricted"
      case .notDetermined:
        return "unknown"
      @unknown default:
        return "unknown"
      }
    }
    return "unknown"
  }
}

private final class MotionFitnessPaceStreamHandler: NSObject, FlutterStreamHandler {
  private let pedometer = CMPedometer()
  private var eventSink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CMPedometer.isPaceAvailable() else {
      events(
        FlutterError(
          code: "unsupported",
          message: "Pace is not available on this device.",
          details: nil
        )
      )
      return nil
    }

    eventSink = events
    pedometer.startUpdates(from: Date()) { [weak self] data, error in
      guard let self else { return }
      DispatchQueue.main.async {
        if let error = error as NSError? {
          self.eventSink?(
            FlutterError(
              code: "motion_error",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }

        guard let secondsPerMeter = data?.currentPace?.doubleValue,
              secondsPerMeter.isFinite,
              secondsPerMeter > 0 else {
          return
        }

        self.eventSink?([
          "secondsPerMeter": secondsPerMeter,
          "timestampMillis": Int(Date().timeIntervalSince1970 * 1000),
        ])
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pedometer.stopUpdates()
    eventSink = nil
    return nil
  }
}
