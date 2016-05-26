//
//  Expression.m
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTExpression.h"
#import "MTExpressionUtil.h"

const char kMTUnaryMinus = '_';
const char kMTSubtraction = '-';
const char kMTAddition = '+';
const char kMTMultiplication = '*';
const char kMTDivision = '/';

#pragma mark - MTExpression

@interface MTExpression ()
@property (nonatomic) MTMathListRange* range;
@end

@implementation MTExpression


- (NSArray*) children
{
    return nil;
}

- (NSString*) description
{
    return self.stringValue;
}

- (NSString*) stringValue
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSUInteger) degree
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)hasDegree
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (enum MTExpressionType) expressionType
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (id) expressionValue
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL) isEquivalentToExpression:(MTExpression*) expr
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)isEquivalent:(id<MTMathEntity>)entity
{
    if (entity.entityType == kMTExpression) {
        return [self isEquivalentToExpression:entity];
    } else {
        return NO;
    }
}

- (BOOL) isEqualUptoRearrangement:(MTExpression *)expr
{
    return [self isEqual:expr];
}

- (BOOL)isEqualUptoRearrangementRecursive:(MTExpression *)expr
{
    return [self isEqualUptoRearrangement:expr];
}

- (BOOL)equalsExpressionValue:(int)value
{
    return [self isExpressionValueEqualToNumber:[NSNumber numberWithInt:value]];    
}

- (BOOL)isExpressionValueEqualToNumber:(NSNumber *)number
{
    return [number isEqual:self.expressionValue];
}

-(MTMathEntityType)entityType
{
    return kMTExpression;
}

