#import <Foundation/Foundation.h>

@interface VSMCameraConfig : NSObject

/**
 * 줌 레벨 갯수
 */
@property (class, nonatomic, readonly) int LEVEL_COUNT;

/**
 * 각 레벨 별 최대 기울기 각도
 */
@property (nonatomic, strong, readonly) NSArray<NSNumber *> *max3dAngles;

/**
 * 기본 생성자
 */
- (instancetype)init;

- (void)setMax3dAngles:(NSArray<NSNumber *> *)max3dAngles;
@end
