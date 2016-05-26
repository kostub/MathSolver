//
//  FlattenRule.h
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "Rule.h"

@class Expression;

// Flattens operators from binary to n-ary.
@interface FlattenRule : Rule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args;

@end
