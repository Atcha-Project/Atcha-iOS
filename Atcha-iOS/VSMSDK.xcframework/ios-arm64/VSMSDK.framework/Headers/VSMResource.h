//
//  VSMResource.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 19..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Resource 정보를 담고 있는 클래스
 */
@interface VSMResource : NSObject

/**
 * Resource 파일명을 반환합니다.
 *
 * @return 리소스 파일명
 */
@property (strong, nonatomic, readonly) NSString *fileName;

/**
 * Resource 파일의 전체 경로를 반환합니다.
 *
 * @return 리소스 파일의 전체 경로
 */
@property (strong, nonatomic, readonly) NSString *fullPath;

/**
 * Resource 코드를 반환합니다.
 *
 * @return Resource 코드
 */
@property (strong, nonatomic, readonly) NSString *code;

/**
 * Resource 파일 ID를 반환합니다.
 *
 * @return File ID
 */
@property (strong, nonatomic, readonly) NSString *fileId;

/**
 * Resource 파일의 URL을 반환합니다.
 *
 * @return url
 */
@property (strong, nonatomic, readonly) NSString *uri;

/**
 * 선택적으로 받을 수 있는 Resource인지 여부. 예) 추가 성우
 *
 * @return 선택적으로 받을 수 있는 Resource인지 여부
 */
@property (assign, nonatomic, readonly) bool optional;

/**
 * Resource의 파일 크기를 반환합니다.
 *
 * @return 파일 크기
 */
@property (assign, nonatomic, readonly) long fileSize;

/**
 * 오프라인 전용 Resource 여부를 반환합니다.
 *
 * @return 오프라인 전용 Resource 여부
 */
@property (assign, nonatomic, readonly) bool offlineOnly;

/**
 * Resource가 다운로드 되었는지 여부를 반환합니다.
 *
 * @return 다운로드 되었는지 여부
 */
@property (assign, nonatomic, readonly) bool downloaded;

/**
 * Resource 업데이트 되었는지 여부를 반환합니다.
 *
 * @return 업데이트 되었는지 여부
 */
@property (assign, nonatomic, readonly) bool updated;

/**
 * Resource가 가진 속성값을 반환합니다.
 *
 * @return Resource Property
 */
@property (strong, nonatomic, readonly) NSDictionary *properties;

/**
 * nativeClass Native Resource
 */
@property (assign, nonatomic, readonly, getter=getNativeClass) void* nativeClass;

/**
 * 초기화 메소드
 * @param nativeClass Native Resource
 */
-(instancetype)initWithNativeClass:(void*)nativeClass;

@end
