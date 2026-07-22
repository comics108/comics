//
//  Date+Extension.swift
//  Date+Extension
//
//  Created by Roman Developer on 22 Apr 2016.
//  Updated by Vasiliy Ursu on 07 Oct 2020.
//
//  Copyright © 2018 IronWaterStudio. All rights reserved.
//
//  Changes history:
//		04 Jun 2018. Stanislav Grinberg:
//			* Reworked UTC methods.
//			* More swifty syntax.
//		05 Jun 2018. Stanislav Grinberg:
//			* Used init instead some static date methods.
//			* Used Calendar instead NSCalendar.
//		06 Jun 2018. Stanislav Grinberg:
//			* Format strings now are static constants.
//		24 Jan 2020. Andrey Kozlov:
//			* Added TODO for gmt() method.
//		30 Jan 2020. Vasiliy Ursu:
//			* Added iso8601 format support + changed kXXX constants to Formats enum
//		04 Mar 2020. Oleg Demidov:
//			* Fixed iso8601 format: added support 24 hours format
//		29 Jul 2020. Oleg Demidov:
//			* Fixed iso8601 format: added httpDateFormat
//		07 Oct 2020. Vasiliy Ursu:
//			* Added timezone offset by using date parsing & formatting
//
//	Referemces:
//  	* Date service: http://i-leon.ru/tools/time
//		* ios8101: https://stackoverflow.com/a/28016692

import UIKit

/// "dd MMM yyyy | hh:mm | ff | zzz | zz | z"
/// will output:
/// 07 Mai 2009 | 08:16 | 13 | +02:00 | +02 | +2
extension Date {
	
	/// https://stackoverflow.com/a/50143920
	enum Formats: String {
		case fullDateFormat = "dd.MM.yyyy hh:mm:ss"
		case shortDateFormat = "dd.MM.yyyy"
		case shortDateShortYearFormat = "dd.MM.yy"
		case fullTimeFormat = "hh:mm:ss"
		case fullTime24Format = "HH:mm:ss"
		case shortTimeFormat = "hh:mm"
		case shortTime24Format = "HH:mm"
		/// ISO short (without timezone offset and milliseconds) server format based on 8601 standart
		case iso8601ShortFormat = "yyyy-MM-dd'T'HH:mm:ss"
		// Server format date, like: "2015-10-21'T'07:28:00.000+03:00",
		// see: https://developer.apple.com/documentation/foundation/iso8601dateformatter
		// https://www.w3.org/TR/NOTE-datetime
		/// ISO full (with timezone offset and milliseconds) server format based on 8601 standart
		/// Such as: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ", see:  https://stackoverflow.com/a/28016692
		case iso8601Format = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
		// HTTP protocol format date, like: "Wed, 21 Oct 2015 07:28:00 GMT", see: https://tools.ietf.org/html/rfc7231#section-7.1.1.2
		// Other possible format values: "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'" or "E, dd MMM yyyy hh:mm:ss zzz" or "E, dd MMM yyyy hh:mm:ss zzz"
		case httpDateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
	}
	
	// MARK: - Init
	
	init?(_ time: TimeInterval = 0.0, _ asGMT: Bool = true) {
		self.init(timeIntervalSince1970: time)
		
		if !asGMT {
			self = self.asGMT()
		}
	}
	
	init?(_ time: NSNumber?, _ asGMT: Bool = true) {
		guard let timeInterval = time else { return nil }
		self.init(timeInterval.doubleValue, asGMT)
	}
	
	// MARK: - Diff
	
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
	
	func minutesAgoSinceNow() -> Int {
		return self.minutesAgoSinceDate(Date())
	}
	
	func hoursAgoSinceNow() -> Int {
		return self.hoursAgoSinceDate(Date())
	}
	
	func daysAgoSinceNow() -> Int {
		return self.daysAgoSinceDate(Date())
	}
	
	// MARK: - Equality
	
