//
//  MahabharataCacheManager.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 14/02/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import Foundation

final class MahabharataCacheManager {
	enum FileType {
		case comics
		case music
	}
	
	static let directories : [FileType : String] =
		[.comics : "Comics",
		 .music : "Music"]
	
	static func documentsPath(fileType: FileType, createIfNotExist: Bool = true, fileName: String) -> String {
		return FileManager.pathInDocuments(subdirectory: directories[fileType]!, createIfNotExist: createIfNotExist, fileName: fileName)
	}
}
