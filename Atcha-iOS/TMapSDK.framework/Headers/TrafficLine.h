

#import <Foundation/Foundation.h>
#import "VSMSDK/VSMMapPoint.h"
#import "VSMSDK/VSMMarkerRouteLine.h"

NS_ASSUME_NONNULL_BEGIN

@interface TrafficLine : NSObject
    @property int traffic;
    @property NSArray<VSMMapPoint*>* vertices;
@end

@interface VSMTrafficLine : NSObject
-(VSMMarkerRouteLine*)createMarker:(NSArray<TrafficLine*>*)trafficLine params:(VSMMarkerRouteLineParams*) params;

@end

NS_ASSUME_NONNULL_END
