//
//  RationalAdditionRule.m
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "RationalAdditionRule.h"
#import "Expression.h"
#import "ExpressionUtil.h"

@implementation RationalAdditionRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    if ([ExpressionUtil isAddition:expr]) {
        FXOperator* division = nil;
        NSMutableArray* addends = [NSMutableArray arrayWithCapacity:args.count];
        for (Expression* arg in args) {
            if (division == nil && [ExpressionUtil isDivision:arg]) {
                division = (FXOperator*) arg;
            } else {
                [addends addObject:arg];
            }
        }
        
        if (division) {
            // Add all the addends together.
            // a/b + c => (a + (b*c)) / b. mulitplier is c.
            NSAssert(addends.count > 0, @"There should be at least one addend");
            FXOperator* multiplier;
            if (addends.count == 1) {
                multiplier = addends[0];
            } else {
                multiplier = [FXOperator operatorWithType:kAddition args:addends];
            }
            NSAssert(division.children.count == 2, @"Division should have exactly 2 children");
            Expression* numerator = division.children[0];
            Expression* denominator = division.children[1];
            // a/b + c => (a + (b*c)) / b. numeratorAddend is b*c.
            FXOperator* numeratorAddend = [FXOperator operatorWithType:kMultiplication args:denominator :multiplier];
            FXOperator* newNumerator = [FXOperator operatorWithType:kAddition args:numerator :numeratorAddend];
            return [FXOperator operatorWithType:kDivision args:newNumerator :denominator];
        }
    }
    return expr;
}

@end
