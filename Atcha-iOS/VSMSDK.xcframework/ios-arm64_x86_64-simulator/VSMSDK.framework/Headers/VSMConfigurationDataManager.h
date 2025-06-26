//
//  VSMConfigurationDataManager.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 19..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSMConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Active한 VSMConfiguration가 변경될 때 호출되는 인터페이스
 */
@protocol VSMConfigurationChangedDelegate <NSObject>
/**
 * VSMConfiguration가 변경되기 전, VSM 엔진에서 기존 VSMConfiguration 와 의존성이 있는 부분이 정리된 후 호출됩니다.
 */
-(void)onConfigurationDataWillChange;
/**
 * VSMConfiguration가 변경된 후, VSM 엔진이 새로운 VSMConfiguration 를 사용할 준비가 되었을 때 호출됩니다.
 */
-(void)onConfigurationDataDidChange:(nullable VSMConfiguration*)newData;
@end

/**
 * VSMConfiguration를 관리하기 위한 클래스
 */
@interface VSMConfigurationDataManager : NSObject

/**
 * VSM 엔진은 특정 Resource에 대해 등록된 VSMConfiguration 중 최신의 것을 사용할 수 있습니다.
 *
 * @param configuration Stage할 ConfigurationData
 */
+(void)stageConfigurationData:(VSMConfiguration*)configuration;

/**
 * 등록된 VSMConfiguration 를 해제합니다. <b><i>정상적인 메모리 반환을 위해 등록 해제 필요합니다.</i></b>
 *
 * @param configuration Unstage할 ConfigurationData
 */
+(void)unstageConfigurationData:(VSMConfiguration*)configuration;

/**
 * VSMConfiguration 변경에 대한 Delegate를 등록합니다.
 * @param listener 추가할 VSMConfigurationChangedDelegate
 */
+(void)addOnConfigurationDataChangeDelegate:(id<VSMConfigurationChangedDelegate>)listener;

/**
 * VSMConfiguration 변경에 대한 Delegate를 삭제합니다.
 * @param listener 삭제할 VSMConfigurationChangedDelegate
 */
+(void)removeOnConfigurationDataChangeDelegate:(id<VSMConfigurationChangedDelegate>)listener;

/**
 * 주어진 VSMConfiguration 를 Active로 설정합니다. [VSMMap initEngine] 호출 전 반드시 필요합니다.
 * Active한 VSMConfiguration 변경 시 VSM 엔진은 기존 VSMConfiguration 와 의존성이 있는 부분을 정리하고 새로운 VSMConfiguration 을 사용하게 됩니다.
 *
 * @param configuration Active로 설정할 ConfigurationData
 * @param changedCallback ConfigurationData 변경에 대한 callback
 */
+(void)setActiveConfigurationData:(nullable VSMConfiguration*)configuration
                  changedCallback:(nullable id<VSMConfigurationChangedDelegate>)changedCallback;

/**
 * Active VSMConfiguration 반환
 * @return Active VSMConfiguration
 */
+(nullable VSMConfiguration*)activeConfigurationData;

@end

NS_ASSUME_NONNULL_END