	func isEqual(_ to: Date, _ onlyDateComponents: Bool = true) -> Bool {
		return onlyDateComponents ? to.dateWithoutTime() == self.dateWithoutTime() : to == self
		
		// FIXME: Not working when difference of dates is less than 1 day
		/*
		let unitFlags: NSCalendar.Unit = [.day, .month, .year]
		let components = (Calendar.current as NSCalendar).components(unitFlags, from: self, to: otherDate, options: NSCalendar.Options.matchFirst)
		return components.day == 0 && components.month == 0 && components.year == 0
		*/
	}
	
	func isToday() -> Bool {
		return self.isEqual(Date())
	}
	
	func isYesterday() -> Bool {
		return self.isEqual(Date().addDay(-1))
	}
	
	func isYearEqual(to date: Date = Date()) -> Bool {
		let calendar = Calendar.current
		return calendar.component(.year, from: self) == calendar.component(.year, from: date)
	}
	
	// MARK: - Change
	
	func addSecond(_ seconds: Int) -> Date {
		let cal = Calendar.current
		var comps = DateComponents()
		comps.second = seconds
		return cal.date(byAdding: comps, to: self/*, wrappingComponents: false*/)!
	}
	
	func addMinute(_ minutes: Int) -> Date {
		let cal = Calendar.current
		var comps = DateComponents()
		comps.minute = minutes
		return cal.date(byAdding: comps, to: self/*, wrappingComponents: false*/)!
	}
	
	func addHour(_ hours: Int) -> Date {
		let cal = Calendar.current
		var comps = DateComponents()
		comps.hour = hours
		return cal.date(byAdding: comps, to: self/*, wrappingComponents: false*/)!
	}
	
	func addDay(_ days: Int) -> Date {
		let cal = Calendar.current
		var comps = DateComponents()
		comps.day = days
		return cal.date(byAdding: comps, to: self/*, wrappingComponents: false*/)!
	}
	
	func addMonth(_ months: Int) -> Date {
		let cal = Calendar.current
		var comps = DateComponents()
		comps.month = months
		return cal.date(byAdding: comps, to: self/*, wrappingComponents: false*/)!
	}
	
	func addYear(_ years: Int) -> Date {
		let cal = Calendar.current
		var comps = DateComponents()
		comps.year = years
		return cal.date(byAdding: comps, to: self/*, wrappingComponents: false*/)!
	}
	
	// MARK: - Create
	
	static func date(date: Date?, time: TimeInterval?) -> Date? {
		if let dt = date, let time = time {
			let cal = Calendar.current
			let year = cal.component(.year, from: dt)
			let month = cal.component(.month, from: dt)
			let day = cal.component(.day, from: dt)
			let hours = Int(time / 3600)
			let minutes = Int(Int(time) - hours * 3600)
			return cal.date(from: DateComponents(year: year, month: month, day: day, hour: hours, minute: minutes))
		}
		return nil
	}

	// Check this method duplicates
	static func date(day: Int, month: Int, year: Int) -> Date? {
		var comps = DateComponents()
		comps.day = day
		comps.month = month
		comps.year = year
		return Calendar.current.date(from: comps) //Calendar(identifier: .gregorian)
	}
	
	// MARK: - ToString
	
	/// Converts Date to string representation
	/// - Parameter timeZoneOffset: Timezone offset in SECONDS
	/// - Returns: representation of Date
	func fullDateString(timeZoneOffset: Int? = nil) -> String {
		return self.stringWithFormat(.fullDateFormat, timeZoneOffset: timeZoneOffset)
	}
	
	/// Converts Date to string representation
	/// - Parameter timeZoneOffset: Timezone offset in SECONDS
	/// - Returns: representation of Date
	func shortDateString(timeZoneOffset: Int? = nil) -> String {
		return self.stringWithFormat(.shortDateFormat, timeZoneOffset: timeZoneOffset)
	}
	
	/// Converts Date to string representation
	/// - Parameter timeZoneOffset: Timezone offset in SECONDS
	/// - Returns: representation of Date
	func shortDateShortYearString(timeZoneOffset: Int? = nil) -> String {
		return self.stringWithFormat(.shortDateShortYearFormat, timeZoneOffset: timeZoneOffset)
	}
	
