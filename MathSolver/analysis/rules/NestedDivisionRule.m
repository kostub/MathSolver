//
//  NestedDivisionRule.m
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "NestedDivisionRule.h"
#import "Expression.h"
#import "ExpressionUtil.h"

@implementation NestedDivisionRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    if ([ExpressionUtil isDivision:expr]) {
        NSAssert(args.count == 2, @"A division can only have 2 arguments.");
        Expression* first = args[0];
        Expression* second = args[1];
        
        if ([ExpressionUtil isDivision:first] ) {
            return [self simplifyNumeratorIsDivision:(FXOperator*) first denominator:second];
        } else if ([ExpressionUtil isDivision:second]) {
            return [self simplifyDenominatorIsDivision:first denominator:(FXOperator*) second];
        }
    }
    return expr;
}

// (a/b) / c becomes a / (b*c)
- (Expression*) simplifyNumeratorIsDivision:(FXOperator*) numerator denominator:(Expression*) denominator
{
    NSAssert(numerator.type == kDivision, @"Expected numerator to be division");
    NSAssert(numerator.children.count == 2, @"Division can only have 2 arguments");
    
    Expression* nFirst = numerator.children[0];
    Expression* nSecond = numerator.children[1];
    
    FXOperator* newDenominator = [FXOperator operatorWithType:kMultiplication args:nSecond :denominator];
    return [FXOperator operatorWithType:kDivision args:nFirst :newDenominator];
}

// a / (b/c) becomes (a*c) / b
- (Expression*) simplifyDenominatorIsDivision:(Expression*) numerator denominator:(FXOperator*) denominator
{
    NSAssert(denominator.type == kDivision, @"Expected numerator to be division");
    NSAssert(denominator.children.count == 2, @"Division can only have 2 arguments");
    
    Expression* dFirst = denominator.children[0];
    Expression* dSecond = denominator.children[1];
    
    FXOperator* newNumerator = [FXOperator operatorWithType:kMultiplication args:numerator :dSecond];
    return [FXOperator operatorWithType:kDivision args:newNumerator :dFirst];
}


@end
