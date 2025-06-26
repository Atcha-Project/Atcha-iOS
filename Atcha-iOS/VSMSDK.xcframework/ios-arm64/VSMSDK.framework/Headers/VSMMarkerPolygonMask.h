//
//  VSMMarkerPolygonMask.h
//  VSMSDK_static
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/11/16.
//  Copyright © 2021 sktelecom. All rights reserved.
//

#import "VSMMarkerBase.h"
#import "VSMMapPoint.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  써클 마스크 마커 적용시 그라데이션 보간 정보
 */
@interface VSMGradientStop : NSObject

/**
 * 0~1 사이로 정규화된 원의 반경을 기준으로 보간 시작 구간을 의미합니다.
 * 보간 마지막 구간은 다음 VSMGradientStop가 가진 position입니다.
 */
@property(nonatomic, assign) float position;

/**
 * 보간 시작 색상. 보간 마지막 색상은 다음 VSMGradientStop가 가진 color입니다.
 */
@property(nonatomic, retain) UIColor* color;

/**
 * 생성 팩토리 메소드
 * @param position 정규화 보간 시작 구간
 * @param color 보간 시작 색상
 */
+(VSMGradientStop*) gradientStopWithPosition:(float)position color:(UIColor*)color;

@end

/**
 * 폴리곤 마스크 아이템
 */
@interface VSMMarkerPolygonMaskItem : NSObject

/**
 * points
 * 폴리곤 정점 좌표(WGS484)
 * @see VSMMapPoint
 */
@property(nonatomic, retain) NSArray<VSMMapPoint*>* points;

/**
 * 스플라인 보간 적용 여부 - 디폴트: NO
 */
@property(nonatomic, assign) BOOL spline;

/**
 * 테두리 두께(DP) - 디폴트: 1
 */
@property(nonatomic, assign) float strokeWidth;

/**
 * 테두리 색상
 */
@property(nonatomic, retain) UIColor* strokColor;

/**
 * 폴리곤 내부 글로우 효과 두께(DP) - 디폴트: 0
 * innerGlowSizeDP와 innerGlowSizeMeter는 단위만 다르고 같은 성분이므로 둘 중 하나의 값을 씁니다.
 * 둘다 값이 1이상인 경우는 innerGlowSizeMeter를 우선 적용.
 */
@property(nonatomic, assign) int innerGlowSizeDP;

/**
 * 폴리곤 내부 글로우 효과 두께(Meter) - 디폴트: 1
 * innerGlowSizeDP와 innerGlowSizeMeter는 단위만 다르고 같은 성분이므로 둘 중 하나의 값을 씁니다.
 * 둘다 값이 1이상인 경우는 innerGlowSizeMeter를 우선 적용.
 */
@property(nonatomic, assign) int innerGlowSizeMeter;

/**
 * 폴리곤 내부 글로우 외곽 알파 보간 값 - 디폴트: 1
 */
@property(nonatomic, assign) float innerGlowStartAlpha;

/**
 * 폴리곤 내부 글로우 내곽 알파 보간 값 - 디폴트: 0
 */
@property(nonatomic, assign) float innerGlowEndAlpha;

/**
 * 폴리곤 내부 글로우 효과 색상 - 디폴트: whiteColor
 */
@property(nonatomic, retain) UIColor* innerGlowColor;

@end

/**
 * 써클 마스크 아이템.
 */
@interface VSMMarkerCircleMaskItem : NSObject

/**
 * 원의 중심(WGS84)
 * @see VSMMapPoint
 */
@property(nonatomic, retain) VSMMapPoint* point;

/**
 * 원의 반지름(미터) - 디폴트: 100
 */
@property(nonatomic, assign) float radius;

/**
 * 원 내부 그라데이션 효과 속성 immutable array
 * @see VSMGradientStop
 */
@property(nonatomic, retain) NSArray<VSMGradientStop*>* fillGradients;

/**
 * 원 내부  색상
 */
@property(nonatomic, retain) UIColor* fillColor;


@end


/**
 * 폴리곤(써클) 마스크 마커 파라미터입니다.
 * 폴리곤 마스크 아이템과 써클 마스크 아이템을 혼재하여 여러게 가질 수 있습니다.
 */
@interface VSMMarkerPolygonMaskParams : VSMMarkerBaseParams

/**
 * 폴리곤/써클 마스크 아이템 immutable array
 * 반드시 VSMMarkerPolygonMaskItem 혹은 VSMMarkerCircleMaskItem으로만 구성되어야 합니다.
 * 아이템의 최대 갯수는 5개로 제한 합니다.
 * @see VSMMarkerPolygonMaskItem
 * @see VSMMarkerCircleMaskItem
 */
@property (nonatomic, retain) NSArray<NSObject*>* items;

/**
 * 폴리곤 영역 바깥 색상 - 디폴트: blueColor
 */
@property (nonatomic, retain) UIColor* outsideColor;

@end


/**
 * 폴리곤 및 써클 마스크 마커(오버레이) 클래스입니다.
 */
@interface VSMMarkerPolygonMask : VSMMarkerBase

/**
 * 폴리곤/써클 마스크 아이템 immutable array
 * 반드시 VSMMarkerPolygonMaskItem 혹은 VSMMarkerCircleMaskItem으로만 구성되어야 합니다.
 * 아이템의 최대 갯수는 5개로 제한 합니다.
 * @see VSMMarkerPolygonMaskItem
 * @see VSMMarkerCircleMaskItem
 */
@property (nonatomic, strong) NSArray<NSObject*>* items;

/**
 * 폴리곤 영역 바깥 색상
 */
@property (nonatomic, retain) UIColor* outsideColor;

/**
 * 초기화 메소드
 * @param markerID 마커 ID. 삭제/제어시 필요합니다.
 * @param params 초기화 파라미터
 * @see VSMMarkerPolygonMaskParams
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerPolygonMaskParams *)params;


@end

NS_ASSUME_NONNULL_END
