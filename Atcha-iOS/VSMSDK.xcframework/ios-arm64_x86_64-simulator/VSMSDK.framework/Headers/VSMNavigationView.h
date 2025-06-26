//
//  VSMNavigationView.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 20..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import "VSMMapView.h"

/**
 * Navigation View에서 사용되는 상수 정의 클래스.
 */
typedef NS_ENUM(NSUInteger, eNaviMoveMode) {
    /**
     * Map Map 상태로 이동
     */
    MODE_MAP = 0,
    /**
     * Map Navi 상태로 이동
     */
    MODE_NAVI = 1,
    /**
     * Map Simul 상태로 이동
     */
    MODE_SIMUL = 2
};

/**
 * 네비게이션 뷰모드 타입
 */
typedef NS_ENUM(NSUInteger, eNaviViewMode) {
    /** 노말 */
    VIEW_NORMAL = 0,
    /** 지도 정북 기준 보기  */
    VIEW_NORTHBOUND = 1,
    /** 지도 진행방향 기준 보기 */
    VIEW_HEADUP = 2,
    /** 지도 버드뷰 보기 */
    VIEW_BIRDVIEW = 3
};

@class VSMSDI;
@class VSMRouteData;
@class VSMAlternativeRouteInfo;

/**
 Navigation 렌더링 관련 기능을 제공하는 class
 */
@interface VSMNavigationView : VSMMapView

/** 내비게이션용 이동 모드 (조회 상태 / 실주행 상태 / 가상주행 상태)
 * @see eNaviViewMode
 */
@property (nonatomic, assign) eNaviViewMode naviViewMode;

/**    지도 보기 모드 (정북보기, 진행방향보기, 버드뷰보기)
 *     @see eNaviViewMode
 */
@property (nonatomic, assign) eNaviMoveMode naviMoveMode;


/**
 * Screen Center 값을 계산합니다. 특정 view mode에서 자차의 center 위치를 변경하고자 할 경우 override 합니다.
 *
 * @param width View의 width
 * @param height View의 height
 * @param viewMode View의 보기 모드(정북 방향 보기 / 진행 방향 보기 / 버드뷰)
 * @param moveMode 이동 모드(지도 / 내비 / 시뮬레이션)
 * @return Screen Center
 * @see eNaviViewMode
 * @see eNaviMoveMode
 */
- (CGPoint)computeScreenCenter:(int)width
                        height:(int)height
                      viewMode:(eNaviViewMode)viewMode
                      moveMode:(eNaviMoveMode)moveMode;

#pragma mark - Route Drawing API

/** Engine에 지정된 경로중 하나를 선택합니다.

@param index 선택할 경로 ID
 */
- (void) selectRouteLine:(NSInteger) index;

/** Engine에 지정된 경로를 따라갈 것임을 알려줍니다.

*/
- (void) applySelectRouteLine;

/** 경로 렌더링 속성을 설정합니다.
 * @param show 경로선 표출 여부
 * @param showFlag 경로 렌더링 속성
 * @see ShowRouteFlag
 */
- (void) setShowRoute:(BOOL)show
             showFlag:(ShowRouteFlag)showFlag;

/** Engine에 지정된 경로중 하나를 View Level에 맞게 출력되도록 선택합니다.
 @param routeIndex 선택할 경로 ID
 */
- (void) renderRouteLineFitInView:(NSInteger) routeIndex __attribute__((deprecated("Replaced by -drawRectFitInView:minWorldX:minWorldY:maxWorldX:maxWorldY:")));

/** 지정된 경로를 지웁니다.
 */
- (void) clearRouteLine;

/** 지정된 경로를 지웁니다.
 * @param keepDestinationFlag 도착지 삭제 여부
 */
- (void) clearRouteLine:(BOOL)keepDestinationFlag;

/** 경로선을 그립니다.
 
 @param index 도로 ID
 @param rect 도로 ID
 @param showsOilInfo true라면 경로 상의 유가정보를 표출합니다.
 @param showsMainRoadInfo true라면 주요 도로명을 표출합니다.
 */
- (void)drawRouteForIndex:(NSInteger)index
                   inRect:(CGRect)rect
             showsOilInfo:(BOOL)showsOilInfo
        showsMainRoadInfo:(BOOL)showsMainRoadInfo __attribute__((deprecated("Replaced by -drawRectFitInView:minWorldX:minWorldY:maxWorldX:maxWorldY:")));


