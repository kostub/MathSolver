//
//  ReorderTermsRule.m
//
//  Created by Kostub Deshmukh on 7/21/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ReorderTermsRule.h"
#import "MTExpression.h"

@implementation ReorderTermsRule

unsigned long getDegree(MTExpression* expr) {
    if (expr.hasDegree) {
        return [expr degree];
    } else {
        return LONG_MAX;
    }
}

// Returns the variables as an array. Also counts the number of sub operators (i.e. operators which are children of this operator) and returns them in subOperatorCount
NSArray* getVariables(MTOperator* op, int* subOperatorCount) {
    NSMutableArray* vars = [NSMutableArray array];
    *subOperatorCount = 0;
    for (MTExpression* expr in [op children]) {
        if (expr.expressionType == kMTExpressionTypeVariable) {
            [vars addObject:expr];
        } else if (expr.expressionType == kMTExpressionTypeOperator) {
            (*subOperatorCount)++;
        }
    }
    return vars;
}

NSComparisonResult compareOperatorsForAddition(MTOperator *op1, MTOperator *op2) {
    // These operators have the same degree.
    // There arguments should have been sorted by now.
    
    int op1Count = 0, op2Count = 0;
    NSArray* var1 = getVariables(op1, &op1Count);
    NSArray* var2 = getVariables(op2, &op2Count);

    if (op1Count && op2Count) {
        // if both expressions have operators then they are the same,
        // we can't really order x(x+1) and x(x+2) and we don't need to, since this only applies at the end of expansion.
        return NSOrderedSame;
    } else if (op2Count) {
        return NSOrderedAscending;  // operators always come after variables
    } else if (op1Count) {
        return NSOrderedDescending; // operators always come after variables
    } else {
        assert(!op1Count && !op2Count);
        // They have the same degree and no operators so the number of variables must be the same.
        assert([var1 count] == [var2 count]);
        // The variables should already be in lexicographic order. So pick the first one that is different.
        for (int i = 0; i < [var1 count]; ++i) {
            MTVariable *v1 = [var1 objectAtIndex:i];
            MTVariable *v2 = [var2 objectAtIndex:i];
            NSComparisonResult result = [v1 compare:v2];
            if (result != NSOrderedSame) {
                return result;
            }
        }
        // If the variables all match up then they are ordered same.
        return NSOrderedSame;
    }
}

NSComparisonResult compareVariableToOperatorForAddition(MTOperator *op1, MTVariable *op2) {
    int subOpCount = 0;
    NSArray* vars = getVariables(op1, &subOpCount);
    if (subOpCount > 0) {
        return NSOrderedDescending;
    }
    // there should only be one variable since the degrees match.
    assert([vars count] == 1);
    MTVariable* op1Var = [vars lastObject];
    return [op1Var compare:op2];
}

NSArray* reorderForMultiplication(const NSArray* args) {
    return[args sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 isKindOfClass:[MTNumber class]]) {
            if ([obj2 isKindOfClass:[MTNumber class]]) {
                MTNumber* n1 = obj1;
                return [n1 compare:obj2];
            } else {
                // numbers come before operators and variables
                return NSOrderedAscending;
            }
        } else if ([obj1 isKindOfClass:[MTVariable class]]) {
            if ([obj2 isKindOfClass:[MTNumber class]]) {
                // numbers come before variables.
                return NSOrderedDescending;
            } else if ([obj2 isKindOfClass:[MTVariable class]]) {
                MTVariable* v1 = obj1;
                return [v1 compare:obj2];
            } else {
                assert([obj2 isKindOfClass:[MTOperator class]]);
                // variables always come before operators
                return NSOrderedAscending;
            }
        } else if ([obj1 isKindOfClass:[MTOperator class]]) {
            if([obj2 isKindOfClass:[MTOperator class]]) {
                // Should 2x + 1 be lower than x + 2? Don't know, don't really care since this rule should be applied after canoncicalization. Return same for simplicity.
                return NSOrderedSame;
            } else {
                // operators come after numbers and variables
                return NSOrderedDescending;
            }
        } else {
            @throw [NSException exceptionWithName:@"InternalException"
                                           reason:[NSString stringWithFormat:@"Unknown Expression class %@", [obj1 class], nil]
                                         userInfo:nil];
        }
    }];
}

// Note there is some advantage of ordering the operators in a different way for optimizing gcd calculations. Consult book to figure that out.
NSArray* reorderForAddition(const NSArray* args) {
    return[args sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MTExpression* ex1 = obj1;
        MTExpression* ex2 = obj2;
        if (!ex1.hasDegree && !ex2.hasDegree) {
            // These are degree less and can't be ordered, just say they are the same.
            return NSOrderedSame;
        }
        long obj1Degree = getDegree(obj1);
        long obj2Degree = getDegree(obj2);
        if (obj1Degree > obj2Degree) {
            return NSOrderedAscending;
        } else if (obj2Degree > obj1Degree) {
            return NSOrderedDescending;
        } else {
            // lexicographic ordering of variables
            if ([obj1 isKindOfClass:[MTNumber class]]) {
                if ([obj2 isKindOfClass:[MTNumber class]]) {
                    MTNumber* n1 = obj1;
                    return [n1 compare:obj2];
                } else {
                    assert([obj2 isKindOfClass:[MTOperator class]]);
                    // numbers come before operators
                    return NSOrderedAscending;
                }
            } else if ([obj1 isKindOfClass:[MTVariable class]]) {
                if ([obj2 isKindOfClass:[MTVariable class]]) {
                    MTVariable* v1 = obj1;
                    return [v1 compare:obj2];
                } else {
                    assert([obj2 isKindOfClass:[MTOperator class]]);
                    NSComparisonResult result = compareVariableToOperatorForAddition(obj2, obj1);
                    // note the compare function compares obj2 to obj1, so we need to reverse the result
                    if (result == NSOrderedDescending) {
                        return NSOrderedAscending;
                    } else if (result == NSOrderedAscending) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedSame;
                    }
                }
            } else if ([obj1 isKindOfClass:[MTOperator class]]) {
                if([obj2 isKindOfClass:[MTOperator class]]) {
                    return compareOperatorsForAddition(obj1, obj2);
                } else if ([obj2 isKindOfClass:[MTVariable class]]) {
                    return compareVariableToOperatorForAddition(obj1, obj2);
                } else {
                    // operators come after numbers
                    return NSOrderedDescending;
                }
            } else {
                @throw [NSException exceptionWithName:@"InternalException"
                                               reason:[NSString stringWithFormat:@"Unknown Expression class %@", [obj1 class], nil]
                                             userInfo:nil];
            }
        }
    }];
}

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    // Removes addition and multiplication identities from the operators.
    if (![expr isKindOfClass:[MTOperator class]]) {
        return expr;
    }
    MTOperator *oper = (MTOperator *) expr;

    NSArray* sortedArgs = nil;
    if (oper.type == kMTMultiplication) {
        sortedArgs = reorderForMultiplication(args);
    } else if (oper.type == kMTAddition) {
        sortedArgs = reorderForAddition(args);
    } else {
        // No ordering implemented for other operators.
        return expr;
    }
    return [MTOperator operatorWithType:oper.type args:sortedArgs];
}

@end
