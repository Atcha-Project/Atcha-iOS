#import "VSMLocation.h"

NS_ASSUME_NONNULL_BEGIN

/** 경로에 매칭된 위치 정보를 갖는 객체
 */
@interface VSMMatchedLocation : VSMLocation

/** 맵매칭된 경로 vertex index
 */
@property (nonatomic, assign, readonly) int32_t index;

/** 맵매칭에 사용된 경로의 id
 */
@property (nonatomic, assign, readonly) int32_t routeId;

/**
 * 새로운 VSMMatchedLocation 객체를 생성합니다.
 * @param longitude 경도
 * @param latitude 위도
 * @param bearing 방향 각도
 * @param accuracy 정확도 (미터 단위)
 * @param index 맵매칭된 경로 vertex index
 * @param routeId 맵매칭에 사용된 경로의 id
 */
-(instancetype)initWithLongitude:(double)longitude
                        latitude:(double)latitude
                         bearing:(float)bearing
                        accuracy:(float)accuracy
                           index:(int32_t)index
                         routeId:(int32_t)routeId;

/**
 * 새로운 VSMMatchedLocation 객체를 생성합니다.
 * @param longitude 경도
 * @param latitude 위도
 * @param bearing 방향 각도
 * @param accuracy 정확도 (미터 단위)
 */
-(instancetype)initWithLongitude:(double)longitude
                        latitude:(double)latitude
                         bearing:(float)bearing
                        accuracy:(float)accuracy;

/**
 * 새로운 VSMMatchedLocation 객체를 생성합니다.
 * @param location 위치 정보 객체
 * @seee VSMLocation
 */
-(instancetype)initWithLocation:(VSMLocation*)location;

/*
 * 객체 동일성 비교를 합니다.
 * 위치, 경로 인덱스, 경로ID를 비교합니다.
 */
-(BOOL)isEqual:(nullable id)other;

@end

NS_ASSUME_NONNULL_END
