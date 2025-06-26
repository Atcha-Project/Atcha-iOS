#import "VSMResourcePackageData.h"

NS_ASSUME_NONNULL_BEGIN

@class VSMRawImageBundleResource;

/**
 * 바이너리 이미지 번들 리소스들을 갖는 패키지입니다.
 */
@interface VSMRawImageBundleResourcePackage : VSMResourcePackageData

/**
 * 리소스맵. Key: 리소스 코드명 Value: 리소스 참조 정보
 * @see VSMRawImageBundleResource
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString*, VSMRawImageBundleResource*>* imageMap;

/**
 * 초기화 메소드
 * @param nativeClass Native VSMRawImageBundleResourcePackage
 */
- (instancetype)initWithNativeClass:(void*)nativeClass;

/**
 * resource code에 해당하는 리소스를 반환합니다.
 * @param resourceCode 찾을 리소스의 코드
 * @return code에 해당하는 리소스
 */
- (VSMRawImageBundleResource*)imageItem:(NSString*)resourceCode;


@end

NS_ASSUME_NONNULL_END

