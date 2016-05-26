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
    kMTRationalFormatNone = 0,    // Default value
    kMTRationalFormatWhole,       // A whole number
    kMTRationalFormatDecimal,     // A number with a decimal point
    kMTRationalFormatImproper,
    kMTRationalFormatMixed,
} MTRationalFormat;

@interface MTRational : NSObject

@property (nonatomic, readonly) NSInteger numerator;
@property (nonatomic, readonly) NSInteger denominator;
// The format in which this rational was entered.
@property (nonatomic, readonly) MTRationalFormat format;

+ (instancetype) rationalWithNumerator:(NSInteger) numerator denominator:(NSInteger) denominator;

- (MTRational*) negation;
- (MTRational*) reciprocal;
- (MTRational*) absoluteValue;

- (MTRational*) add:(MTRational*) r;
- (MTRational*) subtract:(MTRational*) r;
- (MTRational*) multiply:(MTRational*) r;
- (MTRational*) divideBy:(MTRational*) r;

// Reduced to it's base form
- (MTRational*) reduced;

// Return the rational as a floating point number.
- (float) floatValue;
- (BOOL) isInteger;
- (long) floor;

- (NSString *)description;
- (BOOL)isEqual:(id)object;
- (BOOL)isEqualToRational:(MTRational*) r;

// The number is equivalent, i.e. the same number, but it could be a different representation.
// e.g. 1/2 and 2/4 are equivalent fractions.
- (BOOL)isEquivalent:(MTRational*) r;

- (NSComparisonResult) compare:(MTRational *)aNumber;
- (BOOL) isPositive;
- (BOOL) isNegative;
- (BOOL) isZero;
- (BOOL) isReduced;
- (BOOL) isGreaterThan:(MTRational*) r;
- (BOOL) isLessThan:(MTRational*) r;
- (NSUInteger)hash;

+ (MTRational*) zero;
+ (MTRational*) one;
+ (MTRational*) rationalWithNumber:(NSInteger) number;
// Parses a string of the form a.b where a and b are integers to a rational. Does not handle -ve signs.
// If the string is not in the given format, this fails.
+ (MTRational*) rationalFromDecimalRepresentation:(NSString*) str;

@end
