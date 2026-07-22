//
//  Music+Extension.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 07.12.2020.
//  Copyright © 2020 Iron Water Studio. All rights reserved.
//

import Foundation

extension Music {
	var state: MusicState {
		return MusicState.getBy(id: self.id)
	}
}
