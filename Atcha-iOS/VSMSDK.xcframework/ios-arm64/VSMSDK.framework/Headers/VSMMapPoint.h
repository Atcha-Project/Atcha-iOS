#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * WGS84 좌표를 갖고 있는 immutable 객체.
 * 각 위도, 경도를 double로 표현.
 */
@interface VSMMapPoint : NSObject

/**
 * WGS84 경도값
 * 입력 유효범위: -180 ~ 180
 * 기본값: NaN
 */
@property (nonatomic, assign, readonly) double longitude;

/**
 * WGS84 위도값
 * 유효범위: -90 ~ 90
 * 기본값: NaN
 */
@property (nonatomic, assign, readonly) double latitude;

/**
 * VSMMapPoint 생성 팩토리 메소드
 * @param longitude 경도
 * @param latitude 위도
 * @return VSMMapPoint
 */
+(instancetype)mapPointWithLongitude:(double)longitude
                            latitude:(double)latitude;

/**
 * VSMMapPoint 생성 메소드
 * @param longitude 경도
 * @param latitude 위도
 * @return VSMMapPoint
 */
-(instancetype)initWithLongitude:(double)longitude
                        latitude:(double)latitude;

/**
 * 비교함수
 * @param other 비교 대상인 VSMMapPoint
 * @return True(위도 경도가 모두 같은 경우) False(위도 경도가 다른 경우)
 */
-(BOOL)isEqual:(nullable id)other;

/**
 * 현재 가진 위경도 좌표의 유효성 검사 함수.
 * @return True(유효한 경우) False(유효하지 않은 경우)
 */
-(BOOL)checkValidity;

/**
 * VSMMapPoint INVALID 객체 생성
 * @return INVALID 객체
 */
+(VSMMapPoint*)INVALID;

@end

NS_ASSUME_NONNULL_END
