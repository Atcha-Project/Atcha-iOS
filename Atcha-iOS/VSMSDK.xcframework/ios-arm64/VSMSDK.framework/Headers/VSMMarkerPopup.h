#import <UIKit/UIKit.h>
#import "VSMMarkerBase.h"
#import "MarkerImage.h"


@class VSMMapPoint;

NS_ASSUME_NONNULL_BEGIN

/** overlap 여부에 의한 동적배치를 위한 정보
 */
@interface VSMMarkerPopupPlacement : NSObject

/** viewImage - 적용할 이미지, 디폴트: nil
 * @see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* viewImage;

/** offset - 디폴트: (0, 0)
 *  배치해야 할 위치로부터의 offset입니다.
 */
@property (nonatomic, assign) CGPoint offset;

/** anchor -  디폴트:(0.5, 1)
 * 아이콘 내부 영역중 position좌표와 일치되는 정규화된 좌표. 좌상단은 (0, 0)이고 우상단은 (1, 1)입니다.
 */
@property (nonatomic, assign) CGPoint anchor;

/** anchor - 마커 사이즈, 디폴트:(20, 20)
 */
@property (nonatomic, assign) CGPoint size;

/**
 * 프로퍼티들의 유효성 검사
 * Native Marekr 생성 전에 검사하게 됩니다.
 */
- (BOOL)checkValidity;

@end

/**
 * 팝업 마커 생성을 위한 파라미터입니다.
 */
@interface VSMMarkerPopupParams : VSMMarkerBaseParams

/** 마커가 위치할 좌표(WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** 마커 전용 아이콘 이미지
 * @see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* viewImage;

/** viewAnchor - 디폴트: (1, 0.5)
 * 아이콘 내부 영역중 position좌표와 일치되는 정규화된 좌표. 좌상단은 (0, 0)이고 우상단은 (1, 1)입니다.
 */
@property (nonatomic, assign) CGPoint viewAnchor;

/** viewSize - 디폴트: (0, 0)
 * 띄울 뷰의 사이즈이니다.
 */
@property (nonatomic, assign) CGSize viewSize;

/** viewOffset - 디폴트:(0, 0)
 *  마커 Position을 기준으로 뷰 위치를 이동합니다. (DP 단위)
 */
@property (nonatomic, assign) CGPoint viewOffset;

/** scale - 디폴트: 1
 * 띄울 뷰의 스케일입니다.
 */
@property (nonatomic, assign) float scale;

/** altitude - 디폴트: 0
 * 고도값입니다.
 */
@property (nonatomic, assign) float altitude;

/** alpha - 유효범위:0~1 디폴트: 1
 * 투명도입니다.
 */
@property (nonatomic, assign) float alpha;

/** rotation - 디폴트: 0
 * 배치시 회전각을 의미합니다. (시계방향)
 */
@property (nonatomic, assign) float rotation;

/** overlapTestEnabled - 디폴트: NO
 * 마커간 충돌 검사를 진행할 지 여부입니다.
 */
@property (nonatomic, assign) BOOL overlapTestEnabled;

/** animationEnabled - 디폴트: YES
 *  마커가 나타나고 사라질 때, fade-in/out 효과 적용 여부입니다.
 */
@property (nonatomic, assign) BOOL animationEnabled;

/** coverPoi - 디폴트: YES
 * POI와 겹칠시 겹쳐진 POI를 삭제 시킬지 여부입니다.
 */
@property (nonatomic, assign) BOOL coverPoi;

/** perspectiveEnabled - 디폴트: NO
 */
@property (nonatomic, assign) BOOL perspectiveEnabled;

/** blockViewBitmapScale - 디폴트: YES
 *  팝업 이미지의 스케일 변경 수용 여부.
 */
@property (nonatomic, assign) BOOL blockViewBitmapScale;

/** grade - 디폴트: 0
 *  poi와 겹침시 ranking값
 */
@property (nonatomic, assign) int32_t grade;

/**
 * 동적 배치 요소
 * @see VSMMarkerPopupPlacement
 */
@property (nonatomic, strong) NSMutableArray<VSMMarkerPopupPlacement*>* placements;

/**
 * PopupPlacement 유효성 검사 수행 여부
 */
