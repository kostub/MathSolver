//
//  Canonicalizer.m
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "Canonicalizer.h"
#import "RemoveNegativesRule.h"
#import "FlattenRule.h"
#import "CalculateRule.h"
#import "IdentityRule.h"
#import "DistributionRule.h"
#import "ZeroRule.h"
#import "CollectLikeTermsRule.h"
#import "ReorderTermsRule.h"
#import "ExpressionUtil.h"
#import "ReduceRule.h"
#import "NullRule.h"
#import "NestedDivisionRule.h"
#import "RationalAdditionRule.h"
#import "CancelCommonFactorsRule.h"
#import "RationalMultiplicationRule.h"

@class Expression;

@implementation CanonicalizerFactory

+ (id<Canonicalizer>)getCanonicalizer:(id<MathEntity>)entity
{
    switch (entity.entityType) {
        case kFXEquation:
            return [self getEquationCanonicalizer];
        case kFXExpression:
            return [self getExpressionCanonicalizer];
        case kFXTypeAny:
            NSAssert(false, @"An actual entity with type any: %@", entity);
            return nil;
    }
}

+ (ExpressionCanonicalizer *)getExpressionCanonicalizer
{
    static ExpressionCanonicalizer* expCanonicalizer = nil;
    if (!expCanonicalizer) {
        expCanonicalizer = [ExpressionCanonicalizer new];
    }
    return expCanonicalizer;
}

+ (EquationCanonicalizer *)getEquationCanonicalizer
{
    static EquationCanonicalizer* eqCanon = nil;
    if (!eqCanon) {
        eqCanon = [EquationCanonicalizer new];
    }
    return eqCanon;
}

@end

#pragma mark - ExpressionCanonicalizer

@implementation ExpressionCanonicalizer {
    RemoveNegativesRule *_removeNegatives;
    FlattenRule *_flatten;
    ReorderTermsRule *_reorder;
    NSArray *_canonicalizingRules;
    NSArray *_divisionRules;
}

- (id) init
{
    self = [super init];
    if (self) {
        _removeNegatives = [RemoveNegativesRule rule];
        _flatten = [FlattenRule rule];
        _reorder = [ReorderTermsRule rule];
        // All rules except division rules
        _canonicalizingRules = @[[CalculateRule rule],
                                 [NullRule rule],
                                 [IdentityRule rule],
                                 [ZeroRule rule],
                                 [DistributionRule rule],
                                 [FlattenRule rule],
                                 [CollectLikeTermsRule rule],
                                 [ReduceRule rule]];
        // All rules except distribution with the addition of division rules
        _divisionRules = @[[CalculateRule rule],
                           [NullRule rule],
                           [IdentityRule rule],
                           [ZeroRule rule],
                           [FlattenRule rule],
                           [NestedDivisionRule rule],
                           [CollectLikeTermsRule rule],
                           [ReduceRule rule],
                           [RationalAdditionRule rule],
                           [RationalMultiplicationRule rule],
                           [CancelCommonFactorsRule rule]];
    }
    return self;
}

// Normalize the expression by removing -ves and extra parenthesis.
- (Expression*) normalize: (Expression*) ex
{
    return [_flatten apply:[_removeNegatives apply:ex]];
}

// Canonicalize the expression to its polynomial representation
// i.e. axx + bx +  c
- (Expression*) normalForm: (Expression*) ex {
    Expression* rationalForm = [self applyRules:_divisionRules toExpression:ex];
    // rationalForm should be of the form polynomial / polynomial
    DLog(@"Rational form: %@", rationalForm);
    if ([ExpressionUtil isDivision:rationalForm]) {
        NSAssert(rationalForm.children.count == 2, @"Rational form should only have 2 children");
        Expression* numerator = rationalForm.children[0];
        Expression* denominator = rationalForm.children[1];
        // canonical form for each polynomial
        Expression* canonicalDenonimator = [self canonicalFormForPolynomial:denominator];
        // We make always make the leading coefficient of the denominator 1.
        Rational* leadingCoefficient = [self getLeadingCoefficient:canonicalDenonimator];
        canonicalDenonimator = [self dividePolynomial:canonicalDenonimator byLeadingCoefficient:leadingCoefficient];
        Expression* canonicalNumerator = [self dividePolynomial:numerator byLeadingCoefficient:leadingCoefficient];
        return [FXOperator operatorWithType:kDivision args:canonicalNumerator :canonicalDenonimator];
    } else {
        // canonical form for the polynomial
        return [self canonicalFormForPolynomial:rationalForm];
    }
}

