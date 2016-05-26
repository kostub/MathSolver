//
//  DecimalReduceRule.m
//
//  Created by Kostub Deshmukh on 10/11/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "DecimalReduceRule.h"
#import "Expression.h"

@implementation DecimalReduceRule

- (Expression *)applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    if (expr.expressionType == kFXNumber) {
        Rational* value = expr.expressionValue;
        if (value.format == kRationalFormatDecimal) {
            return [super applyToTopLevelNode:expr withChildren:args];
        }
    }
    return expr;
}

@end
