//
//  UILabel+Style+Mahabharata.swift
//  Mahabharata
//
//  Created by Roman Developer on 7/19/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UILabel {
	static func headerLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(UIFont.light(ofSize: 30)).color(UIColor.yellow1)
	}
	
	static func languageLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(UIFont.semibold(ofSize: 16)).color(UIColor.yellow1)
	}
	
	static func tabLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(UIFont.semibold(ofSize: 14)).color(UIColor.yellow1)
	}
	
	static func numberLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(UIFont.semibold(ofSize: 16)).color(UIColor.yellow1)	//TODO: Currently the same as language
	}
	
	static func numberSmallLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(UIFont.semibold(ofSize: 12)).color(UIColor.yellow1)
	}
	
	static func bttnLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(UIFont.semibold(ofSize: 10)).color(UIColor.yellow1)
	}
	
	static func titleLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(.regular(ofSize: 18)).color(.white).lines(0).wrap(.byWordWrapping)
	}
	
	static func titleSmallLabel(_ text: String = "") -> UILabel {
		return UILabel().text(text).font(UIFont.regular(ofSize: 16)).color(UIColor.white).lines(0).wrap(.byWordWrapping)
	}

	static func seasonSubtitleLabel(_ text: String = "") -> UILabel {
		return UILabel(text).font(.regular(ofSize: 13)).color(.sand).lines(0).wrap(.byWordWrapping)
	}

	static func subtitleSmallLabel(_ text: String = "") -> UILabel {
		return UILabel(text).font(UIFont.regular(ofSize: 12)).color(UIColor.yellow1)
	}

	static func guideLabel(_ text: String = "") -> UILabel {
		return UILabel(text).font(UIFont.regular(ofSize: 12)).color(UIColor.white)
	}
	
	static func chapterLabel(_ text: String = "") -> UILabel {
		return UILabel(text).font(UIFont.semibold(ofSize: 16)).color(UIColor.yellow1).lines(0).wrap(.byWordWrapping).alignment(.center)
	}
	
	static func chapterSmallLabel(_ text: String = "") -> UILabel {
		return UILabel(text).font(UIFont.regular(ofSize: 12)).color(UIColor.yellow1)
	}
	
	static func aboutLabel(_ text: String = "") -> UILabel {
		return UILabel(text).font(UIFont.regular(ofSize: 16)).color(UIColor.white).lines(0).wrap(.byWordWrapping)
	}
}
