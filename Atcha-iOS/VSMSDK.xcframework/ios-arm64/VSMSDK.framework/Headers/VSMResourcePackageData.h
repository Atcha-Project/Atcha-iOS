//
//  VSMResourcePackageData.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 19..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSMResource.h"

/**
 * 리소스 패키지 타입
 */
typedef NS_ENUM(int, RESOURCEPACKAGE_TYPE) {
    /** None
    */
    RESOURCEPACKAGE_TYPE_NONE               = 0,
    /** 오디오
    */
    RESOURCEPACKAGE_TYPE_AUDIO              = 1,
    /** 싱글 이미지
    */
    RESOURCEPACKAGE_TYPE_IMAGESINGLE        = 2,
    /** 이미지 번들
    */
    RESOURCEPACKAGE_TYPE_IMAGEBUNDLE        = 3,
    /** 번들 ZIP
    */
    RESOURCEPACKAGE_TYPE_IMAGEBUNDLEZIP     = 4,
    /** 바이너리 이미지 번들
    */
    RESOURCEPACKAGE_TYPE_RAWIMAGEBUNDLE     = 5,
    /** 텍스처
    */
    RESOURCEPACKAGE_TYPE_TEXTURE            = 6,
    /** 랜드마크
    */
    RESOURCEPACKAGE_TYPE_LANDMARK           = 7,
    /** 아틀라스 이미지
    */
    RESOURCEPACKAGE_TYPE_ATLASIMAGE         = 8,
    /** 바이너리
    */
    RESOURCEPACKAGE_TYPE_BINARY             = 9,
    /** 보이스 가이드
    */
    RESOURCEPACKAGE_TYPE_VOICEGUIDEV2       = 10,
    /** TTSDB
    */
    RESOURCEPACKAGE_TYPE_TTSDB              = 11,
    /** 기타
     */
    RESOURCEPACKAGE_TYPE_ETC                = 12
};

/**
 * Resource 패키지 정보를 갖고 있는 클래스. Resource 패키지는 다수의 VSMResource 을 갖고 있습니다.
 */
@interface VSMResourcePackageData : NSObject

/**
 * 패키지가 갖고 있는 VSMResource들이 저장되는 root 경로를 리턴합니다.
 *
 * @return 패키지가 갖고 있는 VSMResource들이 저장되는 root 경로
 */
@property (strong, nonatomic, readonly) NSString *rootDir;

/**
 * 패키지 id
 *
 * @return 패키지 id
 */
@property (assign, nonatomic, readonly) unsigned int packageID;

/**
 * 패키지 code
 *
 * @return 패키지 code
 */
@property (strong, nonatomic, readonly) NSString *code;

/**
 * 패키지 type
 * @return 패키지 type
 * @see RESOURCEPACKAGE_TYPE
 */
@property (assign, nonatomic, readonly) RESOURCEPACKAGE_TYPE packageType;

/**
 * 패키지 이름
 *
 * @return 패키지 이름
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 * 패키지 버전
 *
 * @return 패키지 버전
 */
@property (strong, nonatomic, readonly) NSString *version;

/**
 * 패키지 다운로드 여부. [VSMResource optional] 이 아닌 Resource가 모두 다운로드 되었다면 true
 *
 * @return 패키지 다운로드 여부
 */
@property (assign, nonatomic, readonly) bool avaliable;

/**
 * VSMResource 목록을 반환합니다.
 * @return ResourceItem 목록
 * @see VSMResource
 */
@property (nonatomic, strong, readonly) NSArray<VSMResource*> *itemList;

/**
 * Native ResourcePackageData
 */
@property (assign, nonatomic, readonly, getter=getNativeClass) void* nativeClass;

/**
 *초기화 메소드
 *@param nativeClass Native ResourcePackageData
 */
-(instancetype)initWithNativeClass:(void*)nativeClass;

/**
 * 코드에 대응하는 리소스 반환
 * @param code 리소스 코드
 * @return 코드에 대응하는 리소스
 */
-(VSMResource*)getItem:(NSString*)code;

@end
