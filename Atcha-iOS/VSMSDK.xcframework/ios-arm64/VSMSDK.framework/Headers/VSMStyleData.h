#import <Foundation/Foundation.h>

/**
 * 스타일 confing 파일에 정의된 스타일 정보를 나타내는 클래스.
 */
@interface VSMStyleData : NSObject

/**
 * 스타일 ID
 */
@property (assign, nonatomic, readonly) uint32_t styleID;

/**
 * group 정보 (일반 or 위성)
 */
@property (strong, nonatomic, readonly) NSString* group;

/**
 * type 정보 (Day, Night 등)
 */
@property (strong, nonatomic, readonly) NSArray<NSString*>* types;

/**
 * type 정보의 정식 명칭
 */
@property (strong, nonatomic, readonly) NSArray<NSString*>* canonicalNames;

/**
 * 초기화 메소드
 * @param nativeClass Native VSMStyleData
 */
-(id)initWithNativeClass:(void*)nativeClass;

@end

