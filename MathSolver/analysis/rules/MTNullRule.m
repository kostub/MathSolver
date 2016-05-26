//
//  NullRule.m
//
//  Created by Kostub Deshmukh on 7/15/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTNullRule.h"
#import "MTExpression.h"

@implementation MTNullRule

- (MTExpression *)applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    // This rule only applies to operators
    if (expr.expressionType != kMTExpressionTypeOperator) {
        return expr;
    }
    // If any argument is null, this returns null.
    for (MTExpression *arg in args) {
        if (arg.expressionType == kMTExpressionTypeNull) {
            return arg;
        }
    }
    return expr;
}

@end
