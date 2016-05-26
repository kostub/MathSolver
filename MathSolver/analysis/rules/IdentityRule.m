//
//  IdentityRule.m
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "IdentityRule.h"
#import "MTExpression.h"
#import "MTExpressionUtil.h"

@implementation IdentityRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    // Removes addition and multiplication identities from the operators.
    if (expr.expressionType != kMTExpressionTypeOperator) {
        return expr;
    }
    MTOperator *oper = (MTOperator *) expr;
    MTNumber* identity = [MTExpressionUtil getIdentity:oper.type];
    if (!identity) {
        return expr;
    }
    for (MTExpression *arg in args) {
        if ([arg isEqual:identity]) {
            NSMutableArray* newArgs = [NSMutableArray arrayWithArray:args];
            [newArgs removeObject:arg];
            assert([newArgs count] > 0);
            if ([newArgs count] == 1) {
                return [newArgs lastObject];
            } else {
                return [MTOperator operatorWithType:oper.type args:newArgs];
            }
        }
    }
    
    return expr;
}

@end
