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
#import "Expression.h"
#import "ExpressionUtil.h"

@implementation RemoveNegativesRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    // traverse the expressions to find any -ve signs and unary minus
    if ([expr isKindOfClass:[FXOperator class]]) {
        FXOperator *oper = (FXOperator *) expr;
        if (oper.type == kUnaryMinus) {
            assert([args count] == 1);
            Expression *arg1 = [args lastObject];
            Expression* arg1WithNegative = [self addNegativeSignIfPossible:arg1];
            if (arg1WithNegative) {
                return arg1WithNegative;
            } else {
                // convert unary minus: - A to: (-1) * A
                return [ExpressionUtil negate:arg1];
            }
        } else if (oper.type == kSubtraction) {
            // convert subtraction: A - B to: A + (-1) * B
            assert([args count] == 2);
            Expression *arg1 = [args objectAtIndex:0];
            Expression *arg2 = [args lastObject];
            Expression* arg2WithNegative = [self addNegativeSignIfPossible:arg2];
            if (arg2WithNegative) {
                return [FXOperator operatorWithType:kAddition args:arg1 :arg2WithNegative range:expr.range];
            } else {
                return [FXOperator operatorWithType:kAddition args:arg1 :[ExpressionUtil negate:arg2] range:expr.range];
            }
        }
    }
    return expr;
}

- (Expression*) addNegativeSignIfPossible:(Expression*) expr
{
    if (expr.expressionType == kFXNumber) {
        // convert the number to it's negative
        FXNumber* num = (FXNumber *) expr;
        return [FXNumber numberWithValue:num.value.negation range:num.range];
    } else if (expr.expressionType == kFXOperator && [expr equalsExpressionValue:kMultiplication]) {
        // recurse
        Expression* neg = [self addNegativeSignIfPossible:expr.children[0]];
        if (neg) {
            NSArray* args = [NSArray arrayWithObject:neg];
            args = [args arrayByAddingObjectsFromArray:[expr.children subarrayWithRange:NSMakeRange(1, expr.children.count - 1)]];
            return [FXOperator operatorWithType:kMultiplication args:args range:expr.range];
        }
    }
    return nil;
}
@end
