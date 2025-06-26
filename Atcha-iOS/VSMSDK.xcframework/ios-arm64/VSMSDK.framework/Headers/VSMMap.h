//
//  VSMMap.h
//  TAModule
//
//  Created by 1001921 on 2015. 3. 24..
//
//

#import <Foundation/Foundation.h>
#import "VSMMapDefine.h"

#define VSMMapInstance [VSMMap sharedInstance]

#define MAP_DL_ON_IOS 1

typedef void (^MapDLEnddedBlock)(BOOL result, NSError *error);

@interface VSMMap : NSObject

/**	싱글톤 VSMMap 객체를 반환합니다.
 */
+ (VSMMap*) sharedInstance;

/**    VSM Engine를 초기화 함.
 
 @return VSM Map Engine 초기화 시작 성공/실패 여부.
 */
- (bool) initEngine;

/**	VSM Engine을 종료 함.
 */
- (BOOL) destoryVSMEngine;

/** Engine Version 리턴
 
 @return Engine Version
 */
+ (NSString*) getEngineVersion;

/** Map Tile Cache 제거
 
    @return 성공 여부
 */
- (BOOL) cleanUpDiskCache;

/** Disk Cache Size 설정
 @param limit cache size (Bytes)
 */
- (void) setDiskCacheSizeLimit:(NSUInteger)limit;

/** 현재 설정된 최대 Disk Cache Size를 반환 (Bytes)
 */
- (NSUInteger) getDiskCacheSizeLimit;

/** 사용 중인 Disk Cache Size를 반환 (Bytes)
 */
- (NSUInteger) getDiskCacheSize;

/** 지도 Tile DB Caching Mode 설정
 @param mode DB Caching Mode
 @return 정상 설정 여부
 @see DB_CACHING_MODE
 */
- (BOOL) setTileDBCachingMode:(DB_CACHING_MODE)mode;

/** 지도 Tile DB Caching Mode 리턴
 
 @return DB Caching Mode
 @see DB_CACHING_MODE
 */
- (DB_CACHING_MODE) getTileDBCachingMode;

/** 신규 Embedded Map 존재 여부 확인

 */
- (void) checkNewEmbeddedMap;

/** Embedded Map Download 시작
 
    @param enddedBlock Embedded Map DL 완료후 수행할 block
    @return 동작 정상 수행 여부
 */
- (bool) startEmbeddedMapDownloadWithCompletion:(MapDLEnddedBlock) enddedBlock;


/** Embedded Map Download에 대한 Delegate를 등록합니다.
 
    @param downloadStatusCB Embedded Map Download에 대한 Delegate
 */
- (void) setEmbeddedMapDownloadDelegate:(id<EmbeddedMapDLStatusDelegate>)downloadStatusCB;

/** Embedded Map Download 정지
 
    @return 동작 정상 수행 여부
 */
- (bool) stopEmbeddedMapDownload;

/** Embedded Map 삭제
 
    @return 동작 정상 수행 여부
 */
- (bool) deleteEmbeddedMapDownload;

/** Embedded Map Download 현재 Status 리턴
 
 @return Embedded Map Download 현재 Status 리턴
 */
- (EmbeddedMapDLStatus) getEmbeddedMapDLStatus;

/** 다운로드 지도의 사용가능 여부를 조회하는 함수.

    @return 다운로드 지도의 사용가능 여부를 반환.
 */
- (bool) getEmbeddedMapAvailable;

/** 다운로드 지도의 신규 업데이트가 존재여부를 조회하는 함수.

    @return 지도의 신규 업데이트 여부를 반환.
 */
- (bool) getMapUpdateAvailable;

/** 지도 다운로드의 이어받기 가능여부를 조회하는 함수.
 
    @return 지도 다운로드의 이어받기 가능여부를 반환.
 */
- (bool) getMapContinuousDownloadAvailable;

/** 지도 전체 다운로드 크기를 조회하는 함수.
    
    @return 지도 전체 다운로드 크기를 반환.
 */
- (int) getMapTotalDownloadSize;

/** 다운로드 중인 지도의 크기를 조회하는 함수.

    @return 다운로드 중인 지도의 크기를 반환.
 */
- (int) getMapDownloadedSize;

/** 다운로드 지도의 버전을 조회하는 함수.

    @return 다운로드 지도의 버전을 조회하는 함수.
 */
- (NSString*) getEmbeddedMapLocalVersion;

/** 네트워크 상태에 대한 Delegate를 등록합니다.
 *  @param networkStatusCB  네트워크 상태에 대한 Delegate
 */
- (void) setNetworkDelegate:(id<NetworkStatusDelegate>)networkStatusCB;


/** VSM Rake logging을 위한 delegate 설정. deprecated
 
 @param delegate VSM Rake logging을 위한 delegate
 */
- (void) setVSMRakeLogEventDelegate:(id)delegate ;

#pragma mark - Unreleased API
// [twice] tyler added
- (void) forceSetEmbeddedMapDLStatus:(EmbeddedMapDLStatus)status;

- (void) enableMMRendering:(bool)enable;
@end
