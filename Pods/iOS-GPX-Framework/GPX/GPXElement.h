//
//  GPXElement.h
//  GPX Framework
//
//  Created by NextBusinessSystem on 12/04/06.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import "GPXType.h"


/** GPXElement is the root class of GPX element hierarchies. 
 */
@interface GPXElement : NSObject


/// ---------------------------------
/// @name Accessing Element Properties
/// ---------------------------------

/** A parent GPXElement of the receiver.
 */
@property (unsafe_unretained, nonatomic) GPXElement *parent;


/// ---------------------------------
/// @name GPX
/// ---------------------------------

/** Return the GPX generated by the receiver.
 @return The GPX string.
 */
- (NSString *)gpx;

@end
