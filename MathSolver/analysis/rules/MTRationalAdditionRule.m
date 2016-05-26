//
//  RationalAdditionRule.m
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTRationalAdditionRule.h"
#import "MTExpression.h"
#import "MTExpressionUtil.h"

@implementation MTRationalAdditionRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if ([MTExpressionUtil isAddition:expr]) {
        MTOperator* division = nil;
        NSMutableArray* addends = [NSMutableArray arrayWithCapacity:args.count];
        for (MTExpression* arg in args) {
            if (division == nil && [MTExpressionUtil isDivision:arg]) {
                division = (MTOperator*) arg;
            } else {
                [addends addObject:arg];
            }
        }
        
        if (division) {
            // Add all the addends together.
            // a/b + c => (a + (b*c)) / b. mulitplier is c.
            NSAssert(addends.count > 0, @"There should be at least one addend");
            MTOperator* multiplier;
            if (addends.count == 1) {
                multiplier = addends[0];
            } else {
                multiplier = [MTOperator operatorWithType:kMTAddition args:addends];
            }
            NSAssert(division.children.count == 2, @"Division should have exactly 2 children");
            MTExpression* numerator = division.children[0];
            MTExpression* denominator = division.children[1];
            // a/b + c => (a + (b*c)) / b. numeratorAddend is b*c.
            MTOperator* numeratorAddend = [MTOperator operatorWithType:kMTMultiplication args:denominator :multiplier];
            MTOperator* newNumerator = [MTOperator operatorWithType:kMTAddition args:numerator :numeratorAddend];
            return [MTOperator operatorWithType:kMTDivision args:newNumerator :denominator];
        }
    }
    return expr;
}

@end
