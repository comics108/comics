//
//  Episode.swift
//  Mahabharata
//
//  Created by Class Generator by Olga Zhegulo on 2020.
//  Copyright (c) 2020 Iron Water Studio. All rights reserved.
//

import Foundation

extension Episode: Codable {}

struct Episode {

	var id: Int
	var name: String
	var image: String
	var file: String
	var version: Int
	var product: String
	// Local property; comes from AppStore
	var price: String
	var date: Date
	var order: Int

	init(id: Int, name: String, image: String, file: String, version: Int, product: String, price: String, date: Date, order: Int) {
		self.id = id
		self.name = name
		self.image = image
		self.file = file
		self.version = version
		self.product = product
		self.price = price
		self.date = date
		self.order = order
	}

	init() {
		self.init(id: Int(), name: String(), image: String(), file: String(), version: Int(), product: String(), price: String(), date: Date(), order: Int())
	}

}

extension Episode: CustomStringConvertible {
	var description: String {
		return [
			"Id: \(id)",
			"Name: \(name)",
			"Image: \(image)",
			"File: \(file)",
			"Version: \(version)",
			"Product: \(product)",
			"Price: \(price)",
			"Date: \(date)",
			"Order: \(order)"
			].joined(separator: ", ")
	}
}

extension Episode {
	/**
		Example for closure:
		 	(success: @escaping (Episode?) -> ())		
		expanded:
			success: { (dataObj: Any) in
				if let item = try? Episode.parse(dataObj), let result = item {
					success(result)
				} else {
					success(nil)
				} }		 
		 collapsed:
		 	success: { (dataObj: Any) in success((try? Episode.parse(dataObj)) ?? nil) }
	*/
	static func parse(_ data: Any?) throws -> Episode? {
		guard let data = data, !(data is NSNull) else { return nil }

		guard let json = data as? [String: Any] else {
			throw "Episode field \"data\" is not dictionary type"
		}
		
		var model = Episode()

		guard let id: Int = try? Int.parse(json["id"], model.id) else {
			throw "Episode field \"id\" has wrong value \"\(String(describing: json["id"]))\" for type \"Int\""
		}
		model.id = id

		guard let name: String = try? String.parse(json["name"], model.name) else {
			throw "Episode field \"name\" has wrong value \"\(String(describing: json["name"]))\" for type \"String\""
		}
		model.name = name

		guard let image: String = try? String.parse(json["image"], model.image) else {
			throw "Episode field \"image\" has wrong value \"\(String(describing: json["image"]))\" for type \"String\""
		}
		model.image = image

		guard let file: String = try? String.parse(json["file"], model.file) else {
			throw "Episode field \"file\" has wrong value \"\(String(describing: json["file"]))\" for type \"String\""
		}
		model.file = file

		guard let version: Int = try? Int.parse(json["version"], model.version) else {
			throw "Episode field \"version\" has wrong value \"\(String(describing: json["version"]))\" for type \"Int\""
		}
		model.version = version

		guard let product: String = try? String.parse(json["product"], model.product) else {
			throw "Episode field \"product\" has wrong value \"\(String(describing: json["product"]))\" for type \"String\""
		}
		model.product = product

		guard let date: Date = try? Date.parse(json["date"], model.date) else {
			throw "Episode field \"date\" has wrong value \"\(String(describing: json["date"]))\" for type \"Date\""
		}
		model.date = date

		guard let order: Int = try? Int.parse(json["order"], model.order) else {
			throw "Episode field \"order\" has wrong value \"\(String(describing: json["order"]))\" for type \"Int\""
		}
		model.order = order

		//Add prefix for short product ID
		if !String.isNilOrWhiteSpace(product) && !product.contains("."), let bundleId = Bundle.main.bundleIdentifier {
			model.product = bundleId + "." + product
		}
		
		return model
	}

	/**
		Example for closure: 
			(success: @escaping ([Episode]?) -> ())		
		expanded:
			success: { (dataObj: Any) in
		 		if let item = try? Episode.array(dataObj), let result = item {
			 		success(result)
			 	} else {
					success(nil)
				} }		 	
		collapsed:
			success: { (dataObj: Any) in success((try? Episode.array(dataObj)) ?? nil) }
	*/
	static func array(_ data: Any?) throws -> [Episode]? {
		guard let data = data else { return nil }
		
		guard let array = data as? [Any] else { throw "Episode field \"data\" is not array type" }
		
		guard let result = try? array.compactMap(Episode.parse) else { throw "Episode field \"data\" contains items with unexpected format" }
		
		return result
	}
}

extension Episode: Equatable {}
