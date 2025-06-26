#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 위치 정보를 갖고 있는 immutable 객체
 */
@interface VSMLocation : NSObject

/**
 * WGS84 경도
 */
@property (nonatomic, assign, readonly) double longitude;

/**
 * WGS84 위도
 */
@property (nonatomic, assign, readonly) double latitude;

/**
 * 방향 각도
 */
@property (nonatomic, assign, readonly) float bearing;

/**
 * 정확도(미터 단위)
 */
@property (nonatomic, assign, readonly) float accuracy;

/**
 * 새로운 VSMLocation 객체를 생성합니다.
 * @param longitude 경도
 * @param latitude 위도
 * @param bearing 방향 각도
 * @param accuracy 정확도 (미터 단위)
 */
-(instancetype)initWithLongitude:(double)longitude
                        latitude:(double)latitude
                         bearing:(float)bearing
                        accuracy:(float)accuracy;

-(BOOL)isEqual:(nullable id)other;

/**
 * 위치를 비교합니다.
 * @see VSMLocation
 */
-(BOOL)isEqualToLocation:(VSMLocation*)location;

@end

NS_ASSUME_NONNULL_END
