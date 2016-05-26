//
//  Canonicalizer.h
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.

#import <Foundation/Foundation.h>
#import "Expression.h"

@class ExpressionCanonicalizer;
@class EquationCanonicalizer;

@protocol Canonicalizer <NSObject>

// Normalize the expression by removing -ves and extra parenthesis.
- (id<MathEntity>) normalize: (id<MathEntity>) ex;

// Convert the expression to its normal form polynomial representation
// It assumes that the expression is already normalized using the function above.
// i.e. axx + bx +  c
- (id<MathEntity>) normalForm: (id<MathEntity>) ex;

@end

@interface CanonicalizerFactory : NSObject

// Returns the singleton instance of a canonicalizer applicable to the given entity
+ (id<Canonicalizer>) getCanonicalizer:(id<MathEntity>) entity;

+ (ExpressionCanonicalizer*) getExpressionCanonicalizer;
+ (EquationCanonicalizer*) getEquationCanonicalizer;

@end

@interface ExpressionCanonicalizer : NSObject<Canonicalizer>

// Normalize the expression by removing -ves and extra parenthesis.
- (Expression*) normalize: (Expression*) ex;

// Convert the expression to its normal form polynomial representation
// It assumes that the expression is already normalized using the function above.
// i.e. axx + bx +  c
- (Expression*) normalForm: (Expression*) ex;

@end

@interface EquationCanonicalizer : NSString<Canonicalizer>

// Normalize the expression by removing -ves and extra parenthesis.
- (Equation*) normalize: (Equation*) ex;

// Convert the expression to its normal form equaton representation
// It assumes that the expression is already normalized using the function above.
// i.e. xx + bx +  c = 0, with the leading coefficient always 1
- (Equation*) normalForm: (Equation*) ex;

@end
