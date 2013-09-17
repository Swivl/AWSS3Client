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

#import "AWSS3Client.h"
#import <CommonCrypto/CommonHMAC.h>
#import "AFHTTPRequestOperation.h"

static NSString * const AFAmazonS3ClientDefaultBaseURLString = @"http://s3.amazonaws.com";

NSString * const AFAmazonS3USStandardRegion = @"s3.amazonaws.com";
NSString * const AFAmazonS3USWest1Region = @"s3-us-west-1.amazonaws.com";
NSString * const AFAmazonS3USWest2Region = @"s3-us-west-2.amazonaws.com";
NSString * const AFAmazonS3EUWest1Region = @"s3-eu-west-1.amazonaws.com";
NSString * const AFAmazonS3APSoutheast1Region = @"s3-ap-southeast-1.amazonaws.com";
NSString * const AFAmazonS3APSoutheast2Region = @"s3-ap-southeast-2.amazonaws.com";
NSString * const AFAmazonS3APNortheast2Region = @"s3-ap-northeast-1.amazonaws.com";
NSString * const AFAmazonS3SAEast1Region = @"s3-sa-east-1.amazonaws.com";

@interface AWSS3Client ()
- (NSString*)canonicalizedResourceWithKey:(NSString*)key;
- (NSString*)stringToSignForRequestMethod:(NSString*)requestMethod contentMD5:(NSString*)contentMD5 mimeType:(NSString*)mimeType dateString:(NSString*)dateString headers:(NSString*)canonicalizedAmzHeaders resource:(NSString*)canonicalizedResource;
- (NSString*)dateString;
- (NSString*)base64EncodedStringFromData:(NSData*)data;
- (NSData*)HMACSHA1WithKey:(NSString*)key string:(NSString*)string;
- (NSData*)MD5FromData:(NSData*)data;
@end


@implementation AWSS3Client

- (instancetype)init {
    return [self initWithBaseURL:[NSURL URLWithString:AFAmazonS3ClientDefaultBaseURLString]];
}

- (id)initWithAccessKeyID:(NSString *)accessKey
                   secret:(NSString *)secret
{
    self = [self init];
    if (!self) {
        return nil;
    }

    self.accessKey = accessKey;
    self.secretKey = secret;

    return self;
}

- (instancetype)initWithBaseURL:(NSURL*)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        _integrityCheck = YES;   //default
    }
    return self;
}

- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self putObjectWithData:data key:key mimeType:mimeType permission:AWSS3ObjectPermissionsPrivate progress:NULL success:success failure:failure];
}

- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self putObjectWithData:data key:key mimeType:mimeType permission:AWSS3ObjectPermissionsPrivate progress:progress success:success failure:failure];
}

- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType permission:(AWSS3ObjectPermission)permission success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self putObjectWithData:data key:key mimeType:mimeType permission:permission progress:NULL success:success failure:failure];
}

- (void)putObjectWithData:(NSData*)data key:(NSString*)key mimeType:(NSString*)mimeType permission:(AWSS3ObjectPermission)permission progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self clearAuthorizationHeader];

    NSString* dateString = [self dateString];
    [self setDefaultHeader:@"Date" value:dateString];

    NSString* contentMD5 = @"";
    if (self.integrityCheck) {
        contentMD5 = [self base64EncodedStringFromData:[self MD5FromData:data]];
        [self setDefaultHeader:@"Content-MD5" value:contentMD5];
    }

    NSMutableArray* xAmzHeaders = [[NSMutableArray alloc] init];

    switch (permission) {
        case AWSS3ObjectPermissionsPrivate:
            [self setDefaultHeader:@"x-amz-acl" value:@"private"];
            break;
        case AWSS3ObjectPermissionPublicRead:
            [self setDefaultHeader:@"x-amz-acl" value:@"public-read"];
            break;
        case AWSS3ObjectPermissionPublicReadWrite:
            [self setDefaultHeader:@"x-amz-acl" value:@"public-read-write"];
            break;
        case AWSS3ObjectPermissionAuthenticatedRead:
            [self setDefaultHeader:@"x-amz-acl" value:@"authenticated-read"];
            break;
        case AWSS3ObjectPermissionBucketOwnerRead:
            [self setDefaultHeader:@"x-amz-acl" value:@"bucket-owner-read"];
            break;
        case AWSS3ObjectPermissionBucketOwnerFullControl:
            [self setDefaultHeader:@"x-amz-acl" value:@"bucket-owner-full-control"];
            break;
    }
    [xAmzHeaders addObject:@"x-amz-acl"];

    if (_sessionToken) {
        [self setDefaultHeader:@"x-amz-security-token" value:_sessionToken];
        [xAmzHeaders addObject:@"x-amz-security-token"];
    }

    [xAmzHeaders sortUsingSelector:@selector(compare:)];
    NSString* canonicalizedAmzHeaders = @"";
    for (NSString* xAmzHeader in xAmzHeaders) {
        NSString* headerValue = [self defaultValueForHeader:xAmzHeader];
        canonicalizedAmzHeaders = [canonicalizedAmzHeaders 
                                   stringByAppendingFormat:@"%@:%@\n", 
                                   xAmzHeader, 
                                   headerValue];
    }

    NSString* requestMethod = @"PUT";
    NSString* canonicalizedResource = [self canonicalizedResourceWithKey:key];
    NSString* stringToSign = [self stringToSignForRequestMethod:requestMethod contentMD5:contentMD5 mimeType:mimeType dateString:dateString headers:canonicalizedAmzHeaders resource:canonicalizedResource];

    NSString* signature = [self base64EncodedStringFromData:[self HMACSHA1WithKey:self.secretKey string:stringToSign]];
    NSString* authorizationString = [NSString stringWithFormat:@"AWS %@:%@", self.accessKey, signature];
    [self setDefaultHeader:@"Authorization" value:authorizationString];

    NSMutableURLRequest* request = [self requestWithMethod:@"PUT" path:canonicalizedResource parameters:nil];
    [request addValue:[NSString stringWithFormat:@"%ld", (long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];

    AFHTTPRequestOperation* operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation* operation, id responseObject) {
        if (success) success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        if (failure) failure(operation, error);
    }];
    if (progress)
        [operation setUploadProgressBlock:progress];

    [self enqueueHTTPRequestOperation:operation];
}

