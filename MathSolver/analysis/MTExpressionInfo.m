//
//  ExpressonInfo.m
//
//  Created by Kostub Deshmukh on 9/11/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTExpressionInfo.h"
#import "MTCanonicalizer.h"

@implementation MTExpressionInfo

- (id)initWithExpression:(id<MTMathEntity>)expression input:(MTMathList *)input
{
    return [self initWithExpression:expression input:input variable:nil];
}

- (id)initWithVariable:(NSString *)variable
{
    return [self initWithExpression:nil input:nil variable:variable];
}

- (id)initWithExpression:(id<MTMathEntity>)expression input:(MTMathList *)input variable:(NSString *)variable
{
    self = [super init];
    if (self) {
        if (expression) {
            id<MTCanonicalizer> canonicalizer = [MTCanonicalizerFactory getCanonicalizer:expression];
            _original = expression;
            _normalized = [canonicalizer normalize:expression];
            _normalForm = [canonicalizer normalForm:_normalized];
        }
        _input = input;
        _variableName = [variable copy];
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *str = [NSMutableString string];
    if (self.variableName) {
        [str appendFormat:@"Variable: %@ ", self.variableName];
    }
    [str appendFormat:@"Original:%@ Normalized:%@ Normal Form:%@", self.original, self.normalized, self.normalForm];
    return str;
}

@end