- (MTExpression *)expressionWithRange:(MTMathListRange *)range
{
    @throw [NSException exceptionWithName:@"InternalException"
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end

#pragma mark - MTNumber

@implementation MTNumber

+(id) numberWithValue:(MTRational*)value
{
    MTNumber* number = [self new];
    number->_value = value;
    return number;
}

+(id) numberWithValue:(MTRational*)value range:(MTMathListRange*)range
{
    MTNumber* number = [self numberWithValue:value];
    number.range = range;
    return number;
}

- (NSString*) stringValue
{
    return self.value.description;
}

- (BOOL) isEqual:(id) anObject
{
    if (self == anObject) {
        return YES;
    }
    if (!anObject || ![anObject isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToNumber:anObject];
}

- (BOOL) isEqualToNumber:(MTNumber*) number
{
    return [self.value isEqualToRational:number.value];
}

- (BOOL) isEquivalentToExpression:(MTExpression*) expr
{
    if (expr.expressionType == kMTExpressionTypeNumber) {
        MTRational* rat = expr.expressionValue;
        return [self.value isEquivalent:rat];
    } else {
        return NO;
    }
}

- (NSUInteger) hash
{
    return self.value.hash;
}

- (NSComparisonResult) compare:(MTNumber *)aNumber
{
    return [self.value compare:aNumber.value];
}

- (NSUInteger) degree
{
    return 0;
}

- (BOOL)hasDegree
{
    return YES;
}

- (enum MTExpressionType) expressionType
{
    return kMTExpressionTypeNumber;
}

- (id) expressionValue
{
    return self.value;
}

- (BOOL)isExpressionValueEqualToNumber:(NSNumber *)number
{
    // convert to a rational before comparing
    MTRational* rat = [MTRational rationalWithNumber:number.integerValue];
    return [rat isEquivalent:self.value];
}

- (MTExpression *)expressionWithRange:(MTMathListRange *)range
{
    return [MTNumber numberWithValue:self.value range:range];
}

@end

#pragma mark - MTVariable

@implementation MTVariable

+(id) variableWithName:(char)name
{
    MTVariable* var = [self new];
    var->_name = name;
    return var;
}

+(id) variableWithName:(char)name range:(MTMathListRange*)range
{
    MTVariable* var = [self variableWithName:name];
    var.range = range;
    return var;
}

- (NSString*) stringValue
{
    return [NSString stringWithFormat:@"%c", _name];
}

- (BOOL) isEqual:(id) anObject
{
    if (self == anObject) {
        return YES;
    }
    if (!anObject || ![anObject isKindOfClass:[self class]]) {
        return NO;
    }
    MTVariable* other = (MTVariable*) anObject;
    return (other.name == self.name);
}

- (BOOL) isEquivalentToExpression:(MTExpression*) expr
{
    return [self isEqual:expr];
}

- (NSUInteger) hash
{
    return self.name;
}

- (NSComparisonResult) compare:(MTVariable *)aVariable
{
    if (self.name > aVariable.name) {
        return NSOrderedDescending;
    } else if (aVariable.name > self.name) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

- (NSUInteger) degree
{
    return 1;
}

- (BOOL)hasDegree
{
    return YES;
}

- (enum MTExpressionType) expressionType
{
    return kMTExpressionTypeVariable;
}

- (id) expressionValue
{
    return [NSNumber numberWithChar:self.name];
}

- (MTExpression *)expressionWithRange:(MTMathListRange *)range
{
    return [MTVariable variableWithName:self.name range:range];
}

@end

#pragma mark - FXOperator

@implementation MTOperator {
    NSArray *_args;
}

- (void) setArgs:(NSArray *) args {
    _args = args;
}

- (NSArray*) children
{
    return _args;
}

- (NSString*) stringValue {
    NSMutableString* str = [NSMutableString stringWithString:@"("];
    if (_args.count == 1) {
        // Unary case is different
        MTExpression* expr = [_args objectAtIndex:0];
        [str appendFormat:@"%c %@)", _type, expr.stringValue];
        return str;
    }
    
    for (int i = 0; i < _args.count; ++i) {
        MTExpression* expr = [_args objectAtIndex:i];
        [str appendString:expr.stringValue];
        if (i != _args.count - 1) {
            [str appendFormat:@" %c ", _type];
        }
    }
    [str appendString:@")"];
    return str;
}

+(id) operatorWithType:(char)type args:(MTExpression *)arg1 :(MTExpression *)arg2
{
    MTMathListRange* opRange = nil;
    if (arg1.range && arg2.range) {
        opRange = [arg1.range unionRange:arg2.range];
    } else if (arg1.range) {
        opRange = arg1.range;
    } else if (arg2.range) {
        opRange = arg2.range;
    }
    return [self operatorWithType:type args:arg1 :arg2 range:opRange];
}

+(id) operatorWithType:(char)type args:(MTExpression *)arg1 :(MTExpression *)arg2 range:(MTMathListRange*)range
{
    MTOperator* op = [[MTOperator alloc] init];
    op->_type = type;
    [op setArgs:@[arg1, arg2]];
    op.range = range;
    return op;
}

+(id) unaryOperatorWithType:(char)type arg:(MTExpression *)arg range:(MTMathListRange*)range
{
    MTOperator* op = [[MTOperator alloc] init];
    op->_type = type;
    [op setArgs:@[arg]];
    op.range = range;
    return op;
}

+(id) operatorWithType:(char)type args:(NSArray *)args {
    return [self operatorWithType:type args:args range:nil];
}

+ (id)operatorWithType:(char)type args:(NSArray *)args range:(MTMathListRange *)range
{
    MTOperator* op = [[MTOperator alloc] init];
    assert([args count] > 1);   // no unary operators allowed.
    op->_type = type;
    op.range = range;
    [op setArgs:args];
    return op;
}

- (BOOL)isEqualToOperator:(MTOperator*) object
{
    return (self.type == object.type && [_args isEqualToArray:object->_args]);
}

- (BOOL) isEqual:(id) anObject
{
    if (self == anObject) {
        return YES;
    }
    if (!anObject || ![anObject isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToOperator:anObject];
}

- (BOOL) isEquivalentToExpression:(MTExpression*) expr
{
    if (expr.expressionType == kMTExpressionTypeOperator) {
        MTOperator* oper = (MTOperator*) expr;
        NSArray* children = oper.children;
        if (self.type == oper.type && _args.count == children.count) {
            // check that each child is equivalent to the corresponding child
            for (int i = 0; i < _args.count; i++) {
                MTExpression* expr1 = _args[i];
                MTExpression* expr2 = children[i];
                if (![expr1 isEquivalent:expr2]) {
                    return NO;
                }
            }
            return YES;
        }
    }
    return NO;
}

- (NSUInteger) hash
{
    const int prime = 31;
    return prime * self.type + [_args hash];
}

- (NSUInteger) degree
{
    if (self.type == kMTAddition) {
        // In the case of addition the degree is the max of the degrees of all the arguments.
        return [[_args valueForKeyPath:@"@max.degree"] intValue];
    } else if (self.type == kMTMultiplication) {
        // In the case of multiplication the degree is the sum of all the degrees of the arguments.
        return [[_args valueForKeyPath:@"@sum.degree"] intValue];
    } else {
        return NSNotFound;
    }
}

- (BOOL)hasDegree
{
    return (self.type == kMTAddition) || (self.type == kMTMultiplication);
}

- (enum MTExpressionType) expressionType
{
    return kMTExpressionTypeOperator;
}

- (id) expressionValue
{
    return [NSNumber numberWithChar:self.type];
}

- (BOOL) isEqualUptoRearrangement:(MTExpression *)expr
{
    if (self.expressionType != expr.expressionType) {
        return false;
    }
    if (![self.expressionValue isEqual:expr.expressionValue]) {
        return false;
    }
    
    return ![MTExpressionUtil diffOperator:self with:(MTOperator*)expr removedChildren:nil addedChildren:nil];
}

- (BOOL)isEqualUptoRearrangementRecursive:(MTExpression *)expr
{
    if (self.expressionType != expr.expressionType) {
        return false;
    }
    if (![self.expressionValue isEqual:expr.expressionValue]) {
        return false;
    }
    
    if ([self isEqual:expr]) {
        return true;
    }
    if ([self isEqualUptoRearrangement:expr]) {
        return true;
    }
    
    // This algorithm is exponential, please use carefully
    NSMutableArray* remainingChildren = [NSMutableArray arrayWithArray:expr.children];
    for (MTExpression* child in self.children) {
        BOOL foundChild = false;
        for (MTExpression* theirChild in remainingChildren) {
            if ([child isEqualUptoRearrangementRecursive:theirChild]) {
                foundChild = true;
                [remainingChildren removeObject:theirChild];
                break;
            }
        }
        if (!foundChild) {
            return false;
        }
    }
    return remainingChildren.count == 0;
}

- (MTExpression *)expressionWithRange:(MTMathListRange *)range
{
    if (self.children.count == 1) {
        return [MTOperator unaryOperatorWithType:self.type arg:self.children[0] range:range];
    } else {
        return [MTOperator operatorWithType:self.type args:self.children range:range];
    }
}

@end

#pragma mark - MTNull

@implementation MTNull

+ (instancetype) null
{
    static MTNull *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [MTNull new];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (NSString*) stringValue
{
    return @"(null)";
}

- (NSUInteger) degree
{
    return 0;
}

- (BOOL)hasDegree
{
    return NO;
}

- (enum MTExpressionType) expressionType
{
    return kMTExpressionTypeNull;
}

- (id) expressionValue
{
    return [NSNull null];
}

- (BOOL) isEquivalentToExpression:(MTExpression*) expr
{
    return expr.expressionType == kMTExpressionTypeNull;
}

@end


#pragma mark - MTEquation

@implementation MTEquation

+ (id)equationWithRelation:(char)relation lhs:(MTExpression *)lhs rhs:(MTExpression *)rhs
{
    MTEquation* eq = [MTEquation new];
    eq->_relation = relation;
    eq->_lhs = lhs;
    eq->_rhs = rhs;
    return eq;
}

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@ %c %@", _lhs.stringValue, _relation, _rhs.stringValue];
}

- (NSString*) description
{
    return self.stringValue;
}

- (MTMathEntityType)entityType
{
    return kMTEquation;
}

- (BOOL)isEqual:(id)anObject
{
    if (self == anObject) {
        return YES;
    }
    if (!anObject || ![anObject isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToEquation:anObject];
}

- (BOOL) isEqualToEquation:(MTEquation*) eq
{
    return self.relation == eq.relation && [self.lhs isEqual:eq.lhs] && [self.rhs isEqual:eq.rhs];
}

- (BOOL)isEquivalent:(id<MTMathEntity>)entity
{
    if (entity.entityType == kMTEquation) {
        MTEquation* other = (MTEquation*) entity;
        return self.relation == other.relation && [self.lhs isEquivalent:other.lhs] && [self.rhs isEquivalent:other.rhs];
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    const int prime = 23;
    NSUInteger hash = self.relation;
    hash = prime*hash + self.lhs.hash;
    hash = prime*hash + self.rhs.hash;
    return hash;
}

@end
