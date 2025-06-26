//
//  VSMMapViewController.h
//  VSMSDK_static
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/06/24.
//  Copyright © 2021 sktelecom. All rights reserved.
//

// NS_ASSUME_NONNULL_BEGIN
#import <UIKit/UIKit.h>

@class VSMMapView;

/**
 * 지도 뷰를 제어하는 컨트롤러
 */
@interface VSMMapViewController : UIViewController

/**
 *지도 뷰
 */
@property (nonatomic, retain) VSMMapView* vsmMapView;

@end

// NS_ASSUME_NONNULL_END
