#import <Foundation/Foundation.h>

@class VSMLocation;

/**
 * 현위치 제공 프로토콜
 */
@protocol VSMLocationProviderDelegate <NSObject>
/**
 * 현위치를 리턴합니다. 현위치를 얻지 못한 경우 nil을 반환합니다.
 * @see VSMLocation
 */
- (nullable VSMLocation*) getLocation;

@end
