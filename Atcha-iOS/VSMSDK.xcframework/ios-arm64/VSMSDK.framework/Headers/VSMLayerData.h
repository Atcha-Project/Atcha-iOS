#import <Foundation/Foundation.h>

/**
 * 레이어 타입
 */
typedef NS_ENUM(NSUInteger, VSMLayerDataType) {
    /** 정의되지 않음
     */
    VSMLayerDataTypeUnknown = 0,
    /** 배경
     */
    VSMLayerDataTypeBackground,
    /** POI
     */
    VSMLayerDataTypePoi,
    /** 네트워크
     */
    VSMLayerDataTypeNetwork,
    /** 교통
     */
    VSMLayerDataTypeTraffic,
    /** 3D 모델
     */
    VSMLayerDataType3DModel,
    /** 위성지도
     */
    VSMLayerDataTypeSatellite
};

@class VSMStackData;

NS_ASSUME_NONNULL_BEGIN

/**
 * 1개의 지도 레이어 정보와 하위 스택 정보들을 갖는 클래스입니다.
 */
@interface VSMLayerData : NSObject

/**
 * ID
 */
@property (assign, nonatomic, readonly) uint32_t layerId;

/**
 * 이름
 */
@property (strong, nonatomic, readonly) NSString* name;

/**
 * VSMLayerDataType
 * @see VSMLayerDataType
 */
@property (assign, nonatomic, readonly) uint32_t type;

/**
 * 버전
 */
@property (strong, nonatomic, readonly) NSString* version;

/**
 * 타일 경로
 */
@property (strong, nonatomic, readonly) NSString* tilePath;

/**
 * 원격 서버상의 지도DB uri 주소. 새 지도DB 다운로딩시 사용할 수 있습니다.
 */
@property (strong, nonatomic, readonly) NSString* dbUri;

/**
 * 하위 스택 데이터 immutable array
 * @see VSMStackData
 */
@property (strong, nonatomic, readonly) NSArray<VSMStackData*>* stacks;

/**
 * 교통, 테마(스타일) 등의 부가 정보들이 가변적으로 포함되는 Dictionary
 */
@property (strong, nonatomic, readonly) NSDictionary<NSString*, NSString*>* properties;

/**
 * 초기화 메소드
 * @param nativeClass Native Layer 정보
 */
-(instancetype)initWithNativeClass:(void*)nativeClass;

@end

NS_ASSUME_NONNULL_END
