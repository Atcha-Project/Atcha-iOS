#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 색상 변환 유틸
 */
@interface VSMColorUtil : NSObject

/**
 * ARGB UInt To UIColor
 * @param color ARGB값
 * @return UIColor
 */
+(UIColor*)UIColorFromARGB:(uint32_t)color;

@end

NS_ASSUME_NONNULL_END
