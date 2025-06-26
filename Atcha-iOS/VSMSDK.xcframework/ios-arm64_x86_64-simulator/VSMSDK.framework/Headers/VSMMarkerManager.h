//
//  VSMMarkerManager.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 1. 26..
//

#import <Foundation/Foundation.h>

@class VSMMarkerBase;
@class VSMMapView;

/** VSMMapView에 종속적인 마커 관리자 객체합니다.
*/
@interface VSMMarkerManager : NSObject

/**
 * 마커 관리자를 소유중인 맵 뷰
 * @see VSMMapView
 */
@property (nonatomic, weak) VSMMapView* vsmView;

-(void) viewWillAppear;
-(void) viewWillDisappear;

/** marker를 추가합니다.
 @param marker 마커 데이터 객체
 @return boolean 변환 성공 여부.
 @see VSMMarkerBase
 */
-(BOOL) addMarker:(VSMMarkerBase*) marker;

/** marker를 제거합니다.
 @param marker 마커 데이터 객체
 @return boolean 변환 성공 여부.
 @see VSMMarkerBase
 */
-(BOOL) removeMarker:(VSMMarkerBase*) marker;

/** 모든 marker를 제거합니다.
 */
-(void) removeAllMarkers;

/** 마커 ID에 해당하는 마커를 반환합니다.
 * @param markerId 마커ID
 * @return 마커ID에 해당하는 마커
 */
-(VSMMarkerBase*) getMarker:(NSString*) markerId;

/** 오브젝트 ID에 해당하는 마커를 반환합니다.
 * @param objectId 오브젝트ID
 * @return 오브젝트ID에 해당하는 마커
 */
-(VSMMarkerBase*) getMarkerWithObjectId:(NSUInteger) objectId;

#if 0
/** internal use, 마커의 위경도 bbox
 */
-(LatLonBounds*) getBounds;
#endif

@end
