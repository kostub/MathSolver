//
//  DistributionRule.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "DistributionRule.h"
#import "MTExpression.h"

@implementation DistributionRule

// Distrubution distributes multiplication over addition ie. A*(B+C) becomes A*B + A*C
// This rule does distribution from both left and right.
- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args {
    if (expr.expressionType != kMTExpressionTypeOperator) {
        return expr;
    }
    MTOperator *oper = (MTOperator *) expr;
    NSMutableArray* leftMultipliers = [NSMutableArray array];
    NSMutableArray* rightMultipliers = [NSMutableArray array];
    
    MTOperator* distributee = [DistributionRule findDistributee:oper withArgs:args leftMultipliers:leftMultipliers rightMultiplers:rightMultipliers];
    if (!distributee) {
        return expr;
    }
    
    NSMutableArray *newArgs = [NSMutableArray arrayWithCapacity:[distributee.children count]];
    for (MTExpression *arg in distributee.children) {
        NSMutableArray *multiplicationArgs = [NSMutableArray arrayWithArray:leftMultipliers];
        [multiplicationArgs addObject:arg];
        [multiplicationArgs addObjectsFromArray:rightMultipliers];
        [newArgs addObject:[MTOperator operatorWithType:kMTMultiplication args:multiplicationArgs]];
    }
    return [MTOperator operatorWithType:kMTAddition args:newArgs];
}

// Returns nil if it cannot find a distributee.
+ (MTOperator*) findDistributee:(MTExpression*)op withArgs:(NSArray*) args leftMultipliers:(NSMutableArray*) leftMultipliers rightMultiplers:(NSMutableArray*) rightMultipliers
{
    if (![DistributionRule isDistributableOperator:op]) {
        return nil;
    }
    
    // If any of the children are addition operators then this rule is valid.
    // There may be multiple children who may be addition e.g. (a + b)*(c + d)
    // In that case we only open the first one so it will become a * (c + d) + b * (c + d)
    // And the rule will need to be applied again to open the subsequent distributions.
    // If there are more than 2 args all will be distributed, so
    // a * (b + c) * d will become a * b * d + a * c * d.
    
    MTOperator *distributee = nil;
    
    for (MTExpression *arg in args) {
        // Find an arg to distribute on
        if (!distributee && [DistributionRule isDistributee:arg]) {
            distributee = (MTOperator*) arg;
            continue;
        }
        // For everything else, add them to the left or right multipliers as appropriate.
        if (distributee && rightMultipliers) {
            [rightMultipliers addObject:arg];
        } else if (!distributee && leftMultipliers) {
            [leftMultipliers addObject:arg];
        }
    }
    return distributee;
}

+(BOOL) isDistributee:(MTExpression*) expr
{
    // We can only distribute over addition
    return expr.expressionType == kMTExpressionTypeOperator && [expr equalsExpressionValue:kMTAddition];
}

+(BOOL) isDistributableOperator:(MTExpression *)expr
{
    // Only multiplication operators can have distributees
    return expr.expressionType == kMTExpressionTypeOperator && [expr equalsExpressionValue:kMTMultiplication];
}

+(BOOL) canDistribute:(MTExpression*) expr
{
    return [self findDistributee:expr withArgs:expr.children leftMultipliers:nil rightMultiplers:nil] != nil;
}

+(NSArray*) getDistributees:(MTExpression*) expr
{
    if (![self isDistributableOperator:expr]) {
        return nil;
    }
    
    NSMutableArray* array = [NSMutableArray array];
    for (MTExpression* arg in expr.children) {
        if ([self isDistributee:arg]) {
            [array addObject:arg];
        }
    }
    return array;
}

@end