	/// Converts Date to string representation
	/// - Parameter useAmPm: Show AM or PM
	/// - Parameter timeZoneOffset: Timezone offset in SECONDS
	/// - Returns: representation of Date
	func fullTimeString(useAmPm: Bool = false, timeZoneOffset: Int? = nil) -> String {
		return self.stringWithFormat(useAmPm ? .fullTimeFormat : .fullTime24Format, timeZoneOffset: timeZoneOffset)
	}
	
	/// Converts Date to string representation
	/// - Parameter useAmPm: Show AM or PM
	/// - Parameter timeZoneOffset: Timezone offset in SECONDS
	/// - Returns: representation of Date
	func shortTimeString(useAmPm: Bool = false, timeZoneOffset: Int? = nil) -> String {
		return self.stringWithFormat(useAmPm ? .shortTimeFormat : .shortTime24Format, timeZoneOffset: timeZoneOffset)
	}
	
	func stringWithFormat(_ format: Formats, timeZoneOffset: Int? = nil) -> String {
		return self.stringWithFormat(format.rawValue, timeZoneOffset: timeZoneOffset)
	}
	
	/// Converts Date to string representation
	/// - Parameters:
	///   - formatString: Format string
	///   - timeZoneOffset: Timezone offset in seconds
	/// - Returns: String representation of Date
	func stringWithFormat(_ formatString: String, timeZoneOffset: Int? = nil) -> String {
		let dtFormatter = DateFormatter()
		// When timezone offset specified then will be created timezone and used for formatting
		if let tzOffset = timeZoneOffset {
			dtFormatter.timeZone = TimeZone(secondsFromGMT: tzOffset)
		}
		dtFormatter.dateFormat = formatString
		return dtFormatter.string(from: self)
	}
	
	func stringWithDateStyle(_ formatStyle: DateFormatter.Style, timeZoneOffset: Int? = nil) -> String {
		let dtFormatter = DateFormatter()
		dtFormatter.dateStyle = formatStyle
		// When timezone offset specified then will be created timezone and used for formatting
		if let tzOffset = timeZoneOffset {
			dtFormatter.timeZone = TimeZone(secondsFromGMT: tzOffset)
		}
		return dtFormatter.string(from: self)
	}
	
	func iso8601String(short: Bool = false) -> String {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = short ? Formats.iso8601ShortFormat.rawValue : Formats.iso8601Format.rawValue
		return formatter.string(from: self)
	}
	
	func httpString() -> String {
		/* if #available(iOS 11.0, *) {
			// v1 ~ automatic solution
			let dateFormatter = ISO8601DateFormatter()
			dateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime, .withTimeZone]
			return dateFormatter.string(from: self)
		} else { */
			// v2 ~ manual solution
			let formatter = DateFormatter()
			formatter.calendar = Calendar(identifier: .iso8601)
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.timeZone = TimeZone(secondsFromGMT: 0)
			formatter.dateFormat = Formats.httpDateFormat.rawValue
			return formatter.string(from: self)
		/* } */
	}
	
	/*
	// TODO: need to compare iso8601String with htmlDateString and if both equals than use iso8601String
	@available(swift, deprecated: 0, message: "Use iso8601String instead")
	func httpDateString() -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US")
		formatter.timeZone = TimeZone(abbreviation: "GMT")
		// RFC 7232 format
		formatter.dateFormat = Formats.httpDateFormat.rawValue
		return formatter.string(from: self)
	}
	*/
	
	// MARK: - Date from string
	
