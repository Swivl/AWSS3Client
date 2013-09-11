# AWSS3Client

AWSS3Client - is an Alternative [AFNetworking](https://github.com/AFNetworking/AFNetworking) Client, [AFHTTPClient](http://afnetworking.github.com/AFNetworking/Classes/AFHTTPClient.html) subclass for interacting with the [Amazon S3 API](http://aws.amazon.com/s3/).

As the S3 API returns XML responses, you may find it useful to include [AFKissXMLRequestOperation](https://github.com/AFNetworking/AFKissXMLRequestOperation) (just remember to do `-registerHTTPOperationClass:`)

```**Caution:** This code is still in its early stages of development, so exercise caution when incorporating this into production code.```

## Example Usage

```objective-c
	AWSS3Client *s3Client = [[AWSS3Client alloc] initWithAccessKeyID:@"..." secret:@"..."];
    s3Client.bucket = @"the-bucket";

    [s3Client putObjectWithData:imageData key:key mimeType:@"image/jpg" progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"Upload Successful!");
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Upload Failed...");
	}];
```

## Important Notes

- This code uses **Automatic Reference Counting**, if your project does not use ARC, you must add the `-fobjc-arc` compiler flag to each implementation files in `Target Settings > Build Phases > Compile Source`.
- This code also uses the **literals syntax**, so at least Xcode 4.5 is required.


## Adding to your project

If you're using [`CocoaPods`](http://cocoapods.org/), there's nothing simpler.
Add the following to your [`Podfile`](http://docs.cocoapods.org/podfile.html)
and run `pod install`

```
pod 'AWSS3Client', :git => 'https://github.com/swivl/AWSS3Client.git'
```

Don't forget to `#import "AWSS3Client.h"` where it's needed.

## Contact

Sergei Me

* http://github.com/merenkoff
* http://twitter.com/sergeimer
* mer.sergei@gmail.com

## License

AWSS3Client is available under the [MIT license](http://opensource.org/licenses/MIT). See the [`LICENSE`](https://github.com/merenkoff/AWSS3Client/blob/master/LICENSE) file for more info.
