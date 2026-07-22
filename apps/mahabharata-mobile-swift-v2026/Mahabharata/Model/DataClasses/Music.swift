//
//  Music.swift
//  Mahabharata
//
//  Created by Class Generator by Olga Zhegulo on 22 Oct 2019.
//  Copyright (c) 2019 Iron Water Studio. All rights reserved.
//

import Foundation

struct Music {
	//From server
	var id: Int
	var name: String
	var author: String
	var file: String

	//Custom properties
	var duration: TimeInterval = 0.0
	var isCurrent: Bool = false
	var position: TimeInterval = 0.0

	init(id: Int, name: String, author: String, file: String) {
		self.id = id
		self.name = name
		self.author = author
		self.file = file
	}

	init() {
		self.init(id: Int(), name: String(), author: String(), file: String())
	}

}

extension Music: CustomStringConvertible {
	var description: String {
		return [
			"Id: \(id)",
			"Name: \(name)",
			"Author: \(author)",
			"File: \(file)"
			].joined(separator: ", ")
	}
}

extension Music {
	/**
		Example for closure:
		 	(success: @escaping (Music?) -> ())		
		expanded:
			success: { (dataObj: Any) in
				if let item = try? Music.parse(dataObj), let result = item {
					success(result)
				} else {
					success(nil)
				} }		 
		 collapsed:
		 	success: { (dataObj: Any) in success((try? Music.parse(dataObj)) ?? nil) }
	*/
	static func parse(_ data: Any?) throws -> Music? {
		guard let data = data, !(data is NSNull) else { return nil }

		guard let json = data as? [String: Any] else {
			throw "Music field \"data\" is not dictionary type"
		}
		
		var model = Music()

		guard let id: Int = try? Int.parse(json["id"], model.id) else {
			throw "Music field \"id\" has wrong value \"\(String(describing: json["id"]))\" for type \"Int\""
		}
		model.id = id

		guard let name: String = try? String.parse(json["name"], model.name) else {
			throw "Music field \"name\" has wrong value \"\(String(describing: json["name"]))\" for type \"String\""
		}
		model.name = name

		guard let author: String = try? String.parse(json["author"], model.author) else {
			throw "Music field \"author\" has wrong value \"\(String(describing: json["author"]))\" for type \"String\""
		}
		model.author = author

		guard let file: String = try? String.parse(json["file"], model.file) else {
			throw "Music field \"file\" has wrong value \"\(String(describing: json["file"]))\" for type \"String\""
		}
		model.file = file

		return model
	}

	/**
		Example for closure: 
			(success: @escaping ([Music]?) -> ())		
		expanded:
			success: { (dataObj: Any) in
		 		if let item = try? Music.array(dataObj), let result = item {
			 		success(result)
			 	} else {
					success(nil)
				} }		 	
		collapsed:
			success: { (dataObj: Any) in success((try? Music.array(dataObj)) ?? nil) }
	*/
	static func array(_ data: Any?) throws -> [Music]? {
		guard let data = data else { return nil }
		
		guard let array = data as? [Any] else { throw "Music field \"data\" is not array type" }
		
		guard let result = try? array.compactMap(Music.parse) else { throw "Music field \"data\" contains items with unexpected format" }
		
		return result
	}
}

