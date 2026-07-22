//
//  Foundation+Currency.swift
//  Foundation+Currency
//
//  Created by Olga Zhegulo on 19 Oct 2018.
// 	Updated by Olga Zhegulo on 10 Nov 2020.
//  Based on: Neftmagistral
//
//	Changes history:
//		* 9 Nov 2020. Olga Zhegulo:
//			* added currencyFormatter, formatCurrency methods & removed extensions for Int, Double, Float, NSNumber
//		* 10 Nov 2020. Olga Zhegulo:
//			* added showSymbol argument to formatCurrency(...)
//
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import Foundation

extension NumberFormatter {
	func formatCurrency(_ amount: Double, showSymbol: Bool = true, symbol: String? = nil) -> String {
		return formatCurrency(amount as NSNumber, showSymbol: showSymbol, symbol: symbol)
	}

	func formatCurrency(_ amount: Float, showSymbol: Bool = true, symbol: String? = nil) -> String {
		return formatCurrency(amount as NSNumber, showSymbol: showSymbol, symbol: symbol)
	}
	
	func formatCurrency(_ amount: Int, showSymbol: Bool = true, symbol: String? = nil) -> String {
		return formatCurrency(amount as NSNumber, showSymbol: showSymbol, symbol: symbol)
	}

	/// Format as money amount
	/// - Parameters:
	///   - amount: number to format
	///   - showSymbol: show or not currency symbol, e.g. ruble
	///   - symbol: currency symbol to format number manually if
	/// - Returns: string formatted by standart formatter or concatenation of input number & symbol of currency if number cannot be formatted (e.g. pointer)
	func formatCurrency(_ amount: NSNumber, showSymbol: Bool = true, symbol: String? = nil) -> String {
		// Store old style
		let style = numberStyle
		// Apply number style
		numberStyle = showSymbol ? .currency : .decimal
		if let result = string(from: amount) {
			// Revert numberStyle
			numberStyle = style
			return result
		}
		// Revert numberStyle
		numberStyle = style
		// Some NSNumbers cannot be formatted as currency, e.g. if the object is not an NSDecimalNumber
		// https://stackoverflow.com/questions/48504597/why-does-numberformatters-stringfrom-return-an-optional
		if showSymbol, let symbol = symbol {
			return "\(amount) \(symbol)"
		} else {
			return "\(amount)"
		}
	}
	
	/// Create NumberFormatter for amount of money
	/// - Parameters:
	///   - locale: locale
	///   - decimalSeparator: string to separate decimal part, usually "." or ","
	///   - groupingSeparator: string to separate groups, usually "" or " " -> "1200 ₽" or "1 200 ₽"
	///   - showSymbol: show or not currency symbol
	///   - showFraction:
	///   `true`: show decimal part;
	///   `false`: do not show decimal part and round Double/Float value to Int
	/// - Returns: formatted amount of money with currency symbol if
	static func currencyFormatter(_ locale: Locale = Locale.current, separator: String? = nil, groupingSeparator: String? = nil, showSymbol: Bool = true, showFraction: Bool = true) -> NumberFormatter {
		let formatter = NumberFormatter()
		formatter.locale = locale
		formatter.numberStyle = showSymbol ? .currency : .decimal
		if let groupingSeparator = groupingSeparator {
			formatter.groupingSeparator = groupingSeparator
			formatter.currencyGroupingSeparator = groupingSeparator
		}
		if let decimalSeparator = separator {
			formatter.decimalSeparator = decimalSeparator
			formatter.currencyDecimalSeparator = decimalSeparator
		}
		formatter.maximumFractionDigits = showFraction ? 2 : 0
		formatter.alwaysShowsDecimalSeparator = showFraction
		formatter.formatterBehavior = .behavior10_4
		return formatter
	}
}
