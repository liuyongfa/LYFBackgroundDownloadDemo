//
//  LYFBackgroundDownload.m
//  LYFBackgroundDownloadDemo
//
//  Created by yongfaliu on 2019/2/18.
//  Copyright © 2019 yongfaliu. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "LYFBackgroundDownload.h"
#import "AppDelegate.h"

@interface LYFBackgroundDownload() <NSURLSessionDownloadDelegate>
@property (strong, nonatomic) UILocalNotification *localNotification;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSURLSession *backgroundSession;
@property (strong, nonatomic) NSString *downloadTaskIdentifier;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic) CompletionHandlerType completionHandler;
@property (weak, nonatomic) id <LYFBackgroundDownloadDelegate> delegate;

@end
@implementation LYFBackgroundDownload
- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [self initLYFBackgroundDownload];
    }
    return self;
}

+ (id)sharedManager {
    static LYFBackgroundDownload *staticInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        staticInstance = [[self alloc] init];
    });
    return staticInstance;
}

- (void)registerDownloadTaskWithIdentifier: (NSString *)identifier {
    _downloadTaskIdentifier = identifier;
    _backgroundSession = [self backgroundURLSession];
    _localNotification.userInfo = @{_downloadTaskIdentifier: _downloadTaskIdentifier};
}

- (void)setDelegate:(id<LYFBackgroundDownloadDelegate>)delegate {
    _delegate = delegate;
}

- (void)setCompletionHandler: (CompletionHandlerType )completionHandler {
    _completionHandler = completionHandler;
}

- (NSString *)downloadTaskIdentifier {
    return _downloadTaskIdentifier;
}

- (BOOL)isDownloadLocalNotification: (UILocalNotification *)localNotification {
    return [_localNotification.userInfo[_downloadTaskIdentifier] isEqualToString:localNotification.userInfo[_downloadTaskIdentifier]];
}

- (void)initLYFBackgroundDownload  {
    [self registerUserNotification];
    [self initLocalNotification];
}

- (NSURLSession *)backgroundSession {
    if (_backgroundSession) {
        return _backgroundSession;
    }
    return [self backgroundURLSession];
}

- (NSURLSession *)backgroundURLSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration* sessionConfig = nil;
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.downloadTaskIdentifier];
        self.operationQueue = [[NSOperationQueue alloc] init];
        //队列可同时执行的任务数为1,即串行
        self.operationQueue.maxConcurrentOperationCount = 1;
        //允许蜂窝网络下载
        sessionConfig.allowsCellularAccess = YES;
        
        __weak __typeof(self) weakSelf = self;
        //iOS9之前很多框架的delegate都是强引用：@property (nullable, readonly, retain) id <NSURLSessionDelegate> delegate
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:weakSelf
                                           delegateQueue:self.operationQueue];
        
    });
    
    return session;
}

#pragma mark - LYFBackgroundDownload
- (void)beginDownloadWithUrl:(NSString *)downloadURLString {
    __weak __typeof(self) weakSelf = self;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    //如果backgroundSession已经有downloadTask，就继续，如果没有，就添加。保证backgroundSession最多只有一个downloadTask
    [self.backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        //        for (NSURLSessionDataTask *task in dataTasks) {
        //        }
        //
        //        for (NSURLSessionUploadTask *uploadTask in uploadTasks) {
        //        }
        NSAssert(downloadTasks.count <= 1, @"后台下载任务超过1个");
        if (downloadTasks.count == 0) {
            NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
            NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
            weakSelf.downloadTask = [self.backgroundSession downloadTaskWithRequest:request];
        } else {
            weakSelf.downloadTask= downloadTasks[0];
        }
        dispatch_semaphore_signal(semaphore);
        
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self.downloadTask resume];
}
- (void)pauseDownload {
    [self.downloadTask suspend];
}
- (void)continueDownload {
    [self.downloadTask resume];
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@", (unsigned long)downloadTask.taskIdentifier, location);
    
    // 用 NSFileManager 将文件复制到应用的存储中
    NSString *locationString = [location path];
    NSString *finalLocation = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lufile",(unsigned long)downloadTask.taskIdentifier]];
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:finalLocation error:&error];
    
    NSLog(@"finalLocation = %@", finalLocation);
    __weak __typeof(self) weakSlef = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSlef.delegate respondsToSelector:@selector(LYFBackgroundDownloadDidFinishDownloadingToURL:)]) {
            [weakSlef.delegate LYFBackgroundDownloadDidFinishDownloadingToURL:[NSURL fileURLWithPath:finalLocation]];
        }
    });
}

//downloadTaskWithResumeData会触发调用该方法
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    NSLog(@"fileOffset:%lld expectedTotalBytes:%lld",fileOffset,expectedTotalBytes);
}

//进入后台后将不再触发
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
     CGFloat progress = (CGFloat)totalBytesWritten / totalBytesExpectedToWrite;
    NSLog(@"downloadTask:%lu percent:%.2f%%",(unsigned long)downloadTask.taskIdentifier,progress * 100);
    __weak __typeof(self) weakSlef = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSlef.delegate respondsToSelector:@selector(LYFBackgroundDownloadProgress:)]) {
            [weakSlef.delegate LYFBackgroundDownloadProgress:progress];
        }
    });
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"Background URL session %@ finished events.\n", session);
    NSString *identifier = session.configuration.identifier;
    if ([identifier isEqualToString:_downloadTaskIdentifier]) {
        // 调用在 -application:handleEventsForBackgroundURLSession: 中保存的 handler
        if (_completionHandler) {
            NSLog(@"Calling completion handler for session %@", identifier);
            _completionHandler();
        }
    }
}

/*
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
//下载完成
//•函数里可以做：
//1.发出下载完成的本地通知，如果在后台就可以发本地通知，在前台不可以显示本地通知，可以由didReceiveLocalNotification里面来处理本地通知
//2.因为在后台是不会更新下载进度的，所有这个函数里要处理把进度改为100%

//•断点下载处理：
//如果app退出（发现Xcode重新编译不算app退出），下次进入app会触发该方法，error不为空，可以进行断点下载工作
//这里app退出，重新进入调用该函数也说明了NSURLSession的多任务是由系统管理，所以NSURLSessionConfiguration的identifier要包含bundle id，以防止和其他app混淆。
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    NSLog(@"didCompleteWithError");
    if ([session.configuration.identifier isEqualToString:_downloadTaskIdentifier]) {
        if (error) {
            if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
                NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
                NSLog(@"self.resumeData.length = %ld, %@", resumeData.length, session.configuration.identifier);
                //            self.downloadTask = [self.backgroundSession downloadTaskWithCorrectResumeData:self.resumeData];
                self.downloadTask = [self.backgroundSession downloadTaskWithResumeData: resumeData];
                [self.downloadTask resume];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sendLocalNotification];
                //更新进度条
                if ([self.delegate respondsToSelector:@selector(LYFBackgroundDownloadProgress:)]) {
                    [self.delegate LYFBackgroundDownloadProgress:1];
                }
            });
        }
    }
}

#pragma mark - Local Notification
- (void)registerUserNotification {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

- (void)initLocalNotification {
    self.localNotification = [[UILocalNotification alloc] init];
    self.localNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:5];
    self.localNotification.alertAction = nil;
    self.localNotification.soundName = UILocalNotificationDefaultSoundName;
    self.localNotification.alertBody = @"下载完成了！";
    //    self.localNotification.applicationIconBadgeNumber = 1;
    //    self.localNotification.repeatInterval = 0;
}

- (void)sendLocalNotification {
    [[UIApplication sharedApplication] scheduleLocalNotification:self.localNotification];
}
@end
