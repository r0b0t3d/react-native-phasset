#import "Phasset.h"
#import <Photos/Photos.h>

#import <React/RCTConvert.h>

static NSString *const kErrorAuthRestricted = @"E_PHOTO_LIBRARY_AUTH_RESTRICTED";
static NSString *const kErrorAuthDenied = @"E_PHOTO_LIBRARY_AUTH_DENIED";

typedef void (^PhotosAuthorizedBlock)(void);

static void requestPhotoLibraryAccess(RCTPromiseRejectBlock reject, PhotosAuthorizedBlock authorizedBlock) {
  PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
  if (authStatus == PHAuthorizationStatusRestricted) {
    reject(kErrorAuthRestricted, @"Access to photo library is restricted", nil);
  } else if (authStatus == PHAuthorizationStatusAuthorized) {
    authorizedBlock();
  } else if (authStatus == PHAuthorizationStatusNotDetermined) {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
      requestPhotoLibraryAccess(reject, authorizedBlock);
    }];
  } else {
    reject(kErrorAuthDenied, @"Access to photo library was denied", nil);
  }
}


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

RCT_ENUM_CONVERTER(PHAssetCollectionSubtype, (@{
   @"album": @(PHAssetCollectionSubtypeAny),
   @"all": @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
   @"event": @(PHAssetCollectionSubtypeAlbumSyncedEvent),
   @"faces": @(PHAssetCollectionSubtypeAlbumSyncedFaces),
   @"library": @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
   @"photo-stream": @(PHAssetCollectionSubtypeAlbumMyPhotoStream), // incorrect, but legacy
   @"photostream": @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
   @"saved-photos": @(PHAssetCollectionSubtypeAny), // incorrect, but legacy correspondence in PHAssetCollectionSubtype
   @"savedphotos": @(PHAssetCollectionSubtypeAny), // This was ALAssetsGroupSavedPhotos, seems to have no direct correspondence in PHAssetCollectionSubtype
}), PHAssetCollectionSubtypeAny, integerValue)

@end

@implementation Phasset

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(checkExists:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *assetId = [RCTConvert NSString:params[@"id"]] ?: @"";
    NSString *const mediaType = [RCTConvert NSString:params[@"assetType"]];
    NSString *const groupName = [RCTConvert NSString:params[@"groupName"]];
    NSString *const groupTypes = [RCTConvert NSString:params[@"groupTypes"]];

    PHFetchOptions *const options = [RCTConvert PHFetchOptionsFromMediaType:mediaType];
    if (groupName != nil) {
        [self getCollection:groupName groupTypes:groupTypes rejecter:reject completion:^(PHAssetCollection *assetCollection) {
            if (assetCollection != nil) {
                PHFetchOptions *const assetFetchOptions = [RCTConvert PHFetchOptionsFromMediaType:mediaType];
                // Find asset inside collection
                PHFetchResult<PHAsset *> *const assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:assetFetchOptions];
                BOOL __block exists = NO;
                [assetsFetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *const uri = [NSString stringWithFormat:@"ph://%@", [obj localIdentifier]];
                    if ([uri isEqualToString:assetId]) {
                        exists = YES;
                        *stop = YES;
                    }
                }];
                resolve(exists ? @YES : @NO);
            }
        }];
    } else {
        PHFetchResult<PHAsset *> *const assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
        BOOL __block exists = NO;
        [assetsFetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *const uri = [NSString stringWithFormat:@"ph://%@", [obj localIdentifier]];
            if ([uri isEqualToString:assetId]) {
                exists = YES;
                *stop = YES;
            }
        }];
        resolve(exists ? @YES : @NO);
    }
}

RCT_EXPORT_METHOD(requestImage:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *assetId = [RCTConvert NSString:params[@"id"]] ?: @"";
    int maxWidth = [params[@"maxWidth"] intValue] ?: 1024;
    int maxHeight = [params[@"maxHeight"] intValue] ?: 1024;
    BOOL useBase64 = [params[@"useBase64"] boolValue] ?: false;
    
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
        
        NSDictionary* location = asset.location != nil ? @{
            @"latitude": @(asset.location.coordinate.latitude),
            @"longitude": @(asset.location.coordinate.longitude)
        } : [NSNull null];
        
        NSDictionary* data = @{
            @"id": asset.localIdentifier,
            @"path": (filePath && ![filePath isEqualToString:(@"")]) ? filePath : [NSNull null],
            @"base64": useBase64 ? [imageData base64EncodedStringWithOptions:0] : [NSNull null],
            @"sourceURL": (sourceURL) ? sourceURL : [NSNull null],
            @"localIdentifier": asset.localIdentifier,
            @"filename": [asset valueForKey:@"filename"],
            @"width": (exif) && [exif valueForKey:@"PixelWidth"] ? [exif valueForKey:@"PixelWidth"] : 0,
            @"height": (exif) && [exif valueForKey:@"PixelHeight"] ? [exif valueForKey:@"PixelHeight"] : 0,
            @"mime": @"image/jpeg",
            @"size": [NSNumber numberWithUnsignedInteger:imageData.length],
            @"exif": (exif) ? exif : [NSNull null],
            @"location": location,
            @"creationDate": (asset.creationDate) ? [NSString stringWithFormat:@"%.0f", [asset.creationDate timeIntervalSince1970]] : [NSNull null],
            @"modificationDate": (asset.modificationDate) ? [NSString stringWithFormat:@"%.0f", [asset.modificationDate timeIntervalSince1970]] : [NSNull null],
        };
        
        resolve(data);
    }];
}

- (void)getCollection:(NSString*)collectionName groupTypes:(NSString*)groupTypes rejecter:(RCTPromiseRejectBlock)reject completion:(void(^)(PHAssetCollection*))completion {
    PHFetchOptions *const collectionFetchOptions = [PHFetchOptions new];
    collectionFetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:NO]];
    collectionFetchOptions.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"localizedTitle == '%@'", collectionName]];
    // If groupTypes is "all", we want to fetch the SmartAlbum "all photos". Otherwise, all
    // other groupTypes values require the "album" collection type.
    PHAssetCollectionType const collectionType = ([groupTypes isEqualToString:@"all"]
                                                  ? PHAssetCollectionTypeSmartAlbum
                                                  : PHAssetCollectionTypeAlbum);
    PHAssetCollectionSubtype const collectionSubtype = [RCTConvert PHAssetCollectionSubtype:groupTypes];
    
    requestPhotoLibraryAccess(reject, ^{
        PHFetchResult<PHAssetCollection *> *const assetCollectionFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:collectionType subtype:collectionSubtype options:nil];
        [assetCollectionFetchResult enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull assetCollection, NSUInteger collectionIdx, BOOL * _Nonnull stopCollections) {
            if ([collectionName isEqualToString:[assetCollection localizedTitle]]) {
                completion(assetCollection);
                *stopCollections = YES;
            }
        }];
        completion(nil);
    });
    
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
