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

#import "MTRational.h"
#import "MTMathListIndex.h"

extern const char kMTUnaryMinus;
extern const char kMTSubtraction;
extern const char kMTAddition;
extern const char kMTMultiplication;
extern const char kMTDivision;

typedef enum {
    kMTTypeAny = 0,
    kMTExpression,
    kMTEquation,
} MTMathEntityType;

@protocol MTMathEntity <NSObject>

- (NSString*) stringValue;

- (MTMathEntityType) entityType;

/**
 * Returns true if the two entities are to be considered equivalent for the purposes.
 * of correctness. This is not the same as equals as certain entities may be considered 
 * equivalent even though they may not be equal. e.g. 0.33 and 1/3.
 * @param entity The entity to compare with.
 */
- (BOOL) isEquivalent:(id<MTMathEntity>) entity;

@end

@interface MTExpression : NSObject<MTMathEntity>

enum MTExpressionType {
    kMTExpressionTypeNumber = 1,
    kMTExpressionTypeVariable,
    kMTExpressionTypeOperator,
    kMTExpressionTypeNull,
};

// The range in the original MTMathList that created it, that this expression denotes.
// Note range is only present when the Expression is created by the parser. For subsequent manipulations range is not required and not maintained.
@property (nonatomic, readonly) MTMathListRange* range;

// Returns a copy of the expression with the given range.
- (MTExpression*) expressionWithRange:(MTMathListRange*) range;

// The children of this expression, all of whom are expressions themselves.
- (NSArray*) children;

// The degree of the expression.
- (NSUInteger) degree;

// If the expression has a degree. If hasDegree returns false, do not call degree. The result may be unpredictable.
- (BOOL) hasDegree;

- (enum MTExpressionType) expressionType;

- (id) expressionValue;

// Returns true if the expression has the given value
- (BOOL) equalsExpressionValue:(int) value;
- (BOOL) isExpressionValueEqualToNumber:(NSNumber*) number;

- (BOOL) isEqualUptoRearrangement:(MTExpression*) expr;

// Same as above but recursive
- (BOOL) isEqualUptoRearrangementRecursive:(MTExpression*) expr;

@end


@interface MTNumber : MTExpression

@property (nonatomic, readonly) MTRational* value;

+(id) numberWithValue:(MTRational*) value;
+(id) numberWithValue:(MTRational*) value range:(MTMathListRange*) range;

- (BOOL) isEqualToNumber:(MTNumber*) number;
- (NSComparisonResult) compare: (MTNumber*) aNumber;

@end

@interface MTVariable : MTExpression

@property (nonatomic, readonly) char name;

+(id) variableWithName:(char) name;
+(id) variableWithName:(char) name range:(MTMathListRange*) range;

- (NSComparisonResult) compare: (MTVariable*) aVariable;

@end

@interface MTOperator : MTExpression

@property (nonatomic, readonly) char type;

// binary
+(id) operatorWithType:(char)type args:(MTExpression *)arg1 :(MTExpression *)arg2 range:(MTMathListRange*)range;
+(id) operatorWithType:(char) type args:(MTExpression*) arg1 :(MTExpression*) arg2;

// unary
+(id) unaryOperatorWithType:(char) type arg:(MTExpression*) arg range:(MTMathListRange*) range;

+(id) operatorWithType:(char)type args:(NSArray*) args;
+(id) operatorWithType:(char)type args:(NSArray*) args range:(MTMathListRange*) range;

@end

@interface MTNull : MTExpression

// Returns the singleton FXNull object
+ (instancetype) null;

@end

@interface MTEquation : NSObject<MTMathEntity>

+(id) equationWithRelation:(char) relation lhs:(MTExpression *)lhs rhs:(MTExpression*) rhs;

@property (nonatomic, readonly) char relation;   // = > < etc.

@property (nonatomic, readonly) MTExpression* lhs;
@property (nonatomic, readonly) MTExpression* rhs;

@end
