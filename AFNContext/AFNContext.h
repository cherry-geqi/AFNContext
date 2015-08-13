//
//  AFNContext.h
//  AFNContext
//
//  Created by 张贤德 on 15/7/29.
//  Copyright (c) 2015年 onemo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFHTTPRequestOperationManager.h>

@interface AFNContext : NSObject

+ (AFNContext * (^)(AFHTTPRequestOperationManager *manager))context;

- (AFNContext * (^)(NSString *method))method;

- (AFNContext * (^)(NSString *prefix))prefix;
- (AFNContext * (^)(NSString *path, ...))path;

- (AFNContext * (^)(NSString *key, id value))addParameter;
- (AFNContext * (^)(NSDictionary *parameters))addParameters;

- (AFNContext * (^)(void (^)(id<AFMultipartFormData> formData)))addMultipartFormData;

- (AFNContext * (^)(void(^)(CGFloat progress)))uploadProgress;
- (AFNContext * (^)(void(^)(CGFloat progress)))downloadProgress;

- (AFNContext * (^)(void (^responseCallback)(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error))))addResponseCallback;

- (void (^)())done;

@end

@interface AFNContext (AFNContextMultipartExtension)

- (AFNContext * (^)(NSData *data, NSString *name, NSString *fileName, NSString *mimeType))addMultipartFileData;
- (AFNContext * (^)(NSURL *fileURL, NSString *name, NSError * __autoreleasing * error))addMultipartFileURL;
- (AFNContext * (^)(NSURL *fileURL, NSString *name, NSString *fileName, NSString *mimeType, NSError * __autoreleasing * error))addMultipartFileURL2;
- (AFNContext * (^)(NSInputStream *inputStream, NSString *name, NSString *fileName, int64_t length, NSString *mimeType))addMultipartInputStream;

@end

@interface AFNContext (AFNContextResponseExtension)

- (AFNContext * (^)(void(^)(id responseObject)))success;
- (AFNContext * (^)(void(^)(NSError *error)))failure;
- (AFNContext * (^)(void(^)(id responseObject, NSError *error)))response;

@end
