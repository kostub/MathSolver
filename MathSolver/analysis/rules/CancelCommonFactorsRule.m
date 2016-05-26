//
//  CancelCommonFactorsRule.m
//
//  Created by Kostub Deshmukh on 7/17/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "CancelCommonFactorsRule.h"
#import "Expression.h"
#import "ExpressionUtil.h"

@implementation CancelCommonFactorsRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    if ([ExpressionUtil isDivision:expr]) {
        NSAssert(args.count == 2, @"A division can only have 2 arguments.");
        Expression* first = args[0];
        Expression* second = args[1];
        NSArray* numeratorFactors = [self factors:first];
        NSMutableArray* denominatorFactors = [self factors:second].mutableCopy;
        
        BOOL foundCommonFactors = NO;
        NSMutableArray* remainingNumerators = [NSMutableArray arrayWithCapacity:numeratorFactors.count];
        for (Expression* factor in numeratorFactors) {
            Expression* common = [ExpressionUtil getExpressionEquivalentTo:factor in:denominatorFactors];
            if (common) {
                [denominatorFactors removeObject:common];
                foundCommonFactors = YES;
            } else {
                [remainingNumerators addObject:factor];
            }
        }
        
        if (foundCommonFactors) {
            Expression* newNumerator = [ExpressionUtil combineExpressions:remainingNumerators withOperatorType:kMultiplication];
            Expression* newDenominator = [ExpressionUtil combineExpressions:denominatorFactors withOperatorType:kMultiplication];
            return [FXOperator operatorWithType:kDivision args:newNumerator :newDenominator];
        }
    }
    return expr;
}

- (NSArray*) factors:(Expression*) expr
{
    if ([ExpressionUtil isMultiplication:expr]) {
        return expr.children;
    } else {
        return [NSArray arrayWithObject:expr];
    }
}

@end
