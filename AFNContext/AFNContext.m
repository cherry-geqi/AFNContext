//
//  AFNContext.m
//  AFNContext
//
//  Created by 张贤德 on 15/7/29.
//  Copyright (c) 2015年 onemo. All rights reserved.
//

#import "AFNContext.h"

@interface AFNContext ()

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

@property (nonatomic, copy) NSString *requestMethod;
@property (nonatomic, copy) NSString *requestPathPrefix;
@property (nonatomic, copy) NSString *requestPath;
@property (nonatomic, strong) NSMutableDictionary *parameters;

@property (nonatomic, copy) void (^multipartFormDataBlock)(id<AFMultipartFormData> formData);
@property (nonatomic, copy) void (^uploadProgressBlock)(CGFloat progress);
@property (nonatomic, copy) void (^downloadProgressBlock)(CGFloat progress);

@property (nonatomic, copy) void (^responseCallback)(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error));

@end

@implementation AFNContext

- (id)initWithHttpRequestOperationManager:(AFHTTPRequestOperationManager *)manager
{
    self = [super init];
    if (self) {
        self.manager = manager ?: [AFHTTPRequestOperationManager manager];
        self.parameters = [@{} mutableCopy];
    }
    
    return self;
}

+ (AFNContext * (^)(AFHTTPRequestOperationManager *manager))context;
{
    return ^(AFHTTPRequestOperationManager *manager) {
        return [[self alloc] initWithHttpRequestOperationManager:manager];
    };
}

- (AFNContext * (^)(NSString *method))method
{
    return ^(NSString *method) {
        self.requestMethod = method;
        return self;
    };
}

- (AFNContext * (^)(NSString *prefix))prefix
{
    return ^(NSString *prefix) {
        self.requestPathPrefix = prefix;
        return self;
    };
}

- (AFNContext * (^)(NSString *path, ...))path
{
    return ^(NSString *path, ...) {
        va_list arglist;
        va_start(arglist, path);
        
        self.requestPath = [[NSString alloc] initWithFormat:path arguments:arglist];
        
        va_end(arglist);
        
        return self;
    };
}

- (AFNContext * (^)(NSString *key, id value))addParameter;
{
    return ^(NSString *key, NSString *value) {
        if (key && value) {
            self.parameters[key] = value;
        }
        return self;
    };
}

- (AFNContext * (^)(NSDictionary *parameters))addParameters
{
    return ^(NSDictionary *parameters) {
        [self.parameters addEntriesFromDictionary:parameters];
        return self;
    };
}

- (AFNContext * (^)(void (^)(id<AFMultipartFormData> formData)))addMultipartFormData
{
    return ^(void (^multipartFormDataBlock)(id<AFMultipartFormData> formData)) {
        void (^oldBlock)(id<AFMultipartFormData>) = self.multipartFormDataBlock;
        
        self.multipartFormDataBlock = ^(id<AFMultipartFormData> formData) {
            if (oldBlock) {
                oldBlock(formData);
            }
            multipartFormDataBlock(formData);
        };
        return self;
    };
}

- (AFNContext * (^)(void(^)(CGFloat progress)))uploadProgress
{
    return ^(void(^progressBlock)(CGFloat progress)) {
        self.uploadProgressBlock = progressBlock;
        return self;
    };
}

- (AFNContext * (^)(void(^)(CGFloat progress)))downloadProgress
{
    return ^(void(^progressBlock)(CGFloat progress)) {
        self.downloadProgressBlock = progressBlock;
        return self;
    };
}

- (AFNContext * (^)(void (^responseCallback)(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error))))addResponseCallback
{
    return ^(void (^responseCallback)(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error))) {
        void (^prev)(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error)) = self.responseCallback;
        
        if (!prev) {
            prev = ^(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error)) {
                next(responseObject, error);
            };
        }
        
        self.responseCallback = ^(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error)) {
            prev(responseObject, error, ^(id responseObject, NSError *error) {
                responseCallback(responseObject, error, next);
            });
        };
        
        return self;
    };
}

