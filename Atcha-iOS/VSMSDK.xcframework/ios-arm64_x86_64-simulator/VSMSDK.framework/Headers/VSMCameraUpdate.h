//
//  VSMCameraUpdate.h
//  VSMSDK_static
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/06/29.
//  Copyright © 2021 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VSMMapPoint.h"
#import "VSMMapBounds.h"
#import "VSMMapViewDefine.h"


/**
 * 맵 카메라 이동 Dirty Flag
 */
typedef NS_ENUM(NSInteger, VSMCameraUpdateDirty) {
    /** Center
     */
	VSMCameraUpdateDirtyCenter 		= 1 << 0,
    /** Zoom
     */
	VSMCameraUpdateDirtyZoom   		= 1 << 1,
    /** Angle
     */
	VSMCameraUpdateDirtyAngle  		= 1 << 2,
    /** Tilt
     */
	VSMCameraUpdateDirtyTilt   		= 1 << 3,
    /** Animation
     */
	VSMCameraUpdateDirtyAnimation   = 1 << 4,
    /** MBRBounds (FitBounds)
     */
	VSMCameraUpdateDirtyMBRBounds   = 1 << 5,
    /** Scale
     */
    VSMCameraUpdateDirtyFocusScale  = 1 << 6
};


/**
 * center, zoom, tilt, angle를 동시 설정하는 VSMCameraUpdate 인스턴스를 만들기 위한 속성입니다.
 */
@interface VSMCameraPosition : NSObject

/**
 * 생성 팩토리 메소드
 * @param center 지도 중앙이 위치할 WGS84 좌표
 * @param zoom 지도 뷰레벨
 * @param tilt 버드뷰를 위한 X축 회전각(Degree)
 * @param angle 지도 평면 회전을 위한 Z축 회전각(Degree)
 * @see VSMMapPoint
 */
+ (nullable instancetype)cameraPositionWithCenter:(nonnull VSMMapPoint*)center zoom:(double)zoom tilt:(double)tilt angle:(double)angle;

/**
 *지도 중앙이 위치할 WGS84 좌표
 *@see VSMMapPoint
 */
@property(nonatomic, assign) VSMMapPoint*_Nonnull center;

/**
 *지도 뷰레벨
 */
@property(nonatomic, assign) double zoom;

/**
 *버드뷰를 위한 X축 회전각(Degree)
 */
@property(nonatomic, assign) double tilt;

/**
 *지도 평면 회전을 위한 Z축 회전각(Degree)
 */
@property(nonatomic, assign) double angle;

/**
 *변경사항 Dirty. ReadOnly
 *@see VSMCameraUpdateDirty
 */
@property(nonatomic, assign, readonly) uint32_t dirty;

@end


/**
 * 지도 이동시 에니메이션 구조체입니다.
 * easing함수
 * 변형 완료까지의 지속시간(ms)
 */
typedef struct VSMAnimationInfo {
	VSMCameraUpdateAnimation easing;
	UInt32 duration;
} VSMAnimationInfo;


#ifdef __cplusplus
extern "C" {
#endif

VSMAnimationInfo VSMAnimationInfoMake(VSMCameraUpdateAnimation animation, UInt32 duration);


#ifdef __cplusplus
}
#endif

/**
 * VSMMapeView의 moveCamera를 통해서 기본변형(center, zoom, rotate, tilt)이나 fitBounds를 수행할 수 있도록 하는 클래스입니다.
 * 불변 인스턴스를 지향. pivot  property를 제외한 모든 property는 팩토리 메소드에 한 인스턴스 생성시 단 한번 결정되며, 그 이후로는 불변입니다.
 * pivot property를 제외하고 설정되지 않은 프로퍼티에 대해선 기본값을 쓰지 않고 변형요소에서 제외합니다.
 */
@interface VSMCameraUpdate : NSObject

/**
 * 지정한 좌표로 지도 중심을 이동하는 VSMCameraUpdate 객체를 생성합니다.
 * @param center 지도 중심이 될 WGS84좌표입니다.
 * @see VSMMapPoint
 */
+ (nullable instancetype)cameraUpdateWithCenter:(nonnull VSMMapPoint*)center;

/**
 * 에니메이션과 함께 지정한 좌표로 지도 중심을 이동하는 VSMCameraUpdate 객체를 생성합니다.
 * @param center 지도 중심이 될 WGS84좌표입니다.
 * @param animation 지도 변형시 에니메이션 정보입니다.(Easing, Duration)
 * @see VSMMapPoint
 */
+ (nullable instancetype)cameraUpdateWithCenter:(nonnull VSMMapPoint*)center animation:(VSMAnimationInfo)animation;

/**
 * 지정한 Delta(screen 좌표계) 만큼 이동하는 VSMCameraUpdate 객체를 생성합니다.
 * @param delta 이동해야 할 스크린 좌표계 거리입니다.
 */
+ (nullable instancetype)cameraUpdateWithScreenDelta:(CGPoint)delta;

/**
 * 에니메이션과 함께 지정한 Delta(screen 좌표계) 만큼 이동하는 VSMCameraUpdate 객체를 생성합니다.
 * @param delta 이동해야 할 스크린 좌표계 거리입니다.
 * @param animation 지도 변형시 에니메이션 정보입니다. (Easing, Duration)
 */
+ (nullable instancetype)cameraUpdateWithScreenDelta:(CGPoint)delta animation:(VSMAnimationInfo)animation;


/**
 * zoom(뷰레벨 변경) 하는 데이터 반환입니다.
 * @param zoom 뷰레벨입니다.
 */
+ (nullable instancetype)cameraUpdateWithZoom:(double)zoom;

