//
//  DistributionRule.h
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "Rule.h"
#import "MTExpression.h"

// Distributes multiplication over addition.
@interface DistributionRule : Rule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args;

// Returns true if a operator can be distributed on. Only expressions of the form a*(b+c) are
// considered distributable. Does not recurse to children of the operator.
+(BOOL) canDistribute:(MTExpression*) expr;

// Get all the children of expr which can be distributed on. E.g. for a*(b+c) will return (b+c)
// For a(b+c)(d+e) will return an array containing (b+c) and (d+e).
+(NSArray*) getDistributees:(MTExpression*) expr;

@end
