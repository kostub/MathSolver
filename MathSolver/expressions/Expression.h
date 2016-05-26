//
//  Expression.h
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

#import "Rational.h"
#import "MTMathListIndex.h"

extern const char kUnaryMinus;
extern const char kSubtraction;
extern const char kAddition;
extern const char kMultiplication;
extern const char kDivision;

typedef enum {
    kFXTypeAny = 0,
    kFXExpression,
    kFXEquation,
} MathEntityType;

@protocol MathEntity <NSObject>

- (NSString*) stringValue;

- (MathEntityType) entityType;

/**
 * Returns true if the two entities are to be considered equivalent for the purposes.
 * of correctness. This is not the same as equals as certain entities may be considered 
 * equivalent even though they may not be equal. e.g. 0.33 and 1/3.
 * @param entity The entity to compare with.
 */
- (BOOL) isEquivalent:(id<MathEntity>) entity;

@end

@interface Expression : NSObject<MathEntity>

enum ExpressionType {
    kFXNumber = 1,
    kFXVariable,
    kFXOperator,
    kFXNull,
};

// The range in the original MTMathList that created it, that this expression denotes.
// Note range is only present when the Expression is created by the parser. For subsequent manipulations range is not required and not maintained.
@property (nonatomic, readonly) MTMathListRange* range;

// Returns a copy of the expression with the given range.
- (Expression*) expressionWithRange:(MTMathListRange*) range;

// The children of this expression, all of whom are expressions themselves.
- (NSArray*) children;

// The degree of the expression.
- (NSUInteger) degree;

// If the expression has a degree. If hasDegree returns false, do not call degree. The result may be unpredictable.
- (BOOL) hasDegree;

- (enum ExpressionType) expressionType;

- (id) expressionValue;

// Returns true if the expression has the given value
- (BOOL) equalsExpressionValue:(int) value;
- (BOOL) isExpressionValueEqualToNumber:(NSNumber*) number;

- (BOOL) isEqualUptoRearrangement:(Expression*) expr;

// Same as above but recursive
- (BOOL) isEqualUptoRearrangementRecursive:(Expression*) expr;

@end


@interface FXNumber : Expression

@property (nonatomic, readonly) Rational* value;

+(id) numberWithValue:(Rational*) value;
+(id) numberWithValue:(Rational*) value range:(MTMathListRange*) range;

- (BOOL) isEqualToNumber:(FXNumber*) number;
- (NSComparisonResult) compare: (FXNumber*) aNumber;

@end

@interface FXVariable : Expression

@property (nonatomic, readonly) char name;

+(id) variableWithName:(char) name;
+(id) variableWithName:(char) name range:(MTMathListRange*) range;

- (NSComparisonResult) compare: (FXVariable*) aVariable;

@end

@interface FXOperator : Expression

@property (nonatomic, readonly) char type;

// binary
+(id) operatorWithType:(char)type args:(Expression *)arg1 :(Expression *)arg2 range:(MTMathListRange*)range;
+(id) operatorWithType:(char) type args:(Expression*) arg1 :(Expression*) arg2;

// unary
+(id) unaryOperatorWithType:(char) type arg:(Expression*) arg range:(MTMathListRange*) range;

+(id) operatorWithType:(char)type args:(NSArray*) args;
+(id) operatorWithType:(char)type args:(NSArray*) args range:(MTMathListRange*) range;

@end

@interface FXNull : Expression

// Returns the singleton FXNull object
+ (instancetype) null;

@end

@interface Equation : NSObject<MathEntity>

+(id) equationWithRelation:(char) relation lhs:(Expression *)lhs rhs:(Expression*) rhs;

@property (nonatomic, readonly) char relation;   // = > < etc.

@property (nonatomic, readonly) Expression* lhs;
@property (nonatomic, readonly) Expression* rhs;

@end
