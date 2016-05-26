//
//  Rational.h
//
//  Created by Kostub Deshmukh on 9/6/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

// Represents a rational number
#import <Foundation/Foundation.h>

typedef enum
{
    kRationalFormatNone = 0,    // Default value
    kRationalFormatWhole,       // A whole number
    kRationalFormatDecimal,     // A number with a decimal point
    kRationalFormatImproper,
    kRationalFormatMixed,
} RationalFormat;

@interface Rational : NSObject

@property (nonatomic, readonly) NSInteger numerator;
@property (nonatomic, readonly) NSInteger denominator;
// The format in which this rational was entered.
@property (nonatomic, readonly) RationalFormat format;

+ (instancetype) rationalWithNumerator:(NSInteger) numerator denominator:(NSInteger) denominator;

- (Rational*) negation;
- (Rational*) reciprocal;
- (Rational*) absoluteValue;

- (Rational*) add:(Rational*) r;
- (Rational*) subtract:(Rational*) r;
- (Rational*) multiply:(Rational*) r;
- (Rational*) divideBy:(Rational*) r;

// Reduced to it's base form
- (Rational*) reduced;

// Return the rational as a floating point number.
- (float) floatValue;
- (BOOL) isInteger;
- (long) floor;

- (NSString *)description;
- (BOOL)isEqual:(id)object;
- (BOOL)isEqualToRational:(Rational*) r;

// The number is equivalent, i.e. the same number, but it could be a different representation.
// e.g. 1/2 and 2/4 are equivalent fractions.
- (BOOL)isEquivalent:(Rational*) r;

- (NSComparisonResult) compare:(Rational *)aNumber;
- (BOOL) isPositive;
- (BOOL) isNegative;
- (BOOL) isZero;
- (BOOL) isReduced;
- (BOOL) isGreaterThan:(Rational*) r;
- (BOOL) isLessThan:(Rational*) r;
- (NSUInteger)hash;

+ (Rational*) zero;
+ (Rational*) one;
+ (Rational*) rationalWithNumber:(NSInteger) number;
// Parses a string of the form a.b where a and b are integers to a rational. Does not handle -ve signs.
// If the string is not in the given format, this fails.
+ (Rational*) rationalFromDecimalRepresentation:(NSString*) str;

@end
