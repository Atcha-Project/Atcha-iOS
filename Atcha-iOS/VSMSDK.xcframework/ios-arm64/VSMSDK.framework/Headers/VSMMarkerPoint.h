//
//  VSMMarkerPoint.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 1. 25..
//

#import <UIKit/UIKit.h>

#import "VSMMarkerBase.h"
#import "MarkerImage.h"

/**
 * 포인트 마커 표출 타입
 */
typedef NS_ENUM(NSInteger, MarkerRenderType) {
    /** 아이콘만 표출
     */
    MarkerRender_SymbolOnly,
    /** 텍스트만 표출
     */
    MarkerRender_TextOnly,
    /** 모두 표출
     */
    MarkerRender_All
};

/**
 * 포인트 마커 겹침처리 허용 타입
 */
typedef NS_ENUM(NSInteger, MarkerOverlapAllowOption) {
    /** 허용하지 않음
     */
    MarkerOverlapAllow_None,
    /** 텍스트 허용
     */
    MarkerOverlapAllow_Text,
    /** 아이콘 허용
     */
    MarkerOverlapAllow_Icon
};

@class VSMMapPoint;

/** 포인트 마커 파라미터
 */
@interface VSMMarkerPointParams : VSMMarkerBaseParams

/** 마커가 위치할 좌표(WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** 마커에 표시할 텍스트
 */
@property (nonatomic, copy) NSString* text;

/** 마커 전용 아이콘 이미지
 * @see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* icon;

/** 아이콘 사이즈 - 디폴트:(-1, -1) 이미지 사이즈로 노출됩니다.
 */
@property (nonatomic, assign) CGSize iconSize;

/** 아이콘 앵커 - 디폴트:(0, 0)
 *  아이콘 내부 영역중 position좌표와 일치되는 정규화된 좌표. 좌상단은 (0, 0)이고 우상단은 (1, 1)입니다.
 */
@property (nonatomic, assign) CGPoint iconAnchor;

/** Text offset - 디폴트:(0, 0)
 * 마커 Position을 기준으로 텍스트 위치를 이동합니다. (DP 단위)
 */
@property (nonatomic, assign) CGPoint textOffset;

/** Marker Render Type - 디폴트: MarkerRender_SymbolOnly
 * 아이콘 / 텍스트 표출 여부를 결정합니다.
 * @see MarkerRenderType
 */
@property (nonatomic, assign) MarkerRenderType markerRenderType;
 
/** Fill color - 디폴트: blackColor
 * 내부 색상입니다.
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color - 디폴트: whiteColor
 * 테두리 색상입니다.
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width - 디폴트: 1
 * 테두리 두께 입니다. (DP)
 */
@property (nonatomic, assign) float strokeWidth;

/** Font Size - 디폴트:14
 *  표시될 글씨 크기를 결정합니다.
 */
@property (nonatomic, assign) float fontSize;

/**
 텍스트의 자간을 결정합니다. (default : 0)
 */
@property (nonatomic, assign) int32_t textTracking;

/** rotation - 디폴트: 0
 *  배치시 회전각을 의미합니다. (시계방향)
 */
@property (nonatomic, assign) float rotation;

/** coverPoi - 디폴트: NO
 * POI와 겹칠시 겹쳐진 POI를 삭제 시킬지 여부입니다.
 */
@property (nonatomic, assign) BOOL coverPoi;

/** grade - 디폴트: 0
 * poi와 겹침시 ranking값
 */
@property (nonatomic, assign) int32_t grade;

/** animationEnabled - 디폴트: YES
 * 마커가 나타나고 사라질 때, fade-in/out 효과 적용 여부입니다.
 */
@property (nonatomic, assign) BOOL animationEnabled;

/** overlapTestEnabled - 디폴트: NO
 * 마커간 충돌 검사를 진행할 지 여부입니다.
 */
@property (nonatomic, assign) BOOL overlapTestEnabled;