- (void)putObjectWithPath:(NSString*)path key:(NSString*)key mimeType:(NSString*)mimeType permission:(AWSS3ObjectPermission)permission progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self clearAuthorizationHeader];
    
    NSString* dateString = [self dateString];
    [self setDefaultHeader:@"Date" value:dateString];
    
    NSString* contentMD5 = @"";
    NSMutableArray* xAmzHeaders = [[NSMutableArray alloc] init];
    
    switch (permission) {
        case AWSS3ObjectPermissionsPrivate:
            [self setDefaultHeader:@"x-amz-acl" value:@"private"];
            break;
        case AWSS3ObjectPermissionPublicRead:
            [self setDefaultHeader:@"x-amz-acl" value:@"public-read"];
            break;
        case AWSS3ObjectPermissionPublicReadWrite:
            [self setDefaultHeader:@"x-amz-acl" value:@"public-read-write"];
            break;
        case AWSS3ObjectPermissionAuthenticatedRead:
            [self setDefaultHeader:@"x-amz-acl" value:@"authenticated-read"];
            break;
        case AWSS3ObjectPermissionBucketOwnerRead:
            [self setDefaultHeader:@"x-amz-acl" value:@"bucket-owner-read"];
            break;
        case AWSS3ObjectPermissionBucketOwnerFullControl:
            [self setDefaultHeader:@"x-amz-acl" value:@"bucket-owner-full-control"];
            break;
    }
    [xAmzHeaders addObject:@"x-amz-acl"];
    
    if (_sessionToken) {
        [self setDefaultHeader:@"x-amz-security-token" value:_sessionToken];
        [xAmzHeaders addObject:@"x-amz-security-token"];
    }
    
    [xAmzHeaders sortUsingSelector:@selector(compare:)];
    NSString* canonicalizedAmzHeaders = @"";
    for (NSString* xAmzHeader in xAmzHeaders) {
        NSString* headerValue = [self defaultValueForHeader:xAmzHeader];
        canonicalizedAmzHeaders = [canonicalizedAmzHeaders
                                   stringByAppendingFormat:@"%@:%@\n",
                                   xAmzHeader,
                                   headerValue];
    }
    
    NSString* requestMethod = @"PUT";
    NSString* canonicalizedResource = [self canonicalizedResourceWithKey:key];
    NSString* stringToSign = [self stringToSignForRequestMethod:requestMethod contentMD5:contentMD5 mimeType:mimeType dateString:dateString headers:canonicalizedAmzHeaders resource:canonicalizedResource];
    
    NSString* signature = [self base64EncodedStringFromData:[self HMACSHA1WithKey:self.secretKey string:stringToSign]];
    NSString* authorizationString = [NSString stringWithFormat:@"AWS %@:%@", self.accessKey, signature];
    [self setDefaultHeader:@"Authorization" value:authorizationString];
    
    NSInputStream *postBodyStream = [[NSInputStream alloc] initWithFileAtPath:path];
    

    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    NSString *contentLength = [fileSizeNumber stringValue];
    
    NSMutableURLRequest* request = [self requestWithMethod:@"PUT" path:canonicalizedResource parameters:nil];
    [request setHTTPBodyStream:postBodyStream];
    [request addValue:contentLength forHTTPHeaderField:@"Content-Length"];
    
    AFHTTPRequestOperation* operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation* operation, id responseObject) {
        if (success) success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        if (failure) failure(operation, error);
    }];
    if (progress)
        [operation setUploadProgressBlock:progress];
    
    [self enqueueHTTPRequestOperation:operation];
}

