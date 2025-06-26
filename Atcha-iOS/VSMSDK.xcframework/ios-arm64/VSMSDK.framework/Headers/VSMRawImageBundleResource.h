#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 바이너리 이미지 번들 내부의 이미지 참조 정보입니다.
 */
@interface VSMRawImageBundleResource : NSObject

/**
 * 이미지 코드명
 */
@property (nonatomic, strong, readonly) NSString* code;

/**
 * 번들 바이너리내 해당 이미지의 바이너리 시작 위치
 */
@property (nonatomic, assign, readonly) int offset;

/**
 * 바이너리 사이즈
 */
@property (nonatomic, assign, readonly) int size;

/**
 * 이미지 너비
 */
@property (nonatomic, assign, readonly) int width;

/**
 * 이미지 높이
 */
@property (nonatomic, assign, readonly) int height;

/**
 * 초기화 메소드
 * @param nativeClass Native RawImageBundleResourceItem
 */
-(instancetype)initWithNativeClass:(void*)nativeClass;

@end

NS_ASSUME_NONNULL_END