/** 경로 상의 주유소/유가 정보를 표시합니다.
 
 @param poiIds 주유소 POI의 ID, 빈 배열을
 @param lowestPricePoiId 최저가 주유소의 ID, 앱에서 경로 데이터의 주유소 가격 정보를 이용하여 사용자 타입에 맞는 최저가 주유소의 ID를 넘겨줘야 합니다.
 @param oilType 사용자가 사용하는 유류타입 (0: gasoline, 1: dissel, 2: LPG, 3: Electrocity, 4: PremiumGasoline)
 
 */
- (void)drawGasStationInfo:(NSArray *_Nullable)poiIds
          lowestPricePoiId:(NSUInteger)lowestPricePoiId
                   oilType:(NSInteger)oilType;

/** 맵엔진(네이티브 엔진)으로 경로 데이터를 설정한다.
 @param routeDataArray 출발지, 도착지 정보
 @param isReroute 경로 재탐색 유무
 @return 설정 성공 여부
 */
-(BOOL) setDrawRouteData:(NSArray<NSData *> *_Nullable)routeDataArray
               isReroute:(BOOL)isReroute;

/** 맵엔진(네이티브 엔진)으로 경로 데이터를 설정한다.
 * @param routeItems 경로 데이터
 * @param keepDepartureFlag  출발지 유지 여부
 * @return 설정 성공 여부
 * @see VSMRouteData
 */
- (BOOL) setDrawRouteData:(NSArray<VSMRouteData *> *_Nullable)routeItems
                          keepDepartureFlag:(BOOL)keepDepartureFlag;

/** Safe drive info를 추가합니다.
 사고다발, 과속카메라, 방지턱 등등 도로 안전 운행 정보를 출력합니다.
 @param pstSDI 주행 경로 상세 정보, nil값을 넣으면 아무 기능도 하지 않습니다.
 @return 설정 성공 여부
 @see VSMSDI
 */
-(BOOL) setCurrentRGSDI:(nullable VSMSDI*)pstSDI;

-(BOOL) setCurrentRGSDI:(nullable VSMSDI*)pstSDI scale:(float)scale;

/**
 * 표시할 RG SDI 데이터 정보를 설정합니다. 제한속도 정보를 텍스트로 표출합니다.
 * Setting config - NAVI_MAP_OPTION 에 정의된 텍스트 속성을 사용합니다.
 * @param sdiData
 * @return
 */
-(BOOL) setCurrentRGSDIv2:(nullable VSMSDI*)pstSDI;
-(BOOL) setCurrentRGSDIv2:(nullable VSMSDI*)pstSDI scale:(float)scale;

#pragma mark - Traffic information API

/**
 * 교통 정보 렌더링 여부(Default: NO)
 */
@property (nonatomic, assign) BOOL showTrafficInfoOnRouteLine;

/** 뷰모드 변경시 Track모드 자동 변경(Default: YES)
 */
@property (nonatomic, assign) BOOL autoChangeTrackMode;

/** 뷰모드 변경시 Gesture 자동 변경(Default: YES)
 */
@property (nonatomic, assign) BOOL autoChangeGesture;

/** 뷰모드 변경시 지도/뷰 각도 자동 변경(Default: YES)
 */
@property (nonatomic, assign) BOOL autoChangeAngles;

/** 경로가 지나가는 타일 다운로드 설정(Default: NO)
 */
@property (nonatomic) BOOL downloadRouteTile;


#pragma mark - Unreleased API

//---------------------------------------------------------------------------------------------
// Unreleased API - 개발 계획중인 API
//---------------------------------------------------------------------------------------------
///** 경로 표출 스타일을 지정한다
//
// @param type 경로 타입:RouteTypeBasic(기본경로), RouteTypePassed(지나온 경로), RouteTypeAlternative(대안경로)
// @param basicColor 경로선색
// @param basicOutlineColor 경로선외곽선색
// @param nightColor 야간모드 경로선색
// @param nightOutlineColor 야간모드 경로선외곽선색
//
// @return 경로표출 스타일 지정 성공/실패
// */
//- (BOOL) setRouteDrawStyle:(RouteType) type
//                basicColor:(NSUInteger) basicColor
//         basicOutlineColor:(NSUInteger) basicOutlineColor
//                nightColor:(NSUInteger) nightColor
//         nightOutlineColor:(NSUInteger) nightOutlineColor


//v1.39
//@property (nonatomic) NSInteger oilType;


//-(BOOL) ForceSetMapPositionWithCurrentLocation;

//-(BOOL) ForceSetAlternativeStartPoint:(NSInteger)worldX
//                               worldY:(NSInteger)worldY;


/** 최저가 유가 정보만 표출한다.
 */
