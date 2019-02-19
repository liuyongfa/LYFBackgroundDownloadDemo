//
//  LYFBackgroundDownload.h
//  LYFBackgroundDownloadDemo
//
//  Created by yongfaliu on 2019/2/18.
//  Copyright © 2019 yongfaliu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CompletionHandlerType)(void);
@class LYFBackgroundDownload;

@protocol LYFBackgroundDownloadDelegate <NSObject>
@optional
- (void)LYFBackgroundDownloadProgress:(CGFloat)progress;
- (void)LYFBackgroundDownloadDidFinishDownloadingToURL:(NSURL *)location;
@end

@interface LYFBackgroundDownload : NSObject
+ (id)sharedManager;

- (void)registerDownloadTaskWithIdentifier:(NSString *)identifier;
- (void)setDelegate:(id <LYFBackgroundDownloadDelegate>)delegate;

- (void)beginDownloadWithUrl: (NSString *)downloadURLString;
- (void)pauseDownload;
- (void)continueDownload;

- (NSString *)downloadTaskIdentifier;
- (void)setCompletionHandler:(CompletionHandlerType )completionHandler;
- (BOOL)isDownloadLocalNotification:(UILocalNotification *)localNotification;
@end


NS_ASSUME_NONNULL_END