- (Rational*) getLeadingCoefficient:(Expression*) normalPolynomial
{
    Expression* leadingTerm = [ExpressionUtil getLeadingTerm:normalPolynomial];
    // get the coefficient of the leading term
    Rational* coefficient;
    NSArray* variables;
    BOOL rv = [ExpressionUtil expression:leadingTerm getCoefficent:&coefficient variables:&variables];
    NSAssert(rv, @"Normalized expression leading term %@ not of the form Nxyz for expression %@", leadingTerm, normalPolynomial);
    return coefficient;
}

- (Expression*) dividePolynomial:(Expression*) expr byLeadingCoefficient:(Rational*) coefficient
{
    // divide by the leading coefficient
    Expression* dividedExpr = [FXOperator operatorWithType:kDivision args:expr :[FXNumber numberWithValue:coefficient]];
    return [self canonicalFormForPolynomial:dividedExpr];
}

- (Expression*) canonicalFormForPolynomial:(Expression*) poly
{
    Expression* normalFormPoly = [self applyRules:_canonicalizingRules toExpression:poly];
    // Order the terms to be in the canonical order.
    return [_reorder apply:normalFormPoly];
}

- (Expression*) applyRules:(NSArray*) rules toExpression:(Expression*) ex
{
    Expression* current = ex;
    BOOL modifed = YES;
    while (modifed) {
        modifed = NO;
        for (Rule* rule in rules) {
            Expression* next = [rule apply:current];
            if (next != current) {
                modifed = YES;
                current = next;
            }
        }
    }
    return current;
}

@end

#pragma mark - EquationCanonicalizer

@implementation EquationCanonicalizer

- (Equation *)normalize:(Equation *)eq
{
    ExpressionCanonicalizer* expCanon = [CanonicalizerFactory getExpressionCanonicalizer];
    Expression* normalizedLhs = [expCanon normalize:eq.lhs];
    Expression* normalizedRhs = [expCanon normalize:eq.rhs];
    return [Equation equationWithRelation:eq.relation lhs:normalizedLhs rhs:normalizedRhs];
}

- (Equation *)normalForm:(Equation *)eq
{
    Expression* newLhs = [FXOperator operatorWithType:kSubtraction args:eq.lhs :eq.rhs];
    ExpressionCanonicalizer* expCanon = [CanonicalizerFactory getExpressionCanonicalizer];
    Expression* normalizedNewLhs = [expCanon normalize:newLhs];
    Expression* normalForm = [expCanon normalForm:normalizedNewLhs];
    
    if (normalForm.expressionType == kFXNull) {
        InfoLog(@"Equation mathematically invalid: %@", eq);
        return [Equation equationWithRelation:eq.relation lhs:normalForm rhs:[FXNumber numberWithValue:[Rational zero]]];
    }

    Expression* lhsExpression = normalForm;
    if ([ExpressionUtil isDivision:normalForm]) {
        // its a rational expression. We can ignore the denominator since it multiplies with 0.
        NSAssert(normalForm.children.count == 2, @"Division should have 2 children");
        lhsExpression = normalForm.children[0];
    }
    
    Rational* coefficient = [expCanon getLeadingCoefficient:lhsExpression];
    lhsExpression = [expCanon dividePolynomial:lhsExpression byLeadingCoefficient:coefficient];
    
    return [Equation equationWithRelation:eq.relation lhs:lhsExpression rhs:[FXNumber numberWithValue:[Rational zero]]];
}

@end
