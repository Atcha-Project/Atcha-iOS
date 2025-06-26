//
//  VSMMarker.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 1. 25..
//

#import <Foundation/Foundation.h>
#import <UIKit/UIColor.h>

/**
 * 마커 렌더 순서
 */
typedef NS_ENUM(NSInteger, MarkerRenderOrder) {
    /** 2D 이전
     */
    RENDERING_ORDER_BEFORE_2D           = 0,
    /** 2D 이후
     */
    RENDERING_ORDER_AFTER_2D            = 1,
    /** 3D 이전
     */
    RENDERING_ORDER_BEFORE_3D           = 2,
    /** 3D 이후
     */
    RENDERING_ORDER_AFTER_3D            = 3,
    /** POI 이전
     */
    RENDERING_ORDER_BEFORE_POI          = 4,
    /** POI 이후
     */
    RENDERING_ORDER_AFTER_POI           = 5,
    /** 포인트 마커 이전
     */
    RENDERING_ORDER_BEFORE_POINT_MARKER = 6,
    /** 포인트 마커
     */
    RENDERING_ORDER_POINT_MARKER        = 7,
    /** 포인트 마커 이후
     */
    RENDERING_ORDER_AFTER_POINT_MARKER  = 8
};


/** 마커 공통 속성 파라미터
 */
@interface VSMMarkerBaseParams : NSObject

/** Visible 여부
 */
@property (nonatomic, assign) BOOL visible;

/** Touch 지원 여부
 */
@property (nonatomic, assign) BOOL touchable;

/** Show priority - 디폴트: 9999
 */
@property (nonatomic, assign) float showPriority;

/** renderOrder - 유효범위: 0(RENDERING_ORDER_BEFORE_2D) ~ 8(RENDERING_ORDER_AFTER_POINT_MARKER) 디폴트: 7(RENDERING_ORDER_POINT_MARKER)
 */
@property (nonatomic, assign) uint32_t renderOrder;

/** minViewLevel - 유효범위: 0 ~ 23 디폴트: 0
 */
@property (nonatomic, assign) uint32_t minViewLevel;

/** maxViewLevel - 유효범위: 0 ~ 23 디폴트: 23
 */
@property (nonatomic, assign) uint32_t maxViewLevel;


+ (UIColor*) defaultFillColor;

+ (UIColor*) defaultStrokeColor;

@end

/** 마커(오버레이) 공통 클래스
 * 마커(오버레이) 란 완전하게 지도 위에 그려지는 객체로서, 지도의 어떤 요소로도 가려지지 않으며, 추가/삭제를 자유롭게 할 수 있습니다.
 * 예) 경로 그리기, 팝업 띄우기, 2D/3D 오브젝트 띄우기 등
 */
@interface VSMMarkerBase : NSObject

/** 마커 아이디 생성
 * @return 생성 ID
 */
+ (NSString*)getAutoID;

/** 초기화 메소드
 * @param markerID 마커ID
 * @param params 초기화 파라미터
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerBaseParams*)params;

/** 마커 ID. 삭제/제어시 필요합니다.
 */
@property (nonatomic, copy, readonly) NSString* markerID;

/** 내부 ID.
 */
@property (nonatomic, assign, readonly) NSUInteger objectId;

/**
 * 태그를 사용하여 개체를 이 마커와 연결할 수 있습니다.
 * 메모리 누수를 방지하려면 setTag(null)를 호출해야 합니다.
 */
@property (nonatomic, strong) NSObject* tag;

/** Visible - 디폴트:YES
 */
@property (nonatomic, assign) BOOL visible;

/** touchable - 디폴트:YES
 */
@property (nonatomic, assign) BOOL touchable;

/** showPriority (Marker간 z-order) 디폴트: 9999
 */
@property (nonatomic, assign) float showPriority;

/** renderOrder 디폴트: 7
 */
@property (nonatomic, assign) uint32_t renderOrder;

/**
 * minViewLevel - 디폴트: 0
 * 표출 최소 레벨입니다.
 * minViewLevel <= maxViewLevel이 성립하는지 주의해야 합니다.
 */
@property (nonatomic, assign) uint32_t minViewLevel;

/**
 * maxViewLevel - 디폴트: 23
 * 표출 최대 레벨입니다.
 * minViewLevel <= maxViewLevel이 성립하는지 주의해야 합니다.
 */
@property (nonatomic, assign) uint32_t maxViewLevel;

/**
 * 표출 최소/최대 뷰 레벨 설정합니다.
 * @param minViewLevel 표출 최소 뷰 레벨
 * @param maxViewLevel 표출 최대 뷰 레벨
 */
- (void)setViewLevel:(NSUInteger)minViewLevel maxViewLevel:(NSUInteger)maxViewLevel;

/**
 * 기본 최소 뷰 레벨 반환
 * @return 기본 최소 뷰 레벨
 */
+(NSUInteger) defaultMinViewLevel;

/**
 * 기본 최대 뷰 레벨 반환
 * @return 기본 최대 뷰 레벨
 */
+(NSUInteger) defaultMaxViewLevel;


@end