	// https://stackoverflow.com/questions/28016578/how-to-create-a-date-time-stamp-and-format-as-iso-8601-rfc-3339-utc-time-zone
	// https://stackoverflow.com/a/28016692
	static func parseIso8601(_ dateString: String?, short: Bool = false) -> Date? {
		guard let dateString = dateString else { return nil }
		/* if #available(iOS 11.0, *) {
			// v1 ~ automatic solution
			let dateFormatter = ISO8601DateFormatter()
			dateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime, .withTimeZone]
			return dateFormatter.date(from: dateString)
		} else { */
			// v2 ~ manual solution
			let formatter = DateFormatter()
			formatter.calendar = Calendar(identifier: .iso8601)
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.timeZone = TimeZone(secondsFromGMT: 0)
			formatter.dateFormat = short ? Formats.iso8601ShortFormat.rawValue : Formats.iso8601Format.rawValue
			return formatter.date(from: dateString)
		/* } */
	}
	
	static func parseHttp(_ dateString: String?) -> Date? {
		guard let dateString = dateString else { return nil }
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = Formats.httpDateFormat.rawValue
		return formatter.date(from: dateString)
	}
	
	/*
	// TODO: need to compare iso8601String with htmlDateString and if both equals than use iso8601String
	@available(swift, deprecated: 0, message: "Use parseIso8601 instead")
	static func parseHttpDate(_ dateString: String?) -> Date? {
		guard let dateString = dateString else { return nil }
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US")
		formatter.timeZone = TimeZone(abbreviation: "GMT")
		formatter.dateFormat = Formats.httpDateFormat.rawValue
		return formatter.date(from: dateString)
	}
	*/
	
	static func parseShortDate(_ dateString: String?, timeZoneOffset: Int? = nil) -> Date? {
		return parse(dateString, format: "yyyy/MM/dd", timeZoneOffset: timeZoneOffset)
	}

	
	/// Parsing Date from string representation
	/// - Parameters:
	///   - dateString: Source string with date
	///   - format: Format of strored date
	///   - useGMT: Flag indicates that no timezone should be used (GMT = 0-time offset)
	///   - timeZoneOffset: Timezone offset in seconds, can be used only when useGMT is false
	/// - Returns: Date instance created from string representation
	static func parse(_ dateString: String?, format: String, useGMT: Bool = false, timeZoneOffset: Int? = nil) -> Date? {
		if let dtStr = dateString {
			let dtFormatter = DateFormatter()
			dtFormatter.dateFormat = format
			// When specified flag useGMT then will be used ZERO timezone offset
			if useGMT, let tz = TimeZone(secondsFromGMT: 0) {
				dtFormatter.timeZone = tz
				return dtFormatter.date(from: dtStr)
			} else {
				// When timezone offset specified then will be created timezone and used for formatting
				if let tzOffset = timeZoneOffset {
					dtFormatter.timeZone = TimeZone(secondsFromGMT: tzOffset)
				}
				let dt = dtFormatter.date(from: dtStr)
				return useGMT ? dt?.asGMT() : dt
			}
		}
		
		return nil
	}

	// MARK: - GMT
	
	/*
	// FIXME: Same method in creation mark, only asGMT inverse apply!!!
	static func date(_ timeInterval: TimeInterval?, asGMT: Bool = false) -> Date? {
		guard let timeInterval = timeInterval else { return nil }
		
		let dt: Date = Date(timeIntervalSince1970: timeInterval)
		return asGMT ? dt.asGMT() : dt
	}
	*/
	static func date(hour: Int, minute: Int, second: Int = 0) -> Date? {
		let cal = Calendar.current
		var comps = DateComponents()
		comps.calendar = cal
		comps.hour = hour
		comps.minute = minute
		comps.second = second
		comps.year = 1970
		comps.month = 1
		comps.day = 1
		if let timeWithoutDay = cal.date(from: comps) {
			return timeWithoutDay
		}
		return nil
	}
	
	// Convertation date <-> minutes (for settings)
	static func date(minutes: Int) -> Date? {
		let hours = minutes / 60
		let minutes = minutes % 60
		return self.date(hour: hours, minute: minutes)
	}
	
