//
//  NSDate+Extensions.swift
//  Tomato
//
//  Created by Roman Developer on 4/22/16.
//  Updated by Mikhail Kulichkov on 13 Apr 2017.
//  Copyright © 2016 IronWaterStudio. All rights reserved.
//

import UIKit

public extension Date {
	
	// MARK: Diff
	func minutesAgoSinceDate(_ pastDate: Date) -> Int {
		let seconds = self.timeIntervalSince1970 - pastDate.timeIntervalSince1970
		return Int(seconds / 60)
	}
	
	func hoursAgoSinceDate(_ pastDate: Date) -> Int {
		return self.minutesAgoSinceDate(pastDate) / 60
	}
	
	func daysAgoSinceDate(_ pastDate: Date) -> Int {
		return self.hoursAgoSinceDate(pastDate) / 24
	}
	
	func minutesAgoSinceCurrentDate() -> Int {
		return self.minutesAgoSinceDate(Date())
	}
	
	func hoursAgoSinceCurrentDate() -> Int {
		return self.hoursAgoSinceDate(Date())
	}
	
	func daysAgoSinceCurrentDate() -> Int {
		return self.daysAgoSinceDate(Date())
	}
	
	// MARK: Equality
	func isEqualToDay(_ otherDate: Date) -> Bool {
		let unitFlags: NSCalendar.Unit = [.day, .month, .year]
		let components = (Calendar.current as NSCalendar).components(unitFlags, from: self, to: otherDate, options: NSCalendar.Options.matchFirst)
		
		return components.day == 0 && components.month == 0 && components.year == 0
	}
	
	func isToday() -> Bool {
		return self.isEqualToDay(Date())
	}
	
	func isYesterday() -> Bool {
		return self.isEqualToDay(Date().addDay(-24))
	}
	
	// MARK: Change
	func addSecond(_ seconds: Int) -> Date {
		let calendar = Calendar.current
		var comps = DateComponents()
		comps.second = seconds
		return (calendar as NSCalendar).date(byAdding: comps, to: self, options: .matchFirst)!
	}
	
	func addMinute(_ minutes: Int) -> Date {
		let calendar = Calendar.current
		var comps = DateComponents()
		comps.minute = minutes
		return (calendar as NSCalendar).date(byAdding: comps, to: self, options: .matchFirst)!
	}
	
	func addHour(_ hours: Int) -> Date {
		let calendar = Calendar.current
		var comps = DateComponents()
		comps.hour = hours
		return (calendar as NSCalendar).date(byAdding: comps, to: self, options: .matchFirst)!
	}
	
	func addDay(_ days: Int) -> Date {
		let calendar = Calendar.current
		var comps = DateComponents()
		comps.day = days
		return (calendar as NSCalendar).date(byAdding: comps, to: self, options: .matchFirst)!
	}
	
	func addMonth(_ months: Int) -> Date {
		let calendar = Calendar.current
		var comps = DateComponents()
		comps.month = months
		return (calendar as NSCalendar).date(byAdding: comps, to: self, options: .matchFirst)!
	}
	
	func addYear(_ years: Int) -> Date {
		let calendar = Calendar.current
		var comps = DateComponents()
		comps.year = years
		return (calendar as NSCalendar).date(byAdding: comps, to: self, options: .matchFirst)!
	}
	
	// MARK: Create
	
	static func dateWithComponents(_ day: Int, month: Int, year: Int) -> Date? {
		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = day
		
		return Calendar.current.date(from: components)
	}
	
	// MARK: ToString
	func fullDateString() -> String {
		let kFullDateFormat = "dd.MM.yyyy hh:mm:ss"
		return self.stringWithFormat(kFullDateFormat)
	}
	
	func shortDateString() -> String {
		let kShortDateFormat = "dd.MM.yyyy"
		return self.stringWithFormat(kShortDateFormat)
	}
	
	func shortDateShortYearString() -> String {
		//NOTE: date format is with dots
		let kShortDateFormatShortYear = "dd.MM.yy"
		return self.stringWithFormat(kShortDateFormatShortYear)
	}
	
	func fullTimeString() -> String {
		let kFullTimeFormat = "hh:mm:ss"
		return self.stringWithFormat(kFullTimeFormat)
	}
	
	func shortTimeString() -> String {
		let kShortTimeFormat = "hh:mm"
		return self.stringWithFormat(kShortTimeFormat)
	}
	
	func fullTime24String() -> String {
		let kFullTimeFormat24 = "HH:mm:ss"
		return self.stringWithFormat(kFullTimeFormat24)
	}
	
