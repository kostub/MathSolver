//
//  Canonicalizer.m
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTCanonicalizer.h"
#import "MTRemoveNegativesRule.h"
#import "MTFlattenRule.h"
#import "MTCalculateRule.h"
#import "MTIdentityRule.h"
#import "MTDistributionRule.h"
#import "MTZeroRule.h"
#import "MTCollectLikeTermsRule.h"
#import "MTReorderTermsRule.h"
#import "MTExpressionUtil.h"
#import "MTReduceRule.h"
#import "MTNullRule.h"
#import "MTNestedDivisionRule.h"
#import "MTRationalAdditionRule.h"
#import "MTCancelCommonFactorsRule.h"
#import "MTRationalMultiplicationRule.h"

@class MTExpression;

@implementation MTCanonicalizerFactory

+ (id<MTCanonicalizer>)getCanonicalizer:(id<MTMathEntity>)entity
{
    switch (entity.entityType) {
        case kMTEquation:
            return [self getEquationCanonicalizer];
        case kMTExpression:
            return [self getExpressionCanonicalizer];
        case kMTTypeAny:
            NSAssert(false, @"An actual entity with type any: %@", entity);
            return nil;
    }
}

+ (MTExpressionCanonicalizer *)getExpressionCanonicalizer
{
    static MTExpressionCanonicalizer* expCanonicalizer = nil;
    if (!expCanonicalizer) {
        expCanonicalizer = [MTExpressionCanonicalizer new];
    }
    return expCanonicalizer;
}

+ (MTEquationCanonicalizer *)getEquationCanonicalizer
{
    static MTEquationCanonicalizer* eqCanon = nil;
    if (!eqCanon) {
        eqCanon = [MTEquationCanonicalizer new];
    }
    return eqCanon;
}

@end

#pragma mark - ExpressionCanonicalizer

@implementation MTExpressionCanonicalizer {
    MTRemoveNegativesRule *_removeNegatives;
    MTFlattenRule *_flatten;
    MTReorderTermsRule *_reorder;
    NSArray *_canonicalizingRules;
    NSArray *_divisionRules;
}

- (id) init
{
    self = [super init];
    if (self) {
        _removeNegatives = [MTRemoveNegativesRule rule];
        _flatten = [MTFlattenRule rule];
        _reorder = [MTReorderTermsRule rule];
        // All rules except division rules
        _canonicalizingRules = @[[MTCalculateRule rule],
                                 [MTNullRule rule],
                                 [MTIdentityRule rule],
                                 [MTZeroRule rule],
                                 [MTDistributionRule rule],
                                 [MTFlattenRule rule],
                                 [MTCollectLikeTermsRule rule],
                                 [MTReduceRule rule]];
        // All rules except distribution with the addition of division rules
        _divisionRules = @[[MTCalculateRule rule],
                           [MTNullRule rule],
                           [MTIdentityRule rule],
                           [MTZeroRule rule],
                           [MTFlattenRule rule],
                           [MTNestedDivisionRule rule],
                           [MTCollectLikeTermsRule rule],
                           [MTReduceRule rule],
                           [MTRationalAdditionRule rule],
                           [MTRationalMultiplicationRule rule],
                           [MTCancelCommonFactorsRule rule]];
    }
    return self;
}

// Normalize the expression by removing -ves and extra parenthesis.
- (MTExpression*) normalize: (MTExpression*) ex
{
    return [_flatten apply:[_removeNegatives apply:ex]];
}

// Canonicalize the expression to its polynomial representation
// i.e. axx + bx +  c
- (MTExpression*) normalForm: (MTExpression*) ex {
    MTExpression* rationalForm = [self applyRules:_divisionRules toExpression:ex];
    // rationalForm should be of the form polynomial / polynomial
    DLog(@"Rational form: %@", rationalForm);
    if ([MTExpressionUtil isDivision:rationalForm]) {
        NSAssert(rationalForm.children.count == 2, @"Rational form should only have 2 children");
        MTExpression* numerator = rationalForm.children[0];
        MTExpression* denominator = rationalForm.children[1];
        // canonical form for each polynomial
        MTExpression* canonicalDenonimator = [self canonicalFormForPolynomial:denominator];
        // We make always make the leading coefficient of the denominator 1.
        MTRational* leadingCoefficient = [self getLeadingCoefficient:canonicalDenonimator];
        canonicalDenonimator = [self dividePolynomial:canonicalDenonimator byLeadingCoefficient:leadingCoefficient];
        MTExpression* canonicalNumerator = [self dividePolynomial:numerator byLeadingCoefficient:leadingCoefficient];
        return [MTOperator operatorWithType:kMTDivision args:canonicalNumerator :canonicalDenonimator];
    } else {
        // canonical form for the polynomial
        return [self canonicalFormForPolynomial:rationalForm];
    }
}

