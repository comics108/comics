//
//  InAppPurchaseManager.swift
//	InAppPurchaseManager
//
//	Based on:
//  	EstelColorMaster
//
//  Created by Olga Zhegulo on 14 Aug 2020.
//  Copyright © 2020 Iron Water Studio. All rights reserved.
//

import UIKit
import StoreKit

@objc protocol InAppPurchaseDelegate {
	@objc optional func inAppPurchase(manager: InAppPurchaseManager, didLoaded products: [SKProduct]?)
	
	// When this method implemented then need manualy to finish transaction
	@objc optional func inAppPurchase(manager: InAppPurchaseManager, didPurchased transaction: SKPaymentTransaction, queue: SKPaymentQueue)
	
	// When this method implemented then need manualy to finish transaction
	// ?? did product restored with (productId)
	@objc optional func inAppPurchase(manager: InAppPurchaseManager, didRestored productID: String?, queue: SKPaymentQueue)
	// ?? did fail(with: error, transaction)
	@objc optional func inAppPurchase(manager: InAppPurchaseManager, didFail error: Error?, transaction: SKPaymentTransaction?, queue: SKPaymentQueue?)
}

class InAppPurchaseManager: NSObject {
	typealias ProductRequestSuccessBlock = ([SKProduct]) -> ()
	typealias ProductPurchaseSuccessBlock = (Data, [String]?) -> ()
	typealias ProductRestoreSuccessBlock = ([String]) -> ()
	//TODO: probably optional [String: Any]. Receipt is nil when user has no purchases succeeded in app
	typealias ReceiptSuccessBlock = ([String: Any]) -> ()
	typealias InAppErrorBlock = (InAppError) -> ()
	typealias ErrorBlock = (String, Error?) -> ()
	typealias DownloadReceiptResultBlock = (DownloadReceiptResult) -> ()

	enum Constants {
		static let iTunesURL = "https://buy.itunes.apple.com/verifyReceipt"
		/// Sandbox
		static let iTunesSandboxURL = "https://sandbox.itunes.apple.com/verifyReceipt"
	}
	
	struct PurchaseInfo {
		let identifier: String
		let quantity: Int
		var success: ProductPurchaseSuccessBlock
		var error: InAppErrorBlock
		var paths: [String]
	}
	
	struct RestoreTransactionInfo {
		let originalTransactionID: String?
		let transactionID: String
		let productID: String
		var paths: [String]
	}
	
	enum ReceiptStatus: Int {
		case valid = 0
		/// The request to the App Store was not made using the HTTP POST request method.
		case notHttpPost = 21000
		/// The data in the receipt-data property was malformed or the service experienced a temporary issue. Try again.
		case invalidData = 21002
		/// The receipt could not be authenticated.
		case notAuthenticated = 21003
		/// The shared secret you provided does not match the shared secret on file for your account.
		case secretNotMatch = 21004
		/// The receipt server was temporarily unable to provide the receipt. Try again.
		case serverUnavailable = 21005
		/// This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Only returned for iOS 6-style transaction receipts for auto-renewable subscriptions.
		case subscriptionExpired = 21006
		/// This receipt is from the test environment, but it was sent to the production environment for verification.
		case sandbox = 21007
		/// This receipt is from the production environment, but it was sent to the test environment for verification.
		case productionInSandbox = 21008
		/// Internal data access error. Try again later.
		case accessError = 21009
		/// The user account cannot be found or has been deleted.
		case accountNotFound = 21010
	}
	
	enum LoadReceiptResult {
		case success(Data)
		case error(String, Error?)
	}
	
	enum DownloadReceiptResult {
		case success([String: Any])
		case connectionError(String, Error?)
		case receiptError(ReceiptStatus)
		case error(String)
	}

	static let shared = InAppPurchaseManager()
	
	var productsRequest: SKProductsRequest?
	weak var delegate: InAppPurchaseDelegate?

	//For purchase methods
	var productPurchases: [PurchaseInfo] = []

	//For restore methods
	var productRestoresTransactions: [RestoreTransactionInfo] = []
	var productRestoreSuccessBlock: ProductRestoreSuccessBlock?
	var productRestoreErrorBlock: InAppErrorBlock?

