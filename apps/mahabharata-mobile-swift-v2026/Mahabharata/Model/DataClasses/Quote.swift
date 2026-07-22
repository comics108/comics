//
//  Quote.swift
//  Mahabharata
//
//  Created by Class Generator by Olga Zhegulo on 22 Oct 2019.
//  Copyright (c) 2019 Iron Water Studio. All rights reserved.
//

import Foundation

struct Quote {

	var id: Int
	var name: String
	var image: String

	init(id: Int, name: String, image: String) {
		self.id = id
		self.name = name
		self.image = image
	}

	init() {
		self.init(id: Int(), name: String(), image: String())
	}

}

extension Quote: CustomStringConvertible {
	var description: String {
		return [
			"Id: \(id)",
			"Name: \(name)",
			"Image: \(image)"
			].joined(separator: ", ")
	}
}

extension Quote {
	/**
		Example for closure:
		 	(success: @escaping (Quote?) -> ())		
		expanded:
			success: { (dataObj: Any) in
				if let item = try? Quote.parse(dataObj), let result = item {
					success(result)
				} else {
					success(nil)
				} }		 
		 collapsed:
		 	success: { (dataObj: Any) in success((try? Quote.parse(dataObj)) ?? nil) }
	*/
	static func parse(_ data: Any?) throws -> Quote? {
		guard let data = data, !(data is NSNull) else { return nil }

		guard let json = data as? [String: Any] else {
			throw "Quote field \"data\" is not dictionary type"
		}
		
		var model = Quote()

		guard let id: Int = try? Int.parse(json["id"], model.id) else {
			throw "Quote field \"id\" has wrong value \"\(String(describing: json["id"]))\" for type \"Int\""
		}
		model.id = id

		guard let name: String = try? String.parse(json["name"], model.name) else {
			throw "Quote field \"name\" has wrong value \"\(String(describing: json["name"]))\" for type \"String\""
		}
		model.name = name

		guard let image: String = try? String.parse(json["image"], model.image) else {
			throw "Quote field \"image\" has wrong value \"\(String(describing: json["image"]))\" for type \"String\""
		}
		model.image = image

		return model
	}

	/**
		Example for closure: 
			(success: @escaping ([Quote]?) -> ())		
		expanded:
			success: { (dataObj: Any) in
		 		if let item = try? Quote.array(dataObj), let result = item {
			 		success(result)
			 	} else {
					success(nil)
				} }		 	
		collapsed:
			success: { (dataObj: Any) in success((try? Quote.array(dataObj)) ?? nil) }
	*/
	static func array(_ data: Any?) throws -> [Quote]? {
		guard let data = data else { return nil }
		
		guard let array = data as? [Any] else { throw "Quote field \"data\" is not array type" }
		
		guard let result = try? array.compactMap(Quote.parse) else { throw "Quote field \"data\" contains items with unexpected format" }
		
		return result
	}
}
