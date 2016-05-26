//
//  NestedDivisionRule.m
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTNestedDivisionRule.h"
#import "MTExpression.h"
#import "MTExpressionUtil.h"

@implementation MTNestedDivisionRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if ([MTExpressionUtil isDivision:expr]) {
        NSAssert(args.count == 2, @"A division can only have 2 arguments.");
        MTExpression* first = args[0];
        MTExpression* second = args[1];
        
        if ([MTExpressionUtil isDivision:first] ) {
            return [self simplifyNumeratorIsDivision:(MTOperator*) first denominator:second];
        } else if ([MTExpressionUtil isDivision:second]) {
            return [self simplifyDenominatorIsDivision:first denominator:(MTOperator*) second];
        }
    }
    return expr;
}

// (a/b) / c becomes a / (b*c)
- (MTExpression*) simplifyNumeratorIsDivision:(MTOperator*) numerator denominator:(MTExpression*) denominator
{
    NSAssert(numerator.type == kMTDivision, @"Expected numerator to be division");
    NSAssert(numerator.children.count == 2, @"Division can only have 2 arguments");
    
    MTExpression* nFirst = numerator.children[0];
    MTExpression* nSecond = numerator.children[1];
    
    MTOperator* newDenominator = [MTOperator operatorWithType:kMTMultiplication args:nSecond :denominator];
    return [MTOperator operatorWithType:kMTDivision args:nFirst :newDenominator];
}

// a / (b/c) becomes (a*c) / b
- (MTExpression*) simplifyDenominatorIsDivision:(MTExpression*) numerator denominator:(MTOperator*) denominator
{
    NSAssert(denominator.type == kMTDivision, @"Expected numerator to be division");
    NSAssert(denominator.children.count == 2, @"Division can only have 2 arguments");
    
    MTExpression* dFirst = denominator.children[0];
    MTExpression* dSecond = denominator.children[1];
    
    MTOperator* newNumerator = [MTOperator operatorWithType:kMTMultiplication args:numerator :dSecond];
    return [MTOperator operatorWithType:kMTDivision args:newNumerator :dFirst];
}


@end
