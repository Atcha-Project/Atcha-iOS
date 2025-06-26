//
//  VSMConfigurationLoader.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 19..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSMConfiguration.h"
#import "VSMLoaderOptions.h"
#import "VSMMapDefine.h"

/**
 * VSM [VSMConfigurationLoader load] 에 대한 Listener. VSM 내부의 thread에서 호출됩니다.
 *
 */
@protocol VSMConfigurationLoaderDelegate <NSObject>
/**
 * Configuration을 정상적으로 로딩하였을 경우 VSMConfiguration 객체를 전달합니다.
 * @param data VSMConfiguration 객체
 */
-(void)onConfigurationLoaderSuccess:(VSMConfiguration*)data;

/**
 * Configuration을 정상적으로 로딩하지 못하였을 경우 errorCode를 전달합니다.
 *
 * @param errorCode 에러 코드는 다음과 같습니다.
 * <ul>
 *     <li>﻿LoaderErrorAppHttpClient = 100,</li>
 *     <li>LoaderErrorAppHttpServer,</li>
 *     <li>LoaderErrorAppParsing,</li>
 *     <li>LoaderErrorAppCouldNotResolveHost,</li>
 *     <li>LoaderErrorAppCouldNotConnect,</li>
 *     <li>LoaderErrorAppWriteError,</li>
 *     <li>LoaderErrorAppOperationTimedout,</li>
 *     <li>LoaderErrorAppSendError,</li>
 *     <li>LoaderErrorAppRecvError,</li>
 *     <li>LoaderErrorAppUnknown,</li>
 *     <li>LoaderErrorLayerHttpClient = 200,</li>
 *     <li>LoaderErrorLayerHttpServer,</li>
 *     <li>LoaderErrorLayerParsing,</li>
 *     <li>LoaderErrorLayerCouldNotResolveHost,</li>
 *     <li>LoaderErrorLayerCouldNotConnect,</li>
 *     <li>LoaderErrorLayerWriteError,</li>
 *     <li>LoaderErrorLayerOperationTimedout,</li>
 *     <li>LoaderErrorLayerSendError,</li>
 *     <li>LoaderErrorLayerRecvError,</li>
 *     <li>LoaderErrorLayerUnknown,</li>
 *     <li>LoaderErrorResourceHttpClient = 300,</li>
 *     <li>LoaderErrorResourceHttpServer,</li>
 *     <li>LoaderErrorResourceParsing,</li>
 *     <li>LoaderErrorResourceCouldNotResolveHost,</li>
 *     <li>LoaderErrorResourceCouldNotConnect,</li>
 *     <li>LoaderErrorResourceWriteError,</li>
 *     <li>LoaderErrorResourceOperationTimedout,</li>
 *     <li>LoaderErrorResourceSendError,</li>
 *     <li>LoaderErrorResourceRecvError,</li>
 *     <li>LoaderErrorResourceUnknown,</li>
 *     <li>LoaderErrorStyleHttpClient = 400,</li>
 *     <li>LoaderErrorStyleHttpServer,</li>
 *     <li>LoaderErrorStyleParsing,</li>
 *     <li>LoaderErrorStyleCouldNotResolveHost,</li>
 *     <li>LoaderErrorStyleCouldNotConnect,</li>
 *     <li>LoaderErrorStyleWriteError,</li>
 *     <li>LoaderErrorStyleOperationTimedout,</li>
 *     <li>LoaderErrorStyleSendError,</li>
 *     <li>LoaderErrorStyleRecvError,</li>
 *     <li>LoaderErrorStyleUnknown,</li>
 *     <li>LoaderErrorUnknown = 1000</li>
 * </ul>
 */
-(void)onConfigurationLoaderError:(NSString *)url errorCode:(int)errorCode;
@end

/**
 * VSMLoaderOptions 에 의해 지정된 url(혹은 local 파일)로 부터 지도에 필요한 VSMConfiguration 을 로딩하기 위한 클래스
 */
@interface VSMConfigurationLoader : NSObject

/**
 * [VSMConfigurationLoader load] 에 대한 Listener를 설정합니다.
 */
@property (weak, atomic) id<VSMConfigurationLoaderDelegate> delegate;

/**
 * 네트워크 다운로드 상태에 대한 Listener를 설정합니다.
 */
@property (weak, atomic) id<NetworkStatusDelegate> networkDelegate;

/**
 * ConfigurationLoader 생성자
 *
 * @param loaderID 해당 값은 [VSMConfiguration configurationID] 값으로 사용됩니다.
 * @param options Configuration 로딩 시 사용할 설정값
 */
-(instancetype)init:(int)loaderID options:(VSMLoaderOptions*)options;

/**
 * VSMLoaderOptions 에 의해 지정된 url(혹은 local 파일)로 부터 지도에 필요한 VSMConfiguration 을 로딩합니다.
 * 결과는 [VSMConfigurationLoader delegate] 에 의해 등록된 리스너로 전달됩니다.
 */
-(void)load;

@end
