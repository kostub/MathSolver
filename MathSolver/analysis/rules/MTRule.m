//
//  Rule.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTRule.h"
#import "MTExpression.h"

@implementation MTRule

+ (instancetype) rule {
    return [[self alloc] init];
}

- (MTExpression*) apply:(MTExpression *)expr
{
    // This does a post order traversal of the Expression tree.
    NSArray *args = expr.children;
    NSMutableArray* modifiedArgs = [NSMutableArray arrayWithCapacity:[args count]];
    BOOL newExpressionNeeded = NO;
    for (MTExpression* child in args) {
        MTExpression* modified = [self apply:child];
        if (modified != child) {
            newExpressionNeeded = YES;
        }
        [modifiedArgs addObject:modified];
    }
    
    MTExpression* updatedExpr = [self applyToTopLevelNode:expr withChildren:modifiedArgs];
    if (updatedExpr != expr) {
        return updatedExpr;
    } else if (newExpressionNeeded) {
        // The args were modified even if the top level node wasn't, so recreate the top level node with the new args.
        
        // currently only operators have children, but in the future we could have functions too.
        MTOperator *oper = (MTOperator *) expr;
        return [MTOperator operatorWithType:oper.type args:modifiedArgs range:expr.range];
    }
    
    return expr;
}

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (MTExpression*) applyInnerMost:(MTExpression *)expr onlyFirst:(BOOL) onlyFirst
{
    // This does a post order traversal of the Expression tree.
    NSArray *args = expr.children;
    NSMutableArray* modifiedArgs = [NSMutableArray arrayWithCapacity:[args count]];
    BOOL newExpressionNeeded = NO;
    for (MTExpression* child in args) {
        if (!onlyFirst || !newExpressionNeeded) {
            MTExpression* modified = [self applyInnerMost:child onlyFirst:onlyFirst];
            if (modified != child) {
                newExpressionNeeded = YES;
            }
            [modifiedArgs addObject:modified];
        } else {
            [modifiedArgs addObject:child];
        }
    }
    
    if (newExpressionNeeded) {
        // The args were modified which means that the rule was applied. Do not apply the rule to the top level, since we only apply to the inner most level.
        MTOperator *oper = (MTOperator *) expr;
        return [MTOperator operatorWithType:oper.type args:modifiedArgs];
    } else {
        return [self applyToTopLevelNode:expr withChildren:expr.children];
    }
}

@end