- (void (^)())done;
{
    return ^{
        void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
            if (self.responseCallback) {
                self.responseCallback(responseObject, nil, ^(id responseObject, NSError *error) {});
            }
        };
        
        void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
            if (self.responseCallback) {
                self.responseCallback(nil, error, ^(id responseObject, NSError *error) {});
            }
        };
        
        AFHTTPRequestOperation *operation = nil;
        if (self.multipartFormDataBlock) {
            operation = [self multipartHTTPRequestOperationWithHTTPMethod:self.requestMethod ?: @"POST"
                                                                URLString:[self buildPath]
                                                               parameters:self.parameters
                                                constructingBodyWithBlock:self.multipartFormDataBlock
                                                                  success:successBlock
                                                                  failure:failureBlock];
        }
        else {
            operation = [self HTTPRequestOperationWithHTTPMethod:self.requestMethod ?: @"GET"
                                                       URLString:[self buildPath]
                                                      parameters:self.parameters
                                                         success:successBlock
                                                         failure:failureBlock];
        }
        
        if (operation) {
            if (self.uploadProgressBlock) {
                [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                    if (totalBytesExpectedToWrite > 0) {
                        CGFloat progress = (CGFloat) totalBytesWritten / (CGFloat) totalBytesExpectedToWrite;
                        self.uploadProgressBlock(progress);
                    }
                }];
            }
            
            if (self.downloadProgressBlock) {
                [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                    if (totalBytesExpectedToRead > 0) {
                        CGFloat progress = (CGFloat) totalBytesRead / (CGFloat) totalBytesExpectedToRead;
                        self.downloadProgressBlock(progress);
                    }
                }];
            }
            
            [self.manager.operationQueue addOperation:operation];
        }
    };
}

- (NSString *)buildPath
{
    return [NSString stringWithFormat:@"%@%@", self.requestPathPrefix ?: @"", self.requestPath ?: @""];
}

- (AFHTTPRequestOperation *)multipartHTTPRequestOperationWithHTTPMethod:(NSString *)method
                                                              URLString:(NSString *)URLString
                                                             parameters:(id)parameters
                                                  constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                                success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.manager.requestSerializer multipartFormRequestWithMethod:method
                                                                                        URLString:[[NSURL URLWithString:URLString relativeToURL:self.manager.baseURL] absoluteString]
                                                                                       parameters:parameters constructingBodyWithBlock:block
                                                                                            error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.manager.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    return [self.manager HTTPRequestOperationWithRequest:request success:success failure:failure];
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithHTTPMethod:(NSString *)method
                                                     URLString:(NSString *)URLString
                                                    parameters:(id)parameters
                                                       success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                       failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:method
                                                                           URLString:[[NSURL URLWithString:URLString relativeToURL:self.manager.baseURL] absoluteString]
                                                                          parameters:parameters
                                                                               error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.manager.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    return [self.manager HTTPRequestOperationWithRequest:request success:success failure:failure];
}

@end

#pragma mark - AFNContextMultipartExtension

@implementation AFNContext (AFNContextMultipartExtension)

- (AFNContext * (^)(NSData *data, NSString *name, NSString *fileName, NSString *mimeType))addMultipartFileData
{
    return ^(NSData *data, NSString *name, NSString *fileName, NSString *mimeType) {
        self.addMultipartFormData(^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
        });
        return self;
    };
}

- (AFNContext * (^)(NSURL *fileURL, NSString *name, NSError * __autoreleasing * error))addMultipartFileURL
{
    return ^(NSURL *fileURL, NSString *name, NSError * __autoreleasing * error) {
        self.addMultipartFormData(^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileURL:fileURL name:name error:error];
        });
        return self;
    };
}

- (AFNContext * (^)(NSURL *fileURL, NSString *name, NSString *fileName, NSString *mimeType, NSError * __autoreleasing * error))addMultipartFileURL2
{
    return ^(NSURL *fileURL, NSString *name, NSString *fileName, NSString *mimeType, NSError * __autoreleasing * error) {
        self.addMultipartFormData(^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:error];
        });
        return self;
    };
}

- (AFNContext * (^)(NSInputStream *inputStream, NSString *name, NSString *fileName, int64_t length, NSString *mimeType))addMultipartInputStream
{
    return ^(NSInputStream *inputStream, NSString *name, NSString *fileName, int64_t length, NSString *mimeType) {
        self.addMultipartFormData(^(id<AFMultipartFormData> formData) {
            [formData appendPartWithInputStream:inputStream name:name fileName:fileName length:length mimeType:mimeType];
        });
        return self;
    };
}

@end

#pragma mark - AFNContextMultipartExtension

@implementation AFNContext (AFNContextResponseExtension)

- (AFNContext * (^)(void(^)(id responseObject)))success
{
    return ^(void(^successBlock)(id responseObject)) {
        self.response(^(id responseObject, NSError *error) {
            if (!error) {
                successBlock(responseObject);
            }
        });
        
        return self;
    };
}

- (AFNContext * (^)(void(^)(NSError *error)))failure
{
    return ^(void(^failureBlock)(NSError *error)) {
        self.response(^(id responseObject, NSError *error) {
            if (error) {
                failureBlock(error);
            }
        });
        
        return self;
    };
}

- (AFNContext * (^)(void(^)(id responseObject, NSError *error)))response
{
    return ^(void(^responseBlock)(id responseObject, NSError *error)) {
        self
        .addResponseCallback(^(id responseObject, NSError *error, void (^next)(id responseObject, NSError *error)) {
            responseBlock(responseObject, error);
            next(responseObject, error);
        });
        
        return self;
    };
}

@end