//
//  VSMSDK.h
//  VSMSDK
//
//  Created by 전효성님/Map플랫폼개발 Cell on 2020/05/06.
//  Copyright © 2020 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>

// VSMCoordinates
#import "VSMCoordinates.h"
#import "VSMMapPoint.h"

// VSMConfig
#import "VSMConfiguration.h"
#import "VSMConfigurationDataManager.h"
#import "VSMConfigurationLoader.h"
#import "VSMLoaderOptions.h"
#import "VSMRawImageBundleResource.h"
#import "VSMRawImageBundleResourcePackage.h"
#import "VSMResource.h"
#import "VSMResourceLoader.h"
#import "VSMResourcePackageData.h"
#import "VSMStyleData.h"
#import "VSMLayerData.h"
#import "VSMStackData.h"

// VSMData
#import "VSMAlternativeRouteInfo.h"
#import "VSMRouteData.h"
#import "VSMSDI.h"
#import "SdiCodeConvert.h"  // deprecated

// VSMLocation
#import "VSMLocation.h"
#import "VSMLocationComponent.h"
#import "VSMLocationManager.h"
#import "VSMLocationProviderDelegate.h"

// VSMMap
#import "ObjectProperty.h"
#import "VSMMap.h"
#import "VSMMapDefine.h"
#import "VSMMapView.h"
#import "VSMMapViewDefine.h"
#import "VSMNavigationView.h"
#import "VSMTileLoader.h"
#import "VSMCameraUpdate.h"

// VSMMarker
#import "VSMMarkerBase.h"
#import "VSMMarkerCircle.h"
#import "VSMMarkerLocation.h"
#import "VSMMarkerManager.h"
#import "VSMMarkerPoint.h"
#import "VSMMarkerPolygon.h"
#import "VSMMarkerPolyline.h"
#import "VSMMarkerPopup.h"
#import "VSMMarkerRouteLine.h"
#import "VSMMarkerGround.h"

// NaviRenderer
#import "VSMMatchedLocation.h"


//! Project version number for VSMSDK.
FOUNDATION_EXPORT double VSMSDKVersionNumber;

//! Project version string for VSMSDK.
FOUNDATION_EXPORT const unsigned char VSMSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <VSMSDK/PublicHeader.h>
