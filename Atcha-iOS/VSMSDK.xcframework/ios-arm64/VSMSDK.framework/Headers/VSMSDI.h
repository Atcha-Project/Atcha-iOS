//
//  VSMSDI.h
//  VSMSDK
//
//  Created by HS Jeon on 2020/03/11.
//  Copyright © 2020 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSMMapPoint.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Safe Drive Information(안도) 정보
 */
@interface VSMSDI : NSObject<NSCopying>

/**
 * 안도 리소스 이름
 */
@property (nonatomic, copy) NSString* sdiType;

/**
 * 설치점  WGS84 좌표
 */
@property (nonatomic, strong) VSMMapPoint* sdiPoint;

/**
 * 제한 속도 (0,30,40,50,60,70,80,90,100,110,120)
 */
@property (nonatomic, assign) NSInteger sdiSpeedLimit;

@end

NS_ASSUME_NONNULL_END
