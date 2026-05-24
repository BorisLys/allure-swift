import Foundation

extension Date {
    public var allureMillis: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    public static var allureNow: Int64 {
        Date().allureMillis
    }
}
