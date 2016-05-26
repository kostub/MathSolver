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
#import "MTExpression.h"
#import "MTExpressionUtil.h"

@implementation CancelCommonFactorsRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if ([MTExpressionUtil isDivision:expr]) {
        NSAssert(args.count == 2, @"A division can only have 2 arguments.");
        MTExpression* first = args[0];
        MTExpression* second = args[1];
        NSArray* numeratorFactors = [self factors:first];
        NSMutableArray* denominatorFactors = [self factors:second].mutableCopy;
        
        BOOL foundCommonFactors = NO;
        NSMutableArray* remainingNumerators = [NSMutableArray arrayWithCapacity:numeratorFactors.count];
        for (MTExpression* factor in numeratorFactors) {
            MTExpression* common = [MTExpressionUtil getExpressionEquivalentTo:factor in:denominatorFactors];
            if (common) {
                [denominatorFactors removeObject:common];
                foundCommonFactors = YES;
            } else {
                [remainingNumerators addObject:factor];
            }
        }
        
        if (foundCommonFactors) {
            MTExpression* newNumerator = [MTExpressionUtil combineExpressions:remainingNumerators withOperatorType:kMTMultiplication];
            MTExpression* newDenominator = [MTExpressionUtil combineExpressions:denominatorFactors withOperatorType:kMTMultiplication];
            return [MTOperator operatorWithType:kMTDivision args:newNumerator :newDenominator];
        }
    }
    return expr;
}

- (NSArray*) factors:(MTExpression*) expr
{
    if ([MTExpressionUtil isMultiplication:expr]) {
        return expr.children;
    } else {
        return [NSArray arrayWithObject:expr];
    }
}

@end