- (void)getObjectToFileAtPath:(NSString*)path key:(NSString*)key success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self clearAuthorizationHeader];

    NSString* dateString = [self dateString];
    [self setDefaultHeader:@"Date" value:dateString];

    NSString* canonicalizedAmzHeaders = @"";
    NSString* requestMethod = @"GET";
    NSString* canonicalizedResource = [self canonicalizedResourceWithKey:key];
    NSString* stringToSign = [self stringToSignForRequestMethod:requestMethod contentMD5:@"" mimeType:@"" dateString:dateString headers:canonicalizedAmzHeaders resource:canonicalizedResource];

    NSString* signature = [self base64EncodedStringFromData:[self HMACSHA1WithKey:self.secretKey string:stringToSign]];
    NSString* authorizationString = [NSString stringWithFormat:@"AWS %@:%@", self.accessKey, signature];
    [self setDefaultHeader:@"Authorization" value:authorizationString];

    NSMutableURLRequest* request = [self requestWithMethod:@"GET" path:canonicalizedResource parameters:nil];

    AFHTTPRequestOperation* operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation* operation, id responseObject) {
        if (success) success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        if (failure) failure(operation, error);
    }];

    [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:path append:NO]];

    [self enqueueHTTPRequestOperation:operation];
}


//------------------------------------------------------------------------------
#pragma mark - Private Implementation
//------------------------------------------------------------------------------

- (NSString*)canonicalizedResourceWithKey:(NSString*)key
{
    return [NSString stringWithFormat:@"/%@/%@", self.bucket, [self URLEncodedStringFromString:key encoding:NSUTF8StringEncoding]];
}

- (NSString*)stringToSignForRequestMethod:(NSString*)requestMethod contentMD5:(NSString*)contentMD5 mimeType:(NSString*)mimeType dateString:(NSString*)dateString headers:(NSString*)canonicalizedAmzHeaders resource:(NSString*)canonicalizedResource
{
    if ([requestMethod isEqualToString:@"PUT"]) {
        [self setDefaultHeader:@"Content-Type" value:mimeType];
    }
    return [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@%@", requestMethod, contentMD5, mimeType, dateString, canonicalizedAmzHeaders, canonicalizedResource];
}

- (NSString*)base64EncodedStringFromData:(NSData*)data
{
    NSUInteger length = [data length];
    NSMutableData* mutableData = [NSMutableData dataWithLength:((length + 2) / 3)*  4];

    uint8_t* input = (uint8_t*)[data bytes];
    uint8_t* output = (uint8_t*)[mutableData mutableBytes];

    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }

        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        NSUInteger idx = (i / 3)*  4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }

    NSString* encodedString = [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
    return encodedString;
}

- (NSData*)HMACSHA1WithKey:(NSString*)key string:(NSString*)string
{
    NSData* stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData* keyData = [key dataUsingEncoding:NSUTF8StringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};

    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA1, [keyData bytes], [keyData length]);
    CCHmacUpdate(&hmacContext, [stringData bytes], [stringData length]);
    CCHmacFinal(&hmacContext, digest);

    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

- (NSData*)MD5FromData:(NSData*)data
{
    uint8_t digest[CC_MD5_DIGEST_LENGTH] = {0};

    CC_MD5([data bytes], [data length], digest);

    return [NSData dataWithBytes:digest length:CC_MD5_DIGEST_LENGTH];
}

- (NSString*)URLEncodedStringFromString:(NSString*)string encoding:(NSStringEncoding)encoding
{
    static NSString* const kAFLegalCharactersToBeEscaped = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\|~ ";

    // Following the suggestion in documentation for `CFURLCreateStringByAddingPercentEscapes` to "pre-process" URL strings (using stringByReplacingPercentEscapesUsingEncoding) with unpredictable sequences that may already contain percent escapes.
    NSString* encodedURL = (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)[string stringByReplacingPercentEscapesUsingEncoding:encoding], NULL, (__bridge CFStringRef)kAFLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
    return encodedURL;
}

- (NSString*)dateString
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss Z"];

    return [dateFormatter stringFromDate:[NSDate date]];
}

@end