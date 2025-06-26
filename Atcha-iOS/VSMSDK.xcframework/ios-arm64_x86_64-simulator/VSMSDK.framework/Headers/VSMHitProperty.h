//
//  VSMHitProperty.h
//  VSMSDK_static
//
//  Created by 박창선님/Map플랫폼개발팀 on 2022/06/29.
//  Copyright © 2022 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjectProperty.h"
#import "MeterPoint.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Hit Test 결과를 갖는 프로퍼티
 */
@interface VSMHitProperty : NSObject

/**
 * Hit 오브젝트 unique ID
 */
@property (nonatomic, assign) int identifier;

/**
 * Hit 오브젝트 좌표(WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* geoPos;

/**
 * property
 * @see ObjectProperty
 */
@property (nonatomic, strong) ObjectProperty* property ;

@end

NS_ASSUME_NONNULL_END
