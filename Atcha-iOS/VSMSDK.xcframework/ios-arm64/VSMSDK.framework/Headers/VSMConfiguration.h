//
//  VSMConfiguration.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 19..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSMLoaderOptions.h"

@class VSMResourcePackageData;
@class VSMStyleData;
@class VSMLayerData;
@class VSMSettingData;

/**
 * 지도를 위한 Layer 정보, Resource 정보, Style 정보를 담고 있습니다. VSMConfigurationLoader 를 통해 객체를 생성합니다.
 */

@interface VSMConfiguration : NSObject

/**
 * VSMConfigurationLoader 생성 시 명시한 id 값.
 * Application은 VSMConfiguration 의 구분을 위해 id를 부여할 수 있습니다.
 *
 * @return id Application이 지정한 id 값
 */
@property (assign, nonatomic, readonly) int configurationID;

/**
 * VSMResourcePackageData 리스트를 반환합니다.
 * @return 리소스 패키지 리스트
 * @see VSMResourcePackageData
 */
@property (strong, nonatomic, readonly) NSArray<VSMResourcePackageData*>* resourceList;

/**
 * VSMStyleData 리스트
 * @see VSMStyleData
 */
@property (strong, nonatomic, readonly) NSArray<VSMStyleData*>* styleList;

/**
 * VSMLayerData 리스트
 * @see VSMLayerData
 */
@property (strong, nonatomic, readonly) NSArray<VSMLayerData*>* layerList;


@property (strong, nonatomic, readonly) NSArray<VSMSettingData*>* settingList;

/**
 * [VSMLoaderOptions flags] 값을 반환합니다.
 * @return VSMLoaderOptionsFlags 값
 * @see VSMLoaderOptionsFlagss
 */
@property (assign, nonatomic, readonly) VSMLoaderOptionsFlags flags;

/**
 * native class
 */
@property (assign, nonatomic, readonly, getter=getNativeClass) void* nativeClass;

/**
 * 버전
 */
@property (strong, nonatomic, readonly) NSString* version;

/**
 * 초기화 메소드
 * @param nativeClass Native Configuration
 */
-(instancetype)initWithNativeClass:(void*)nativeClass;

/**
 * 코드에 대응하는 리소스 패키지를 반환합니다.
 * @param code 패키지 코드
 * @return 리소스 패키지
 */
-(VSMResourcePackageData*)getResourcePackage:(NSString*)code;

@end
