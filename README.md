# LYFBackgroundDownloadDemo
NSURLSession 后台断点下载

•只支持同时一个下载任务

•注释部分可能有理解的不对的地方

•GitHub地址：https://github.com/liuyongfa/LYFBackgroundDownloadDemo.git


NSURLSession可以执行长时间的后台下载任务。进入后台后，下载任务可以一直执行。被杀死后，再次进入App会根据NSURLSessionConfiguration的identifier继续下载。下载成功后，可以调用LocalNotification做通知。
