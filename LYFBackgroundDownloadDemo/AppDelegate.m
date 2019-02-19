//
//  AppDelegate.m
//  LYFBackgroundDownloadDemo
//
//  Created by yongfaliu on 2019/2/18.
//  Copyright © 2019 yongfaliu. All rights reserved.
//

#import "AppDelegate.h"
#import "LYFBackgroundDownload.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[LYFBackgroundDownload sharedManager] registerDownloadTaskWithIdentifier:[NSString stringWithFormat:@"%@.%@", [NSBundle mainBundle].bundleIdentifier, @"LYFBackgroundDownload"]];
    return YES;
}

//如果不实现该协议,后台一样可以下载，但是不会调用NSURLSessionDownloadDelegate协议，要等到重新回到前台，那些协议才会一股脑被调用。
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    
    if ([identifier isEqualToString:[[LYFBackgroundDownload sharedManager] downloadTaskIdentifier]]) {
        [[LYFBackgroundDownload sharedManager] setCompletionHandler:completionHandler];
    }
    //在这里调用completionHandler，会使之后的NSURLSessionDownloadDelegate协议只走到didFinishDownloadingToURL，之后的didCompleteWithError,URLSessionDidFinishEventsForBackgroundURLSession不被调用。
    //    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    if ([[LYFBackgroundDownload sharedManager] isDownloadLocalNotification: notification]) {//在后台点击了弹出的横条通知，或者在前台收到了下载完成通知
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"下载通知" message:notification.alertBody preferredStyle:UIAlertControllerStyleAlert];
        alert.title = @"下载通知";
        alert.message = notification.alertBody;
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:action];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}
@end
