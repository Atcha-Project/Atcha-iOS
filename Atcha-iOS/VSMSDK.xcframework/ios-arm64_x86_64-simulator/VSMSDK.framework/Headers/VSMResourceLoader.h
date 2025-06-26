//
//  VSMResourceLoader.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 19..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSMResource.h"
#import "VSMConfiguration.h"
#import "VSMMapDefine.h"

/**
 * Resource 로딩 중 실패 시 재시도를 하지 않습니다.
 */
#define RESOURCELOADER_FLAG_NO_RETRY        (1)

/**
 * Resource 로딩 진행 상태 callback을 호출하지 않습니다.
 */
#define RESOURCELOADER_FLAG_NO_PROGRESS     (1 << 1)

/**
 * [VSMResourceLoader load] 에 대한 Listener. VSM 내부의 thread에서 호출됩니다.
 */
@protocol VSMResourceLoaderDelegate <NSObject>

/**
 * Resource 로딩을 시작한 경우 호출되는 callback
 */
-(void)onResourceLoaderStart;

/**
 * Resource 로딩 진행 상태를 위한 callback
 *
 * @param count 다운로드된 개수
 * @param total 다운로드할 전체 개수
 * @param downloadedSize 다운로드된 사이즈(Byte)
 * @param totalSize 다운로드할 전체 파일 사이즈(Byte)
 */
-(void)onResourceLoaderProgress:(NSUInteger)count
                          total:(NSUInteger)total
                 downloadedSize:(NSUInteger)downloadedSize
                      totalSize:(NSUInteger)totalSize;

/**
 * Resource 로딩을 성공한 경우 호출되는 callback
 */
-(void)onResourceLoaderSuccess;

/**
 * Resource 로딩에 실패할 경우 호출되는 callback
 *
 * @param errorCode 에러 코드는 다음과 같습니다
 *
 * <ul>
 * <li>HttpRequestError_COULDNT_RESOLVE_HOST = 6,</li>
 * <li>HttpRequestError_COULDNT_CONNECT = 7,</li>
 * <li>HttpRequestError_WRITE_ERROR = 23,</li>
 * <li>HttpRequestError_OPERATION_TIMEDOUT = 28,</li>
 * <li>HttpRequestError_SEND_ERROR = 55,</li>
 * <li>HttpRequestError_RECV_ERROR = 56,</li>
 * <li>100~600: Http Status</li>
 * <li>HttpRequestError_UNKNOWN = 1000</li>
 * </ul>
 */
-(void)onResourceLoaderError:(NSString *)url errorCode:(NSInteger)errorCode;

/**
 * Resource 로딩 작업이 완료되었을 경우 호출되는 callback. 성공/실패 관계 없이 항상 호출됩니다.
 */
-(void)onResourceLoaderFinished;
@end

/**
 * VSMResource 을 일괄적으로 로딩하기 위한 클래스
 */
@interface VSMResourceLoader : NSObject

/**
 * [VSMResourceLoader load] 에 대한 Listener를 설정합니다.
 * @see VSMResourceLoaderDelegate
 */
@property (weak, atomic) id<VSMResourceLoaderDelegate> delegate;

/**
 * 네트워크 다운로드 상태에 대한 Listener를 설정합니다.
 * @see NetworkStatusDelegate
 */
@property (weak, atomic) id<NetworkStatusDelegate> networkDelegate;

/**
 * 초기화 메소드
 *@param configuration configuration
 *@see VSMConfiguration
 */
-(instancetype)initWithConfiguration:(VSMConfiguration*)configuration;

/**
 *초기화 메소드
 *@param configuration configuration
 *@param flags 리소스 로딩 관련 flag
 *@see VSMConfiguration
 *@see VSMLoaderOptionsFlags
 */
-(instancetype)initWithConfiguration:(VSMConfiguration*)configuration flags:(int)flags;

/**
 * 다운로드할 Resource를 추가합니다.
 *
 * @param item 다운로드할 VSMResource
 * @see VSMResource
 */
-(void)addItem:(const VSMResource*)item;

/**
 * 추가된 VSMResource을 일괄적으로 다운로드합니다.
 */
-(void)load;

/**
 * 로딩을 중지합니다.
 */
-(void)stop;

@end
