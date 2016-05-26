//
//  DivisionIdentityRule.m
//
//  Created by Kostub Deshmukh on 7/17/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTDivisionIdentityRule.h"
#import "MTExpression.h"
#import "MTExpressionUtil.h"

@implementation MTDivisionIdentityRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if ([MTExpressionUtil isDivision:expr]) {
        NSAssert(args.count == 2, @"A division can only have 2 arguments.");
        MTExpression* first = args[0];
        MTExpression* second = args[1];
        if ([second isEqual:[MTExpressionUtil getIdentity:kMTMultiplication]]) {
            return first;
        }
    }
    return expr;
}

@end
