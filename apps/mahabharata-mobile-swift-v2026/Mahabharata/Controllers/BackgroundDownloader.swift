//
//  BackgroundDownloader.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/3/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import  Foundation


typealias CompletionBlock = (String) -> ()
typealias ProgressBlock = (Int64, Int64, String) -> ()

protocol BackgroundDownloaderDelegate: class {
	func backgroundDownloader(_ downloader: BackgroundDownloader, progressChangedFor item: DownloadItem, bytes: Int64, total: Int64, to path: String)
	func backgroundDownloader(downloader: BackgroundDownloader, didCompletedFor item: DownloadItem, to path: String)
}

protocol DownloadItem {
	var url: URL? { get } // url from
	var fileName: String { get } // file to write
}

class BackgroundDownloader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
	/// Helper class to wrap url arguments of downloadFile with blocks
	struct WrapperDownloadItem: DownloadItem {
		var url: URL?
		var fileName: String {
			url?.lastPathComponent ?? ""
		}
	}
	
	// Helper class to store running downloads
	struct DownloadInfo {
		let downloadItem: DownloadItem
		// Unique task identifier
		let identifier: String
		// Path to write file
		var toPath: String
		var progress: ProgressBlock?
		var completion: CompletionBlock?
	}
	
	static let shared = BackgroundDownloader()
	weak var delegate: BackgroundDownloaderDelegate?
	
	let kBackgroundSessionIdentifier = "kBackgroundSessionIdentifier"
	let configuration: URLSessionConfiguration
	
	var downloads: [DownloadInfo] = []
	
	override private init() {
		self.configuration = URLSessionConfiguration.background(withIdentifier: kBackgroundSessionIdentifier)
		
		super.init()
	}
	
	func resumeSession() {
		_ = URLSession(configuration: self.configuration, delegate: self, delegateQueue: OperationQueue.main)
	}
	
	func cancelAll() {
		let session = URLSession(configuration: self.configuration, delegate: self, delegateQueue: OperationQueue.main)
		session.invalidateAndCancel()
	}
	
	//MARK: - Functionality

	/// Download file from URL with progress and completion blocks. Main download method.
	/// - Parameters:
	///   - item: item to download: instance of class implementing DownloadItem protocol. Contains url and optional data (e.g. state) to pass to delegate.
	///   - path: path to write downloaded file
	///   - identifier: unique download identifier
	///   - progress: block to perform on download progress
	///   - completion: block to perform when download completed
	private func downloadFileInner(item: DownloadItem, to path: String, identifier: String, progress: ProgressBlock?, completion: CompletionBlock?) {
		guard let url = item.url else {
			completion?("")
			delegate?.backgroundDownloader(downloader: self, didCompletedFor: item, to: "")
			return
		}
		//Save data
		if downloads.firstIndex(where: { $0.identifier == item.fileName }) != nil {
			print("Error: Got multiple downloads for a single download task. This should not happen")
			return
		} else {
			self.downloads.append(DownloadInfo(downloadItem: item, identifier: identifier, toPath: path, progress: progress, completion: completion))
		}
		
		//Start download
		let session = URLSession(configuration: self.configuration, delegate: self, delegateQueue: OperationQueue.main)
		let task = session.downloadTask(with: url)
		// Task description should be same as downloadInfo identifier
		task.taskDescription = identifier
		task.resume()
	}
	
	/// Download file from URL with progress and completion blocks
	/// - Parameters:
	///   - item: item to download: instance of class implementing DownloadItem protocol. Contains url and optional data (e.g. state) to pass to delegate.
	///   - path: path to write downloaded file
	///   - identifier: unique download identifier
	///   - progress: block to perform on download progress
	///   - completion: block to perform when download completed
	func downloadFile(item: DownloadItem, to path: String, identifier: String, progress: @escaping(ProgressBlock), completion: @escaping(CompletionBlock)) {
		downloadFileInner(item: item, to: path, identifier: identifier, progress: progress, completion: completion)
	}
	
	/// Download file from URL with progress and completion blocks
	/// - Parameters:
	///   - url: url to download file from
	///   - path: path to write downloaded file
	///   - identifier: unique download identifier
	///   - progress: block to perform on download progress
	///   - completion: block to perform when download completed
	func downloadFile(url: URL, to path: String, identifier: String, progress: @escaping(ProgressBlock), completion: @escaping(CompletionBlock)) {
		let item = WrapperDownloadItem(url: url)
		downloadFileInner(item: item, to: path, identifier: identifier, progress: progress, completion: completion)
	}

	/// Download file from URL. Progress and completion should be handled by BackgroundDownloaderDelegate
	/// - Parameters:
	///   - url: url to download file from
	///   - path: path to write downloaded file
	///   - identifier: unique download identifier
	func downloadFile(item: DownloadItem, to path: String, identifier: String) {
		downloadFileInner(item: item, to: path, identifier: identifier, progress: nil, completion: nil)
	}
	
	//MARK: - URLSessionDelegate
	public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
		print("urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {")
	}
	
	public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
		print("urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {")
	}
	
	//MARK: - URLSessionDownloadDelegate
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		print("Session \(session) download task \(downloadTask) finished downloading to url \(location)")
		//Move file where needed as the temporary download will be removed automatically on this method return
		
		let identifier = downloadTask.taskDescription!
		
		//Fix for download started on previous application run; toPath will be empty
		if let index = downloads.firstIndex(where: { $0.identifier == identifier }) {
			let download = downloads[index]
			//Delete if older one exists
			FileManager.delete(atPath: download.toPath)
			
			//Move
			FileManager.move(atPath: location.path, toPath: download.toPath)
			
			//Call completion handler
			let fileName = (download.toPath as NSString).lastPathComponent
			//Run block; argument if file name
			download.completion?(fileName)
			//Or delegate; last argument is path
			delegate?.backgroundDownloader(downloader: self, didCompletedFor: download.downloadItem, to: download.toPath)
			
			//Cleanup
			self.downloads.remove(at: index)
		}
	}
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		print("Session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes")

		//Call progress block
		if let index = downloads.firstIndex(where: { $0.identifier == downloadTask.taskDescription! }) {
			let download = downloads[index]
			//Run block; argument if file name
			let fileName = (download.toPath as NSString).lastPathComponent
			downloads[index].progress?(totalBytesWritten, totalBytesExpectedToWrite, fileName)
			//Or delegate; last argument is path
			delegate?.backgroundDownloader(self, progressChangedFor: download.downloadItem, bytes: totalBytesWritten, total: totalBytesExpectedToWrite, to: download.toPath)
		}
	}
	
//	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//		//Resume task
//		print("didCompleteWithError: \(String(describing: error))")
//		if let userInfo = (error as? NSError)?.userInfo, let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
//			let newTask = session.downloadTask(withResumeData: resumeData)
//			//Pass identifier of downloaded item
//			newTask.taskDescription = task.taskDescription
//			
//			newTask.resume()
//		} else  {
//			print("resumeData: nil")
//			//TODO:Hide progress
//		}
//	}
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
		print("urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {")
		//TODO: resume download on next application run
	}
	
}
