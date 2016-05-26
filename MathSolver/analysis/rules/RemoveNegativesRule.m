//
//  RemoveNegativesRule.m
//
//  Created by Kostub Deshmukh on 7/18/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "RemoveNegativesRule.h"
#import "MTExpression.h"
#import "MTExpressionUtil.h"

@implementation RemoveNegativesRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    // traverse the expressions to find any -ve signs and unary minus
    if ([expr isKindOfClass:[MTOperator class]]) {
        MTOperator *oper = (MTOperator *) expr;
        if (oper.type == kMTUnaryMinus) {
            assert([args count] == 1);
            MTExpression *arg1 = [args lastObject];
            MTExpression* arg1WithNegative = [self addNegativeSignIfPossible:arg1];
            if (arg1WithNegative) {
                return arg1WithNegative;
            } else {
                // convert unary minus: - A to: (-1) * A
                return [MTExpressionUtil negate:arg1];
            }
        } else if (oper.type == kMTSubtraction) {
            // convert subtraction: A - B to: A + (-1) * B
            assert([args count] == 2);
            MTExpression *arg1 = [args objectAtIndex:0];
            MTExpression *arg2 = [args lastObject];
            MTExpression* arg2WithNegative = [self addNegativeSignIfPossible:arg2];
            if (arg2WithNegative) {
                return [MTOperator operatorWithType:kMTAddition args:arg1 :arg2WithNegative range:expr.range];
            } else {
                return [MTOperator operatorWithType:kMTAddition args:arg1 :[MTExpressionUtil negate:arg2] range:expr.range];
            }
        }
    }
    return expr;
}

- (MTExpression*) addNegativeSignIfPossible:(MTExpression*) expr
{
    if (expr.expressionType == kMTExpressionTypeNumber) {
        // convert the number to it's negative
        MTNumber* num = (MTNumber *) expr;
        return [MTNumber numberWithValue:num.value.negation range:num.range];
    } else if (expr.expressionType == kMTExpressionTypeOperator && [expr equalsExpressionValue:kMTMultiplication]) {
        // recurse
        MTExpression* neg = [self addNegativeSignIfPossible:expr.children[0]];
        if (neg) {
            NSArray* args = [NSArray arrayWithObject:neg];
            args = [args arrayByAddingObjectsFromArray:[expr.children subarrayWithRange:NSMakeRange(1, expr.children.count - 1)]];
            return [MTOperator operatorWithType:kMTMultiplication args:args range:expr.range];
        }
    }
    return nil;
}
@end
