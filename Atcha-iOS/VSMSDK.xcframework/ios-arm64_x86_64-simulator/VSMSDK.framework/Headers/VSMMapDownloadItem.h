//
//  VSMMapDownloadItem.h
//  VSMSDK
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/10/07.
//  Copyright © 2021 sktelecom. All rights reserved.
//

#ifndef VSMMapDownloadItem_h
#define VSMMapDownloadItem_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

enum eEmbeddedMapState {
    eEmbeddedMapStateNewVersionDownloaded = 0,
    eEmbeddedMapStateNewVersionDownloading = 1,
    eEmbeddedMapStateNewVersionFailed = 2,
    eEmbeddedMapStateOldVersionDownloaded = 3,
    eEmbeddedMapStateNone = 4
};

static NSDictionary<NSNumber*, NSString*>* EMBEDDED_MAP_STATE_STRING = @{
    @(eEmbeddedMapStateNewVersionDownloaded) : @"NewDownloaded",
    @(eEmbeddedMapStateNewVersionDownloading) : @"NewDownloading",
    @(eEmbeddedMapStateNewVersionFailed) : @"NewVersionFailed",
    @(eEmbeddedMapStateOldVersionDownloaded) : @"OldDownloaded",
    @(eEmbeddedMapStateNone) : @"None"
};

@protocol VSMMapDownloadItemDelegate <NSObject>
- (void)onComplete:(id)item
             state:(eEmbeddedMapState)state
    httpStatusCode:(int)httpStatusCode
      alreadyExist:(BOOL)alreadyExist;
- (void)onStarted;
- (void)onProgress:(id)item;
@end

//Internal Only
@class VSMMapDownloader;

@interface VSMMapDownloadItem : NSObject <NSURLSessionDownloadDelegate>

@property (nonatomic, assign) int layerID;

@property (nonatomic, retain) NSString* dbUri;

@property (nonatomic, retain) NSString* identifier;

@property (nonatomic, retain) NSString* downloadDirectory;

@property (nonatomic, retain) NSString* downloadFilePath;

@property (nonatomic, retain) NSString* oldFilePath;  // 다운로드 완료후 삭제용

@property (nonatomic, assign) eEmbeddedMapState embeddedMapState;

@property (atomic, assign) uint64_t contentBytes;

@property (atomic, assign) uint64_t expectedContentBytes;

@property (atomic, assign) uint64_t downloadedBytes;

@property (atomic, assign) double progress;

- (id)initWithLayerID:(int)layerID
                dbUri:(NSString*)dbUri
           identifier:(NSString*)identifier
             delegate:(id<VSMMapDownloadItemDelegate>)delegate;

- (void)startDownload;

- (void)stopDownload;

- (BOOL)removeOldFile;

- (BOOL)removeDownloadedFile;

- (uint64_t)getExpactedContentBytes;

@end

NS_ASSUME_NONNULL_END

#endif /* VSMMapDownloadItem_h */