	func shortTime24String() -> String {
		let kShortTimeFormat24 = "HH:mm"
		return self.stringWithFormat(kShortTimeFormat24)
	}
	
	func stringWithFormat(_ formatString: String) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = formatString
		return dateFormatter.string(from: self)
	}
	
	func stringWithDateStyle(_ formatStyle: DateFormatter.Style) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = formatStyle
		return dateFormatter.string(from: self)
	}
	
	//MARK : Date from string
	static func localDateFromShortDateString(_ dateString: String?) -> Date?
	{
		return dateFromString(dateString, format: "yyyy/MM/dd")
	}

	static func dateFromString(_ dateString: String?, format: String) -> Date?
	{
		if let dateStr = dateString {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = format
			let date = dateFormatter.date(from: dateStr)
			return date
		}
		
		return nil
	}

	// MARK: UTC
	
	static func localDateFromUTC(_ utcTime: Double?) -> Date? {
		guard let utcTime = utcTime else { return nil }
		let timeZoneOffset = TimeZone.current.secondsFromGMT(for: Date())
		
		//print ("utc: \(utcTime), timeZoneOffset: \(timeZoneOffset)")
		return Date(timeIntervalSince1970: utcTime + Double(timeZoneOffset))
	}
    
    
    static func dateWithHour(hour: Int, minute: Int, second: Int) -> Date? {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        dateComponents.year = 1970
        dateComponents.month = 1
        dateComponents.day = 1
        if let timeWithoutDay = calendar.date(from: dateComponents) {
            return timeWithoutDay
        }
        return nil
    }
    
    static func dateWithHour(hour: Int, minute: Int) -> Date? {
        return self.dateWithHour(hour: hour, minute: minute, second: 0)
    }
    
	// Convertation date <-> minutes (for settings)
    static func convertMinutesToDate(minutes: Int) -> Date? {
        let hours = minutes / 60
        let minutes = minutes % 60
        return self.dateWithHour(hour: hours, minute: minutes)
    }
    
    static func convertDateToMinutes(date: Date) -> Int? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: date)
        if let minute = dateComponents.minute, let hour = dateComponents.hour {
            return minute + hour * 60
        }
        return nil
    }
    
    // Returns UTC Unix time from current NSDate in local timezone
    func utcDate() -> Int {
        let unixTimeInt = Int(self.timeIntervalSince1970)
        if let floatSysVersion = Float(UIDevice.current.systemVersion) {
            
            //+4 GMT MSK daylight bug fix - need to add 1 hour
            if floatSysVersion >= 7.0 && floatSysVersion <= 8.0 {
                let timeZoneOffset = TimeZone.current.secondsFromGMT(for: self)
                let timeZoneOffsetFixed = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: 0))
                let fix = timeZoneOffset - timeZoneOffsetFixed
                return unixTimeInt + fix
            }
        }
        return unixTimeInt
    }
    
    // Date without addition of timezone offset to seconds
    static func utcDateWithTimeIntervalSince1970(utcTime: Int) -> Date {
        var timeZoneOffset = TimeZone.current.secondsFromGMT(for: Date())
        if let floatSysVersion = Float(UIDevice.current.systemVersion) {
            
            //+4 GMT MSK daylight bug fix - need to add 1 hour
            if floatSysVersion >= 7.0 && floatSysVersion <= 8.0 {
                timeZoneOffset = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: 0))
            }
        }
        return Date(timeIntervalSince1970: TimeInterval(utcTime - timeZoneOffset))
    }
    
	// Today date without time components
    func dateWithoutTime() -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: self)
        if let dateWithoutTime = calendar.date(from: dateComponents) {
            return dateWithoutTime
        }
        return nil
    }
    
    func timeWithoutDay() -> Date? {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.minute, .hour], from: self)
        dateComponents.year = 1970
        dateComponents.month = 1
        dateComponents.day = 1
        dateComponents.second = 0
        if let timeWithoutDay = calendar.date(from: dateComponents) {
            return timeWithoutDay
        }
        return nil
    }
    
    static func today() -> Date? {
        return Date().dateWithoutTime()
    }
    
    static func dateWithYear(year: Int, month: Int, day: Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return calendar.date(from: dateComponents)
    }
    
    static func timeIntervalToString(timeInterval: Int) -> String {
        let seconds = timeInterval % 60
        let minutesTotal = timeInterval / 60
        let minutes = minutesTotal % 60
        let hoursTotal = minutesTotal / 60
        let hours = hoursTotal % 24
        let days = hoursTotal / 24
        if days > 0 {
            return String(format: "%ld.%02ld:%02ld:%02ld", days, hours, minutes, seconds)
        }
        return String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
    }
}
