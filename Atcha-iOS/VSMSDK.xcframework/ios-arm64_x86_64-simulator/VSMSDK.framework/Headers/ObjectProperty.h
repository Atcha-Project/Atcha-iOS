//
//  ObjectProperty.h
//  VSMInterface
//
//  Created by 1001921 on 2018. 3. 7..
//  Copyright © 2018년 sktelecom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjectProperty : NSObject

@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly) NSString* contents;
@property (nonatomic, strong, readonly) NSString* imagePath;
@property (nonatomic, assign, readonly) uint32_t callbackType;
@property (nonatomic, strong, readonly) NSDictionary* extrasList;

- (instancetype)initWithCallbackType:(uint32_t)callbackType;

- (instancetype)initWithCallbackType:(uint32_t)callbackType
                                name:(NSString*)name;

- (instancetype)initWithCallbackType:(uint32_t)callbackType
                                name:(NSString*)name
                            contents:(NSString*)contents
                           imagePath:(NSString*)imagePath
                          extrasList:(NSDictionary*)extras;

@end

NS_ASSUME_NONNULL_END