- (MTRational*) getLeadingCoefficient:(MTExpression*) normalPolynomial
{
    MTExpression* leadingTerm = [MTExpressionUtil getLeadingTerm:normalPolynomial];
    // get the coefficient of the leading term
    MTRational* coefficient;
    NSArray* variables;
    BOOL rv = [MTExpressionUtil expression:leadingTerm getCoefficent:&coefficient variables:&variables];
    NSAssert(rv, @"Normalized expression leading term %@ not of the form Nxyz for expression %@", leadingTerm, normalPolynomial);
    return coefficient;
}

- (MTExpression*) dividePolynomial:(MTExpression*) expr byLeadingCoefficient:(MTRational*) coefficient
{
    // divide by the leading coefficient
    MTExpression* dividedExpr = [MTOperator operatorWithType:kMTDivision args:expr :[MTNumber numberWithValue:coefficient]];
    return [self canonicalFormForPolynomial:dividedExpr];
}

- (MTExpression*) canonicalFormForPolynomial:(MTExpression*) poly
{
    MTExpression* normalFormPoly = [self applyRules:_canonicalizingRules toExpression:poly];
    // Order the terms to be in the canonical order.
    return [_reorder apply:normalFormPoly];
}

- (MTExpression*) applyRules:(NSArray*) rules toExpression:(MTExpression*) ex
{
    MTExpression* current = ex;
    BOOL modifed = YES;
    while (modifed) {
        modifed = NO;
        for (MTRule* rule in rules) {
            MTExpression* next = [rule apply:current];
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

@implementation MTEquationCanonicalizer

- (MTEquation *)normalize:(MTEquation *)eq
{
    MTExpressionCanonicalizer* expCanon = [MTCanonicalizerFactory getExpressionCanonicalizer];
    MTExpression* normalizedLhs = [expCanon normalize:eq.lhs];
    MTExpression* normalizedRhs = [expCanon normalize:eq.rhs];
    return [MTEquation equationWithRelation:eq.relation lhs:normalizedLhs rhs:normalizedRhs];
}

- (MTEquation *)normalForm:(MTEquation *)eq
{
    MTExpression* newLhs = [MTOperator operatorWithType:kMTSubtraction args:eq.lhs :eq.rhs];
    MTExpressionCanonicalizer* expCanon = [MTCanonicalizerFactory getExpressionCanonicalizer];
    MTExpression* normalizedNewLhs = [expCanon normalize:newLhs];
    MTExpression* normalForm = [expCanon normalForm:normalizedNewLhs];
    
    if (normalForm.expressionType == kMTExpressionTypeNull) {
        InfoLog(@"Equation mathematically invalid: %@", eq);
        return [MTEquation equationWithRelation:eq.relation lhs:normalForm rhs:[MTNumber numberWithValue:[MTRational zero]]];
    }

    MTExpression* lhsExpression = normalForm;
    if ([MTExpressionUtil isDivision:normalForm]) {
        // its a rational expression. We can ignore the denominator since it multiplies with 0.
        NSAssert(normalForm.children.count == 2, @"Division should have 2 children");
        lhsExpression = normalForm.children[0];
    }
    
    MTRational* coefficient = [expCanon getLeadingCoefficient:lhsExpression];
    lhsExpression = [expCanon dividePolynomial:lhsExpression byLeadingCoefficient:coefficient];
    
    return [MTEquation equationWithRelation:eq.relation lhs:lhsExpression rhs:[MTNumber numberWithValue:[MTRational zero]]];
}

@end
