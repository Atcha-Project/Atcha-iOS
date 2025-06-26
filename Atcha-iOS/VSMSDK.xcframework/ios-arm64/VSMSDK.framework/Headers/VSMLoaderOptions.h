//
//  VSMLoaderOptions.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 19..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Configuration 로더 옵션
 */
typedef NS_OPTIONS(UInt32, VSMLoaderOptionsFlags) {
    /**
     * local로 부터 설정 파일을 로딩합니다. 필요한 Configuration을 찾을 수 없다면 오류가 발생됩니다.
     */
    LOADER_FLAG_OFFLINE             = 1,
    /**
     * Style 설정값 파싱을 하지 않습니다. 일반적으로 사용되지 않습니다.
     */
    LOADER_FLAG_DO_NOT_PARSE_STYLE  = 1 << 1,
    /**
     * Style 설정값을 동기적으로 파싱합니다. 일반적으로 사용되지 않습니다.
     */
    LOADER_FLAG_PARSE_STYLE_SYNC    = 1 << 2,
    /**
     * Configuration 로딩 시 더이상 사용되지 않는 파일(Configuration 내에 명시되지 않은 파일)을 삭제하지 않습니다.
     * @see ConfigurationData#commitData()
     */
    LOADER_FLAG_KEEP_UNUSED         = 1 << 3,
    /**
     * Configuration 로딩 시 오류가 있는 파일을 삭제하지 않습니다. 일반적으로 사용되지 않습니다.
     */
    LOADER_FLAG_KEEP_FAILED         = 1 << 4,
    /**
     * 오류로 mark된 Resource에 대해 삭제하지 않습니다.
     * @see #LOADER_FLAG_MARK_BROKEN
     */
    LOADER_FLAG_KEEP_BROKEN         = 1 << 5,
    /**
     * Application Configuration 파일 다운로드 시 기존의 Application Configuration 파일을 overwrite 하지 않고 임시 파일 형태로 다운로드 합니다.
     * @see ConfigurationData#commitData()
     */
    LOADER_FLAG_TEMP_APPCONFIG      = 1 << 6,
    /**
     * Resource 사용 시 오류가 있다고 판단될 경우 mark 하도록 합니다.
     */
    LOADER_FLAG_MARK_BROKEN         = 1 << 7,
    /**
     * Configuration 내의 url들을 CDN의 url로 replace 합니다. CDN에 대한 url은 Application Configuration 내에 명시됩니다.
     */
    LOADER_FLAG_USE_CDN             = 1 << 8,
};


/**
 * ConfigurationLoader 를 위해 필요한 옵션 값을 갖고 있는 클래스
 * @see VSMConfigurationLoader
 */
@interface VSMLoaderOptions : NSObject

/**
 * Application Configuration의 url을 설정합니다. 예) https://farm43.ids.onestore.co.kr/hub/vsm_dev/config/application/TMAP.conf
 */
@property (strong, nonatomic) NSString *configUrl;

/**
 * 지도 타일, 교통 정보 등에 사용될 url의 prefix를 설정합니다. 예 https://farm43.ids.onestore.co.kr/hub/vsm_dev
 */
@property (strong, nonatomic) NSString *baseUrlPrefix;

/**
 * SSL 연결 시 인증서를 검증합니다. 기본값은 true 입니다.
 */
@property (assign, nonatomic) bool sslVerifyPeer;

/**
 *  SSL 연결 시 인증서의 host를 검증합니다. 기본값은 true 입니다.
 */
@property (assign, nonatomic) bool sslVerifyHost;

/**
 * <b><i>미지원.</i></b> 인증서 파일의 위치를 설정합니다.
 */
@property (strong, nonatomic) NSString *caCertFile;

/**
 * Configuration 파일 및 Resource 파일이 저장될 root 경로를 설정합니다.
 */
@property (strong, nonatomic) NSString *rootDir;

/**
 * 데이터 파일이 저장되는 경로를 설정합니다.
 */
@property (strong, nonatomic) NSString *dataDir;

/**
 * 지도 타일/커스텀 레이어 파일이 저장되는 경로를 설정합니다.
 */
@property (strong, nonatomic) NSString *cacheDir;

/**
 * 전체 지도 DB를 다운로드할 경로를 설정합니다.
 */
@property (strong, nonatomic) NSString *fullMapDir;

/**
 * 리소스 버전 체크를 위한 값. 모든 리소스는 minSdkVer, maxSdkVer 필드를 갖고 있습니다.
 * 지정한 resourceVersion 값이 [minSdkVer, maxSdkVer] 범위에 포함되지 않는 경우 해당 리소스는 무시됩니다.
 * 이전 버전과의 호환성을 위해 기본값은 5이며, 0으로 설정 시 리소스 버전 확인을 하지 않습니다.
 */
@property (assign, nonatomic) int resourceVersion;

/**
 * ConfigurationLoader 동작에 대한 flags 값. LOADER_FLAG_* 설명을 참조합니다.
 * @see VSMConfigurationLoader
 * @see VSMLoaderOptionsFlags
 */
@property (assign, nonatomic) VSMLoaderOptionsFlags flags;

/**
 * configuration 및 resource 등을 저장할 때 참조하는 identifier 입니다.
 * null인 경우 내부적으로 configUrl의 host명으로부터 생성한 SHA-1 값을 이용하게 됩니다.
 * 다른 server의 configuration을 로딩할 때, 이미 저장되어 있는 configuration/resource의 id, version이 같아 발생할 수 있는 오류를 예방합니다.
 */
@property (copy, nonatomic) NSString* identifier;

@end