/**
 * 에니메이션과 함께 zoom(뷰레벨 변경)하는 VSMCameraUpdate 객체를 생성합니다.
 * @param zoom 뷰레벨입니다.
 * @param animation 지도 변형시 에니메이션 정보입니다. (Easing, Duration)
 */
+ (nullable instancetype)cameraUpdateWithZoom:(double)zoom animation:(VSMAnimationInfo)animation;

/**
 * 지정한 좌표로 center이동 및 zoom하는 VSMCameraUpdate 객체를 생성합니다.
 * @param center 지도 중심이 될 WGS84좌표입니다.
 * @param zoom 뷰레벨입니다.
 * @see VSMMapPoint
 */
+ (nullable instancetype)cameraUpdateWithCenter:(nonnull VSMMapPoint *)center zoom:(double)zoom;


/**
 * 지정한 포커스 스크린좌표를 기준으로 확대 / 축소 하는 VSMCameraUpdate 객체를 생성합니다.
 * @param scale 현상태와의 상대적 배율. 1입력시 변함 없습니다.
 * @param focus 포커싱 지점입니다.
 */
+ (nullable instancetype)cameraUpdateWithScale:(double)scale focus:(CGPoint)focus;


/**
 * 에니메이션과 함께 지정한 좌표로 center이동 및 zoom하는 데이터 반환합니다.
 * @param center 지도 중심이 될 WGS84좌표입니다.
 * @param zoom 뷰레벨입니다.
 * @param animation 지도 변형시 에니메이션 정보입니다. (Easing, Duration)
 * @see VSMMapPoint
 */
+ (nullable instancetype)cameraUpdateWithCenter:(nonnull VSMMapPoint *)center zoom:(double)zoom animation:(VSMAnimationInfo)animation;


/**
 * 지정된 bounds가 온전히 보이는 좌표와 최대 줌 레벨로 카메라의 위치를 변경하는 VSMCameraUpdate 객체를 생성합니다.
 * @param bounds 스크린과 맞닿을 WGS84 사각영역입니다.
 * @see VSMMapBounds
 */
+ (nullable instancetype)cameraUpdateWithFitBounds:(nonnull VSMMapBounds *)bounds;

/**
 * 에니메이션과 함께 지정된 bounds가 온전히 보이는 좌표와 최대 줌 레벨로 카메라의 위치를 변경하는 VSMCameraUpdate 객체를 생성합니다.
 * @param bounds 스크린 꼭지점과 맞닿을 WGS84 사각영역입니다.
 * @param animation 지도 변형시 에니메이션 정보입니다. (Easing, Duration)
 * @see VSMMapBounds
 */
+ (nullable instancetype)cameraUpdateWithFitBounds:(nonnull VSMMapBounds *)bounds animation:(VSMAnimationInfo)animation;

/**
 * 지정된 CameraPosition으로 변형하는 데이터 반환
 * @param cameraPosition 전반적인 지도 변형 정보입니다.
 * @see VSMCameraPosition
 */
+ (nullable instancetype)cameraUpdateWithCameraPosition:(nullable VSMCameraPosition*)cameraPosition;

/**
 * 에니메이션과 함께 지정된 CameraPosition으로 변형하는 데이터 반환
 * @param cameraPosition 전반적인 지도 변형 정보입니다.
 * @param animation 지도 변형시 에니메이션 정보입니다. (Easing, Duration)
 * @see VSMCameraPosition
 */
+ (nullable instancetype)cameraUpdateWithCameraPosition:(nullable VSMCameraPosition*)cameraPosition animation:(VSMAnimationInfo)animation;


/**
 * 지도 중앙이 위치할 WGS84 좌표
 * @see VSMMapPoint
 */
@property(nonatomic, retain, readonly) VSMMapPoint*_Nonnull center;

/**
 * 지도 뷰레벨
 */
@property(nonatomic, assign, readonly) double zoom;

/**
 *지도 평면 회전을 위한 Z축 회전각(Degree)
 */
@property(nonatomic, assign, readonly) double angle;

/**
 *버드뷰를 위한 X축 회전각(Degree)
 */
@property(nonatomic, assign, readonly) double tilt;

/**
 * 지도 변형시 에니메이션 정보- easing, duration(ms)
 */
@property(nonatomic, assign, readonly) VSMAnimationInfo animation;

/**
 * screenMoveDelta 값 적용 여부입니다.
 * True:  카메라를 현재 위치에서 지정한 값(스크린 좌표계) 만큼 상대적으로 이동합니다. (screenMoveDelta 이용)
 * False: 지도 좌표 기반 절대적 이동을 하거나 (center 이용) or 이동이 없음을 의미합니다.
 */
@property(nonatomic, assign, readonly) BOOL isMoveScreenDelta;

/**
 * 카메라를 현재 위치에서 지정한 값(스크린 좌표계)만큼 상대적으로 이동하도록 하는 값입니다.
 */
@property(nonatomic, assign, readonly) CGPoint screenMoveDelta;

/**
 * MBR(Minimum Bounding Rectangle) 사각 영역.
 * FitBounds를 통한 팩토리 메소드로 인해 결정됩니다.
 * @see VSMMapBounds
 */
@property(nonatomic, retain, readonly) VSMMapBounds*_Nonnull mbrBounds;

/**
 * 성분별 dity 상태
 * @see VSMCameraUpdateDirty
 */
@property(nonatomic, assign, readonly) uint32_t dirty;

/**
 * 스케일/포커싱시 포커싱될 스크린 좌표
 */
@property(nonatomic, assign, readonly) CGPoint scaleFocus;

/**
 * 스케일/포커싱시 현상태와의 상대적 배율
 */
@property(nonatomic, assign, readonly) double scale;

@end

