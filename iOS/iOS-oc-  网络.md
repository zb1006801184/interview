# iOS 面试题 - 网络

## 1. iOS 中的网络请求方式有哪些？

### 1.1 主要方式

1. **NSURLConnection**：已废弃（iOS 9+）
2. **NSURLSession**：推荐使用（iOS 7+）
3. **AFNetworking**：第三方库
4. **Alamofire**：Swift 第三方库
5. **原生 Socket**：底层网络通信

### 1.2 对比

| 特性 | NSURLConnection | NSURLSession | AFNetworking |
|------|----------------|--------------|--------------|
| 系统版本 | iOS 2+ | iOS 7+ | iOS 7+ |
| 状态 | 已废弃 | 推荐 | 第三方 |
| 功能 | 基础 | 丰富 | 非常丰富 |
| 易用性 | 一般 | 较好 | 很好 |

## 2. 什么是 NSURLSession？

NSURLSession 是苹果提供的网络请求 API，用于替代 NSURLConnection。

### 2.1 基本用法

```objc
// 创建请求
NSURL *url = [NSURL URLWithString:@"https://api.example.com/data"];
NSURLRequest *request = [NSURLRequest requestWithURL:url];

// 创建 Session
NSURLSession *session = [NSURLSession sharedSession];

// 创建任务
NSURLSessionDataTask *task = [session dataTaskWithRequest:request 
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
        NSLog(@"错误：%@", error);
    } else {
        // 处理数据
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSLog(@"数据：%@", json);
    }
}];

// 启动任务
[task resume];
```

## 3. NSURLSession 的配置？

### 3.1 Session 配置类型

- **defaultSessionConfiguration**：默认配置，使用磁盘缓存
- **ephemeralSessionConfiguration**：临时配置，不使用磁盘缓存
- **backgroundSessionConfiguration**：后台配置，支持后台下载

### 3.2 代码示例

```objc
// 默认配置
NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
config.timeoutIntervalForRequest = 30.0;
config.timeoutIntervalForResource = 60.0;
config.HTTPMaximumConnectionsPerHost = 5;
NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

// 临时配置
NSURLSessionConfiguration *ephemeralConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
NSURLSession *ephemeralSession = [NSURLSession sessionWithConfiguration:ephemeralConfig];

// 后台配置
NSURLSessionConfiguration *backgroundConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.example.background"];
NSURLSession *backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfig delegate:self delegateQueue:nil];
```

## 4. NSURLSession 的任务类型？

### 4.1 任务类型

- **NSURLSessionDataTask**：数据任务，用于 GET、POST 等请求
- **NSURLSessionDownloadTask**：下载任务，用于下载文件
- **NSURLSessionUploadTask**：上传任务，用于上传文件

### 4.2 代码示例

```objc
// 数据任务
NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url 
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    // 处理数据
}];

// 下载任务
NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url 
                                                     completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
    // 处理下载的文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *destinationURL = [documentsURL URLByAppendingPathComponent:@"file.pdf"];
    [fileManager moveItemAtURL:location toURL:destinationURL error:nil];
}];

// 上传任务
NSURL *fileURL = [NSURL fileURLWithPath:@"/path/to/file"];
NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request 
                                                            fromFile:fileURL 
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    // 处理上传结果
}];
```

## 5. 如何发送 POST 请求？

### 5.1 基本用法

```objc
NSURL *url = [NSURL URLWithString:@"https://api.example.com/post"];
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
request.HTTPMethod = @"POST";
request.HTTPBody = [@"key=value" dataUsingEncoding:NSUTF8StringEncoding];
[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request 
                                                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    // 处理响应
}];
[task resume];
```

### 5.2 JSON 请求

```objc
NSURL *url = [NSURL URLWithString:@"https://api.example.com/post"];
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
request.HTTPMethod = @"POST";
request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"key": @"value"} options:0 error:nil];
[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request 
                                                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    // 处理响应
}];
[task resume];
```

## 6. 如何处理 JSON 数据？

### 6.1 解析 JSON

