//
//  VSMMarkerPolyline.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 1. 25..
//

#import "VSMMarkerBase.h"
#import "MarkerImage.h"

@interface LineDashStyleData : NSObject
@property (nonatomic, assign) UInt8 lineDash1;
@property (nonatomic, assign) UInt8 lineDash2;
@property (nonatomic, assign) UInt8 lineDash3;
@property (nonatomic, assign) UInt8 lineDash4;
@end

@class UIColor;
@class UIImage;
@class VSMMapPoint;

/** 폴리라인 마커 파라미터
 */
@interface VSMMarkerPolylineParams : VSMMarkerBaseParams

/** 폴리라인 좌표(WGS84)들
 * @see VSMMapPoint
 */
@property (nonatomic, strong) NSArray<VSMMapPoint*>* points;

/** Fill color - 디폴트: (1, 48/255, 48/255, 1)
 *  선 색상
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color - 디폴트: (1, 1, 1, 153/255)
 *  선 테두리 색상
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width - 유효범위: 0이상 디폴트: 1
 *  선 테두리 두께
 */
@property (nonatomic, assign) float strokeWidth;

/** Line width - 유효범위: 0이상 디폴트: 1
 *  선 두께
 */
@property (nonatomic, assign) float lineWidth;

/** lineDash 디폴트
  *   lineDash.lineDash1 = 0
  *   lineDash.lineDash2 = 0
  *   lineDash.lineDash3 = 0
  *   lineDash.lineDash4 = 0
  * 폴리라인 선의 패턴을 결정합니다.
  *@see LineDashStyleData
 */
@property (nonatomic, copy) LineDashStyleData* lineDash;

/** 마커 전용 아이콘 이미지
 *@see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* icon;

@end

/** 폴리라인 마커(오버레이) 클래스
 * 지도 위에 폴리라인을 그립니다.
 */
@interface VSMMarkerPolyline : VSMMarkerBase

/** 폴리라인 좌표(WGS84)들
 *@see VSMMapPoint
 */
@property (nonatomic, strong) NSArray<VSMMapPoint*>* points;

/** Fill color
 * 선 색상
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color
 *  선 테두리 색상
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width
 *  선 테두리 두께
 */
@property (nonatomic, assign) float strokeWidth;

/** Line width
 *  선 두께
 */
@property (nonatomic, assign) float lineWidth;

/** Line Dash Style
 * 폴리라인 선의 패턴을 결정합니다.
 * @see LineDashStyleData
 */
@property (nonatomic, copy) LineDashStyleData* lineDash;

/** 마커 전용 아이콘 이미지
 *@see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* icon;

/**
 * 초기화 메소드
 * @param markerID 마커ID. 삭제/제어시 필요합니다.
 * @param params 초기화 파라미터
 * @see VSMMarkerPolylineParams
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerPolylineParams*)params;

@end
