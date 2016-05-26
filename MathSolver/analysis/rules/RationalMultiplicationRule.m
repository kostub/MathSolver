//
//  RationalMultiplicationRule.m
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "RationalMultiplicationRule.h"
#import "MTExpression.h" 
#import "MTExpressionUtil.h"

@implementation RationalMultiplicationRule


- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if ([MTExpressionUtil isMultiplication:expr]) {
        BOOL applicable = NO;
        // collect all the numerators & denominators
        NSMutableArray* numerators = [NSMutableArray arrayWithCapacity:args.count];
        NSMutableArray* denominators = [NSMutableArray arrayWithCapacity:args.count];
        for (MTExpression* arg in args) {
            if ([MTExpressionUtil isDivision:arg]) {
                applicable = YES;
                NSAssert(arg.children.count == 2, @"Division should have exactly 2 arguments.");
                [numerators addObject:arg.children[0]];
                [denominators addObject:arg.children[1]];
            } else {
                [numerators addObject:arg];
            }
        }
        
        if (applicable) {
            // Multiply all the numerators together
            MTOperator* numerator = [MTOperator operatorWithType:kMTMultiplication args:numerators];
            NSAssert(denominators.count > 0, @"There should be at least one denominator for this rule to be applicable.");
            MTExpression* denominator = denominators[0];
            if (denominators.count > 1) {
                // If there is more than one denominator, multiply them all.
                denominator = [MTOperator operatorWithType:kMTMultiplication args:denominators];
            }
            return [MTOperator operatorWithType:kMTDivision args:numerator :denominator];
        }
    }
    return expr;
}

@end