	//For product request methods
	var successBlock: ProductRequestSuccessBlock?
	var errorBlock: InAppErrorBlock?
	
	private override init() { }
	
	//MARK: - Public
	
	/**
	Register for handling transactions passing to `SKPaymentQueue`
	
	- Important: Best place for calling this method is `application(_:didFinishLaunchingWithOptions:)`

	Call this method on application launch to have ability to handle pending transactions.
	
	If an application quits when transactions are still being processed, those transactions are not lost.
	The next time the application launches, the payment queue will resume processing the transactions.
	*/
	func registerForPaymentTransactions() {
		SKPaymentQueue.default().add(self)
	}
	
	/**
	Unregister from `SKPaymentQueue` notifications
	
	- Important: Best place for calling this method is `applicationWillTerminate(_:)`
	*/
	func unregisterForPaymentTransactions() {
		SKPaymentQueue.default().remove(self)
	}
	
	func cancel(transaction: SKPaymentTransaction, error: Error) {
		let inAppError = InAppError(transaction, error: error)
		inAppError.isCanceled = true
		
		if transaction.transactionState == .purchased {
			if let errorBlock = self.extractErrorBlock(with: transaction.payment.productIdentifier, quantity: transaction.payment.quantity) {
				errorBlock(inAppError)
			}
		}
		else if transaction.transactionState == .restored {
			self.productRestoreErrorBlock?(inAppError)
			
			self.productRestoresTransactions = []
			self.productRestoreSuccessBlock = nil
			self.productRestoreErrorBlock = nil
		}
	}
	
	//MARK: - Instance methods
	/// Restore purchases (e.g. after installed app to new device of same user)
	/// - Parameters:
	///   - success: block to run when purchase succeeded. Returns: array of product identifiers. Could be called NOT in main thread.
	///   - error: block to run when error. Contains InAppError (custom class). Could be called NOT in main thread.
	public func restoreProducts(success: @escaping(ProductRestoreSuccessBlock), error: @escaping(InAppErrorBlock)) {
		if self.productRestoreSuccessBlock != nil || self.productRestoreErrorBlock != nil  {
			error(InAppError(nil, error: nil, message: "Restore purchases already started"))
			return
		}
		
		self.productRestoreSuccessBlock = success
		self.productRestoreErrorBlock = error

		SKPaymentQueue.default().restoreCompletedTransactions()
	}
	
	/// Requests product information for given `productIDs` from the App Store
	/// - Parameters:
	///   - productIDs: Array of product identifiers for which will be sent request.
	///   - success: Block to which passed `SKProduct` instances of valid products with IDs from `productsID`. Could be called NOT in main thread.
	///   - error: Block to which passed a `NSError` instance if any network error occured. Could be called NOT in main thread.
	public func getProducts(for productIDs: [String], success: @escaping(ProductRequestSuccessBlock), error: @escaping(InAppErrorBlock)) {
		self.successBlock = success
		self.errorBlock = error
		
		self.productsRequest = SKProductsRequest(productIdentifiers: Set(productIDs))
		self.productsRequest?.delegate = self
		self.productsRequest?.start()
	}
	
