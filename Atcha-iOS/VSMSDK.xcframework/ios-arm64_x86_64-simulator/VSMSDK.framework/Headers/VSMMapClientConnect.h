//
//  VSMMapClientConnect.hpp
//  VSMInterface
//
//  Created by 1001921 on 2018. 2. 2..
//

#ifndef VSMMapClientConnect_h
#define VSMMapClientConnect_h

#include "VSM.h"
#include "VSM_Map.h"
#import "VSMMapView.h"
#import "VSMHitProperty.h"

namespace vsm {
class VSMMapClientConnect : public MapClient {
   private:
    VSMMapView* view;

   public:
    VSMMapClientConnect(VSMMapView* v);
    virtual ~VSMMapClientConnect();

   public:
    void onPositionChanged(Double wX, Double wY) override;

    void onViewLevelChanged(UInt8 viewLevel, UInt32 viewSubLevel) override;

    void onViewAngleChanged(Float angle) override;

    void onViewTiltChanged(Float tiltAngle) override;

    void onHitObject(Int32 type, Int32 objectID, Double worldX, Double worldY, const PickedObjectProperty& property,
                     Bool& showCallout) override;

    void onHitCallout(Int32 type, Int32 objectID, Double worldX, Double worldY,
                      const PickedObjectProperty& property) override;

    void onHitMultiObject(const std::vector<PickedObjectProperty>& pickedList, Bool& showCallout) override;

    void onCameraAnimationBegan() override;
    void onCameraAnimationEnded() override;

    void onUserGestureBegan() override;
    void onUserGestureEnded(bool cameraAnimationEnabled) override;

   private:
    ObjectProperty* convertProperty(const PickedObjectProperty* source);
    VSMHitProperty* convertHitProperty(const PickedObjectProperty* source);
};
}  // namespace vsm
#endif /* VSMMapClientConnect_h */
