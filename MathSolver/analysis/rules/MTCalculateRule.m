//
//  CalculateRule.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTCalculateRule.h"
#import "MTExpression.h"

@implementation MTCalculateRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args
{
    if (expr.expressionType != kMTExpressionTypeOperator) {
        return expr;
    }
    if ([expr equalsExpressionValue:kMTDivision]) {
        
        NSAssert(args.count == 2, @"Division with more than 2 arguments: %@", args);
        
        MTExpression* dividend = args[0];
        MTExpression* divisor = args[1];
        if (divisor.expressionType == kMTExpressionTypeNumber) {
            MTExpression* divided = [self performDivision:(MTNumber*)divisor dividend:dividend];
            if (divided) {
                return divided;
            }
        }
    } else if ([expr equalsExpressionValue:kMTAddition] || [expr equalsExpressionValue:kMTMultiplication]) {
        MTOperator* oper = (MTOperator*) expr;
        MTExpression* reduced = [self calculate:args operator:oper.type];
        if (reduced) {
            return reduced;
        }
    }
    
    return expr;
}

- (MTExpression*)performDivision:(MTNumber *)divisor dividend:(MTExpression *)dividend
{
    // Get the coefficent of dividend
    MTRational* divisorValue = divisor.value;
    if (![divisorValue isEquivalent:[MTRational zero]]) {
        MTExpression* multiplication = [MTOperator operatorWithType:kMTMultiplication args:dividend :[MTNumber numberWithValue:divisorValue.reciprocal]];
        switch (dividend.expressionType) {
                
            case kMTExpressionTypeNumber:
                return [MTNumber numberWithValue:[divisorValue.reciprocal multiply:dividend.expressionValue]];
                
            case kMTExpressionTypeVariable:
                return multiplication;
                
            case kMTExpressionTypeOperator:
                if ([dividend equalsExpressionValue:kMTMultiplication]) {
                    // for a multiplication, perform a reduce
                    NSMutableArray* newArgs = [NSMutableArray arrayWithArray:dividend.children];
                    [newArgs addObject:[MTNumber numberWithValue:divisorValue.reciprocal]];
                    MTExpression* reduced = [self calculate:newArgs operator:kMTMultiplication];
                    return (reduced) ? reduced : multiplication;
                } else {
                    return multiplication;
                }
                
            case kMTExpressionTypeNull:
                return [MTNull null];
        }
    } else {
        // Division by 0 is not supported.
        return [MTNull null];
    }
}

- (MTExpression*) calculate:(NSArray *)children operator:(char)operType
{
    NSMutableArray* newArgs = [NSMutableArray arrayWithCapacity:[children count]];
    NSMutableArray* numbersToOperateOn = [NSMutableArray arrayWithCapacity:[children count]];
    
    for (MTExpression *arg in children) {
        if ([arg isKindOfClass:[MTNumber class]]) {
            [numbersToOperateOn addObject:arg];
        } else {
            [newArgs addObject:arg];
        }
    }
    if ([numbersToOperateOn count] > 1) {
        MTNumber* number = [self reduce:numbersToOperateOn withOperator:operType];
        if ([newArgs count] == 0) {
            // there are no non-number expressions, so remove the operator
            return number;
        } else {
            [newArgs addObject:number];
            return [MTOperator operatorWithType:operType args:newArgs];
        }
    }
    return nil;
}


- (MTNumber*) reduce:(NSArray*) numbers withOperator:(char) operType
{
    switch (operType) {
        case '+':
        {
            MTRational* answer = [MTRational zero];
            for (MTNumber* arg in numbers) {
                answer = [answer add:arg.value];
            }
            return [MTNumber numberWithValue:answer];
        }
        case '*':
        {
            MTRational* answer = [MTRational one];
            for (MTNumber* arg in numbers) {
                answer = [answer multiply:arg.value];
            }
            return [MTNumber numberWithValue:answer];
        }
            
        default:
            @throw [NSException exceptionWithName:@"RuleEvaluationError"
                                           reason:[NSString stringWithFormat:@"Unknown operator %c during evaluation", operType]
                                         userInfo:nil];
            
    }
}

@end
