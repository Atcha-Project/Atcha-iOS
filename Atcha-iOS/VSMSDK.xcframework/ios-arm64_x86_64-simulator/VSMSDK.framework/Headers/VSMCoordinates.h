//
//  VSMCoordinates.h
//  TAModule
//
//  Created by 1001921 on 2015. 3. 24..
//
//

#import <Foundation/Foundation.h>
#import "VSMMapPoint.h"

/** (법정동)주소 정보
 */
@interface VSMDetailedAddress : NSObject

/** 시/도
 */
@property (nonatomic, copy) NSString* _Nonnull sido;

/** 구
 */
@property (nonatomic, copy) NSString* _Nonnull gu;

/** 상세
 */
@property (nonatomic, copy) NSString* _Nonnull detail;

/** 행정동 코드
 */
@property (nonatomic, copy) NSString* _Nonnull hcode;

@end

/**	VSM 좌표 변환 클래스입니다.
 */
@interface VSMCoordinates : NSObject

/**
 * World 좌표를 WGS84 좌표로 변환합니다.
 *
 * @param worldX 변경할 World X 좌표
 * @param worldY 변경할 World Y 좌표
 * @param longitude 변경된 WGS84 longitude 좌표
 * @param latitude 변경된 WGS84 latitude 좌표
 */
+(BOOL) convertWorldToWgs84:(double)worldX
                     worldY:(double)worldY
                  longitude:(double *_Nonnull)longitude
                   latitude:(double *_Nonnull)latitude;

/**
 * World 좌표를 SK 좌표로 변환합니다.
 *
 * @param worldX 변경할 World X 좌표
 * @param worldY 변경할 World Y 좌표
 * @param skX 변경된 SK longitude 좌표
 * @param skY 변경된 SK latitude 좌표
 */
+(BOOL) convertWorldToSk:(double)worldX
                  worldY:(double)worldY
                     skX:(double *_Nonnull)skX
                     skY:(double *_Nonnull)skY;

/**
 * World 좌표를 Bessel 좌표로 변환합니다.
 *
 * @param worldX 변경할 World X 좌표
 * @param worldY 변경할 World Y 좌표
 * @param longitude 변경된 Bessel longitude 좌표
 * @param latitude 변경된 Bessel latitude 좌표
 */
+(BOOL) convertWorldToBessel:(double)worldX
                      worldY:(double)worldY
                   longitude:(double *_Nonnull)longitude
                    latitude:(double *_Nonnull)latitude;

/**
 * WGS84 좌표를 World 좌표로 변환합니다.
 *
 * @param longitude 변경할 WGS84 longitude 좌표
 * @param latitude 변경할 WGS84 latitude 좌표
 * @param worldX 변경된 worldX longitude 좌표
 * @param worldY 변경된 worldY latitude 좌표
 */
+(BOOL) convertWgs84ToWorld:(double)longitude
                   latitude:(double)latitude
                     worldX:(double *_Nonnull)worldX
                     worldY:(double *_Nonnull)worldY;

/**
 * WGS84 좌표를 SK 좌표로 변환합니다.
 *
 * @param longitude 변경할 WGS84 longitude 좌표
 * @param latitude 변경할 WGS84 latitude 좌표
 * @param skX 변경된 SK X 좌표
 * @param skY 변경된 SK Y 좌표
 */
+(BOOL) convertWgs84ToSk:(double)longitude
                latitude:(double)latitude
                     skX:(double *_Nonnull)skX
                     skY:(double *_Nonnull)skY;

/**
 * WGS84 좌표를 Bessel 좌표로 변환합니다.
 *
 * @param longitude 변경할 WGS84 longitude 좌표
 * @param latitude 변경할 WGS84 latitude 좌표
 * @param BesselLon 변경된 Bessel longitude 좌표
 * @param BesselLat 변경된 Bessel latitude 좌표
 */
+(BOOL) convertWgs84ToBessel:(double)longitude
                    latitude:(double)latitude
                   longitude:(double *_Nonnull)BesselLon
                    latitude:(double *_Nonnull)BesselLat;