	//MARK: - Products purchasing
	/// Purchase product
	/// If product was purchased early and we buy it again then InApp dialog will be shown with "Buy" button and then will be shown restore confirmation dialog with "Ok" button. After restore in this case we receive transaction with state PURCHASED (NOT RESTORED!, when user manualy performs restore we will receive transactions with status RESTORED)
	/// - Parameters:
	///   - identifier: AppStore purchase identifier
	///   - quantity: number of items (for consumable purchases)
	///   - success: block to run when purchase succeeded. Returns: data of AppStore reciept + optional list of urls of binary content urls (hosted at Apple servers).  Could be called NOT in main thread.
	///   - error: block to run when error. Contains InAppError (custom class). Could be called NOT in main thread.
	public func purchaseProduct(with identifier: String, quantity: Int = 1, success: @escaping(ProductPurchaseSuccessBlock), error: @escaping(InAppErrorBlock)) {
		if !SKPaymentQueue.canMakePayments() {
			error(InAppError(nil, error: nil))
			self.delegate?.inAppPurchase?(manager: self, didFail: nil, transaction: nil, queue: nil)
			return
		}
		
		var currentPurchase = self.productPurchases.first(where: { $0.identifier == identifier && $0.quantity == quantity })
		if currentPurchase == nil {
			self.productPurchases.append(PurchaseInfo(identifier: identifier, quantity: quantity, success: success, error: error, paths: []))
		}
		else {
			currentPurchase?.success = success
			currentPurchase?.error = error
		}
		
		let payment = SKMutablePayment()
		payment.productIdentifier = identifier
		payment.quantity = quantity
		// Uncomment this line if you want to debug Ask To Buy scenario
		// WARNING: Be sure this line is commented in the production build
//		payment.simulatesAskToBuyInSandbox = true
		SKPaymentQueue.default().add(payment)
	}
	
	/// Get success block for purchase with product identifier and quantity and remove information for the purchase from list of running purchases
	func extractSuccessBlock(with identifier: String, quantity: Int) -> ProductPurchaseSuccessBlock? {
		if let index = self.productPurchases.firstIndex(where: { $0.identifier == identifier && $0.quantity == quantity }) {
			let successBlock = self.productPurchases[index].success
			self.productPurchases.remove(at: index)
			
			return successBlock
		}
		
		return nil
	}
	
	/// Get error block for purchase with product identifier and quantity and remove information for the purchase from list of running purchases
	func extractErrorBlock(with identifier: String, quantity: Int) -> InAppErrorBlock? {
		if let index = self.productPurchases.firstIndex(where: { $0.identifier == identifier && $0.quantity == quantity }) {
			//purchase
			let errorBlock = self.productPurchases[index].error
			self.productPurchases.remove(at: index)
			
			return errorBlock
		}
		
		return nil
	}
	
	/// Check if purchase info with success/error blocks exist for certain product id and quantity
	func canExtractBlock(with identifier: String, quantity: Int) -> Bool {
		return self.productPurchases.firstIndex(where: { $0.identifier == identifier && $0.quantity == quantity }) != nil
	}
	
	//MARK: - Receipt

	//Always verify your receipt first with the production URL; proceed to verify with the sandbox URL if you receive a 21007 status code.
	// see https://stackoverflow.com/questions/9677193/ios-storekit-can-i-detect-when-im-in-the-sandbox
	
	/// Get receipt from Apple (verify receipt)
	/// - Parameters:
	///   - success: block to run when receipt received. Returns: dictionary. Could be called NOT in main thread.
	///   - error: block to run when receipt does not exist at device or could not be retrieved. Could be called NOT in main thread.
	public func loadReceipt(with success: @escaping(ReceiptSuccessBlock), error: @escaping(ErrorBlock)) {
		let result = loadReceiptData()
		switch result {
		case .success(let receipt):
			downloadReceipt(receipt: receipt, success: success, error: error)
		case .error(let message, let err):
			error(message, err)
		}
	}
	
	/// Get local (device) AppStore receipt
	private	func loadReceiptData() -> LoadReceiptResult {
		guard let receiptURL = Bundle.main.appStoreReceiptURL else {
			return .error("Error occured when extracting receipt: Bundle.main.appStoreReceiptURL is nil", nil)
		}

		do {
			if try receiptURL.checkResourceIsReachable() {
				return .success(try Data(contentsOf: receiptURL))
			} else {
				// Just for safety. Currenly nil receipt throws error
				return .error("Receipt is nil", nil)
			}
		}
		catch let err {
			// If user has not purchased/restored receipt is empty and throws error
			return .error("Error occured when extracting receipt", err)
		}
	}
	
