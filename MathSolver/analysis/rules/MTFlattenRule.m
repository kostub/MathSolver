//
//  FlattenRule.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTFlattenRule.h"
#import "MTExpression.h"
#import "MTExpressionUtil.h"

@implementation MTFlattenRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if ([self canFlatten:expr]) {
        NSMutableArray* newArgs = [NSMutableArray arrayWithCapacity:[args count]];
        MTOperator *oper = (MTOperator *) expr;
        BOOL flattened = NO;
        for (MTExpression *arg in args) {
            // if the operator is of the same type as the parent, we can flatten out any arguments since our operators are commutative and associative.
            if (arg.expressionType == kMTExpressionTypeOperator && [arg equalsExpressionValue:oper.type]) {
                [newArgs addObjectsFromArray:[arg children]];
                flattened = YES;       
            } else {
                [newArgs addObject:arg];
            }
        }
        if (flattened) {
            // at least one child was flattened then rebuild the expression
            // Note: the range does not change.
            return [MTOperator operatorWithType:oper.type args:newArgs range:oper.range];
        }
    }
    return expr;
}

- (BOOL) canFlatten:(MTExpression*) expr
{
    // Only addition and multiplication are commutative & associative.
    return [MTExpressionUtil isAddition:expr] || [MTExpressionUtil isMultiplication:expr];
}


@end