```objc
NSURLSessionDataTask *task = [session dataTaskWithURL:url 
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (data) {
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data 
                                                              options:NSJSONReadingMutableContainers 
                                                                error:&jsonError];
        if (!jsonError) {
            NSLog(@"JSON：%@", json);
        }
    }
}];
```

### 6.2 生成 JSON

```objc
NSDictionary *dict = @{@"name": @"John", @"age": @25};
NSError *error = nil;
NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict 
                                                   options:NSJSONWritingPrettyPrinted 
                                                     error:&error];
if (!error) {
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"JSON 字符串：%@", jsonString);
}
```

## 7. 什么是 HTTP 和 HTTPS？

### 7.1 HTTP

HTTP（HyperText Transfer Protocol）是超文本传输协议，是应用层协议。

**特点**：
- 明文传输
- 无状态
- 无连接

### 7.2 HTTPS

HTTPS（HTTP Secure）是安全的 HTTP，在 HTTP 基础上加入 SSL/TLS 加密。

**特点**：
- 加密传输
- 身份验证
- 数据完整性

### 7.3 区别

| 特性 | HTTP | HTTPS |
|------|------|-------|
| 端口 | 80 | 443 |
| 加密 | 否 | 是 |
| 证书 | 不需要 | 需要 |
| 安全性 | 低 | 高 |

## 8. 如何处理 HTTPS 证书验证？

### 8.1 默认验证

```objc
// NSURLSession 默认会验证证书
NSURLSession *session = [NSURLSession sharedSession];
// 如果证书无效，请求会失败
```

### 8.2 自定义验证

```objc
- (void)URLSession:(NSURLSession *)session 
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge 
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        // 验证服务器证书
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        // 自定义验证逻辑
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}
```

### 8.3 忽略证书验证（不推荐）

```objc
- (void)URLSession:(NSURLSession *)session 
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge 
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}
```

## 9. 如何处理网络超时？

### 9.1 配置超时

```objc
NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
config.timeoutIntervalForRequest = 30.0;  // 请求超时 30 秒
config.timeoutIntervalForResource = 60.0; // 资源超时 60 秒
NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
```

### 9.2 处理超时错误

```objc
NSURLSessionDataTask *task = [session dataTaskWithRequest:request 
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
        if (error.code == NSURLErrorTimedOut) {
            NSLog(@"请求超时");
        } else {
            NSLog(@"其他错误：%@", error);
        }
    }
}];
```

## 10. 如何处理网络错误？

### 10.1 常见错误类型

- `NSURLErrorTimedOut`：超时
- `NSURLErrorNotConnectedToInternet`：无网络连接
- `NSURLErrorCannotFindHost`：找不到主机
- `NSURLErrorCannotConnectToHost`：无法连接到主机
- `NSURLErrorNetworkConnectionLost`：网络连接丢失

### 10.2 错误处理

```objc
NSURLSessionDataTask *task = [session dataTaskWithRequest:request 
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
        switch (error.code) {
            case NSURLErrorTimedOut:
                NSLog(@"请求超时");
                break;
            case NSURLErrorNotConnectedToInternet:
                NSLog(@"无网络连接");
                break;
            case NSURLErrorCannotFindHost:
                NSLog(@"找不到主机");
                break;
            default:
                NSLog(@"其他错误：%@", error);
                break;
        }
    } else {
        // 处理成功响应
    }
}];
```

## 11. 如何实现文件下载？

### 11.1 简单下载

```objc
NSURL *url = [NSURL URLWithString:@"https://example.com/file.pdf"];
NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:url 
                                                                           completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
    if (error) {
        NSLog(@"下载失败：%@", error);
    } else {
        // 保存文件
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        NSURL *destinationURL = [documentsURL URLByAppendingPathComponent:response.suggestedFilename];
        [fileManager moveItemAtURL:location toURL:destinationURL error:nil];
    }
}];
[downloadTask resume];
```

### 11.2 带进度的下载