	/// Get receipt from Apple (verify local receipt). Handles sandbox case.
	/// Warning: does not handle auto-reneewable subscriptions because does not use Shared Secret
	/// - Parameters:
	///   - storeUrl: url of verifyReceipt method
	///   - receipt: local receipt
	///   - success: block to call if success; returns dictionary of receipt data
	///   - error: block to call if error; returns error and custom error message
	private func downloadReceipt(storeUrl: String = Constants.iTunesURL, receipt: Data, success: @escaping(ReceiptSuccessBlock), error: @escaping(ErrorBlock)) {
		downloadReceiptData(storeUrl: storeUrl, receipt: receipt) { [weak self] (result: DownloadReceiptResult) in
			guard let self = self else { return	}
			
			switch result {
			case let .success(jsonDictionary):
				success(jsonDictionary)
			case let .connectionError(url, err):
				error(url, err)
			case let .receiptError(status):
				// In case of test environment (i.e. is not production)
				if status == .sandbox {
					self.downloadReceipt(storeUrl: Constants.iTunesSandboxURL, receipt: receipt, success: success, error: error)
				} else {
					error("Unsupported receipt status: \(status.rawValue)", nil)
				}
			case let .error(message):
				error(message, nil)
			}
		}
	}
	
	/// Load receipt from Apple.
	/// - Parameters:
	///   - storeUrl: url of verifyReceipt method
	///   - receipt: local receipt
	///   - completion: block with verification result: dictionary with reciept or error
	private func downloadReceiptData(storeUrl: String, receipt: Data, completion: @escaping DownloadReceiptResultBlock) {
		guard let url = URL(string: storeUrl) else {
			completion(.connectionError(storeUrl, URLError(URLError.Code.badURL)))
			return
		}
		
		// Create the JSON object that describes the request. If user has not purchased/restored receipt is empty.
		let requestContents = ["receipt-data": receipt.base64EncodedString()]
		let requestData = try? JSONSerialization.data(withJSONObject: requestContents, options: [])
		
		// Create a POST request with the receipt data
		var storeRequest = URLRequest(url: url)
		storeRequest.httpMethod = "POST"
		storeRequest.httpBody = requestData
		
		let session = URLSession.shared
		let task = session.dataTask(with: storeRequest) { (data: Data?, response: URLResponse?, connectionError: Error?) in
			if connectionError != nil {
				completion(.connectionError(storeUrl, connectionError))
				return
			}
		
			do {
				if let data = data, let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
					#if DEBUG
					print("receipt for \(storeUrl): \(jsonDictionary)")
					#endif
					
					if let status = jsonDictionary["status"] as? Int, status != ReceiptStatus.valid.rawValue {
						completion(.receiptError(ReceiptStatus(rawValue: status) ?? ReceiptStatus.valid))
					} else {
						completion(.success(jsonDictionary))
					}
				}
			}
			catch {
				completion(.error("Receipt data from \(storeUrl) are not valid"))
				return
			}
		}
		task.resume()
	}
	
	//MARK: - Public static
	
	/**
	Indicates whether the user can make payments.
	
	If the user can’t make payments (for example, because of parental restrictions),
	either display UI indicating that that the store isn’t available or omit the store portion of your UI entirely.
	*/
	static func canMakePayments() -> Bool {
		return SKPaymentQueue.canMakePayments()
	}
}

//MARK: - SKProductsRequestDelegate
extension InAppPurchaseManager: SKProductsRequestDelegate {
	func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		for invalidProductID in response.invalidProductIdentifiers {
			print("Invalid product identifier \(invalidProductID)")
		}
		
		successBlock?(response.products)
		
		self.successBlock = nil
		self.errorBlock = nil
		self.productsRequest = nil

		self.delegate?.inAppPurchase?(manager: self, didLoaded: response.products)
	}
	
	func request(_ request: SKRequest, didFailWithError error: Error) {
		errorBlock?(InAppError(nil, error: error))
		
		self.successBlock = nil
		self.errorBlock = nil
		self.productsRequest = nil
		
		self.delegate?.inAppPurchase?(manager: self, didFail: error, transaction: nil, queue: nil)
	}
}

