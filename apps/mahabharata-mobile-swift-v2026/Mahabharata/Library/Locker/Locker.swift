//
//  Locker.swift
//  Locker
//
//  Created by Stanislav Grinberg on 16 Apr 2018.
//
//	Notes:
//		Взят с RequestManager
//
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import Foundation

// iOS9 distribution build problem
class Locker {

	enum LockMode {
		case mutex, recursiveMutex, lock, recursiveLock
	}
	
	private var mutexLockObject: pthread_mutex_t = pthread_mutex_t()
	private var lockObject: NSLock?
	private var recursiveLockObject: NSRecursiveLock?
	
	private let mode: LockMode
	
	// MARK: - Life cycle
	
	init(mode: LockMode = .recursiveLock) {
		self.mode = mode
		
		var err: Int32 = -1
		
		switch mode {
		case .mutex:
			err = pthread_mutex_init(&mutexLockObject, nil)
		case .recursiveMutex:
			var attr = pthread_mutexattr_t()
			
			pthread_mutexattr_init(&attr)
			pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
			err = pthread_mutex_init(&mutexLockObject, &attr)
			
			pthread_mutexattr_destroy(&attr)
		case .lock:
			self.lockObject = NSLock()
		case .recursiveLock:
			self.recursiveLockObject = NSRecursiveLock()
		}
		
		if mode == .mutex || mode == .recursiveMutex {
			switch err {
			case 0:	break // Success
			case EAGAIN: fatalError("Could not create mutex: EAGAIN (The system temporarily lacks the resources to create another mutex.)")
			case EINVAL: fatalError("Could not create mutex: invalid attributes")
			case ENOMEM: fatalError("Could not create mutex: no memory")
			default: fatalError("Could not create mutex, unspecified error \(err)")
			}
		}
	}
	
	deinit {
		//assert(pthread_mutex_trylock(&self.lockObject) == 0 && pthread_mutex_unlock(&self.lockObject) == 0, "deinitialization of a locked mutex results in undefined behavior!")
		if mode == .mutex || mode == .recursiveMutex {
			pthread_mutex_destroy(&mutexLockObject)
		} else {
			// NSLock or NSRecursiveLock deinit
		}
	}
	
	// MARK: - Public
	
	@discardableResult
	func lock<T>(block: () -> (T)) -> T {
		lock()
		
		defer { unlock() }
		
		return block()
	}
	
	func lock() {
		switch mode {
		case .mutex, .recursiveMutex: mutexLock()
		case .lock: lockObject!.lock()
		case .recursiveLock: recursiveLockObject!.lock()
		}
	}
	
	func unlock() {
		switch mode {
		case .mutex, .recursiveMutex: mutexUnlock()
		case .lock: lockObject!.unlock()
		case .recursiveLock: recursiveLockObject!.unlock()
		}
	}
	
	// MARK: - Private methods
	
	private func mutexLock() {
		let err = pthread_mutex_lock(&mutexLockObject)
		switch err {
		case 0: break // Success
		case EDEADLK: fatalError("Could not lock mutex: a deadlock would have occurred")
		case EINVAL: fatalError("Could not lock mutex: the mutex is invalid")
		default: fatalError("Could not lock mutex: unspecified error \(err)")
		}
	}
	
	private func mutexUnlock() {
		let err = pthread_mutex_unlock(&mutexLockObject)
		switch err {
		case 0: break // Success
		case EPERM: fatalError("Could not unlock mutex: thread does not hold this mutex")
		case EINVAL: fatalError("Could not unlock mutex: the mutex is invalid")
		default: fatalError("Could not unlock mutex: unspecified error \(err)")
		}
	}
	
}
