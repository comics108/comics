//
//  NetworkErrorManager.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 25 Jul 2017.
//	Updated by Andrey Kozlov on 06 Feb 2019.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//	Changes history:
//		06 Feb 2019. Andrey Kozlov:
//			* added weak reference control in timer
//

import Foundation

// Network errors localizations
let NETWORKERRORMANAGER_NETWORKERROR_CHECK_OR_WAIT = NSLocalizedString("NetworkErrorManager.NetworkErrorCheckOrWait", comment: "Соединение с сервером не может быть установлено. Пожалуйста, проверьте настройки интернет-соединения или повторите попытку чуть позже.")
let NETWORKERRORMANAGER_NETWORKERROR_CHECK = NSLocalizedString("NetworkErrorManager.NetworkErrorCheck", comment: "Соединение с сервером не может быть установлено. Пожалуйста, проверьте настройки интернет-соединения.")
let NETWORKERRORMANAGER_NETWORKERROR_TIMEOUT = NSLocalizedString("NetworkErrorManager.NetworkErrorTimedOut", comment: "Превышен лимит времени ожидания ответа от сервера. Пожалуйста, проверьте настройки интернет-соединения.")
let NETWORKERRORMANAGER_NETWORKERROR_HOST_IS_NOT_AVAILABLE = NSLocalizedString("NetworkErrorManager.NetworkErrorHostIsNotAvailable", comment: "Не удалось установить соединение с сервером, сервер недоступен.")
let NETWORKERRORMANAGER_NETWORKERROR_WRONG_REQUEST = NSLocalizedString("NetworkErrorManager.NetworkErrorWrongRequest", comment: "Сервер не доступен или неправильный запрос. Обратитесь к администрации ресурса.")

// Buttons localizations
let NETWORKERRORMANAGER_BUTTON_CANCEL = NSLocalizedString("NetworkErrorManager.Cancel", comment: "Отмена")
let NETWORKERRORMANAGER_BUTTON_RETRY = NSLocalizedString("NetworkErrorManager.Retry", comment: "Повторить")
let NETWORKERRORMANAGER_BUTTON_OK = NSLocalizedString("NetworkErrorManager.Ok", comment: "OK")

/**
 *  Класс, который используется для проверки появления сети каждые 2 секунды, путем обращения к NetworkConnectionManager.shared.isInternetAvailable.
 *  а также подписываться должен на событие появления сети класса
	- Note: В будущем стоит подумать об оптимизации - сделать таймер пореже (раз в 5-10 секунд) + подписываться на изменение состояния сети через **NetworkConnectionManager.shared.add** - обсервацию.
 */
final class NetworkErrorManager: NetworkConnectionManagerDelegate {
	enum Mode {
		/// Режим работы при котором пользователю один раз показывается алерт о проблемах с соединением. Данный режим полагается на reachability,
		/// при появлении интернета будет выполнена процедура повтора запросов.
		case autoConnect
		
		/// Режим работы аналогичен режиму `autoConnect` за исключением того факта, что пользователь не будет уведомлен о проблемах с соединением.
		case silent
		
		/// Режим работы при котором пользователь будет уведомлен о проблемах с соединением каждый раз, когда будет срабатывать таймер, если на момент срабатывания
		/// таймера не показывается предыдущий алерт. Алерт для данного режима имеет две кнопки: Повторить и Отменить. Если на момент срабатывания таймера доступ к интернету
		/// будет восстановлен, то будет выполнен перезапуск запросов, иначе будет сформирован новый цикл работы таймера.
		case timer
	}
	
	static let shared = NetworkErrorManager()
	
	var workingMode: Mode = .autoConnect
	
	// MARK: - Private properties
	
	private let workingQueue: DispatchQueue
	private var subscribers: [NetworkErrorSubscriber]
	
	// Retry interval (interval between recieving exeption and starting retry/new request)
	private let retryTimerInterval: TimeInterval = 2.0
	private var timer: DispatchSourceTimer?
	
	private var alertHasBeenShownAtLeastOnce: Bool
	private var alertIsDisplaying: Bool
    
	private init() {
		workingQueue = DispatchQueue(label: "NetworkErrorManager.WorkingQueue", qos: .utility, attributes: [], target: nil)
		subscribers = [NetworkErrorSubscriber]()

		alertHasBeenShownAtLeastOnce = false
		alertIsDisplaying = false
        
		NetworkConnectionManager.shared.delegate = self       
	}
	
	// MARK: - Public
	
	func add(_ target: NSObject, requestError: RequestError, success: @escaping NetworkErrorSubscriber.ResultBlock, cancel: @escaping NetworkErrorSubscriber.ResultBlock) {
		workingQueue.async {
			for subscriber in self.subscribers where subscriber.target === target {
				return
			}
			
			let subscriber = NetworkErrorSubscriber(target: target, requestError: requestError, success: success, cancel: cancel)
			self.subscribers.append(subscriber)
			
			// Запускаем таймер только если до этого у нас небыло subscribers, в противном случае новый subscriber будет обработан согласно режиму работы:
			// по таймеру, либо по появлению интернета.
			// Таймер запускается для того чтобы собрать subscribers.
			// Т.е мы создаем некоторый карман времени, чтобы все работающие запросы смогли попасть в список subscribers.
			if self.subscribers.count == 1 {
				self.scheduleTimer()
			}
		}
	}
	
