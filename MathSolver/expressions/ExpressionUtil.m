//
//  ExpressionUtil.m
//
//  Created by Kostub Deshmukh on 7/29/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ExpressionUtil.h"
#import "CalculateRule.h"
#import "IdentityRule.h"
#import "ReduceRule.h"
#import "Canonicalizer.h"

static CalculateRule *_calc;
static IdentityRule *_identity;

static Rule* getCalculateRule() {
    if (_calc == nil) {
        _calc = [CalculateRule rule];
    }
    return _calc;
}

static Rule* getIdentityRule() {
    if (_identity == nil) {
        _identity = [IdentityRule rule];
    }
    return _identity;
}

@implementation ExpressionUtil

+ (FXOperator*) negate:(Expression *)expr
{
    return [FXOperator operatorWithType:kMultiplication args:[FXNumber numberWithValue:[Rational one].negation range:expr.range] :expr range:expr.range];
}

+ (BOOL) expression: (Expression*) expr getCoefficent:(Rational**) c variables:(NSArray**) vars
{
    switch (expr.expressionType) {
        case kFXNumber: {
            FXNumber *numberArg = (FXNumber *) expr;
            if (c) {
                *c = numberArg.value;
            }
            if (vars) {
                *vars = [NSArray array];
            }
            return true;
        }
        case kFXVariable: {
            if (c) {
                *c = [Rational one];
            }
            if (vars) {
                *vars = [NSArray arrayWithObject:expr];
            }
            return true;
        }
        case kFXOperator: {
            FXOperator* oper = (FXOperator*) expr;
            if (oper.type != kMultiplication) {
                // none of the other operators are of this form
                return NO;
            }
            // we require that there be exactly one FXNumber and no operators as children
            BOOL numberFound = NO;
            FXNumber *coefficient = nil;
            NSMutableArray* mutableVars = [NSMutableArray array];
            for (Expression* childArg in oper.children) {
                if ([childArg isKindOfClass:[FXNumber class]] && !numberFound) {
                    numberFound = YES;
                    coefficient = (FXNumber *)childArg;
                } else if ([childArg isKindOfClass:[FXVariable class]]) {
                    [mutableVars addObject:childArg];
                } else {
                    // arg is notof the form we are looking for.
                    return NO;
                }
            }
            // at this point the operator is combinable, we need to find out what variables to combine by and the coefficient.
            // if we found a coefficent then get its value, otherwise the default is 1.
            if (c) {
                *c = (coefficient) ? coefficient.value : [Rational one];
            }
            if (vars) {
                // sort the variables by name
                [mutableVars sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
                *vars = mutableVars;
            }
            return YES;
        }
            
        case kFXNull: {
            return NO;
        }
    }
}

+ (Expression *)absoluteValue:(Expression *)expr
{
    Rational* coeff;
    NSArray* vars;
    if (![self expression:expr getCoefficent:&coeff variables:&vars]) {
        // Not of required form, can't take the absolute value.
        return expr;
    }
    if (coeff.isPositive) {
        return expr;
    } else {
        // Normalize this to remove the -ve sign. (Calculation and removal of identity are the only things that should happen)
        id<Canonicalizer> canon = [CanonicalizerFactory getExpressionCanonicalizer];
        Expression* normalized = [canon normalize:[self negate:expr]];
        return [canon normalForm:normalized];
    }
}

+ (NSString*) formatAsString:(Expression*) expr
{
    Rational* coeff;
    NSArray* vars;
    if (![self expression:expr getCoefficent:&coeff variables:&vars]) {
        // Not of required form, can't format
        return nil;
    }
    return [NSString stringWithFormat:@"%@%@", coeff, [vars componentsJoinedByString:@""]];
}

+ (BOOL) isEquivalentUptoCalculation:(Expression*) expr toExpression:(Expression*) other
{
    if ([expr isEqualUptoRearrangement:other]) {
        return true;
    }
    Rule* calculate = getCalculateRule();
    Expression* calculatedTerm = [calculate applyToTopLevelNode:expr withChildren:expr.children];
    if ([calculatedTerm isEqualUptoRearrangement:other]) {
        return true;
    }
    
    // Reduce fractions in the expression if any
    Rule* reduceRule = [ReduceRule rule];
    Expression* fractionsReduced = [reduceRule apply:calculatedTerm];
    if (fractionsReduced != calculatedTerm && [fractionsReduced isEqualUptoRearrangement:other]) {
        return true;
    }
    
    // apply the identity rule to strip away any 1s.
    Rule* identity = getIdentityRule();
    Expression* identityRemovedTerm = [identity applyToTopLevelNode:fractionsReduced withChildren:fractionsReduced.children];
    if (identityRemovedTerm != fractionsReduced && [identityRemovedTerm isEqualUptoRearrangement:other]) {
        return true;
    }
    
    return false;
}

+ (Expression*) getExpressionEquivalentTo:(Expression*) expr in:(NSArray*) array
{
    for (Expression* arg in array) {
        if ([self isEquivalentUptoCalculation:expr toExpression:arg] || [self isEquivalentUptoCalculation:arg toExpression:expr]) {
            return arg;
        }
    }
    return nil;
}

+(BOOL) isEquivalentUptoCalculationAndRearrangement:(NSArray *)array1 :(NSArray *)array2
{
    NSMutableArray* otherArray = [NSMutableArray arrayWithArray:array2];
    for (Expression* expr in array1) {
        Expression* other = [self getExpressionEquivalentTo:expr in:otherArray];
        if (other) {
            [otherArray removeObject:other];
        } else {
            return false;
        }
    }
    return (otherArray.count == 0);
}

+ (FXOperator*) toOperator:(Expression *)var
{
    return [FXOperator operatorWithType:kMultiplication args:var :[FXNumber numberWithValue:[Rational one]]];
}

+ (BOOL) diffOperator:(FXOperator*) first with:(FXOperator*) second removedChildren:(NSArray**) removedChildren addedChildren:(NSArray**) addedChildren
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
    for (Expression* child in second.children) {
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


+ (FXNumber*) getIdentity:(char) operatorType
{
    if (operatorType == kMultiplication) {
        return [FXNumber numberWithValue:[Rational one]];
    } else if (operatorType == kAddition) {
        return [FXNumber numberWithValue:[Rational zero]];
    }
    return nil;
}

+ (MTMathListRange*) unionedRange:(NSArray*) exprs
{
    NSMutableArray* ranges = [NSMutableArray arrayWithCapacity:exprs.count];
    for (Expression* expr in exprs) {
        if (expr.range) {
            [ranges addObject:expr.range];
        } else {
            return nil;
        }
    }
    return [MTMathListRange unionRanges:ranges];
}

+ (Expression*) combineExpressions:(NSArray*) exprs withOperatorType:(char) operatorType
{
    if (exprs.count == 0) {
        return [ExpressionUtil getIdentity:operatorType ];
    } else if (exprs.count == 1) {
        return exprs[0];
    } else {
        return [FXOperator operatorWithType:operatorType args:exprs range:[self unionedRange:exprs]];
    }
}

+ (BOOL)expression:(Expression *)expr containsVariable:(FXVariable *)var
{
    switch (expr.expressionType) {
        case kFXNumber:
            return false;
            
        case kFXVariable:
            return [var isEqual:expr];
            
        case kFXOperator: {
            for (Expression* child in expr.children) {
                if ([self expression:child containsVariable:var]) {
                    return true;
                }
            }
            return false;
        }
            
        case kFXNull:
            return false;
    }
}

+ (BOOL) isExpression:(Expression*) expr subsetOf:(FXOperator*) oper difference:(NSArray**) difference
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
    } else if (expr.expressionType == kFXOperator && [expr equalsExpressionValue:oper.type]) {
        NSArray *added;
        if([ExpressionUtil diffOperator:oper with:(FXOperator*) expr removedChildren:difference addedChildren:&added]) {
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


+ (Expression*) getLeadingTerm:(Expression*) expr
{
    if (expr.expressionType != kFXOperator) {
        return expr;
    }
    
    // operator
    if ([expr equalsExpressionValue:kMultiplication]) {
        // This is the leading term, eg. 5x
        return expr;
    } else if ([expr equalsExpressionValue:kAddition]) {
        // first child
        return expr.children[0];
    } else {
        NSAssert(false, @"Unknown type of operator encountered: %@", expr);
        return nil;
    }
}

+ (NSSet *)getVariablesInExpression:(Expression *)expr
{
    switch (expr.expressionType) {
        case kFXNumber:
            // empty set
            return [NSSet set];
            
        case kFXVariable:
            return [NSSet setWithObject:expr];
            
        case kFXOperator: {
            NSMutableSet* set = [NSMutableSet set];
            for (Expression* child in expr.children) {
                [set unionSet:[self getVariablesInExpression:child]];
            }
            return set;
        }
            
        case kFXNull:
            // empty set
            return [NSSet set];
            
    }
}

+ (BOOL) isDivision:(Expression*) expr
{
    return expr.expressionType == kFXOperator && [expr equalsExpressionValue:kDivision];
}

+ (BOOL) isMultiplication:(Expression*) expr
{
    return expr.expressionType == kFXOperator && [expr equalsExpressionValue:kMultiplication];
}

+ (BOOL) isAddition:(Expression *)expr
{
    return expr.expressionType == kFXOperator && [expr equalsExpressionValue:kAddition];
}

@end
