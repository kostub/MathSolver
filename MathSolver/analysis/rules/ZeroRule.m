//
//  ZeroRule.m
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ZeroRule.h"
#import "Expression.h"

@implementation ZeroRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    // Multiplication by 0 returns 0
    if (expr.expressionType != kFXOperator || ![expr equalsExpressionValue:kMultiplication]) {
        return expr;
    }
    for (Expression *arg in args) {
        if (arg.expressionType == kFXNumber && [arg.expressionValue isEquivalent:[Rational zero]]) {
            return arg;
        }
    }    
    return expr;
}

@end
