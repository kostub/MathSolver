//
//  DivisionIdentityRule.m
//
//  Created by Kostub Deshmukh on 7/17/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "DivisionIdentityRule.h"
#import "Expression.h"
#import "ExpressionUtil.h"

@implementation DivisionIdentityRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    if ([ExpressionUtil isDivision:expr]) {
        NSAssert(args.count == 2, @"A division can only have 2 arguments.");
        Expression* first = args[0];
        Expression* second = args[1];
        if ([second isEqual:[ExpressionUtil getIdentity:kMultiplication]]) {
            return first;
        }
    }
    return expr;
}

@end
