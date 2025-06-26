#import <Foundation/Foundation.h>
#import "VSMLocationProviderDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class VSMMapView;
@class VSMLocation;
@class VSMLocationComponent;

/**
 *지속적으로 현 위치를 관리하고 최신화하는 클래스입니다.
 */
@interface VSMLocationManager : NSObject

/** 지도에 설정된 마지막 위치 정보
 * @see VSMLocation
 */
@property (atomic, strong, readonly) VSMLocation* lastLocation;

/** 현위치의 스타일을 변경할 수 있는 객체
 *  @see VSMLocationComponent
 */
@property (nonatomic, strong, readonly) VSMLocationComponent* locationComponent;

/** 현위치 업데이트를 위한 VSMLocationProvider
 * @see VSMLocationProviderDelegate
 */
@property (atomic, weak, nullable) id<VSMLocationProviderDelegate> locationProviderDelegate;

/**
 * 초기화 메소드
 * @param mapView 지도 뷰
 * @see VSMMapView
*/
-(instancetype)initWithMapView:(VSMMapView*)mapView;

/** Internal Use Only
*/
-(void)updateLocation;

/** Internal Use Only
*/
-(void)destroy;

@end

NS_ASSUME_NONNULL_END
