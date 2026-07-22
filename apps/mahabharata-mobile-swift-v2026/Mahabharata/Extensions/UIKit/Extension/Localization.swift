//
//  Localization.swift
//
//  Created by Konstantin Oznobikhin on 11/04/16.
//  Copyright © 2016 ironwaterstudio. All rights reserved.
//

import Foundation

// TODO: нужно создать отдельный проект
// нужно чтобы лезло в конкретный файл локали
// локализуемые картинки
public func Local(_ key: String) -> String {
	return NSLocalizedString(key, comment: "")
}
