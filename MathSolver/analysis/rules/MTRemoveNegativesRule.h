//
//  RemoveNegativesRule.h
//
//  Created by Kostub Deshmukh on 7/18/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "MTRule.h"

@class MTExpression;

// Removes -ve signs and subtraction operators.
@interface MTRemoveNegativesRule : MTRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args;

@end
