//
//  CalculateRule.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "CalculateRule.h"
#import "Expression.h"

@implementation CalculateRule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args
{
    if (expr.expressionType != kFXOperator) {
        return expr;
    }
    if ([expr equalsExpressionValue:kDivision]) {
        
        NSAssert(args.count == 2, @"Division with more than 2 arguments: %@", args);
        
        Expression* dividend = args[0];
        Expression* divisor = args[1];
        if (divisor.expressionType == kFXNumber) {
            Expression* divided = [self performDivision:(FXNumber*)divisor dividend:dividend];
            if (divided) {
                return divided;
            }
        }
    } else if ([expr equalsExpressionValue:kAddition] || [expr equalsExpressionValue:kMultiplication]) {
        FXOperator* oper = (FXOperator*) expr;
        Expression* reduced = [self calculate:args operator:oper.type];
        if (reduced) {
            return reduced;
        }
    }
    
    return expr;
}

- (Expression*)performDivision:(FXNumber *)divisor dividend:(Expression *)dividend
{
    // Get the coefficent of dividend
    Rational* divisorValue = divisor.value;
    if (![divisorValue isEquivalent:[Rational zero]]) {
        Expression* multiplication = [FXOperator operatorWithType:kMultiplication args:dividend :[FXNumber numberWithValue:divisorValue.reciprocal]];
        switch (dividend.expressionType) {
                
            case kFXNumber:
                return [FXNumber numberWithValue:[divisorValue.reciprocal multiply:dividend.expressionValue]];
                
            case kFXVariable:
                return multiplication;
                
            case kFXOperator:
                if ([dividend equalsExpressionValue:kMultiplication]) {
                    // for a multiplication, perform a reduce
                    NSMutableArray* newArgs = [NSMutableArray arrayWithArray:dividend.children];
                    [newArgs addObject:[FXNumber numberWithValue:divisorValue.reciprocal]];
                    Expression* reduced = [self calculate:newArgs operator:kMultiplication];
                    return (reduced) ? reduced : multiplication;
                } else {
                    return multiplication;
                }
                
            case kFXNull:
                return [FXNull null];
        }
    } else {
        // Division by 0 is not supported.
        return [FXNull null];
    }
}

- (Expression*) calculate:(NSArray *)children operator:(char)operType
{
    NSMutableArray* newArgs = [NSMutableArray arrayWithCapacity:[children count]];
    NSMutableArray* numbersToOperateOn = [NSMutableArray arrayWithCapacity:[children count]];
    
    for (Expression *arg in children) {
        if ([arg isKindOfClass:[FXNumber class]]) {
            [numbersToOperateOn addObject:arg];
        } else {
            [newArgs addObject:arg];
        }
    }
    if ([numbersToOperateOn count] > 1) {
        FXNumber* number = [self reduce:numbersToOperateOn withOperator:operType];
        if ([newArgs count] == 0) {
            // there are no non-number expressions, so remove the operator
            return number;
        } else {
            [newArgs addObject:number];
            return [FXOperator operatorWithType:operType args:newArgs];
        }
    }
    return nil;
}


- (FXNumber*) reduce:(NSArray*) numbers withOperator:(char) operType
{
    switch (operType) {
        case '+':
        {
            Rational* answer = [Rational zero];
            for (FXNumber* arg in numbers) {
                answer = [answer add:arg.value];
            }
            return [FXNumber numberWithValue:answer];
        }
        case '*':
        {
            Rational* answer = [Rational one];
            for (FXNumber* arg in numbers) {
                answer = [answer multiply:arg.value];
            }
            return [FXNumber numberWithValue:answer];
        }
            
        default:
            @throw [NSException exceptionWithName:@"RuleEvaluationError"
                                           reason:[NSString stringWithFormat:@"Unknown operator %c during evaluation", operType]
                                         userInfo:nil];
            
    }
}

@end