/**
 * SK 좌표를 World 좌표로 변환합니다.
 *
 * @param skX 변경할 SK X 좌표
 * @param skY 변경할 SK Y 좌표
 * @param worldX 변경된 World X 좌표
 * @param worldY 변경된 World Y 좌표
 */
+(BOOL) convertSkToWorld:(double)skX
                     skY:(double)skY
                  worldX:(double *_Nonnull)worldX
                  worldY:(double *_Nonnull)worldY;

/**
 * SK 좌표를 WGS84 좌표로 변환합니다.
 *
 * @param skX 변경할 SK X 좌표
 * @param skY 변경할 SK Y 좌표
 * @param longitude 변경된 WGS84 longitude 좌표
 * @param latitude 변경된 WGS84 latitude 좌표
 */
+(BOOL) convertSkToWgs84:(double)skX
                     skY:(double)skY
               longitude:(double *_Nonnull)longitude
                latitude:(double *_Nonnull)latitude;

/**
 * SK 좌표를 Bessel 좌표로 변환합니다.
 *
 * @param skX 변경할 SK X 좌표
 * @param skY 변경할 SK Y 좌표
 * @param longitude 변경된 Bessel longitude 좌표
 * @param latitude 변경된 Bessel latitude 좌표
 */
+(BOOL) convertSkToBessel:(double)skX
                      skY:(double)skY
                longitude:(double *_Nonnull)longitude
                 latitude:(double *_Nonnull)latitude;

/**
 * Bessel 좌표를 World 좌표로 변환합니다.
 *
 * @param longitude 변경할 Bessel longitude 좌표
 * @param latitude 변경할 Bessel latitude 좌표
 * @param worldX 변경된 World X 좌표
 * @param worldY 변경된 World Y 좌표
 */
+(BOOL) convertBesselToWorld:(double)longitude
                    latitude:(double)latitude
                      worldX:(double *_Nonnull)worldX
                      worldY:(double *_Nonnull)worldY;

/**
 * Bessel 좌표를 WGS84 좌표로 변환합니다.
 *
 * @param longitude 변경할 Bessel longitude 좌표
 * @param latitude 변경할 Bessel latitude 좌표
 * @param Wgs84Lon 변경된 WGS84 longitude 좌표
 * @param Wgs84Lat 변경된 WGS84 latitude 좌표
 */
+(BOOL) convertBesselToWgs84:(double)longitude
                    latitude:(double)latitude
                   longitude:(double *_Nonnull)Wgs84Lon
                    latitude:(double *_Nonnull)Wgs84Lat;

/**
 * Bessel 좌표를 SK 좌표로 변환합니다.
 *
 * @param longitude 변경할 Bessel longitude 좌표
 * @param latitude 변경할 Bessel latitude 좌표
 * @param skX 변경된 SK X 좌표
 * @param skY 변경된 SK Y 좌표
 */
+(BOOL) convertBesselToSk:(double)longitude
                 latitude:(double)latitude
                      skX:(double *_Nonnull)skX
                      skY:(double *_Nonnull)skY;

/**
 * WGS84 좌표로 부터 주소를 받아옵니다.(Network 이용)
 *
 * @param appKey appKey
 * @param point 조회할 WGS84 경위도 좌표
 * @param isStreedName 도로명 주소 여부
 * @return 주소
 * @see VSMMapPoint
 */
+(NSString *_Nullable) getOnlineAddress:(NSString *_Nonnull)appKey
                 point:(VSMMapPoint *_Nonnull)point
                 isStreedName:(BOOL)isStreedName;

/**
 * WGS84 좌표로 부터 주소를 받아옵니다. (local DB 이용)
 *
 * @param point 조회할 WGS84 경위도 좌표
 * @return 주소
 * @see VSMMapPoint
 */
+(NSString *_Nonnull) getAreaName:(VSMMapPoint *_Nullable)point;

/**
 * WGS84 좌표로 부터 주소를 받아옵니다. (local DB 이용)
 *
 * @param point 조회할 WGS84 경위도 좌표
 * @return 상세 주소
 * @see VSMMapPoint
 */
+(VSMDetailedAddress*_Nonnull) getDetailedAreaName:(VSMMapPoint*_Nonnull)point;

@end
