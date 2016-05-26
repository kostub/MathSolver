//
//  Canonicalizer.h
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.

#import <Foundation/Foundation.h>
#import "MTExpression.h"

@class MTExpressionCanonicalizer;
@class MTEquationCanonicalizer;

@protocol MTCanonicalizer <NSObject>

// Normalize the expression by removing -ves and extra parenthesis.
- (id<MTMathEntity>) normalize: (id<MTMathEntity>) ex;

// Convert the expression to its normal form polynomial representation
// It assumes that the expression is already normalized using the function above.
// i.e. axx + bx +  c
- (id<MTMathEntity>) normalForm: (id<MTMathEntity>) ex;

@end

@interface MTCanonicalizerFactory : NSObject

// Returns the singleton instance of a canonicalizer applicable to the given entity
+ (id<MTCanonicalizer>) getCanonicalizer:(id<MTMathEntity>) entity;

+ (MTExpressionCanonicalizer*) getExpressionCanonicalizer;
+ (MTEquationCanonicalizer*) getEquationCanonicalizer;

@end

@interface MTExpressionCanonicalizer : NSObject<MTCanonicalizer>

// Normalize the expression by removing -ves and extra parenthesis.
- (MTExpression*) normalize: (MTExpression*) ex;

// Convert the expression to its normal form polynomial representation
// It assumes that the expression is already normalized using the function above.
// i.e. axx + bx +  c
- (MTExpression*) normalForm: (MTExpression*) ex;

@end

@interface MTEquationCanonicalizer : NSString<MTCanonicalizer>

// Normalize the expression by removing -ves and extra parenthesis.
- (MTEquation*) normalize: (MTEquation*) ex;

// Convert the expression to its normal form equaton representation
// It assumes that the expression is already normalized using the function above.
// i.e. xx + bx +  c = 0, with the leading coefficient always 1
- (MTEquation*) normalForm: (MTEquation*) ex;

@end