```objc
// 实现 NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session 
      downloadTask:(NSURLSessionDownloadTask *)downloadTask 
      didWriteData:(int64_t)bytesWritten 
 totalBytesWritten:(int64_t)totalBytesWritten 
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
    NSLog(@"下载进度：%.2f%%", progress * 100);
}

- (void)URLSession:(NSURLSession *)session 
      downloadTask:(NSURLSessionDownloadTask *)downloadTask 
didFinishDownloadingToURL:(NSURL *)location {
    // 保存文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *destinationURL = [documentsURL URLByAppendingPathComponent:downloadTask.response.suggestedFilename];
    [fileManager moveItemAtURL:location toURL:destinationURL error:nil];
}
```

## 12. 如何实现文件上传？

### 12.1 简单上传

```objc
NSURL *url = [NSURL URLWithString:@"https://api.example.com/upload"];
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
request.HTTPMethod = @"POST";

NSURL *fileURL = [NSURL fileURLWithPath:@"/path/to/file"];
NSURLSessionUploadTask *uploadTask = [[NSURLSession sharedSession] uploadTaskWithRequest:request 
                                                                                 fromFile:fileURL 
                                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
        NSLog(@"上传失败：%@", error);
    } else {
        NSLog(@"上传成功");
    }
}];
[uploadTask resume];
```

### 12.2 带进度的上传

```objc
// 实现 NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session 
              task:(NSURLSessionTask *)task 
   didSendBodyData:(int64_t)bytesSent 
    totalBytesSent:(int64_t)totalBytesSent 
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    float progress = (float)totalBytesSent / totalBytesExpectedToSend;
    NSLog(@"上传进度：%.2f%%", progress * 100);
}
```

## 13. 如何实现后台下载？

### 13.1 配置后台 Session

```objc
NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.example.background"];
NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

NSURL *url = [NSURL URLWithString:@"https://example.com/largefile.zip"];
NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
[task resume];
```

### 13.2 处理后台任务

```objc
// AppDelegate.m
- (void)application:(UIApplication *)application 
handleEventsForBackgroundURLSession:(NSString *)identifier 
  completionHandler:(void (^)(void))completionHandler {
    // 保存 completionHandler
    self.backgroundSessionCompletionHandler = completionHandler;
}

// 下载完成
- (void)URLSession:(NSURLSession *)session 
      downloadTask:(NSURLSessionDownloadTask *)downloadTask 
didFinishDownloadingToURL:(NSURL *)location {
    // 处理下载的文件
    // 调用 completionHandler
    if (self.backgroundSessionCompletionHandler) {
        self.backgroundSessionCompletionHandler();
        self.backgroundSessionCompletionHandler = nil;
    }
}
```

## 14. 如何实现网络请求缓存？

### 14.1 使用默认缓存

```objc
NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
config.URLCache = [NSURLCache sharedURLCache];
config.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
```

### 14.2 自定义缓存策略

```objc
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
request.cachePolicy = NSURLRequestReturnCacheDataElseLoad; // 优先使用缓存
NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    // 处理响应
}];
```

### 14.3 缓存策略类型

- `NSURLRequestUseProtocolCachePolicy`：使用协议缓存策略
- `NSURLRequestReloadIgnoringLocalCacheData`：忽略本地缓存
- `NSURLRequestReturnCacheDataElseLoad`：优先使用缓存
- `NSURLRequestReturnCacheDataDontLoad`：只使用缓存

## 15. 如何实现网络请求的取消和暂停？

### 15.1 取消任务

```objc
NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    // 处理响应
}];
[task resume];

// 取消任务
[task cancel];
```

### 15.2 暂停和恢复下载

```objc
NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
    // 处理下载
}];
[downloadTask resume];

// 暂停下载（保存恢复数据）
[downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
    // 保存 resumeData
    self.resumeData = resumeData;
}];

// 恢复下载
if (self.resumeData) {
    NSURLSessionDownloadTask *resumeTask = [session downloadTaskWithResumeData:self.resumeData];
    [resumeTask resume];
}
```

## 16. 如何实现网络请求的拦截和修改？

### 16.1 使用 NSURLProtocol