/**
 * 포인트 마커 겹침처리 허용 타입 - 디폴트: MarkerOverlapAllow_None
 * @see MarkerOverlapAllowOption
 */
@property (nonatomic, assign) MarkerOverlapAllowOption overlapAllowOption;

/** blockIconScale - 디폴트: YES
 *  Icon의 스케일 변경 수용 여부를 설정합니다.
 */
@property (nonatomic, assign) BOOL blockIconScale;

/** blockIconScale - 디폴트: NO
 *  Label의 스케일 변경 수용 여부를 설정합니다.
 */
@property (nonatomic, assign) BOOL blockLabelScale;

@end

/** 마커(오버레이) 포인트 클래스입니다.
 * 지도위에 점형의 오브젝트를 표시합니다.
 */
@interface VSMMarkerPoint : VSMMarkerBase

/** 마커가 위치할 좌표(WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** 마커에 표시할 텍스트
 */
@property (nonatomic, copy) NSString* text;

/** 마커 전용 아이콘 이미지
 * @see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* icon;

/** 아이콘 사이즈. 디폴트 (-1, -1): 이미지 기본 사이즈로 출력
 */
@property (nonatomic, assign) CGSize iconSize;

/** 아이콘 앵커
 *  아이콘 내부 영역중 position좌표와 일치되는 정규화된 좌표. 좌상단은 (0, 0)이고 우상단은 (1, 1)입니다.
 */
@property (nonatomic, assign) CGPoint iconAnchor;

/** Text offset
 * 마커 Position을 기준으로 텍스트 위치를 이동합니다. (DP 단위)
 */
@property (nonatomic, assign) CGPoint textOffset;

/** Marker Render Type - 디폴트: MarkerRender_SymbolOnly
 * 아이콘 / 텍스트 표출 여부를 결정합니다.
 * @see MarkerRenderType
 */
@property (nonatomic, assign) MarkerRenderType markerRenderType;

/** Fill color
 * 내부 색상입니다.
 */
@property (nonatomic, strong) UIColor* fillColor;

/** Stroke color
 * 테두리 색상입니다.
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** Stroke Width
 * 테두리 두께 입니다. (DP)
 */
@property (nonatomic, assign) float strokeWidth;

/** Font Size
 *  표시될 글씨 크기를 결정합니다.
 */
@property (nonatomic, assign) float fontSize;

/**
 텍스트의 자간을 결정합니다.
 */
@property (nonatomic, assign) int32_t textTracking;

/** rotation
 * 배치시 회전각을 의미합니다. (시계방향)
 */
@property (nonatomic, assign) float rotation;

/** 초기화 메소드
 * @param markerID 지정할 마커 ID. 삭제/제어시 필요합니다.
 * @param params 초기화 파라미터
 * @see VSMMarkerPointParams
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerPointParams*)params;

/** Cover ther poi
 * POI와 겹칠시 겹쳐진 POI를 삭제 시킬지 여부입니다.
 */
@property (nonatomic, assign) BOOL coverPoi;

/** poi와 겹침시 ranking값
 */
@property (nonatomic, assign) int32_t grade;

/** animationEnabled
 * 마커가 나타나고 사라질 때, fade-in/out 효과 적용 여부입니다.
 */
@property (nonatomic, assign) BOOL animationEnabled;

/** overlapTestEnabled
 * 마커간 충돌 검사를 진행할 지 여부입니다.
 */
@property (nonatomic, assign) BOOL overlapTestEnabled;

/**
 * 포인트 마커 겹침처리 허용 타입
 * @see MarkerOverlapAllowOption
 */
@property (nonatomic, assign) MarkerOverlapAllowOption overlapAllowOption;

/** blockIconScale
 *  Icon의 스케일 변경 수용 여부를 설정합니다.
 */
@property (nonatomic, assign) BOOL blockIconScale;

/** blockIconScale
 *  Label의 스케일 변경 수용 여부를 설정합니다.
 */
@property (nonatomic, assign) BOOL blockLabelScale;

@end
