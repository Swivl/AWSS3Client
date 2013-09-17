// Copyright (c) 2013 Sergei Merenkov (mer.sergei@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFHTTPClient.h"

typedef enum {
    AWSS3ObjectPermissionsPrivate = 0,
    AWSS3ObjectPermissionPublicRead = 1,
    AWSS3ObjectPermissionPublicReadWrite = 2,
    AWSS3ObjectPermissionAuthenticatedRead = 3,
    AWSS3ObjectPermissionBucketOwnerRead = 4,
    AWSS3ObjectPermissionBucketOwnerFullControl = 5
} AWSS3ObjectPermission;

@interface AWSS3Client : AFHTTPClient

@property (nonatomic, retain) NSString* accessKey;
@property (nonatomic, retain) NSString* secretKey;
@property (nonatomic, retain) NSString* sessionToken;
@property (nonatomic, retain) NSString* bucket;
@property (nonatomic, assign) BOOL integrityCheck;

- (id)initWithAccessKeyID:(NSString *)accessKey secret:(NSString *)secret;

- (void)putObjectWithPath:(NSString*)path key:(NSString*)key mimeType:(NSString*)mimeType permission:(AWSS3ObjectPermission)permission progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;
- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType permission:(AWSS3ObjectPermission)permission success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;
- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType permission:(AWSS3ObjectPermission)permission progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)getObjectToFileAtPath:(NSString*)path key:(NSString*)key success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

@end