	// Returns current offset from GMT in seconds
	static func timeZoneOffset()  -> Int {
		var timeZoneOffset = TimeZone.current.secondsFromGMT()
		//+4 GMT MSK daylight bug fix - need to add 1 hour
		if let floatSysVersion = Float(UIDevice.current.systemVersion) {
			if floatSysVersion >= 7.0 && floatSysVersion <= 8.0 {
				let timeZoneOffsetFixed = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: 0))
				let fix = timeZoneOffset - timeZoneOffsetFixed
				timeZoneOffset += fix
			}
		}
		return timeZoneOffset
	}
	
	// Because internal date representaion does not contain date kind (timezone offset information).
	// When we need get UTC only date component (without time) and next call timeIntervalSince1970 (offset from 01.01.1970).
	// This method substructs timezone offset from Date.
	// Let's review following example:
	//		let dt: Date = Date() // 04 Jun 2018 2:00 am
	//		let utcDt: Date = Date(timeIntervalSince1970: (dt.dateWithoutTime().utcDate())
	/// Interprets as GMT timezone date
	func asGMT() -> Date {
		return self.addSecond(Date.timeZoneOffset())
	}
	
	// Interprets as current timezone date
	func asCurrent() -> Date {
		return self.addSecond(-Date.timeZoneOffset())
	}
	
	// Date without addition of timezone offset to seconds
	/*
	static func utcDateWithTimeIntervalSince1970(utcTime: Int) -> Date {
		//TODO: remove for:Date()?????
		var timeZoneOffset = TimeZone.current.secondsFromGMT(for: Date())
		if let floatSysVersion = Float(UIDevice.current.systemVersion) {
			
			//+4 GMT MSK daylight bug fix - need to add 1 hour
			if floatSysVersion >= 7.0 && floatSysVersion <= 8.0 {
				timeZoneOffset = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: 0))
			}
		}
		return Date(timeIntervalSince1970: TimeInterval(utcTime - timeZoneOffset))
	}
	*/
	//  date without time components
	func dateWithoutTime(_ useGMT: Bool = false) -> Date? {
		var cal = Calendar.current
		let comps = cal.dateComponents([.day, .month, .year], from: self)
		if useGMT, let tz = TimeZone(secondsFromGMT: 0) {
			cal.timeZone = tz
			if let dtWithoutTime = cal.date(from: comps) {
				return dtWithoutTime
			}
		} else {
			//calendar.timeZone = .current
			if let dtWithoutTime = cal.date(from: comps) {
				return useGMT ? dtWithoutTime.asGMT() : dtWithoutTime
			}
		}
		
		return nil
	}
	
	// Returns UTC Unix time offset in seconds from 01.01.1970
	// asGMT indicates that self should be reviewed as GMT date representation, otherwise we should add timezone offset
	// TODO: Change signature to func unixTime(isGmt: Bool = false) -> TimeInterval
	func gmt(_ asGMT: Bool = false) -> TimeInterval {
		let dt = asGMT ? self : self.addSecond(Date.timeZoneOffset())
		return dt.timeIntervalSince1970
	}
	
	// Returns time offset in seconds from beginning of day/today
	// asGMT indicates that self should be reviewed as GMT date representation, otherwise we should add timezone offset
	func time(_ asGMT: Bool = false) -> TimeInterval? {
		let dt = asGMT ? self : self.addSecond(Date.timeZoneOffset())
		let cal = Calendar.current
		var comps = cal.dateComponents([.minute, .hour], from: dt)
		comps.year = 1970
		comps.month = 1
		comps.day = 1
		if let timeWithoutDay = cal.date(from: comps) {
			return timeWithoutDay.timeIntervalSince1970
		}
		return nil
	}
	
	// Getting today date (now) component without time
	// asGMT indicates that self should be reviewed as GMT date representation, otherwise we should add timezone offset
	static func today(_ useGMT: Bool = false) -> Date? {
		return Date().dateWithoutTime(useGMT)
	}
	
	// Returns current date
	// asGMT indicates that self should be reviewed as GMT date representation, otherwise we should add timezone offset
	static func now(_ asGMT: Bool = false) -> Date {
		return  asGMT ? Date() : Date().asGMT()
	}
	
	// MARK: - Helper
	
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
