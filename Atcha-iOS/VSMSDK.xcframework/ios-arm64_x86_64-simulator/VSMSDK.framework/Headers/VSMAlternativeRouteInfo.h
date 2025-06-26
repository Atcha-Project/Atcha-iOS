//
//  VSMAlternativeRouteInfo.h
//  VSMSDK
//
//  Created by HS Jeon on 2020/03/11.
//  Copyright © 2020 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VSMMapPoint;

NS_ASSUME_NONNULL_BEGIN

/**
 * 대안 경로 팝업창이 표시될 조건을 나타내는 클래스. 레벨 별로 팝업 위치를 설정할 수 있습니다.
 */
@interface PopupPos : NSObject<NSCopying>

/**
 * 팝업이 표시될 줌 레벨 범위 중 최소 줌 레벨.
 */
@property (nonatomic, assign) int32_t levelMin;

/**
 * 팝업이 표시될 줌 레벨 범위 중 최대 줌 레벨.
 */
@property (nonatomic, assign) int32_t levelMax;

/**
 * 팝업 좌표 (WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* pos;

/**
 * 초기화 메소드
 * @param levelMin 팝업이 표시될 줌 레벨 범위 중 최소 줌 레벨.
 * @param levelMax 팝업이 표시될 줌 레벨 범위 중 최대 줌 레벨.
 * @param pos 팝업 좌표 (WGS84)
 * @see VSMMapPoint
 */
-(instancetype) init:(int32_t)levelMin levelMax:(int32_t)levelMax pos:(VSMMapPoint*)pos;

@end

/**
 * 대안경로 팝업창에 표시될 정보를 나타내는 클래스.
 */
@interface VSMAlternativeRouteInfo : NSObject<NSCopying>

/**
 * deprecated
 */
@property (nonatomic, assign) int32_t day;

/**
 * deprecated
 */
@property (nonatomic, assign) int32_t hour;

/**
 * 시간 차이
 */
@property (nonatomic, assign) int32_t minute;

/**
 * deprecated
 */
@property (nonatomic, assign) int32_t second;

/**
 * deprecated
 */
@property (nonatomic, assign) BOOL  costFree;

/** 남은 거리
 */
@property (nonatomic, assign) float distLeft;

/** 비용 차이
 */
@property (nonatomic, assign) int32_t cost;

/** 분기점 좌표 (WGS84)
 *@see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* pos;

/** 분기점에서 주행도로 진행 방향 위치
 *@see VSMMapPoint
 */
@property (nonatomic, strong, nullable) VSMMapPoint* carDirection;

/**
 * 레벨별 대안경로 팝업 위치 정보
 * @see PopupPos
 */
@property (nonatomic, strong) NSArray<PopupPos*>* popupPos;

@end

NS_ASSUME_NONNULL_END
