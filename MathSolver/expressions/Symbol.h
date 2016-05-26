//
//  Symbol.h
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

@interface Symbol : NSObject

enum Type {
    kVariable = 1,
    kNumber,
    kOperator,
    kOpenParen,
    kClosedParen,
    kRelation
};


// Create an symbol with type and value
+ (id) symbolWithType:(enum Type) type value:(NSNumber*) value offset:(NSRange) offset;

- (unichar) charValue;
- (unsigned int) intValue;

@property (nonatomic, readonly) enum Type type;
@property (nonatomic, readonly) NSNumber *value;
@property (nonatomic, readonly) NSRange offset;

@end

