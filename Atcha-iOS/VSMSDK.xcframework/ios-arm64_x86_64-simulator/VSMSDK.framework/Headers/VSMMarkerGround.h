//
//  VSMMarkerGround.h
//  VSMInterface
//

#import "VSMMarkerBase.h"
#import "MarkerImage.h"

@class VSMMapBounds;

/**
 * 그라운드 마커 초기화를 위한 파라미터
 */
@interface VSMMarkerGroundParams : VSMMarkerBaseParams

/** 마커의 지도 영역 (WGS84)
 * @see VSMMapBounds
 */
@property (nonatomic, strong) VSMMapBounds* bounds;

/** 마커의 이미지
 * @see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* image;

@end

/**
 * 지도 위 특정 영역에 이미지를 나타내는 마커(오버레이) 클래스.
 */
@interface VSMMarkerGround : VSMMarkerBase

/** 마커의 지도 영역 (WGS84)
 * @see VSMMapBounds
 */
@property (nonatomic, strong) VSMMapBounds* bounds;

/** 마커의 이미지
 * @see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* image;

/**
 * 초기화 메소드
 * @param markerID 마커ID. 삭제/제어시 필요합니다.
 * @param params 초기화 파라미터
 * @see VSMMarkerGroundParams
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerGroundParams *)params;

@end
