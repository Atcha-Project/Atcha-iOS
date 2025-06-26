//
//  VSMMapMatchingData.h
//  VSMSDK_static
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/11/18.
//  Copyright © 2021 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSMMapPoint.h"
#import "VSMMapBounds.h"

/**
 * 위치점 색상 타입
 */
typedef NS_ENUM(NSUInteger, eMMColor) {
    /** Black
     */
    eMMColorBLACK,
    /** Red
     */
    eMMColorRED,
    /**Blue
     */
    eMMColorBLUE,
    /** Green
     */
    eMMColorGREEN,
    /** Orange
     */
    eMMColorORANGE
};

NS_ASSUME_NONNULL_BEGIN

/**
 * MapMatching 위치점 정보 시각화를 위한 클래스
 */
@interface VSMMapMatchingPoint : NSObject

/**
 * 위치점 WGS84 좌표
 */
@property (nonatomic, retain) VSMMapPoint* pos;

/**
 * 위치점 각도(degree)
 */
@property (nonatomic, assign) float angle;

/**
 * 위치점 반경
 */
@property (nonatomic, assign) int radius;

/**
 * 위치점 색상 타입
 * @see eMMColor
 */
@property (nonatomic, assign) eMMColor type;

/**
 * 시각화 여부
 */
@property (nonatomic, assign) bool valid;

/**
 * MapMatching 위치점 정보 시각화 객체 생성 팩토리 메소드
 * @param angle 위치점 각도
 * @param radius 위치점 반경
 * @param type 위치점 색상타입
 * @param valid 위치점 시각화 여부
 * @return VSMMapMatchingPoint
 * @see VSMMapPoint
 */
+ (VSMMapMatchingPoint*)mapMatchingPointWithPos:(VSMMapPoint*)pos
                                          angle:(float)angle
                                         radius:(float)radius
                                           type:(int)type
                                          valid:(BOOL)valid;
@end

/**
 * MapMatching 사각영역 정보 시각화를 위한 클래스
 */
@interface VSMMapMatchingRect : NSObject

/**
 * MapMatching 사각영역  WGS84좌표 정보
 */
@property (nonatomic, retain) VSMMapBounds* rect;

/**
 * 위치점 색상 타입
 */
@property (nonatomic, assign) eMMColor type;

/**
 * 시각화 여부
 */
@property (nonatomic, assign) bool valid;

/**
 * MapMatching 사각영역 객체 생성 팩토리 메소드
 * @param rect 위치 사각영역 좌표
 * @param type 색상 타입
 * @param valid 위치 사각영역 시각화 여부
 * @return VSMMapMatchingPoint
 * @see VSMMapBounds
 */
+ (VSMMapMatchingRect*)mapMatchingRectWithRect:(VSMMapBounds*)rect type:(int)type valid:(BOOL)valid;

@end

/**
 * MapMatching 링크 정보 시각화를 위한 클래스
 */
@interface VSMMapMatchingLink : NSObject

/**
 * 구성 버텍스(WGS84)좌표 immutable array
 * @see VSMMapPoint
 */
@property (nonatomic, retain) NSArray<VSMMapPoint*>* verticies;

/**
 * 링크 ID
 */
@property (nonatomic, assign) int identifier;

/**
 * 구성 버텍스 전체를 아우르는 사각영역
 * @see VSMMapBounds
 */
@property (nonatomic, retain) VSMMapBounds* extent;

/**
 * 링크 색상타입
 */
@property (nonatomic, assign) eMMColor type;

/**
 * MapMatching 링크 객체 생성 팩토리 메소드
 * @param verticies 링크 버텍스 좌표 불변 array
 * @param type 링크 색상 타입
 * @param extent 버텍스 전체를 아우르는 사각영역
 * @param identifier 링크 ID
 * @return VSMMapMatchingLink
 * @see VSMMapPoint
 * @see VSMMapBounds
 */
+ (VSMMapMatchingLink*)mapMatchingLinkWithVertices:(NSArray<VSMMapPoint*>*)verticies
                                              type:(int)type
                                            extent:(VSMMapBounds*)extent
                                        identifier:(int)identifier;

@end


/**
 * VSMMapMatching 네트워크 정보 시각화를 위한 클래스
 */
@interface VSMMapMatchingNetwork : NSObject

/**
 * 구성 링크 array
 * @see VSMMapMatchingLink
 */
@property (nonatomic, retain) NSArray<VSMMapMatchingLink*>* links;

/**
 * 네트워크 ID
 */
@property (nonatomic, assign) int identifier;

/**
 * 구성 링크 전체를 아우르는 사각영역
 * @see VSMMapBounds
 */
@property (nonatomic, retain) VSMMapBounds* extent;

/**
 * VSMMapMatching 네트워크 객체 생성 팩토리 메소드
 * @param links 링크 immutable array
 * @param extent 링크 전체를 아우르는 사각영역
 * @param identifier 네티워크 ID
 * @see VSMMapMatchingLink
 * @see VSMMapBounds
 */
+ (VSMMapMatchingNetwork*)mapMatchingNetworkWithVertices:(NSArray<VSMMapMatchingLink*>*)links
                                                  extent:(VSMMapBounds*)extent
                                              identifier:(int)identifier;

@end

NS_ASSUME_NONNULL_END
