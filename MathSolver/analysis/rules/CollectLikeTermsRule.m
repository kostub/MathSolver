//
//  CollectLikeTermsRule.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "CollectLikeTermsRule.h"
#import "Expression.h"
#import "ExpressionUtil.h"

@implementation CollectLikeTermsRule


// Collects the terms with the same variables together and adds the coefficients of the variables.
// This only works for addition operators. so 5x + 3 + 2x + 5 will become 7x + 3 + 5
- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args {
    
    if (![ExpressionUtil isAddition:expr]) {
        return expr;
    }

    NSMutableArray* otherTerms = [NSMutableArray arrayWithCapacity:[args count]];
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    BOOL combinedTerms = NO;
    for (Expression* arg in args) {
        NSArray* vars;
        Rational* coefficent;
        if ([ExpressionUtil expression:arg getCoefficent:&coefficent variables:&vars]) {
            if (arg.expressionType == kFXNumber) {
                // numbers get combined if it is a CLT but by themselves don't trigger a CLT rule
                [self combineTerms:vars withValue:coefficent inDict:dict];
            } else {
                combinedTerms |= [self combineTerms:vars withValue:coefficent inDict:dict];
            }
        } else {
            // not combinable
            [otherTerms addObject:arg];
        }
    }
    
    if (combinedTerms) {
        // if we combined the terms, then create a new expression with the combined terms
        for (NSArray* key in dict) {
            Rational* coeff = [dict objectForKey:key];
            FXNumber* coeffNum = [FXNumber numberWithValue:coeff];
            if (key.count > 0) {
                NSMutableArray* args = [NSMutableArray arrayWithObject:coeffNum];
                [args addObjectsFromArray:key];
                [otherTerms addObject:[FXOperator operatorWithType:kMultiplication args:args]];
            } else {
                // no variables, just a number
                [otherTerms addObject:coeffNum];
            }
        }
        assert([otherTerms count] > 0);
        if ([otherTerms count] == 1) {
            // skip the addition operator
            return [otherTerms lastObject];
        }
        return [FXOperator operatorWithType:kAddition args:otherTerms];
    } else {
        return expr;
    }
}

- (BOOL) combineTerms:(NSArray*) variables withValue:(Rational*) value inDict:(NSMutableDictionary*) dict
{
    Rational* currentVal = [dict objectForKey:variables];
    if (currentVal) {
        Rational* updatedValue = [currentVal add:value];
        [dict setObject:updatedValue forKey:variables];
        return YES;
    } else {
        [dict setObject:value forKey:variables];
        return NO;
    }
}



@end
