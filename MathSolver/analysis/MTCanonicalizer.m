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
#import "RemoveNegativesRule.h"
#import "FlattenRule.h"
#import "CalculateRule.h"
#import "IdentityRule.h"
#import "DistributionRule.h"
#import "ZeroRule.h"
#import "CollectLikeTermsRule.h"
#import "ReorderTermsRule.h"
#import "MTExpressionUtil.h"
#import "ReduceRule.h"
#import "NullRule.h"
#import "NestedDivisionRule.h"
#import "RationalAdditionRule.h"
#import "CancelCommonFactorsRule.h"
#import "RationalMultiplicationRule.h"

@class MTExpression;

@implementation CanonicalizerFactory

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
        for (Rule* rule in rules) {
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

@implementation EquationCanonicalizer

- (MTEquation *)normalize:(MTEquation *)eq
{
    ExpressionCanonicalizer* expCanon = [CanonicalizerFactory getExpressionCanonicalizer];
    MTExpression* normalizedLhs = [expCanon normalize:eq.lhs];
    MTExpression* normalizedRhs = [expCanon normalize:eq.rhs];
    return [MTEquation equationWithRelation:eq.relation lhs:normalizedLhs rhs:normalizedRhs];
}

- (MTEquation *)normalForm:(MTEquation *)eq
{
    MTExpression* newLhs = [MTOperator operatorWithType:kMTSubtraction args:eq.lhs :eq.rhs];
    ExpressionCanonicalizer* expCanon = [CanonicalizerFactory getExpressionCanonicalizer];
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
