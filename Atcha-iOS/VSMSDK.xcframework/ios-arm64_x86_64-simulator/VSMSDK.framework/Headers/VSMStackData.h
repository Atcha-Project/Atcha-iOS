#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  레이어 config 파일에 정의된  레이어의 1개의 스택 데이터를 나타내는 클래스.
 */
@interface VSMStackData : NSObject

/*
 * 스택 ID
 */
@property (assign, nonatomic, readonly) uint32_t stackId;

/**
 * 스택 코드
 */
@property (strong, nonatomic, readonly) NSString* code;

/**
 * 초기화 메소드
 * @param nativeClass Native Stack Data
 */
-(instancetype)initWithNativeClass:(void*)nativeClass;

@end

NS_ASSUME_NONNULL_END
