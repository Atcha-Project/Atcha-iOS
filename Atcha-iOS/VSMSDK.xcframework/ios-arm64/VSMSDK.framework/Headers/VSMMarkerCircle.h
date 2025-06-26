//
//  VSMMarkerCircle.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 1. 25..
//

#import "VSMMarkerBase.h"

@class VSMMapPoint;
@class UIColor;

/**
 * 원을 표시 하는 마커 파라미터입니다.
 */
@interface VSMMarkerCircleParams : VSMMarkerBaseParams

/** Position
 *  원의 중심 좌표 (WGS84)
 *  @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** radius - 유효범위: 0 ~ 300000 기본값: 0
 */
@property (nonatomic, assign) float radius;

/** visibleRadius - 디폴트: NO
 */
@property (nonatomic, assign) BOOL visibleRadius;

/** Fill color - 디폴트: (1, 48/255, 48/255, 1)
 * 원 내부 색상
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color - 디폴트: (1, 1, 1, 153/255)
 * 원 테두리 색상
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width - 디폴트: 1
 * 원 테두리 두께
 */
@property (nonatomic, assign) float strokeWidth;

@end

/**
 * 지도위에 원을 표시 하는 마커(오버레이) 클래스입니다.
 */
@interface VSMMarkerCircle : VSMMarkerBase

/** Position
 * 원의 중심 좌표 (WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** radius - 유효범위: 0 ~ 300000
 */
@property (nonatomic, assign) float radius;

/** visibleRadius
 */
@property (nonatomic, assign) BOOL visibleRadius;

/** Fill color
 * 원 내부 색상
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color
 * 원 테두리 색상
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width
 * 원 테두리 두께
 */
@property (nonatomic, assign) float strokeWidth;

/**
 * 초기화 메소드
 * @param markerID 마커 ID. 삭제/제어시 필요합니다.
 * @param params 초기화 파라미터
 * @see VSMMarkerCircleParams
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerCircleParams*)params;

@end