	func remove(_ target: NSObject) {
		workingQueue.async {
			for i in 0..<self.subscribers.count where self.subscribers[i] === target {
				self.subscribers.remove(at: i)
				break
			}
			
			if self.subscribers.isEmpty {
				self.timer?.cancel()
				self.timer = nil
				
				self.alertHasBeenShownAtLeastOnce = false
			}
		}
	}
	
	// MARK: - Private
	
	// WARNING: Всегда вызывайте этот метод на workingQueue
	private func processSubscribers(_ success: Bool) {
		for subscriber in self.subscribers {
			if success {
				subscriber.success()
			} else {
				subscriber.cancel()
			}
		}
		
		self.subscribers.removeAll()
		
		self.alertHasBeenShownAtLeastOnce = false
	}
	
	private func scheduleTimer() {
		timer = DispatchSource.makeTimerSource(queue: self.workingQueue)
		timer?.schedule(deadline: .now() + self.retryTimerInterval, leeway: .milliseconds(Int(self.retryTimerInterval) * 100))
		timer?.setEventHandler { [weak self] in
			guard let self = self else { return }
			self.handleTimerTick()
		}
		timer?.resume()
	}
	
	private func errorCode(forSubscribers subscribers: [NetworkErrorSubscriber]) -> Int {
		let errorsImportance = [NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost,
		                        NSURLErrorDNSLookupFailed,
		                        NSURLErrorBadURL, NSURLErrorUnsupportedURL,
		                        NSURLErrorTimedOut,
		                        NSURLErrorUnknown]
		var errorCode = errorsImportance.last!
		
		for subscriber in subscribers {
			let subsriberErrorCode = subscriber.requestError.code
			if subsriberErrorCode != errorCode {
				// If received error code have more left place that prev. then need use more left code, because it more important
				if let index = errorsImportance.index(of: subsriberErrorCode), let errorCodeIndex = errorsImportance.index(of: errorCode), index < errorCodeIndex {
					errorCode = subsriberErrorCode
				}
			}
		}
		
		return errorCode
	}
	
	private func errorText(forErrorCode networkErrorCode: Int) -> String {
		switch networkErrorCode {
		case NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed:
			return NETWORKERRORMANAGER_NETWORKERROR_HOST_IS_NOT_AVAILABLE
		case NSURLErrorBadURL, NSURLErrorUnsupportedURL:
			return NETWORKERRORMANAGER_NETWORKERROR_WRONG_REQUEST
		case NSURLErrorTimedOut:
			return NETWORKERRORMANAGER_NETWORKERROR_TIMEOUT
		case NSURLErrorCannotFindHost, NSURLErrorUnknown:
			return NETWORKERRORMANAGER_NETWORKERROR_CHECK_OR_WAIT
		default:
			return NETWORKERRORMANAGER_NETWORKERROR_CHECK_OR_WAIT
		}
	}
	
	// MARK: - Handlers
	
	private func handleTimerTick() {
		guard subscribers.count != 0 else { return }
		
        self.timer = nil
		
		// Логика показа алертов:
		// - Для режима silent алерты никогда не показываются
		// - Для режима autoСonnect алерт показывается только один раз
		// - Для режима timer алерты показываются всегда, но если на экране уже отображается алерт, то еще один показан не будет
		
		if self.workingMode == .silent {
			if NetworkConnectionManager.shared.isInternetAvailable() {
				self.processSubscribers(true)
			}
			return
		}
		
		if !self.alertHasBeenShownAtLeastOnce || self.workingMode == .timer {
			self.alertIsDisplaying = true
			
			let errorCode = self.errorCode(forSubscribers: self.subscribers)
			let message = self.errorText(forErrorCode: errorCode)
			
			// Для режима autoConnect всегда показываем алерт с 1 кнопкой (OK).
			// Для режима timer c 2 кнопками (Повторить и Отмена)
			
			let buttons = self.workingMode != .timer ? [NETWORKERRORMANAGER_BUTTON_OK] : [NETWORKERRORMANAGER_BUTTON_CANCEL, NETWORKERRORMANAGER_BUTTON_RETRY]
			
			AlertManager.present(message: message,
			                     buttons: buttons,
			                     dismissBlock: { (buttonIndex: Int) in
									self.workingQueue.async {
										defer { self.alertIsDisplaying = false }
										
										// Проверяем текущий статус наличия интернета
										let hasInternetConnection = NetworkConnectionManager.shared.isInternetAvailable()
										
										if self.workingMode == .autoConnect {
											// Обрабатываем subscribers, если интернет появился, иначе ждем сообщения от NetworkConnectionManager
											if hasInternetConnection {
												self.processSubscribers(true)
											}
										} else if self.workingMode == .timer {
											if hasInternetConnection {
												self.processSubscribers(buttonIndex == 1)
											} else {
												// Если нет интернета, то для режима timer запускаем новый цикл таймера
												self.scheduleTimer()
											}
										}
									}
			})
			
			self.alertHasBeenShownAtLeastOnce = true
		}
	}
	
	// MARK: - NetworkConnectionManagerDelegate
	
	func networkConnectionStateDidChanged(_ hasConnection: Bool) {
		guard self.workingMode != .timer else { return }
		
		workingQueue.async {
			// Если интернет появился, но пользователь не среагировал на алерт, то ничего не делаем
			if hasConnection, !self.alertIsDisplaying {
				self.processSubscribers(true)
			}
		}
	}
	
}
