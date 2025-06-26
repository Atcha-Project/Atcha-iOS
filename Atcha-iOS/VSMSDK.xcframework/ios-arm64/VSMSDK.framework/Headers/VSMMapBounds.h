//
//  VSMMapPointBounds.h
//  VSMSDK_static
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/06/14.
//  Copyright © 2021 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSMMapPoint.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * WGS84 좌표기반 지도 사각영역을 표현하는 immutable 객체.
 */
@interface VSMMapBounds : NSObject

/**
 * 사각영역 좌하단 WGS84 좌표
 * @see VSMMapPoint
 */
@property (nonatomic, retain, readonly, nonnull) VSMMapPoint* southWest;

/**
 * 사각영역 우상단 좌표 WGS84  좌표
 * @see VSMMapPoint
 */
@property (nonatomic, retain, readonly, nonnull) VSMMapPoint* northEast;

/**
 * 사각영역 중앙
 * @see VSMMapPoint
 */
@property (nonatomic, retain, readonly, nonnull) VSMMapPoint* center;

/**
 * 사각영역 세로길이
 */
@property (nonatomic, readonly) double latitudeSpan;

/**
 * 사각영역 가로길이
 */
@property (nonatomic, readonly) double longitudeSpan;

/**
 * VSMMapBounds 생성 팩토리 메소드
 * @param southWest 좌하단 WGS84 좌표
 * @param northEast 우상단 WGS84 좌표
 * @return VSMMapBounds
 * @see VSMMapPoint
 */
+ (instancetype)boundsWithSouthWest:(VSMMapPoint*)southWest northEast:(VSMMapPoint*)northEast;

/**
 * VSMMapBounds 생성 메소드
 * @param southWest 좌하단 WGS84 좌표
 * @param northEast 우상단 WGS84 좌표
 * @return VSMMapBounds
 * @see VSMMapPoint
 */
- (instancetype)initWithSouthWest:(VSMMapPoint*)southWest northEast:(VSMMapPoint*)northEast;

/**
 * point가 사각영역내에 있는지 검사
 * @param point 검사할 WGS84 좌표
 * @return True(포함될 경우) False(포함되지 않을 경우)
 * @see VSMMapPoint
 */
- (BOOL)hasPoint:(nonnull VSMMapPoint*)point;

/**
 * bounds이 사각영역내에 완전히 포함되는지 검사
 * @param bounds 검사할 사각영역
 * @return True(완전히 포함될 경우) False(그렇지 않을 경우)
 */
- (BOOL)hasBounds:(nonnull VSMMapBounds*)bounds;

/**
 * bounds이 사각영역내과 겹치는지 검사
 * @param bounds 검사할 사각영역
 * @return True(겹치는 영역이 존재할 경우) False(그렇지 않을 경우)
 */
- (BOOL)isIntersect:(nonnull VSMMapBounds*)bounds;

/**
 * point를 포함하도록 확장한 영역을 반환.
 * 영역이 이미 point를 포함하고 있을 경우는 현 객체 반환.
 * 그렇지 않은 경우는 사각영역이 point를 포함하도록 영역을 확장하여 새 객체 반환.
 * @param point 확장할 WGS84좌표
 * @return point만큼 확장된 새 객체 OR 현 객체
 * @see VSMMapPoint
 */
- (nonnull VSMMapBounds*)expandToPoint:(nonnull VSMMapPoint*)point;

/**
 * bounds를 포함하도록 확장한 영역을 반환.
 * 영역이 이미 bounds를 포함하고 있을 경우는 현 객체 반환.
 * 그렇지 않은 경우는 사각영역이 point를 포함하도록 영역을 확장하여 새 객체 반환.
 * @param bounds 확장할 WGS84좌표 사각영역
 * @return bounds만큼 확장된 새 객체 OR 현 객체
 */
- (nonnull VSMMapBounds*)unionBounds:(nonnull VSMMapBounds*)bounds;

/**
 * 사각영역 값의 유효성 검사
 * @return True(유효할 경우) False(그렇지 않은 경우)
 */
- (BOOL)checkValidity;

+ (VSMMapBounds*)INVALID;

@end

NS_ASSUME_NONNULL_END
