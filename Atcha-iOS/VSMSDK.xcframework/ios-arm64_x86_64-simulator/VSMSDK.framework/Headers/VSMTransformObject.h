//
//  VSMTransformObject.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 1. 31..
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (*CB_TRANSLATION_FLING)(void* view);

@interface MapTransformData : NSObject

@property (nonatomic) BOOL isNeedTransform;
@property (nonatomic) float scale;
@property (nonatomic) CGPoint scalePoint;
@property (nonatomic) float rotate;
@property (nonatomic) CGPoint rotateCenter;
@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint targetPoint;
@property (nonatomic) float fAmount;
@property (nonatomic) float fDegree;
@property (nonatomic) float tiltPercent;
@property (nonatomic) float fScale;
@property (nonatomic, assign) CB_TRANSLATION_FLING cameraTranslationFlingCB;
@property (nonatomic, assign) void* injection;

- (instancetype)init;
- (instancetype)initWithData:(MapTransformData*)data;
- (void)set:(MapTransformData*)data;
- (void)clear;

@end

@interface VSMTransformObject : NSObject

- (MapTransformData*)transformData;

- (void)scaleTo:(float)scale atScalePoint:(CGPoint)point;

- (void)rotateTo:(float)angle rotateCenter:(CGPoint)point;

- (void)translateFrom:(CGPoint)start toTargetPoint:(CGPoint)target;

- (void)translateAccumulate:(CGPoint)target;

- (void)tiltTo:(float)tiltPercent;

- (void)flingTo:(float)amount degree:(float)degree;

- (void)flingScale:(float)amount scale:(float)scale;

- (void)commit;

// reset transform request state
- (void)clear;

- (void)setTranslationAnimationEndCallback:(CB_TRANSLATION_FLING)func injection:(void*)injection;

@end
