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
#import "Expression.h"
#import "ExpressionUtil.h"

@implementation IdentityRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    // Removes addition and multiplication identities from the operators.
    if (expr.expressionType != kFXOperator) {
        return expr;
    }
    FXOperator *oper = (FXOperator *) expr;
    FXNumber* identity = [ExpressionUtil getIdentity:oper.type];
    if (!identity) {
        return expr;
    }
    for (Expression *arg in args) {
        if ([arg isEqual:identity]) {
            NSMutableArray* newArgs = [NSMutableArray arrayWithArray:args];
            [newArgs removeObject:arg];
            assert([newArgs count] > 0);
            if ([newArgs count] == 1) {
                return [newArgs lastObject];
            } else {
                return [FXOperator operatorWithType:oper.type args:newArgs];
            }
        }
    }
    
    return expr;
}

@end
