#import "Phasset.h"
#import <Photos/Photos.h>

#import <React/RCTConvert.h>

@implementation Phasset

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(requestImage:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *assetId = [RCTConvert NSString:params[@"id"]] ?: @"";
    
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    NSArray* localIds = [NSArray arrayWithObjects: assetId, nil];
    PHAsset * _Nullable asset = [PHAsset fetchAssetsWithLocalIdentifiers:localIds options:nil].firstObject;
    CGSize targetSize = CGSizeMake(1024, 1024);
    
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
        NSInteger const length = [imageData length];
        
        NSURL *sourceURL = [info objectForKey:@"PHImageFileURLKey"];
        
        NSDictionary* exif = nil;
        if([[params objectForKey:@"includeExif"] boolValue]) {
            exif = [[CIImage imageWithData:imageData] properties];
        }

        NSString *filePath = @"";
        NSDictionary* result = [self createAttachmentResponse:filePath
                                                     withExif: exif
                                                withSourceURL:[sourceURL absoluteString]
                                          withLocalIdentifier: asset.localIdentifier
                                                 withFilename: [asset valueForKey:@"filename"]
                                                    withWidth:@(1024)
                                                   withHeight:@(1024)
                                                     withMime:@"image/jpeg"
                                                     withSize:[NSNumber numberWithUnsignedInteger:imageData.length]
                                                     withData:[[params objectForKey:@"includeBase64"] boolValue] ? [imageData base64EncodedStringWithOptions:0]: nil
                                                     withRect:CGRectNull
                                             withCreationDate:asset.creationDate
                                         withModificationDate:asset.modificationDate
                                   ];
        resolve(result);
    }];
//    [manager requestImageDataForAsset:(PHAsset *)asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
//        NSURL *sourceURL = [info objectForKey:@"PHImageFileURLKey"];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            @autoreleasepool {
//                UIImage *imgT = [UIImage imageWithData:imageData];
//
//                Boolean forceJpg = [[params valueForKey:@"forceJpg"] boolValue];
//
//                NSNumber *compressQuality = [params valueForKey:@"compressImageQuality"];
//                Boolean isLossless = (compressQuality == nil || [compressQuality floatValue] >= 0.8);
//
//                NSNumber *maxWidth = [params valueForKey:@"compressImageMaxWidth"];
//                Boolean useOriginalWidth = (maxWidth == nil || [maxWidth integerValue] >= imgT.size.width);
//
//                NSNumber *maxHeight = [params valueForKey:@"compressImageMaxHeight"];
//                Boolean useOriginalHeight = (maxHeight == nil || [maxHeight integerValue] >= imgT.size.height);
//
//                NSString *mimeType = [self determineMimeTypeFromImageData:imageData];
//                Boolean isKnownMimeType = [mimeType length] > 0;
//
//                NSDictionary* exif = nil;
//                if([[params objectForKey:@"includeExif"] boolValue]) {
//                    exif = [[CIImage imageWithData:imageData] properties];
//                }
//
//                NSString *filePath = @"";
//                NSDictionary* result = [self createAttachmentResponse:filePath
//                                                            withExif: exif
//                                                       withSourceURL:[sourceURL absoluteString]
//                                                 withLocalIdentifier: asset.localIdentifier
//                                                        withFilename: [asset valueForKey:@"filename"]
//                                                           withWidth:@(imgT.size.width)
//                                                          withHeight:@(imgT.size.height)
//                                                            withMime:mimeType
//                                                            withSize:[NSNumber numberWithUnsignedInteger:imageData.length]
//                                                            withData:[[params objectForKey:@"includeBase64"] boolValue] ? [imageData base64EncodedStringWithOptions:0]: nil
//                                                            withRect:CGRectNull
//                                                    withCreationDate:asset.creationDate
//                                                withModificationDate:asset.modificationDate
//                                       ];
//            }
//        });
//    }];
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

- (NSDictionary*) createAttachmentResponse:(NSString*)filePath withExif:(NSDictionary*) exif withSourceURL:(NSString*)sourceURL withLocalIdentifier:(NSString*)localIdentifier withFilename:(NSString*)filename withWidth:(NSNumber*)width withHeight:(NSNumber*)height withMime:(NSString*)mime withSize:(NSNumber*)size withData:(NSString*)data withRect:(CGRect)cropRect withCreationDate:(NSDate*)creationDate withModificationDate:(NSDate*)modificationDate {
    return @{
             @"path": (filePath && ![filePath isEqualToString:(@"")]) ? filePath : [NSNull null],
             @"sourceURL": (sourceURL) ? sourceURL : [NSNull null],
             @"localIdentifier": (localIdentifier) ? localIdentifier : [NSNull null],
             @"filename": (filename) ? filename : [NSNull null],
             @"width": width,
             @"height": height,
             @"mime": mime,
             @"size": size,
             @"data": (data) ? data : [NSNull null],
             @"exif": (exif) ? exif : [NSNull null],
             @"creationDate": (creationDate) ? [NSString stringWithFormat:@"%.0f", [creationDate timeIntervalSince1970]] : [NSNull null],
             @"modificationDate": (modificationDate) ? [NSString stringWithFormat:@"%.0f", [modificationDate timeIntervalSince1970]] : [NSNull null],
             };
}

@end
