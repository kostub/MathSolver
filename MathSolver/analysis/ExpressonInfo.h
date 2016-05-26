//
//  ExpressonInfo.h
//
//  Created by Kostub Deshmukh on 9/11/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.

#import <Foundation/Foundation.h>
#import "Expression.h"
#import "MTMathList.h"

// Information about an expression
@interface ExpressionInfo : NSObject

// Create an ExpressionInfo object with the parsed expression, the original unparsed input MTMathList and if present a variableName
- (id) initWithExpression:(id<MathEntity>) expression input:(MTMathList*) input variable:(NSString*) variable;
// Same as above but variableName is nil
- (id) initWithExpression:(id<MathEntity>) expression input:(MTMathList*) input;
// We allow empty expression infos with just a variable.
- (id) initWithVariable:(NSString*) variable;

- (NSString *)description;

// The original expression as displayed
@property (nonatomic, readonly) id<MathEntity> original;
// Normalized form of the expression
@property (nonatomic, readonly) id<MathEntity> normalized;
// The expression in normal form (i.e. where 0 is 0) this is represented as A/B where A and B are polynomials or A = 0 for equations.
@property (nonatomic, readonly) id<MathEntity> normalForm;
// The variable (if any) for this expression.
@property (nonatomic, readonly) NSString* variableName;
// The original input from the user.
@property (nonatomic, readonly) MTMathList* input;

@end
