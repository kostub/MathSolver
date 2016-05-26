//
//  ExpressionAnalysis.m
//
//  Created by Kostub Deshmukh on 6/6/15.
//  Copyright (c) 2015 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTExpressionAnalysis.h"

#import "MTExpressionInfo.h"
#import "MTExpressionUtil.h"
#import "MTReorderTermsRule.h"
#import "MTDecimalReduceRule.h"

@implementation MTExpressionAnalysis

+ (BOOL) isExpressionFinalStep:(MTExpressionInfo*) expressionInfo forEntityType:(MTMathEntityType) originalEntityType
{
    if (originalEntityType == kMTExpression) {
        MTReorderTermsRule* rule = [MTReorderTermsRule rule];
        // apply the rules before checking equality since the user may not have the terms in the right order or reduced decimals.
        return [self isReducedExpression:[rule apply:expressionInfo.normalized] withNormalForm:expressionInfo.normalForm];
    } else if (originalEntityType == kMTEquation) {
        // Note: This works only for linear equations, systems of equations and quadratics may need different things to check.
        MTEquation* eq = (MTEquation*) expressionInfo.normalized;
        // x = 5 or 5 = x is acceptable.
        if ((eq.lhs.expressionType == kMTExpressionTypeVariable && [self isReducedEquationSide:eq.rhs])
            || (eq.rhs.expressionType == kMTExpressionTypeVariable && [self isReducedEquationSide:eq.lhs])) {
            return true;
        }
    }
    return false;
}

+ (BOOL) isReducedExpression:(MTExpression*) expr withNormalForm:(MTExpression*) normalForm
{
    MTDecimalReduceRule* decimalReduce = [MTDecimalReduceRule rule];
    return [normalForm isEqual:[decimalReduce apply:expr]];
}

+ (BOOL) isReducedEquationSide:(MTExpression*) expr
{
    MTExpressionInfo* exprInfo = [[MTExpressionInfo alloc] initWithExpression:expr input:nil];
    return expr.expressionType == kMTExpressionTypeNumber && [self isReducedExpression:expr withNormalForm:exprInfo.normalForm];
}

+ (BOOL)hasCheckableAnswer:(MTExpressionInfo*) start
{
    id<MTMathEntity> expr = start.original;
    if ([self isExpressionFinalStep:start forEntityType:expr.entityType]) {
        InfoLog(@"Expression %@ cannot be solved further", expr);
        return NO;
    }

    switch (start.original.entityType) {
        case kMTExpression: {
            MTExpression* normal = start.normalForm;
            if ([MTExpressionUtil isDivision:normal]) {
                MTExpression* numerator = normal.children[0];
                MTExpression* denominator = normal.children[1];
                if (numerator.degree > 1 || denominator.degree > 1) {
                    InfoLog(@"Expression %@ has numerator or denominator degree > 1", expr);
                    return NO;
                }
            } else if (normal.degree > 1) {
                InfoLog(@"Expression %@ has degree > 1", expr);
                return NO;
            }
            if (normal.expressionType == kMTExpressionTypeNull) {
                InfoLog(@"Expression %@ is mathematically invalid.", expr);
                return NO;
            }
            NSSet* vars = [MTExpressionUtil getVariablesInExpression:normal];
            if (vars.count > 1) {
                InfoLog(@"Expression %@ has more than one variable.", expr);
                return NO;
            }
            break;
        }

        case kMTEquation: {
            MTEquation* eq = start.normalForm;
            // only need to check lhs since the rhs is always 0
            if (eq.lhs.expressionType == kMTExpressionTypeNull) {
                InfoLog(@"Expression %@ is mathematically invalid.", expr);
                return NO;
            } else if (eq.lhs.degree == 0) {
                // It is just a constant on the lhs, i.e. constant = 0.
                InfoLog(@"Expression %@ is not an equation.", expr);
                return NO;
            } else if (eq.lhs.degree > 1) {
                InfoLog(@"Expression %@ has degree > 1", expr);
                return NO;
            } else if ([MTExpressionUtil getVariablesInExpression:eq.lhs].count > 1) {
                InfoLog(@"Equation %@ has more than one variable", expr);
                return NO;
            }
            break;
        }

        case kMTTypeAny:
            InfoLog(@"Unknown expression type %@", start.original);
            return NO;
    }
    
    return YES;
}
@end
