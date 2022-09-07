///
/// Created by Zheng Kanyan on 2021/10/1.
/// 
///

import XCTest

class DateISO8601Tests: XCTestCase {
    func test_date_iso8601() {
        let date = Date()
        let string = ISO8601DateFormatter().string(from: date)
        
        print("date: \(date)")
        print("time interval: \(date.timeIntervalSince1970)")
        print("string: \(string)")
        
        let specificDate = Date(timeIntervalSince1970: 1633041523)
        let specificString = ISO8601DateFormatter().string(from: specificDate)
        
        let GMT = TimeZone(abbreviation: "GMT")!
        let options: ISO8601DateFormatter.Options = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]
        let formatString = ISO8601DateFormatter.string(from: specificDate, timeZone: GMT, formatOptions: options)
        
        print("spicific date: \(specificDate)")
        print("spicific time interval: \(specificDate.timeIntervalSince1970)")
        print("spicific string: \(specificString)")
        print("format string: \(formatString)")
    }
    
    func test_iso8601DateStringToDate() {
        let iso8601String = "2020-05-20T11:24:59+0000"
        let date = ISO8601DateFormatter().date(from: iso8601String)
        
        print("date from iso8601 string: \(String(describing: date))")
    }
    
    func test_iso8601withFractionalSeconds() {
//        let iso8601WithFractionalSecondsString = "2020-05-20T11:24:59.234Z"
        let iso8601WithFractionalSecondsString = "2020-05-20T11:24:59.234+0000"
        let iso8601WithFractionalSecondsDate = Formatter.iso8601withFractionalSeconds.date(from: iso8601WithFractionalSecondsString)!
        let iso8601WithFractionalSecondsTimeInterval = iso8601WithFractionalSecondsDate.timeIntervalSince1970
        
        print("date from iso8601 string: \(String(describing: iso8601WithFractionalSecondsDate))")
        print("time interval: \(iso8601WithFractionalSecondsTimeInterval)")
    }
}

private extension Formatter {
    static let iso8601withFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
