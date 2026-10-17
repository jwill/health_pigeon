import Flutter
import HealthKit
import UIKit

public class HealthPigeonPlugin: NSObject, FlutterPlugin, HealthConnectApi {
  private let healthStore = HKHealthStore()

  private var systolicType: HKQuantityType? {
    HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
  }

  private var diastolicType: HKQuantityType? {
    HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
  }

  private var bloodPressureCorrelationType: HKCorrelationType? {
    HKCorrelationType.correlationType(forIdentifier: .bloodPressure)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = HealthPigeonPlugin()
    HealthConnectApiSetup.register(api: instance)
  }

  func hasPermissions() async throws -> Bool {
    guard HKHealthStore.isHealthDataAvailable() else { return false }
    guard let systolic = systolicType, let diastolic = diastolicType else { return false }

    let systolicStatus = healthStore.authorizationStatus(for: systolic)
    let diastolicStatus = healthStore.authorizationStatus(for: diastolic)

    return systolicStatus == .sharingAuthorized && diastolicStatus == .sharingAuthorized
  }

  func requestPermissions() async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw PigeonError(
        code: "HEALTH_DATA_UNAVAILABLE",
        message: "HealthKit is not available on this device",
        details: nil
      )
    }
    guard let systolic = systolicType,
          let diastolic = diastolicType else {
      throw PigeonError(
        code: "INVALID_TYPES",
        message: "Blood pressure quantity types are unavailable",
        details: nil
      )
    }

    let typesToShare: Set<HKSampleType> = [systolic, diastolic]
    let typesToRead: Set<HKObjectType> = [systolic, diastolic]

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      DispatchQueue.main.async {
        self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
          if let error = error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: ())
          }
        }
      }
    }
  }

  func openHealthConnectSettings() async throws {
    await MainActor.run {
      if let url = URL(string: UIApplication.openSettingsURLString),
         UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
      }
    }
  }

  func readBloodPressure(startMillis: Int64, endMillis: Int64) async throws -> [BloodPressureRecordPigeon] {
    guard HKHealthStore.isHealthDataAvailable() else { return [] }
    guard let correlationType = bloodPressureCorrelationType,
          let systolicType = systolicType,
          let diastolicType = diastolicType else { return [] }

    let startDate = Date(timeIntervalSince1970: TimeInterval(startMillis) / 1000.0)
    let endDate = Date(timeIntervalSince1970: TimeInterval(endMillis) / 1000.0)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate, .strictEndDate])
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

    return try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: correlationType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [sortDescriptor]
      ) { _, samples, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }

        guard let correlations = samples as? [HKCorrelation] else {
          continuation.resume(returning: [])
          return
        }

        let mmhgUnit = HKUnit.millimeterOfMercury()
        var results: [BloodPressureRecordPigeon] = []

        for correlation in correlations {
          var systolicValue: Int64?
          var diastolicValue: Int64?

          if let sysSample = correlation.objects(for: systolicType).first as? HKQuantitySample {
            systolicValue = Int64(sysSample.quantity.doubleValue(for: mmhgUnit).rounded())
          }
          if let diaSample = correlation.objects(for: diastolicType).first as? HKQuantitySample {
            diastolicValue = Int64(diaSample.quantity.doubleValue(for: mmhgUnit).rounded())
          }

          if let sys = systolicValue, let dia = diastolicValue {
            let dateMillis = Int64(correlation.startDate.timeIntervalSince1970 * 1000.0)
            results.append(BloodPressureRecordPigeon(
              systolic: sys,
              diastolic: dia,
              dateMillis: dateMillis,
              notes: ""
            ))
          }
        }

        continuation.resume(returning: results)
      }

      healthStore.execute(query)
    }
  }

  func writeBloodPressure(record: BloodPressureRecordPigeon) async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw PigeonError(
        code: "HEALTH_DATA_UNAVAILABLE",
        message: "HealthKit is not available on this device",
        details: nil
      )
    }
    guard let systolicType = systolicType,
          let diastolicType = diastolicType,
          let correlationType = bloodPressureCorrelationType else {
      throw PigeonError(
        code: "INVALID_TYPES",
        message: "Blood pressure quantity types are unavailable",
        details: nil
      )
    }

    let date = Date(timeIntervalSince1970: TimeInterval(record.dateMillis) / 1000.0)
    let mmhgUnit = HKUnit.millimeterOfMercury()

    let systolicQuantity = HKQuantity(unit: mmhgUnit, doubleValue: Double(record.systolic))
    let diastolicQuantity = HKQuantity(unit: mmhgUnit, doubleValue: Double(record.diastolic))

    let metadata: [String: Any] = [
      HKMetadataKeyWasUserEntered: true
    ]

    let systolicSample = HKQuantitySample(
      type: systolicType,
      quantity: systolicQuantity,
      start: date,
      end: date,
      metadata: metadata
    )

    let diastolicSample = HKQuantitySample(
      type: diastolicType,
      quantity: diastolicQuantity,
      start: date,
      end: date,
      metadata: metadata
    )

    let objects: Set<HKSample> = [systolicSample, diastolicSample]
    let correlation = HKCorrelation(
      type: correlationType,
      start: date,
      end: date,
      objects: objects,
      metadata: metadata
    )

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      healthStore.save(correlation) { success, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }
}
