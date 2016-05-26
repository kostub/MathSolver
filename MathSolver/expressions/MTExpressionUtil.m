//
//  ExpressionUtil.m
//
//  Created by Kostub Deshmukh on 7/29/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTExpressionUtil.h"
#import "MTCalculateRule.h"
#import "MTIdentityRule.h"
#import "MTReduceRule.h"
#import "MTCanonicalizer.h"

static MTCalculateRule *_calc;
static MTIdentityRule *_identity;

static MTRule* getCalculateRule() {
    if (_calc == nil) {
        _calc = [MTCalculateRule rule];
    }
    return _calc;
}

static MTRule* getIdentityRule() {
    if (_identity == nil) {
        _identity = [MTIdentityRule rule];
    }
    return _identity;
}

@implementation MTExpressionUtil

+ (MTOperator*) negate:(MTExpression *)expr
{
    return [MTOperator operatorWithType:kMTMultiplication args:[MTNumber numberWithValue:[MTRational one].negation range:expr.range] :expr range:expr.range];
}

+ (BOOL) expression: (MTExpression*) expr getCoefficent:(MTRational**) c variables:(NSArray**) vars
{
    switch (expr.expressionType) {
        case kMTExpressionTypeNumber: {
            MTNumber *numberArg = (MTNumber *) expr;
            if (c) {
                *c = numberArg.value;
            }
            if (vars) {
                *vars = [NSArray array];
            }
            return true;
        }
        case kMTExpressionTypeVariable: {
            if (c) {
                *c = [MTRational one];
            }
            if (vars) {
                *vars = [NSArray arrayWithObject:expr];
            }
            return true;
        }
        case kMTExpressionTypeOperator: {
            MTOperator* oper = (MTOperator*) expr;
            if (oper.type != kMTMultiplication) {
                // none of the other operators are of this form
                return NO;
            }
            // we require that there be exactly one FXNumber and no operators as children
            BOOL numberFound = NO;
            MTNumber *coefficient = nil;
            NSMutableArray* mutableVars = [NSMutableArray array];
            for (MTExpression* childArg in oper.children) {
                if ([childArg isKindOfClass:[MTNumber class]] && !numberFound) {
                    numberFound = YES;
                    coefficient = (MTNumber *)childArg;
                } else if ([childArg isKindOfClass:[MTVariable class]]) {
                    [mutableVars addObject:childArg];
                } else {
                    // arg is notof the form we are looking for.
                    return NO;
                }
            }
            // at this point the operator is combinable, we need to find out what variables to combine by and the coefficient.
            // if we found a coefficent then get its value, otherwise the default is 1.
            if (c) {
                *c = (coefficient) ? coefficient.value : [MTRational one];
            }
            if (vars) {
                // sort the variables by name
                [mutableVars sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
                *vars = mutableVars;
            }
            return YES;
        }
            
        case kMTExpressionTypeNull: {
            return NO;
        }
    }
}

+ (MTExpression *)absoluteValue:(MTExpression *)expr
{
    MTRational* coeff;
    NSArray* vars;
    if (![self expression:expr getCoefficent:&coeff variables:&vars]) {
        // Not of required form, can't take the absolute value.
        return expr;
    }
    if (coeff.isPositive) {
        return expr;
    } else {
        // Normalize this to remove the -ve sign. (Calculation and removal of identity are the only things that should happen)
        id<MTCanonicalizer> canon = [MTCanonicalizerFactory getExpressionCanonicalizer];
        MTExpression* normalized = [canon normalize:[self negate:expr]];
        return [canon normalForm:normalized];
    }
}

+ (NSString*) formatAsString:(MTExpression*) expr
{
    MTRational* coeff;
    NSArray* vars;
    if (![self expression:expr getCoefficent:&coeff variables:&vars]) {
        // Not of required form, can't format
        return nil;
    }
    return [NSString stringWithFormat:@"%@%@", coeff, [vars componentsJoinedByString:@""]];
}

+ (BOOL) isEquivalentUptoCalculation:(MTExpression*) expr toExpression:(MTExpression*) other
{
    if ([expr isEqualUptoRearrangement:other]) {
        return true;
    }
    MTRule* calculate = getCalculateRule();
    MTExpression* calculatedTerm = [calculate applyToTopLevelNode:expr withChildren:expr.children];
    if ([calculatedTerm isEqualUptoRearrangement:other]) {
        return true;
    }
    
    // Reduce fractions in the expression if any
    MTRule* reduceRule = [MTReduceRule rule];
    MTExpression* fractionsReduced = [reduceRule apply:calculatedTerm];
    if (fractionsReduced != calculatedTerm && [fractionsReduced isEqualUptoRearrangement:other]) {
        return true;
    }
    
    // apply the identity rule to strip away any 1s.
    MTRule* identity = getIdentityRule();
    MTExpression* identityRemovedTerm = [identity applyToTopLevelNode:fractionsReduced withChildren:fractionsReduced.children];
    if (identityRemovedTerm != fractionsReduced && [identityRemovedTerm isEqualUptoRearrangement:other]) {
        return true;
    }
    
    return false;
}

+ (MTExpression*) getExpressionEquivalentTo:(MTExpression*) expr in:(NSArray*) array
{
    for (MTExpression* arg in array) {
        if ([self isEquivalentUptoCalculation:expr toExpression:arg] || [self isEquivalentUptoCalculation:arg toExpression:expr]) {
            return arg;
        }
    }
    return nil;
}

+(BOOL) isEquivalentUptoCalculationAndRearrangement:(NSArray *)array1 :(NSArray *)array2
{
    NSMutableArray* otherArray = [NSMutableArray arrayWithArray:array2];
    for (MTExpression* expr in array1) {
        MTExpression* other = [self getExpressionEquivalentTo:expr in:otherArray];
        if (other) {
            [otherArray removeObject:other];
        } else {
            return false;
        }
    }
    return (otherArray.count == 0);
}

+ (MTOperator*) toOperator:(MTExpression *)var
{
    return [MTOperator operatorWithType:kMTMultiplication args:var :[MTNumber numberWithValue:[MTRational one]]];
}

+ (BOOL) diffOperator:(MTOperator*) first with:(MTOperator*) second removedChildren:(NSArray**) removedChildren addedChildren:(NSArray**) addedChildren
{
    if (first.type != second.type) {
        if (removedChildren) {
            *removedChildren = nil;
        }
        if (addedChildren) {
            *addedChildren = nil;
        }
        return true;
    }
    // This is an n^2 algorithm for checking every child of first against every child of second
    // (Since there isn't a well ordering amongst expressions, (it might be useful to establish one)
    // Note this does not recurse, i.e. it checks the children using isEquals
    // So we don't catch 5(a+b) = (b+a)*5.
    NSMutableArray* added = [NSMutableArray arrayWithCapacity:second.children.count];
    
    NSMutableArray* removed = [NSMutableArray arrayWithArray:first.children];
    for (MTExpression* child in second.children) {
        NSUInteger index = [removed indexOfObject:child];
        if (index == NSNotFound) {
            [added addObject:child];
        } else {
            // remove the object so that we don't double count it
            [removed removeObjectAtIndex:index];
        }
    }

    if (removedChildren) {
        *removedChildren = removed;
    }
    if (addedChildren) {
        *addedChildren = added;
    }
    return (removed.count > 0) || (added.count > 0);
}


+ (MTNumber*) getIdentity:(char) operatorType
{
    if (operatorType == kMTMultiplication) {
        return [MTNumber numberWithValue:[MTRational one]];
    } else if (operatorType == kMTAddition) {
        return [MTNumber numberWithValue:[MTRational zero]];
    }
    return nil;
}

+ (MTMathListRange*) unionedRange:(NSArray*) exprs
{
    NSMutableArray* ranges = [NSMutableArray arrayWithCapacity:exprs.count];
    for (MTExpression* expr in exprs) {
        if (expr.range) {
            [ranges addObject:expr.range];
        } else {
            return nil;
        }
    }
    return [MTMathListRange unionRanges:ranges];
}

+ (MTExpression*) combineExpressions:(NSArray*) exprs withOperatorType:(char) operatorType
{
    if (exprs.count == 0) {
        return [MTExpressionUtil getIdentity:operatorType ];
    } else if (exprs.count == 1) {
        return exprs[0];
    } else {
        return [MTOperator operatorWithType:operatorType args:exprs range:[self unionedRange:exprs]];
    }
}

+ (BOOL)expression:(MTExpression *)expr containsVariable:(MTVariable *)var
{
    switch (expr.expressionType) {
        case kMTExpressionTypeNumber:
            return false;
            
        case kMTExpressionTypeVariable:
            return [var isEqual:expr];
            
        case kMTExpressionTypeOperator: {
            for (MTExpression* child in expr.children) {
                if ([self expression:child containsVariable:var]) {
                    return true;
                }
            }
            return false;
        }
            
        case kMTExpressionTypeNull:
            return false;
    }
}

+ (BOOL) isExpression:(MTExpression*) expr subsetOf:(MTOperator*) oper difference:(NSArray**) difference
{
    // There are two cases of a subset, one when the expression expr is wholly a part of oper. Two when both are the same
    // operators and all children of expr are children of oper.
    if ([oper.children containsObject:expr]) {
        // clearly a subset
        // All other terms should resolve to identity.
        if (difference) {
            NSMutableArray* childrenWithoutExpr = [NSMutableArray arrayWithArray:oper.children];
            [childrenWithoutExpr removeObject:expr];
            *difference = childrenWithoutExpr;
        }
        return true;
    } else if (expr.expressionType == kMTExpressionTypeOperator && [expr equalsExpressionValue:oper.type]) {
        NSArray *added;
        if([MTExpressionUtil diffOperator:oper with:(MTOperator*) expr removedChildren:difference addedChildren:&added]) {
            NSParameterAssert(added);
            if (added.count > 0) {
                // for a subset all children of expr should be children of oper
                return false;
            }
            return true;
        }
    }
    return false;
}


+ (MTExpression*) getLeadingTerm:(MTExpression*) expr
{
    if (expr.expressionType != kMTExpressionTypeOperator) {
        return expr;
    }
    
    // operator
    if ([expr equalsExpressionValue:kMTMultiplication]) {
        // This is the leading term, eg. 5x
        return expr;
    } else if ([expr equalsExpressionValue:kMTAddition]) {
        // first child
        return expr.children[0];
    } else {
        NSAssert(false, @"Unknown type of operator encountered: %@", expr);
        return nil;
    }
}

+ (NSSet *)getVariablesInExpression:(MTExpression *)expr
{
    switch (expr.expressionType) {
        case kMTExpressionTypeNumber:
            // empty set
            return [NSSet set];
            
        case kMTExpressionTypeVariable:
            return [NSSet setWithObject:expr];
            
        case kMTExpressionTypeOperator: {
            NSMutableSet* set = [NSMutableSet set];
            for (MTExpression* child in expr.children) {
                [set unionSet:[self getVariablesInExpression:child]];
            }
            return set;
        }
            
        case kMTExpressionTypeNull:
            // empty set
            return [NSSet set];
            
    }
}

+ (BOOL) isDivision:(MTExpression*) expr
{
    return expr.expressionType == kMTExpressionTypeOperator && [expr equalsExpressionValue:kMTDivision];
}

+ (BOOL) isMultiplication:(MTExpression*) expr
{
    return expr.expressionType == kMTExpressionTypeOperator && [expr equalsExpressionValue:kMTMultiplication];
}

+ (BOOL) isAddition:(MTExpression *)expr
{
    return expr.expressionType == kMTExpressionTypeOperator && [expr equalsExpressionValue:kMTAddition];
}

@end
