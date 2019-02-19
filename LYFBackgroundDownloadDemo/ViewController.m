//
//  ViewController.m
//  LYFBackgroundDownloadDemo
//
//  Created by yongfaliu on 2019/2/18.
//  Copyright © 2019 yongfaliu. All rights reserved.
//

#import "ViewController.h"
#import "LYFBackgroundDownload.h"

@interface ViewController () <LYFBackgroundDownloadDelegate>
@property (strong, nonatomic) IBOutlet UIProgressView *downloadProgress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[LYFBackgroundDownload sharedManager] setDelegate: self];
}

- (void)updateDownloadProgress:(CGFloat)progress {
    self.progressLabel.text = [NSString stringWithFormat:@"%.2f%%",progress * 100];
    self.downloadProgress.progress = progress;
}

#pragma mark Method
- (IBAction)download:(id)sender {
//    [[LYFBackgroundDownload sharedManager] beginDownloadWithUrl:@"https://www.baidu.com/img/bdlogo.png"];
    [[LYFBackgroundDownload sharedManager] beginDownloadWithUrl:@"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4"];
}

- (IBAction)pauseDownlaod:(id)sender {
    [[LYFBackgroundDownload sharedManager] pauseDownload];
}

- (IBAction)continueDownlaod:(id)sender {
    [[LYFBackgroundDownload sharedManager] continueDownload];
}

#pragma mark LYFBackgroundDownloadDelegate
- (void)LYFBackgroundDownloadProgress:(CGFloat)progress {
    [self updateDownloadProgress:progress];
}
- (void)LYFBackgroundDownloadDidFinishDownloadingToURL:(NSURL *)location {
    self.imageView.image = [UIImage imageWithContentsOfFile:[location path]];
}
@end
