//
//  IWSBackgroundDownloader.m
//  HolyBooks
//
//  Created by RomanMac on 11/01/15.
//  Copyright (c) 2015 Iron Water Studio. All rights reserved.
//

#import "IWSBackgroundDownloader.h"

#define kBackgroundSessionIdentifier @"DownloadBackgroundSessionIdentifier"

@implementation IWSBackgroundDownloader

+ (IWSBackgroundDownloader *)sharedDownloader
{
	static IWSBackgroundDownloader *downloader;
	if (downloader == nil)
		downloader = [[IWSBackgroundDownloader alloc] init];
	
	return downloader;
}

- (id)init
{
	if ((self = [super init]))
	{
		_completionHandlerDictionary = [[NSMutableDictionary alloc] init];

		_toPaths = [[NSMutableDictionary alloc] init];
		_completionDictionary = [[NSMutableDictionary alloc] init];
		_progressDictionary = [[NSMutableDictionary alloc] init];
		
		NSURLSessionConfiguration *backgroundConfiguration = nil;
		backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];
		_backgroundSession = [[NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]] retain];
	}
	
	return self;
}

- (void)dealloc
{
	[_completionHandlerDictionary release];
	[_backgroundSession release];
	
	[_toPaths release];
	[_completionDictionary release];
	[_progressDictionary release];
	
	[super dealloc];
}

#pragma mark - Functionality
- (void)downloadFile: (NSString *)url toPath: (NSString *)path downloadIdentifier: (NSString *)identifier
		  completion: (CompletionWithIdentifierBlock)completion
			progress: (ProgressWithIdentifierBlock)progress
{
	//Debug validation
	if ([_toPaths objectForKey:identifier])
		NSLog(@"Error: Got multiple to paths for a single download task. This should not happen");
	if ([_completionDictionary objectForKey:identifier])
		NSLog(@"Error: Got multiple handlers for a single download completion identifier. This should not happen");
	if ([_progressDictionary objectForKey:identifier])
		NSLog(@"Error: Got multiple handlers for a single download progress identifier. This should not happen");
	
	//Save info
	[_toPaths setObject:path forKey:identifier];
	[_completionDictionary setObject:[completion copy] forKey:identifier];
	[_progressDictionary setObject:[progress copy] forKey:identifier];
	
	//Run task
	NSURLSessionDownloadTask *downloadTask = [_backgroundSession downloadTaskWithURL:[NSURL URLWithString:url]];
	downloadTask.taskDescription = identifier;
	[downloadTask resume];
	NSLog(@"Download task resumed: @%", url);
}

- (void)tryToRejoinToSessionWithCompletion: (CompletionWithIdentifierBlock)completion
								  progress: (ProgressWithIdentifierBlock)progress
{
	//Rejoin to tasks
	[_backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		for (NSURLSessionDownloadTask *downloadTask in downloadTasks)
		{
			if (![_completionDictionary objectForKey:downloadTask.taskDescription])
				[_completionDictionary setObject:[completion copy] forKey:downloadTask.taskDescription];
			if (![_progressDictionary objectForKey:downloadTask.taskDescription])
				[_progressDictionary setObject:[progress copy] forKey:downloadTask.taskDescription];
		}
		
		if ([downloadTasks count] == 0)
			completion(nil);
	}];
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
	NSLog(@"Session %@ download task %@ finished downloading to url %@", session, downloadTask, location);
	
	//There was some hack here
	[self callCompletionHandlerForSession:session.configuration.identifier];
	
	if (location == nil)
	{
		NSLog(@"Error: NIL url finished loading");
		return;
	}
	
	//Move file where needed as the temporary download will be removed automatically on this method return
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *toPath = _toPaths[downloadTask.taskDescription];
	if (toPath == nil)
		NSLog(@"*** - downloadTask didFinishDownloadingToURL: location:%@, toPath: nil", location);

	NSURL *toURL = [NSURL fileURLWithPath:toPath];
	
	//Remove if older one exists
	if ([fileManager fileExistsAtPath:toPath isDirectory:nil])
	{
		if (![fileManager removeItemAtPath:toPath error:&error])
		{
			NSLog(@"Error removing file at path %@. Error: %@", toPath, error.localizedDescription);
			return;
		}
	}
	
	if ([fileManager fileExistsAtPath:location.path isDirectory:nil]) {
//		NSLog(@"downloaded file exists");
	}
	else
	{
		//TODO: remove
		NSLog(@"Temporary downloaded file disappeared");
	}
	//Move
	if ([fileManager moveItemAtURL:location toURL:toURL error:&error])
	{
		//Call completion block and cleanup
		CompletionWithIdentifierBlock completion = _completionDictionary[downloadTask.taskDescription];
		if (completion)
		{
			[_completionDictionary removeObjectForKey:downloadTask.taskDescription];
			
			completion(downloadTask.taskDescription);
		}
		
		[_toPaths removeObjectForKey:downloadTask.taskDescription];
		[_progressDictionary removeObjectForKey:downloadTask.taskDescription];
	}
	else
	{
		NSLog(@"Error occured during file moving from URL %@ to URL %@. Error: %@", location, toURL, error.localizedDescription);
	}
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	NSLog(@"Session %@ download task %@ wrote an additional %lld bytes (total %lld bytes) out of an expected %lld bytes", session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
	
	//Call progress block
	ProgressWithIdentifierBlock progress = _progressDictionary[downloadTask.taskDescription];
	if (progress)
		progress(totalBytesWritten, totalBytesExpectedToWrite, downloadTask.taskDescription);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
	NSLog(@"Session %@ download task %@ resumed at offset %lld bytes out of an expected %lld bytes", session, downloadTask, fileOffset, expectedTotalBytes);
	//TODO: handle it somehow
}

#pragma mark - Background activity
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
	NSLog(@"Background URL session %@ finished events", session);
	
	if (session.configuration.identifier)
		[self callCompletionHandlerForSession:session.configuration.identifier];
}

- (void)addCompletionHandler: (CompletionHandlerType)handler forSession: (NSString *)identifier
{
	if ([_completionHandlerDictionary objectForKey:identifier])
		NSLog(@"Error: Got multiple handlers for a single session identifier. This should not happen");
	
	[_completionHandlerDictionary setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession: (NSString *)identifier
{
	CompletionHandlerType handler = [_completionHandlerDictionary objectForKey:identifier];
	if (handler)
	{
		[_completionHandlerDictionary removeObjectForKey:identifier];
		NSLog(@"Calling completion handler");
		
		handler();
	}
}

@end
