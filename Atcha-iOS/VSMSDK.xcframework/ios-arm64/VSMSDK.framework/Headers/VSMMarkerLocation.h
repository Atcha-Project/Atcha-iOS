#import <UIKit/UIKit.h>

#import "VSMMarkerBase.h"
#import "VSMMarkerPolyline.h"
#import "MarkerImage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 로케이션 마커 렌더 모드
 */
typedef NS_ENUM(NSInteger, LocationMarkerRenderMode)
{   /**
     * 그라운드
     */
    LocationMarkerRenderMode_Ground = 0,
    /**
     * 빌보드
     */
    LocationMarkerRenderMode_Billboard = 1
};

@class VSMMapPoint;


/**
 * 3D 위치 마커를 위한 파라미터에 사용되는 경로 정보입니다.
 */
@interface VSMMarkerLocation3DObjectResourceInfo : NSObject
/**
 * 3D 위치 마커를 위한 파라미터에 사용되는 경로 정보 팩토리 메소드
 * @param packageCode 서버상의 패키지 코드
 * @param resourceCode 서버상의 리소스 코드
 */
+ (instancetype)location3DObjectResourceInfoWithPackageCode:(nonnull NSString*)packageCode
                                               resourceCode:(nonnull NSString*)resourceCode;
@end



/**
 * 3D 위치 마커를 위한 파라미터입니다.
 */
@interface VSMMarkerLocation3DObject : NSObject

/** 패키지 코드. 서버로 부터 내려 받을 패키지/리소스 코드 정보입니다.
 * @see VSMMarkerLocation3DObjectResourceCode
 */
@property (nonatomic, strong) VSMMarkerLocation3DObjectResourceInfo* resourceInfo;

/** 부가 텍스처 (Optional)
 */
@property (nonatomic, strong, nullable) NSString* optionalTexturePath;

@end



/** 위치 마커 아이콘
 */
@interface VSMMarkerLocationIcon : NSObject

/** Icon
 *@see MarkerImage
 */
@property (nonatomic, strong, nullable) MarkerImage* icon;

/** Icon3D
 *@see MarkerImage
 */
@property (nonatomic, strong, nullable) MarkerImage* icon3D;

@end

/**
 * 위치 가이드 라인 스타일
 */
@interface VSMMarkerLocationGuideStyle : NSObject

/** fillColor - 디폴트: blueColor
 * 색상
 */
@property (nonatomic, strong) UIColor* fillColor;

/** strokeColor - 디폴트: clearColor
 * 테두리 색상
 */
@property (nonatomic, strong) UIColor* strokeColor;

/** width - 디폴트: 1
 */
@property (nonatomic, assign) float width;

/** strokeWidth - 디폴트: 0
 */
@property (nonatomic, assign) float strokeWidth;

/** lineDash 디폴트
 *   lineDash.lineDash1 = 5
 *   lineDash.lineDash2 = 5
 *   lineDash.lineDash3 = 5
 *   lineDash.lineDash4 = 5
 *
 *   @see LineDashStyleData
 */
@property (nonatomic, copy) LineDashStyleData* lineDash;

@end

/**
 * 위치 마커 파라미터
 */
@interface VSMMarkerLocationParams : VSMMarkerBaseParams

/** Position (WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** Icon
 * @see VSMMarkerLocationIcon
 */
@property (nonatomic, strong) VSMMarkerLocationIcon* icon;


/** RenderMode 디폴트값:LocationMarkerRenderMode_Ground
 * @see LocationMarkerRenderMode
 */
@property (nonatomic, assign) LocationMarkerRenderMode renderMode;

/** IconSize - 디폴트:(0, 0)
 */
@property (nonatomic, assign) CGSize iconSize;

/** bearing - 디폴트: 0
 * 회전 각(Degree)
 */
@property (nonatomic, assign) float bearing;

/** showGuide - 디폴트:NO
 * 현위치가 지도 밖으로 벗어나는 경우 가이드선 출력 여부.
 */
@property (nonatomic, assign) BOOL showGuide;

/** 가이드 선 스타일
 * @see VSMMarkerLocationGuideStyle
 */
@property (nonatomic, strong) VSMMarkerLocationGuideStyle* guideStyle;

/** 3D 모델 정보
 * @see VSMMarkerLocation3DObject
 */
@property (nonatomic, strong) VSMMarkerLocation3DObject* object3D;

/** 3D 모델 중 표시하지 않을 Mesh 목록
 */
@property (nonatomic, nonatomic) NSArray<NSString*>* object3DFilterOut;

/** 3D 모델 중 Hit영역에 포함되지 않을 Mesh 목록
 */
@property (nonatomic, nonatomic) NSArray<NSString*>* object3DHitBoundsFilterOut;

@end

/** 위치 마커(오버레이) 클래스
 * 지도위에 현재 위치한 지점을 2D/3D모형으로 표출합니다.
 */
@interface VSMMarkerLocation : VSMMarkerBase

/** Position (WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** Icon
 *@see VSMMarkerLocationIcon
 */
@property (nonatomic, strong) VSMMarkerLocationIcon* icon;


/**  3D 모델
 * @see VSMMarkerLocation3DObject
 */
@property (nonatomic, strong) VSMMarkerLocation3DObject* object3D;

/** 3D 모델 중 표시하지 않을 Mesh 목록
 */
@property (nonatomic, nonatomic) NSArray<NSString*>* object3DFilterOut;

/** 3D 모델 중 Hit영역에서 제외 될  Mesh 목록
 */
@property (nonatomic, nonatomic) NSArray<NSString*>* object3DHitBoundsFilterOut;

/** RenderMode 디폴트값:LocationMarkerRenderMode_Ground
 * @see LocationMarkerRenderMode
 */
@property (nonatomic, assign) LocationMarkerRenderMode renderMode;

/** Icon Width/Height
 */
@property (nonatomic, assign) CGSize iconSize;

/** bearing
 * 회전 각(Degree)
 */
@property (nonatomic, assign) float bearing;

/** showGuide
 * 현위치가 지도 밖으로 벗어나는 경우 가이드선 출력 여부.
 */
@property (nonatomic, assign) BOOL showGuide;

/** 가이드 선 스타일
 *@see VSMMarkerLocationGuideStyle
 */
@property (nonatomic, strong) VSMMarkerLocationGuideStyle* guideStyle;


/** 초기화 메소드
 * @param markerID 마커ID. 삭제/제어시 필요합니다.
 * @param params 초기화 파라미터
 * @see VSMMarkerLocationParams
 */
- (id)initWithID:(NSString*)markerID params:(VSMMarkerLocationParams*)params;

@end

NS_ASSUME_NONNULL_END