```objc
@interface CustomURLProtocol : NSURLProtocol
@end

@implementation CustomURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 判断是否需要拦截
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    // 规范化请求
    return request;
}

- (void)startLoading {
    // 修改请求
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    [mutableRequest setValue:@"CustomValue" forHTTPHeaderField:@"CustomHeader"];
    
    // 发送请求
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:mutableRequest 
                                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.client URLProtocol:self didFailWithError:error];
        } else {
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
            [self.client URLProtocol:self didLoadData:data];
            [self.client URLProtocolDidFinishLoading:self];
        }
    }];
    [task resume];
}

- (void)stopLoading {
    // 停止加载
}
@end

// 注册 Protocol
[NSURLProtocol registerClass:[CustomURLProtocol class]];
```

## 17. 如何检测网络状态？

### 17.1 使用 Reachability

```objc
#import <SystemConfiguration/SystemConfiguration.h>

- (BOOL)isNetworkAvailable {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "www.apple.com");
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    
    if (!success) {
        return NO;
    }
    
    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL needsConnection = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
    BOOL canConnectAutomatically = ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
                                   ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0);
    BOOL canConnectWithoutUserInteraction = canConnectAutomatically &&
                                           ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    
    return isReachable && (!needsConnection || canConnectWithoutUserInteraction);
}
```

### 17.2 监听网络状态变化

```objc
SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "www.apple.com");
SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
SCNetworkReachabilitySetCallback(reachability, ReachabilityCallback, &context);
SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    // 网络状态变化
}
```

## 18. 如何优化网络请求性能？

### 18.1 请求优化

- 使用连接池复用连接
- 压缩请求和响应数据
- 使用 CDN 加速
- 合理设置超时时间

### 18.2 缓存优化

- 使用 HTTP 缓存
- 实现本地缓存
- 设置合理的缓存策略

### 18.3 并发优化

- 控制并发数量
- 使用优先级队列
- 避免重复请求

## 19. 什么是 AFNetworking？

AFNetworking 是 iOS 开发中最流行的网络请求库。

### 19.1 基本用法

```objc
#import <AFNetworking/AFNetworking.h>

AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
[manager GET:@"https://api.example.com/data" 
  parameters:nil 
     success:^(NSURLSessionDataTask *task, id responseObject) {
    NSLog(@"成功：%@", responseObject);
} 
     failure:^(NSURLSessionDataTask *task, NSError *error) {
    NSLog(@"失败：%@", error);
}];
```

### 19.2 POST 请求

```objc
[manager POST:@"https://api.example.com/post" 
   parameters:@{@"key": @"value"} 
      success:^(NSURLSessionDataTask *task, id responseObject) {
    NSLog(@"成功：%@", responseObject);
} 
      failure:^(NSURLSessionDataTask *task, NSError *error) {
    NSLog(@"失败：%@", error);
}];
```

## 20. 网络的常见面试题总结

1. **iOS 中的网络请求方式？** - NSURLConnection、NSURLSession、AFNetworking
2. **什么是 NSURLSession？** - 苹果提供的网络请求 API
3. **NSURLSession 的配置类型？** - default、ephemeral、background
4. **NSURLSession 的任务类型？** - DataTask、DownloadTask、UploadTask
5. **如何发送 POST 请求？** - 设置 HTTPMethod 和 HTTPBody
6. **如何处理 JSON 数据？** - NSJSONSerialization
7. **HTTP 和 HTTPS 的区别？** - 加密、证书、安全性
8. **如何处理 HTTPS 证书验证？** - didReceiveChallenge
9. **如何处理网络超时？** - timeoutIntervalForRequest
10. **如何实现文件下载？** - NSURLSessionDownloadTask
11. **如何实现文件上传？** - NSURLSessionUploadTask
12. **如何实现后台下载？** - backgroundSessionConfiguration
13. **如何实现网络请求缓存？** - URLCache、cachePolicy
14. **如何检测网络状态？** - SCNetworkReachability
15. **如何优化网络请求性能？** - 连接复用、缓存、并发控制

## 21. 网络的最佳实践

### 21.1 错误处理

- 处理所有可能的错误
- 提供友好的错误提示
- 实现重试机制

### 21.2 安全性

- 使用 HTTPS
- 验证证书
- 加密敏感数据

### 21.3 性能优化

- 使用缓存
- 压缩数据
- 控制并发

### 21.4 用户体验

- 显示加载状态
- 提供取消功能
- 处理网络异常

