//
//  VSMMapDownloader.h
//  VSMSDK
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/09/14.
//  Copyright © 2021 sktelecom. All rights reserved.
//

#ifndef VSMMapDownloader_h
#define VSMMapDownloader_h

#import "VSMMapDownloadItem.h"
#include "VSM.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 지도 데이터 베이스(Layer)들을 다운로드 받는 클래스입니다.
 */
@interface VSMMapDownloader : NSObject <VSMMapDownloadItemDelegate>

/**
 * 싱글톤 메소드
 * @return Shared VSMMapDownloader
 */
+ (instancetype)sharedInstance;

/**
 * 다운로드 받을 Item들을 초기화합니다.
 * @return 초기화 성공 여부 (이미 준비가 되었다면 True)
 */
- (BOOL)initDownloadItems;

/**
 * 다운로드 받을 Item들을 초기화합니다.
 * @param endCallback 각 아이템들의 다운로드 상태 변경시마다 호출 해주는 콜백
 * @param networkCallback 각 아이템들의 다운로드 성공 혹은 실패시 호출 해주는 콜백
 * @param userData caller 데이터
 * @return 다운로드 시작 여부
 */
- (BOOL)startDownload:(vsm::CB_VSM_EMBEDDEDMAP_DOWNLOAD_STATUS_CALLBACK)endCallback
      networkCallback:(vsm::CB_VSM_NETWORK_STATUS_CALLBACK)networkCallback
             userData:(void*)userData;

/**
 * 모든 다운로드 아이템을 지우고
 * Native에 EmbeddedMap의 Available 상태를 Fasle로 전환합니다.
 */
- (BOOL)deleteEmbeddedMap;

/**
 * 모든 다운로드 아이템을 지우고
 * Native에 EmbeddedMap의 Available 상태를 Fasle로 전환합니다.
 */
- (void)stopDownload:(BOOL)callback;

/**
 * NetworkCallback을 설정합니다.
 * @param callback NetworkCallback
 */
- (void)setNetworkCallback:(vsm::CB_VSM_NETWORK_STATUS_CALLBACK)callback;

/**
 * 지도 데이터 베이스가 새버전으로써, 가용 가능한지 체크합니다.
 * @param callback 상태체크 후 콜백
 * @param userData caller 데이터
 * @return 0
 */
- (int)checkNewEmbeddedMap:(vsm::CB_VSM_EMBEDDEDMAP_DOWNLOAD_STATUS_CALLBACK)callback userData:(void*)userData;

/**
 * 신규 버전 데이터베이스 다운로딩된 사이즈를 반환합니다.
 * @return 다운로드 사이즈 (Byte)
 */
- (uint64_t)getDownloadedSize;

/**
 * 필요한 신규 버전 총 사이즈를 반환합니다.
 * @return 신규 버전 총 사이즈 (Byte)
 */
- (uint64_t)getContentSize;

/**
 * ID
 */
@property (nonatomic, retain) NSString* identifier;

@end

NS_ASSUME_NONNULL_END

#endif /* VSMMapDownloader_h */
