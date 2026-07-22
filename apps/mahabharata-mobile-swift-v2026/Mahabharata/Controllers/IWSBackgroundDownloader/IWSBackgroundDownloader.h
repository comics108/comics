//
//  IWSBackgroundDownloader.h
//  HolyBooks
//
//  Created by RomanMac on 11/01/15.
//  Copyright (c) 2015 Iron Water Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

//All "CompletionHandler" properties and methods does not seem to be used right now. Needs testing.

typedef void (^CompletionHandlerType)();

//typedef void (^CompletionBlock)();
typedef void (^CompletionWithIdentifierBlock)(NSString *);
//typedef void (^ProgressBlock)(int64_t, int64_t);
typedef void (^ProgressWithIdentifierBlock)(int64_t, int64_t, NSString *);

@interface IWSBackgroundDownloader : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>
{
	NSURLSession *_backgroundSession;
	NSMutableDictionary *_completionHandlerDictionary;	//We only have one session, so there is no need in dictionary. This is for future.
	
	NSMutableDictionary *_toPaths;
	NSMutableDictionary *_completionDictionary;
	NSMutableDictionary *_progressDictionary;
}

+ (IWSBackgroundDownloader *)sharedDownloader;
- (void)downloadFile: (NSString *)url toPath: (NSString *)path downloadIdentifier: (NSString *)identifier
		  completion: (CompletionWithIdentifierBlock)completion
			progress: (ProgressWithIdentifierBlock)progress;
- (void)tryToRejoinToSessionWithCompletion: (CompletionWithIdentifierBlock)completion
								  progress: (ProgressWithIdentifierBlock)progress;

- (void)addCompletionHandler: (CompletionHandlerType)handler forSession: (NSString *)identifier;
- (void)callCompletionHandlerForSession: (NSString *)identifier;

@end