//MARK: - SKPaymentTransactionObserver
extension InAppPurchaseManager: SKPaymentTransactionObserver {
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		for transaction in transactions {
			switch transaction.transactionState {
			case .purchasing:
				print("Transaction is being added to the server queue: \(transaction.payment.productIdentifier)")
			case .purchased:
				// Download binary content from Apple server (for Apple hosted purchase)
				if transaction.downloads.count > 0 {
					queue.start(transaction.downloads)
					break
				}
				
				// Delegate method should call finishTransaction()
				if let method = self.delegate?.inAppPurchase(manager:didPurchased:queue:) {
					method(self, transaction, queue)
				}
				else {
					queue.finishTransaction(transaction)
				}
				
			case .failed:
				// We should finish failed transaction. https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/1506107-paymentqueue
				// Otherwise second try to buy product will result error! Case: user canceled purchase and then clicked it second time. AppStore dialog would not appear until user restarted device.
				queue.finishTransaction(transaction)
				
				if let errorBlock = self.extractErrorBlock(with: transaction.payment.productIdentifier, quantity: transaction.payment.quantity) {
					let error = InAppError(transaction)
					errorBlock(error)
				}
				
				self.delegate?.inAppPurchase?(manager: self, didFail: transaction.error, transaction: transaction, queue: queue)
				
			case .restored:
				guard let transactionIdentifier = transaction.transactionIdentifier else {
					return
				}
				self.productRestoresTransactions.append(RestoreTransactionInfo(originalTransactionID: transaction.original?.transactionIdentifier, transactionID: transactionIdentifier, productID: transaction.payment.productIdentifier, paths: []))
				
				if transaction.downloads.count > 0 && transaction.downloads[0].downloadState == .waiting {
					queue.start(transaction.downloads)
					break
				}
				
				// Delegate method should call finishTransaction()
				if let method = self.delegate?.inAppPurchase(manager:didPurchased:queue:) {
					method(self, transaction, queue)
				}
				else {
					queue.finishTransaction(transaction)
				}
				
			case .deferred:
				if let errorBlock = self.extractErrorBlock(with: transaction.payment.productIdentifier, quantity: transaction.payment.quantity) {
					let error = InAppError(transaction)
					error.askToBuy = true
					errorBlock(error)
				}
				
				self.delegate?.inAppPurchase?(manager: self, didFail: transaction.error, transaction: transaction, queue: queue)
			@unknown default:
				break
			}
		}
	}
	
	// Sent when the download state has changed.
	func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
		for download in downloads {
			switch download.downloadState {
			case .active:
				print("Download progress: \(download.progress), time remaining: \(download.timeRemaining)")
			case .finished:
				print("Download finished: \(download.transaction.payment.productIdentifier)")
				guard let contentURL = download.contentURL else {
					// Local url for downloaded file always present for downloadState = .finished
					return
				}
				// Download is complete. Content file URL is at path referenced by download.contentURL.
				// Move it somewhere safe, unpack it and give the user access to it
				// Extracted files will be saved to Documents/InApp/ dir
				
				//"Contents" directory is the default in .PKG files
				let packageContentsDirectory = FileManager.pathIn(contentURL.path, subdirectory: "Contents")
				let packageContents = FileManager.contents(atPath: packageContentsDirectory)
				var destinationPaths = [String]()
				for fileName in packageContents {
					let filePath = FileManager.pathIn(contentURL.path, subdirectory: "Contents", fileName: fileName)
					let destinationFilePath = FileManager.pathInDocuments(subdirectory: "InApp", fileName: fileName)
					FileManager.copy(atPath: filePath, toPath: destinationFilePath)
					FileManager.markNoBackup(atPath: destinationFilePath)
					
					// Save destinationPath for saving in storage
					destinationPaths.append(destinationFilePath)
				}
				
				// Need to store restored and purchased data separately
				if download.transaction.transactionState == .restored {
					if let index = self.productRestoresTransactions.firstIndex(where: { $0.transactionID == download.transaction.transactionIdentifier }) {
						self.productRestoresTransactions[index].paths = destinationPaths
					}
					
					// Delegate method should call finishTransaction()
					if let method = self.delegate?.inAppPurchase(manager:didRestored:queue:) {
						method(self, download.transaction.payment.productIdentifier, queue)
					}
					else {
						SKPaymentQueue.default().finishTransaction(download.transaction)
					}
				}
				else if download.transaction.transactionState == .purchased {
					let payment = download.transaction.payment
					if let index = self.productPurchases.firstIndex(where: { $0.identifier == payment.productIdentifier && $0.quantity == payment.quantity }) {
						self.productPurchases[index].paths = destinationPaths
					}
					
					// Delegate method should call finishTransaction()
					if let method = self.delegate?.inAppPurchase(manager:didPurchased:queue:) {
						method(self, download.transaction, queue)
					}
					else {
						SKPaymentQueue.default().finishTransaction(download.transaction)
					}
				}
				
			case .paused:
				print("Download paused: \(String(describing: download.contentURL))")
			case .failed:
				print("Download failed: \(String(describing: download.contentURL)) with error: \(String(describing: download.error))")
				let transaction = download.transaction
				let payment = transaction.payment
				
				if transaction.transactionState == .purchased {
					if let errorBlock = self.extractErrorBlock(with: payment.productIdentifier, quantity: payment.quantity) {
						let error = InAppError(transaction)
						errorBlock(error)
					}
				}
				else if transaction.transactionState == .restored {
					let error = InAppError(transaction)
					self.productRestoreErrorBlock?(error)
					
					// Comment: Remove even if errorRestoreBlock is nil
					self.productRestoresTransactions = []
					self.productRestoreSuccessBlock = nil
					self.productRestoreErrorBlock = nil
				}
				
				// Delegate method should call finishTransaction()
				if let method = self.delegate?.inAppPurchase(manager:didFail:transaction:queue:) {
					method(self, download.transaction.error, transaction, queue)
				}
				else {
					SKPaymentQueue.default().finishTransaction(transaction)
				}
			default:
				break
			}
		}
	}
	
	func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
		// Restored transactions
		let restoreTransactions = self.productRestoresTransactions
		if !restoreTransactions.isEmpty {
			let productIDs = restoreTransactions.map({ $0.productID })
			self.productRestoreSuccessBlock?(productIDs)
		}
		
		// Comment: Always clean up any restoration related data
		self.productRestoresTransactions = []
		self.productRestoreSuccessBlock = nil
		self.productRestoreErrorBlock = nil
		
		for transaction in transactions {
			print("Transaction removed from the server queue: \(transaction.payment.productIdentifier)")
			if transaction.transactionState == .purchased {
				let payment = transaction.payment
				let purchase = self.productPurchases.first(where: { $0.identifier == payment.productIdentifier && $0.quantity == payment.quantity })
				let downloadPaths = purchase?.paths
				
				// Receipt exist if user purchased some products at device. receiptURL should be not nil because product is purchased
				if canExtractBlock(with: payment.productIdentifier, quantity: payment.quantity) {
					// Try to extract local AppStore receipt
					let result = loadReceiptData()
					switch result {
					case .success(let receiptData):
						// Run purchase success
						let successBlock = extractSuccessBlock(with: payment.productIdentifier, quantity: payment.quantity)
						successBlock?(receiptData, downloadPaths)
					case .error(let message, let err):
						// This branch normally will not execute because receipt should exist for purchased transaction
						let errorBlock = extractErrorBlock(with: payment.productIdentifier, quantity: payment.quantity)
						errorBlock?(InAppError(transaction, error: err, message: message))
					}
				}
			}
		}
	}
	
	// This method called after we processed restored transactions in paymentQueue:updatedTransactions: method
	// In this method we only handle the case when the user doesn't have any purchased products but started restoration process
	func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
		if self.productRestoresTransactions.isEmpty {
			self.productRestoreSuccessBlock?([])
			
			self.productRestoresTransactions = []
			self.productRestoreSuccessBlock = nil
			self.productRestoreErrorBlock = nil
		}
	}
	
	func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
		let inAppError = InAppError(nil, error: error)
		self.productRestoreErrorBlock?(inAppError)
		
		// Comment: Delete in all cases
		self.productRestoresTransactions = []
		self.productRestoreSuccessBlock = nil
		self.productRestoreErrorBlock = nil
	}
	

}
