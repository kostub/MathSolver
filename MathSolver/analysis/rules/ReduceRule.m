//
//  ReduceRule.m
//
//  Created by Kostub Deshmukh on 9/11/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ReduceRule.h"
#import "Expression.h"

@implementation ReduceRule

- (Expression *)applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    if (expr.expressionType == kFXNumber) {
        Rational* value = expr.expressionValue;
        if (!value.isReduced) {
            return [FXNumber numberWithValue:value.reduced];
        }
    }
    return expr;
}

@end
