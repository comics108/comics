//
//  FileManager+Extension.swift
//  DbLibrary
//
//  Created by Olga Zhegulo on 13 Feb 2019.
//  Based on: EstelColorMaster
//
//  Dependencies:
//      system: Foundation
//		custom: String+Extension
//
//	Changes history:
//		25 Oct 2019. Olga Zhegulo:
//			* added method fileNameWithoutExtension
//
//  Copyright © 2019 Iron Water Studio. All rights reserved.
//

import Foundation

extension FileManager {
	static func applicationDocumentsDirectory() -> String {
		return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
	}
	
	static func applicationCachesDirectory() -> String {
		return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
	}
	
	static func pathInDocuments(subdirectory: String = "", createIfNotExist: Bool = true, fileName: String = "") -> String {
		return self.pathInDirectory(self.applicationDocumentsDirectory(), subdirectory: subdirectory, createIfNotExist: createIfNotExist, fileName: fileName)
	}
	
	static func pathInCaches(subdirectory: String = "", createIfNotExist: Bool = true, fileName: String = "") -> String {
		return self.pathInDirectory(self.applicationCachesDirectory(), subdirectory: subdirectory, createIfNotExist: createIfNotExist, fileName: fileName)
	}
	
	static func pathIn(_ directory: String, subdirectory: String = "", createIfNotExist: Bool = true, fileName: String = "") -> String {
		return self.pathInDirectory(directory, subdirectory: subdirectory, createIfNotExist: createIfNotExist, fileName: fileName)
	}
	
	static func fileName(from: String) -> String? {
		if let url = URL(string: from) {
			return url.lastPathComponent
		}
		
		return nil
	}
	
	static func fileNameWithoutExtension(from: String) -> String? {
		if let url = URL(string: from) {
			return url.deletingPathExtension().lastPathComponent
		}
		
		return nil
	}

	static func delete(atPath filePath: String) {
		if FileManager.default.fileExists(atPath: filePath) {
			do {
				try FileManager.default.removeItem(atPath: filePath)
			}
			catch {
				print("Error removing file at path \(filePath). Error: \(error.localizedDescription)")
			}
		}
	}
	
	static func move(atPath: String, toPath: String) {
		do {
			try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
			print("Moved file to \(toPath)")
		}
		catch {
			print("Error occured during file moving from \(atPath) to \(toPath). Error: \(error.localizedDescription)")
		}
	}
	
	static func copy(atPath: String, toPath: String) {
		do {
			try FileManager.default.copyItem(atPath: atPath, toPath: toPath)
			print("Copied file to \(toPath)")
		}
		catch {
			print("Error occured during file copiing from \(atPath) to \(toPath). Error: \(error.localizedDescription)")
		}
	}
	
	static func contents(atPath: String) -> [String] {
		var contents: [String]? = nil
		do {
			try contents = FileManager.default.contentsOfDirectory(atPath: atPath)
		}
		catch {
			print("Error: \(error.localizedDescription)")
		}
		return contents ?? [String]()
	}
	
	static func markNoBackup(atPath filePath: String) {
		var url = URL(fileURLWithPath: filePath)
		do {
			var resourceValues = URLResourceValues()
			resourceValues.isExcludedFromBackup = true
			try url.setResourceValues(resourceValues)
		} catch {
			print(error.localizedDescription)
		}
	}
	
	// MARK: - Private
	static private func pathInDirectory(_ directory: String, subdirectory: String, createIfNotExist: Bool, fileName: String) -> String {
		
		//Create directory if not exist
		if createIfNotExist && !String.isNilOrWhiteSpace(subdirectory) {
			let path = directory + "/" + subdirectory
			if !FileManager.default.fileExists(atPath: path) {
				do {
					try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
				}
				catch {
					print(error.localizedDescription)
				}
			}
		}
		
		//Concatenate and return
		var path = directory
		if !String.isNilOrWhiteSpace(subdirectory) {
			path += "/" + subdirectory
		}
		if !String.isNilOrWhiteSpace(fileName) {
			path += "/" + fileName
		}
		
		return path
	}	
}