//- (void)drawLowestOilInfoOnly;

#pragma mark -

/**
 * 경로 바이너리 데이터 설정합니다.
 * @param routeData 경로 바이너리 데이터 immutable array
 * @return 설정 성공 여부
 */
- (BOOL)setRouteData:(NSArray<NSData *> *_Nullable)routeData;

/**
 * 경로 정보 렌더링 여부를 설정합니다.
 * @param show True(경로정보 렌더링) False(경로정보 스킵)
 */
- (void)setShowRoute:(BOOL)show;

/**
 * 경로 렌더링 속성을 설정합니다.
 * @param flag 경로 렌더링 속성
 * @see ShowRouteFlag
 */
- (void)setShowRouteFlag:(ShowRouteFlag)flag;

// 설정된 경로를 rect 안에 그립니다.
- (void)drawSelectedRouteInRect:(CGRect)rect __attribute__((deprecated("Replaced by -drawRectFitInView:minWorldX:minWorldY:maxWorldX:maxWorldY:")));

/**
 * 대안경로 정보를 설정합니다.
 * @param info 안경로 정보
 * @see VSMAlternativeRouteInfo
 *
 * */
- (void)setAlternativeRouteInfo:(nullable VSMAlternativeRouteInfo*)info;

#pragma mark - Object Theme

/** Object Theme 설정
 @see eObjectThemeType
 */
@property (nonatomic, assign) uint32_t objectTheme;

/** Object theme는 지도 위의 객체(경로선, 교통정보 등)에 대한 스타일을 갖고 있습니다.
 THEME_DAY 및 THEME_NIGHT는 기본값으로 제공되며, 신규로 object theme를 생성할 수 있습니다.
 
 @param theme 생성할 theme로 THEME_USER_DEFINE 이상의 값
 @param baseTheme 명시한 object theme를 기본값으로 생성합니다.
 @see eObjectThemeType
 */
-(BOOL) createObjectTheme:(uint32_t)theme baseTheme:(uint32_t)baseTheme;

/** object theme 내의 스타일을 업데이트 합니다.
 @param theme 테마
 @param jsonData 속성 (참조 : https://tde.sktelecom.com/wiki/display/TMAPVSMSDK/Theme )
 @see eObjectThemeType
 */
-(BOOL) updateObjectTheme:(uint32_t)theme jsonData:(NSString *_Nullable)jsonData;

#pragma mark - Overridden Methods

/** 엔진에서 수신된 HitTest 결과를 가로채어 NaviRenderer에 전달합니다.
 * @see HitObjectType
 * @see MeterPoint
 * @see ObjectProperty
 */
- (void)dispatchHitTestResult:(HitObjectType)type
                     objectID:(int)objectID
                   meterPoint:(MeterPoint *_Nullable)meterPoint
                     property:(ObjectProperty *_Nullable)property
                   hitCallout:(bool)hitCallout
                  showCallout:(bool *_Nullable)showCallout;

/** 엔진에서 수신된 View Level 변경 이벤트를 가로채어 NaviRenderer에 전달합니다.
 */
- (void)dispatchViewLevelChanged:(int32_t)level subLevel:(int32_t)subLevel;

/** 지정한 사각영역(스크린좌표)에 지도상의 남서 좌표와 북동 좌표가 맞도록 지도를 이동시킵니다.
 * @param rect Fit시키고 싶은 사각영역
 * @param northEast 지도의 북동 좌표  (WGS84)
 * @param southWest 지도의 남서 좌표 (WGS84)
 * @see VSMMapPoint
 */
-(void)drawRectFitInView:(CGRect)rect
               northEast:(VSMMapPoint* _Nonnull)northEast
               southWest:(VSMMapPoint* _Nonnull)southWest;

/** 주유소 및 충전소 팝업 객체 선택 혹은 해제합니다.
 *@param oilInfoID 대상 주유소 ID
 *@param selected 선택 / 해제 여부
 */
-(void) selectOilInfo:(NSInteger) oilInfoID
             selected:(BOOL)selected;

/** 주유소 및 충전소 팝업 객체 선택상태를 얻어옵니다.
 * @return 해당 객체의 선택여부
*/
-(BOOL) isSelectedOilInfo:(NSInteger) oilInfoID;

/** 주유소 및 충전소 팝업을 선택해제합니다.
*/
-(void) unselectAllOilInfo;

/**
 * 경로데이터 string encoding charset을 설정합니다.
 * 기본값은 kCFStringEncodingDOSKorean 입니다.
 */
-(void) setNaviCharset:(NSStringEncoding) charset;
@end
