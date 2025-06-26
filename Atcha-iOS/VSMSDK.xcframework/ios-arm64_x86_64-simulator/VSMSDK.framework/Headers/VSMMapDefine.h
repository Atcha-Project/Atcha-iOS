//
//  VSMMapDefine.h
//  VSMInterface
//
//  Created by 1001921 on 2015. 11. 18..
//
//

/**
 * 지도 캐시 정책
 */
typedef NS_ENUM(NSUInteger, DB_CACHING_MODE) {
    /** 스트리밍
     */
    DB_CACHING_MODE_STREAMING_ONLY = 0,
    /** 스트리밍-임베디드 하이브리드
     */
    DB_CACHING_MODE_HYBRID = 1,
    /** 임베디드
     */
    DB_CACHING_MODE_EMBEDDED = 2,
};

//---------------------------------------------------------------------------------------------
// #. EmbeddedMapDLStatusDelegate
//---------------------------------------------------------------------------------------------

/**	Embedded Map Download 상태
 */
typedef NS_ENUM(NSUInteger, EmbeddedMapDLStatus) {
    /** None
     */
    eEmbeddedMapDLStatusNone = -1,
    /** Download Start
     */
    eEmbeddedMapDLStatusStarted = 300,
    /** Download Stopped
     */
    eEmbeddedMapDLStatusStopped,
    /** Download Prgress
     */
    eEmbeddedMapDLStatusProgress,
    /** Download Finished
     */
    eEmbeddedMapDLStatusFinished,
    /** Download Failed
     */
    eEmbeddedMapDLStatusFailed,
    /** Validation Checked
     */
    eEmbeddedMapDLStatusChecked,
};

/**	Embedded Map Download Status Delegate
 
 */
@protocol EmbeddedMapDLStatusDelegate

/**	Embedded Map Download start
 
 */
-(bool) onEmbeddedMapDownloadStart;

/**	Embedded Map Download stop
 
 */
-(bool) onEmbeddedMapDownloadStop;

/**	Embedded Map Download progress
 
    @parem current 현재까지 다운받은 Size
    @parem total 총 다운 받을 Size
 */
-(bool) onEmbeddedMapDownloadProgress:(NSUInteger)current total:(NSUInteger)total;

/**	Embedded Map Download end
 
 */
-(bool) onEmbeddedMapDownloadEnd;

/**	Embedded Map Download fail
 
 */
-(bool) onEmbeddedMapDownloadFail;

/** Embedded Map Checked
 
 */
-(bool) onEmbeddedMapDownloadChecked;

@end

/** 네트워크 상태
 */
typedef NS_ENUM(NSInteger, VSMNetworkStatus) {
    /** None
     */
    VSMNetworkStatusNone = -1,
    /** Successed
     */
    VSMNetworkStatusSuccessed,
    /** Failed
     */
    VSMNetworkStatusFailed
};

/** 네트워크 리퀘스트 상태
 */
typedef NS_ENUM(NSInteger, VSMNetworkRequestType) {
    /** None
     */
    VSMNetworkRequestTypeNone = -1,
    /** StreamingVectorTile
     */
    VSMNetworkRequestTypeStreamingVectorTile,
    /** StreamingImageTile
     */
    VSMNetworkRequestTypeStreamingImageTile,
    /** AreaTile
     */
    VSMNetworkRequestTypeAreaTile,
    /** RouteTile
     */
    VSMNetworkRequestTypeRouteTile,
    /** EmbeddedMap
     */
    VSMNetworkRequestTypeEmbeddedMap,
    /** Config
     */
    VSMNetworkRequestTypeConfig,
    /** Resource
     */
    VSMNetworkRequestTypeResource,
    /** Traffic
     */
    VSMNetworkRequestTypTraffic,
    /** Accient
     */
    VSMNetworkRequestTypAccient,
};

/** 네트워크 다운로드 상태 프로토콜
 */
@protocol NetworkStatusDelegate <NSObject>

/** 다운로드 성공시
 * @param type 리퀘스트 타입
 * @param url 다운로드 URL
 * @param size 다운로드 사이즈(Byte)
 * @see VSMNetworkRequestType
 */
- (void)onNetworkDownloadSuccessed:(VSMNetworkRequestType)type url:(NSString *)url size:(NSUInteger)size;

/** 다운로드 실패시
 * @param type 리퀘스트 타입
 * @param url 다운로드 URL
 * @param size 다운로드 사이즈(Byte)
 * @param responseCode HTTP Response
 * @see VSMNetworkRequestType
 */
- (void)onNetworkDownloadFailed:(VSMNetworkRequestType)type url:(NSString *)url size:(NSUInteger)size responseCode:(NSUInteger)responseCode;

@end
