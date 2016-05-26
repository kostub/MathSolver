//
//  DecimalReduceRule.m
//
//  Created by Kostub Deshmukh on 10/11/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTDecimalReduceRule.h"
#import "MTExpression.h"

@implementation MTDecimalReduceRule

- (MTExpression *)applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if (expr.expressionType == kMTExpressionTypeNumber) {
        MTRational* value = expr.expressionValue;
        if (value.format == kMTRationalFormatDecimal) {
            return [super applyToTopLevelNode:expr withChildren:args];
        }
    }
    return expr;
}

@end
