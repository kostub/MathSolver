//
//  ExpressionAnalysis.m
//
//  Created by Kostub Deshmukh on 6/6/15.
//  Copyright (c) 2015 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ExpressionAnalysis.h"

#import "ExpressonInfo.h"
#import "ExpressionUtil.h"
#import "ReorderTermsRule.h"
#import "DecimalReduceRule.h"

@implementation ExpressionAnalysis

+ (BOOL) isExpressionFinalStep:(ExpressionInfo*) expressionInfo forEntityType:(MathEntityType) originalEntityType
{
    if (originalEntityType == kFXExpression) {
        ReorderTermsRule* rule = [ReorderTermsRule rule];
        // apply the rules before checking equality since the user may not have the terms in the right order or reduced decimals.
        return [self isReducedExpression:[rule apply:expressionInfo.normalized] withNormalForm:expressionInfo.normalForm];
    } else if (originalEntityType == kFXEquation) {
        // Note: This works only for linear equations, systems of equations and quadratics may need different things to check.
        Equation* eq = (Equation*) expressionInfo.normalized;
        // x = 5 or 5 = x is acceptable.
        if ((eq.lhs.expressionType == kFXVariable && [self isReducedEquationSide:eq.rhs])
            || (eq.rhs.expressionType == kFXVariable && [self isReducedEquationSide:eq.lhs])) {
            return true;
        }
    }
    return false;
}

+ (BOOL) isReducedExpression:(Expression*) expr withNormalForm:(Expression*) normalForm
{
    DecimalReduceRule* decimalReduce = [DecimalReduceRule rule];
    return [normalForm isEqual:[decimalReduce apply:expr]];
}

+ (BOOL) isReducedEquationSide:(Expression*) expr
{
    ExpressionInfo* exprInfo = [[ExpressionInfo alloc] initWithExpression:expr input:nil];
    return expr.expressionType == kFXNumber && [self isReducedExpression:expr withNormalForm:exprInfo.normalForm];
}

+ (BOOL)hasCheckableAnswer:(ExpressionInfo*) start
{
    id<MathEntity> expr = start.original;
    if ([self isExpressionFinalStep:start forEntityType:expr.entityType]) {
        InfoLog(@"Expression %@ cannot be solved further", expr);
        return NO;
    }

    switch (start.original.entityType) {
        case kFXExpression: {
            Expression* normal = start.normalForm;
            if ([ExpressionUtil isDivision:normal]) {
                Expression* numerator = normal.children[0];
                Expression* denominator = normal.children[1];
                if (numerator.degree > 1 || denominator.degree > 1) {
                    InfoLog(@"Expression %@ has numerator or denominator degree > 1", expr);
                    return NO;
                }
            } else if (normal.degree > 1) {
                InfoLog(@"Expression %@ has degree > 1", expr);
                return NO;
            }
            if (normal.expressionType == kFXNull) {
                InfoLog(@"Expression %@ is mathematically invalid.", expr);
                return NO;
            }
            NSSet* vars = [ExpressionUtil getVariablesInExpression:normal];
            if (vars.count > 1) {
                InfoLog(@"Expression %@ has more than one variable.", expr);
                return NO;
            }
            break;
        }

        case kFXEquation: {
            Equation* eq = start.normalForm;
            // only need to check lhs since the rhs is always 0
            if (eq.lhs.expressionType == kFXNull) {
                InfoLog(@"Expression %@ is mathematically invalid.", expr);
                return NO;
            } else if (eq.lhs.degree == 0) {
                // It is just a constant on the lhs, i.e. constant = 0.
                InfoLog(@"Expression %@ is not an equation.", expr);
                return NO;
            } else if (eq.lhs.degree > 1) {
                InfoLog(@"Expression %@ has degree > 1", expr);
                return NO;
            } else if ([ExpressionUtil getVariablesInExpression:eq.lhs].count > 1) {
                InfoLog(@"Equation %@ has more than one variable", expr);
                return NO;
            }
            break;
        }

        case kFXTypeAny:
            InfoLog(@"Unknown expression type %@", start.original);
            return NO;
    }
    
    return YES;
}
@end