@property (nonatomic, assign) BOOL insideScreen;

/**
 * PopupPlacement 유효성 검사 일회성 수행 여부
 */
@property (nonatomic, assign) BOOL insideScreenOnetime;

/**
 * UIView로 부터 마커 Icon을 생성합니다.
 * @param view 아이콘화 시킬 view
 */
- (void)setViewImageWithView:(UIView*)view;

@end

/**
 * 마커(오버레이) 팝업 클래스입니다.
 * 지도위에 팝업창을 띄우기 위해 사용합니다.
 */
@interface VSMMarkerPopup : VSMMarkerBase

/** 마커가 위치할 좌표(WGS84)
 * @see VSMMapPoint
 */
@property (nonatomic, strong) VSMMapPoint* position;

/** 마커 전용 아이콘 이미지
 * @see MarkerImage
 */
@property (nonatomic, strong) MarkerImage* viewImage;

/** viewAnchor
 * 아이콘 내부 영역중 position좌표와 일치되는 정규화된 좌표. 좌상단은 (0, 0)이고 우상단은 (1, 1)입니다.
 */
@property (nonatomic, assign) CGPoint viewAnchor;

/** viewSize
 * 띄울 뷰의 사이즈이니다.
 */
@property (nonatomic, assign) CGSize viewSize;

/** viewOffset
 *  마커 Position을 기준으로 뷰 위치를 이동합니다. (DP 단위)
 */
@property (nonatomic, assign) CGPoint viewOffset;

/** scale
 * 띄울 뷰의 스케일입니다.
 */
@property (nonatomic, assign) float scale;

/** altitude
 * 고도값입니다.
 */
@property (nonatomic, assign) float altitude;

/** alpha - 유효범위:0~1
 * 투명도입니다.
 */
@property (nonatomic, assign) float alpha;

/** rotation
 * 배치시 회전각을 의미합니다. (시계방향)
 */
@property (nonatomic, assign) float rotation;

/** overlapTestEnabled
 * 마커간 충돌 검사를 진행할 지 여부입니다.
 */
@property (nonatomic, assign) BOOL overlapTestEnabled;

/** animationEnabled
 *  마커가 나타나고 사라질 때, fade-in/out 효과 적용 여부입니다.
 */
@property (nonatomic, assign) BOOL animationEnabled;

/** coverPoi -
 * POI와 겹칠시 겹쳐진 POI를 삭제 시킬지 여부입니다.
 */
@property (nonatomic, assign) BOOL coverPoi;

/** perspectiveEnabled
 */
@property (nonatomic, assign) BOOL perspectiveEnabled;

/** blockViewBitmapScale
 *  팝업 이미지의 스케일 변경 수용 여부.
 */
@property (nonatomic, assign) BOOL blockViewBitmapScale;

/** grade
 *  poi와 겹침시 ranking값
 */
@property (nonatomic, assign) int32_t grade;

/**
 * 동적 배치 요소
 * @see VSMMarkerPopupPlacement
 */
@property (nonatomic, strong) NSMutableArray<VSMMarkerPopupPlacement*>* placements;

/**
 * PopupPlacement 유효성 검사 수행 여부
 */
@property (nonatomic, assign) BOOL insideScreen;

/**
 * PopupPlacement 유효성 검사 일회성 수행 여부
 */
@property (nonatomic, assign) BOOL insideScreenOnetime;

/**
 * 초기화 메소드
 * @param markerID 마커 ID. 삭제/제어시 필요합니다.
 * @param params 빌드 파라미터
 * @see VSMMarkerPopupParams
 */
- (instancetype)initWithID:(NSString*)markerID params:(VSMMarkerPopupParams *)params;

/**
 * UIView로 부터 마커 Icon을 생성합니다.
 * @param view 아이콘화 시킬 view
 */
- (void)setViewImageWithView:(UIView*)view;

/**
 * 동적 배치 요소를 추가합니다.
 * @param placement 동적 배치 요소
 */
- (void)addPlacement:(VSMMarkerPopupPlacement*)placement;


/**
 * 모든 배치 요소를 삭제합니다.
 */
- (void)removeAllPlacements;


@end

NS_ASSUME_NONNULL_END
