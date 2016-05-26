//
//  ReduceRule.m
//
//  Created by Kostub Deshmukh on 9/11/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTReduceRule.h"
#import "MTExpression.h"

@implementation MTReduceRule

- (MTExpression *)applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if (expr.expressionType == kMTExpressionTypeNumber) {
        MTRational* value = expr.expressionValue;
        if (!value.isReduced) {
            return [MTNumber numberWithValue:value.reduced];
        }
    }
    return expr;
}

@end
