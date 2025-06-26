//
//  MarkerImage.h
//  HelloVSMiOS
//
//  Created by 박창선님/Map플랫폼개발팀 on 2021/05/11.
//  Copyright © 2021 sktelecom. All rights reserved.
//

#ifndef MarkerImage_h
#define MarkerImage_h
#import <UIKit/UIKit.h>

/** 마커(오버레이)에서 사용하는 비트맵 이미지를 나타내는 불변 클래스.
 *  팩토리 메서드를 이용해 UIImage, imageName 등으로부터 인스턴스를 생성할 수 있습니다.
 */
@interface MarkerImage : NSObject

/** 재사용 식별자.
 */
@property (nonatomic, copy, readonly) NSString* _Nonnull reuseIdentifier;

/** 이미지.
 */
@property (nonatomic, retain, readonly) UIImage* _Nullable image;

/**
 * UIImage로부터 MarkerImage 객체를 생성합니다.
 * @param image 이미지
 * @return MarkerImage
 */
+ (nonnull instancetype)markerImageWithImage:(nonnull UIImage*)image;

/**
 * App 번들의 asset에 존재하는 이미지로부터 MarkerImage 객체를 생성합니다.
 * @param imageName 이미지 이름
 * @return MarkerImage
 */
+ (nonnull instancetype)markerImageWithImageName:(nonnull NSString*)imageName;

/**
 * 지정한 bundle의 asset에 존재하는 이미지로부터 MarkerImage 객체를 생성합니다.
 * @param imageName 이미지 이름
 * @param bundle 이미지를 가져올 번들
 * @return MarkerImage
 */
+ (nonnull instancetype)markerImageWithImageName:(nonnull NSString*)imageName bundle:(nonnull NSBundle*)bundle;

@end

#endif /* MarkerImage_h */
