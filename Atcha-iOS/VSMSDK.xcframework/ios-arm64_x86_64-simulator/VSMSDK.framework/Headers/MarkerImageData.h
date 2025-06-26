//
//  MarkerImageData.h
//  VSMSDK
//
//  Created by vsm on 2018. 4. 27..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MarkerImageData : NSObject

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger pitch;
@property (nonatomic, assign) NSInteger bpp;
@property (nonatomic, strong) NSData* data;
@property (nonatomic, assign) BOOL premultipliedAlpha;

+ (MarkerImageData*)imageDataFromUIImage:(UIImage*)image;

@end
