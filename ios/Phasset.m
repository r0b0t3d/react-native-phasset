#import "Phasset.h"
#import <Photos/Photos.h>

#import <React/RCTConvert.h>

@implementation RCTConvert (PHFetchOptions)

+ (PHFetchOptions *)PHFetchOptionsFromMediaType:(NSString *)mediaType
{
  // This is not exhaustive in terms of supported media type predicates; more can be added in the future
  NSString *const lowercase = [mediaType lowercaseString];
  
  if ([lowercase isEqualToString:@"photos"]) {
    PHFetchOptions *const options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    return options;
  } else if ([lowercase isEqualToString:@"videos"]) {
    PHFetchOptions *const options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeVideo];
    return options;
  } else {
    if (![lowercase isEqualToString:@"all"]) {
      RCTLogError(@"Invalid filter option: '%@'. Expected one of 'photos',"
                  "'videos' or 'all'.", mediaType);
    }
    // This case includes the "all" mediatype
    PHFetchOptions *const options = [PHFetchOptions new];
    return options;
  }
}

@end

@implementation Phasset

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(checkExists:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *assetId = [RCTConvert NSString:params[@"id"]] ?: @"";
    NSArray* localIds = [NSArray arrayWithObjects: assetId, nil];
    NSString *const mediaType = [RCTConvert NSString:params[@"assetType"]];

    PHFetchOptions *const options = [RCTConvert PHFetchOptionsFromMediaType:mediaType];
    PHAsset * _Nullable asset = [PHAsset fetchAssetsWithLocalIdentifiers:localIds options:options].firstObject;
    resolve(asset != NULL ? @YES : @NO);
}

RCT_EXPORT_METHOD(requestImage:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *assetId = [RCTConvert NSString:params[@"id"]] ?: @"";
    int maxWidth = [params[@"maxWidth"] intValue] ?: 1024;
    int maxHeight = [params[@"maxHeight"] intValue] ?: 1024;
    
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    NSArray* localIds = [NSArray arrayWithObjects: assetId, nil];
    PHAsset * _Nullable asset = [PHAsset fetchAssetsWithLocalIdentifiers:localIds options:nil].firstObject;
    CGSize targetSize = CGSizeMake(maxWidth, maxHeight);
    
    [manager requestImageForAsset:(PHAsset *)asset
                       targetSize:(CGSize)targetSize
                      contentMode:(PHImageContentMode)PHImageContentModeAspectFit
                          options:(PHImageRequestOptions *)options
                    resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
        NSError *const error = [info objectForKey:PHImageErrorKey];
        if (error) {
            reject(@"", @"", error);
            return;
        }
        
        NSData *const imageData = UIImageJPEGRepresentation(image, 1.0);
        
        NSURL *sourceURL = [info objectForKey:@"PHImageFileURLKey"];
        
        NSDictionary* exif = [[CIImage imageWithData:imageData] properties];
        
        NSString *filePath = [self saveFile:imageData];
        NSDictionary* data = @{
            @"id": asset.localIdentifier,
            @"path": (filePath && ![filePath isEqualToString:(@"")]) ? filePath : [NSNull null],
            @"sourceURL": (sourceURL) ? sourceURL : [NSNull null],
            @"localIdentifier": asset.localIdentifier,
            @"filename": [asset valueForKey:@"filename"],
            @"width": [exif valueForKey:@"PixelWidth"],
            @"height": [exif valueForKey:@"PixelHeight"],
            @"mime": @"image/jpeg",
            @"size": [NSNumber numberWithUnsignedInteger:imageData.length],
            @"exif": (exif) ? exif : [NSNull null],
            @"creationDate": (asset.creationDate) ? [NSString stringWithFormat:@"%.0f", [asset.creationDate timeIntervalSince1970]] : [NSNull null],
            @"modificationDate": (asset.modificationDate) ? [NSString stringWithFormat:@"%.0f", [asset.modificationDate timeIntervalSince1970]] : [NSNull null],
        };
        
        resolve(data);
    }];
}

- (NSString*) getTmpDirectory {
    NSString *TMP_DIRECTORY = @"react-native-phasset/";
    NSString *tmpFullPath = [NSTemporaryDirectory() stringByAppendingString:TMP_DIRECTORY];

    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:tmpFullPath isDirectory:&isDir];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath: tmpFullPath
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return tmpFullPath;
}

- (NSString*) saveFile:(NSData*)data {
    NSString *tmpDir = [self getTmpDirectory];
    NSString *filePath = [tmpDir stringByAppendingString:[[NSUUID UUID] UUIDString]];
    filePath = [filePath stringByAppendingString:@".jpg"];

    // save cropped file
    BOOL status = [data writeToFile:filePath atomically:YES];
    if (!status) {
        return nil;
    }

    return filePath;
}

// See https://stackoverflow.com/questions/4147311/finding-image-type-from-nsdata-or-uiimage
- (NSString *)determineMimeTypeFromImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];

    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return @"";
}

@end
