//
//  VSMMarkerPolygon.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 1. 25..
//

#import "VSMMarkerBase.h"

@class UIColor;
@class VSMMapPoint;

/**
 * 폴리곤 마커 초기화를 위한 파라미터
 */
@interface VSMMarkerPolygonParams : VSMMarkerBaseParams

/** 폴리곤 좌표(WGS84)들
 *@see VSMMapPoint
 */
@property (nonatomic, strong) NSArray<VSMMapPoint*>* points;

/** Fill color - 디폴트: (1, 48/255, 48/255, 1)
 * 내부 색상
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color - 디폴트: (1, 1, 1, 153/255)
 * 테두리 색상
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width - 유효범위: 0이상 디폴트: 1
 * 테두리 두께
 */
@property (nonatomic, assign) float strokeWidth;

@end

/** 폴리곤 마커(오버레이) 클래스.
 * 지도위에 폴리곤을 그립니다.
 */
@interface VSMMarkerPolygon : VSMMarkerBase

/** 폴리곤 좌표(WGS84)들
 * @see VSMMapPoint
 */
@property (nonatomic, strong) NSArray<VSMMapPoint*>* points;

/** Fill color
 * 내부 색상
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color
 * 테두리 색상
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width - 유효범위: 0이상
 * 테두리 두께
 */
@property (nonatomic, assign) float strokeWidth;

/**
 * 초기화 메소드
 * @param markerID 마커ID. 삭제/제어시 필요합니다.
 * @param params 초기화 파라미터
 * @see VSMMarkerPolygonParams
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerPolygonParams *)params;

@end
