//
//  Rational.m
//
//  Created by Kostub Deshmukh on 9/6/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "Rational.h"

static NSUInteger gcd(NSUInteger a, NSUInteger b) {
    while (b != 0) {
        NSUInteger prev = b;
        b = a % b;
        a = prev;
    }
    return a;
}

// Represents a rational number
@implementation Rational {
    NSUInteger _gcd;
}

+ (instancetype) rationalWithNumerator:(NSInteger) numerator denominator:(NSInteger) denominator format:(RationalFormat) format;
{
    if (denominator == 0) {
        // can't have a rational number divided by 0
        return nil;
    }
    if (format == kRationalFormatWhole && denominator != 1) {
        // Whole number should always have a denominator of 1.
        return nil;
    }
    return [[[self class] alloc] initWithNumerator:numerator denominator:denominator format:format];
}

+ (instancetype)rationalWithNumerator:(NSInteger)numerator denominator:(NSInteger)denominator
{
    return [self rationalWithNumerator:numerator denominator:denominator format:kRationalFormatImproper];
}

+ (Rational *)zero
{
    static Rational* zero = nil;
    if (!zero) {
        zero = [Rational rationalWithNumber:0];
    }
    return zero;
}

+ (Rational *)one
{
    static Rational* one = nil;
    if (!one) {
        one = [Rational rationalWithNumber:1];
    }
    return one;
}

+ (Rational *)rationalWithNumber:(NSInteger)number
{
    return [[[self class] alloc] initWithNumerator:number denominator:1u format:kRationalFormatWhole];
}

+ (Rational*)rationalFromDecimalRepresentation:(NSString *)str
{
    NSParameterAssert(str);
    if (str.length == 0) {
        return nil;
    }
    NSScanner* scanner = [NSScanner scannerWithString:str];
    scanner.charactersToBeSkipped = nil;
    // check for -ve sign
    if ([scanner scanString:@"-" intoString:NULL]) {
        // -ve signs are not supported
        return nil;
    }
    
    NSInteger whole;
    if (![scanner scanInteger:&whole]) {
        whole = 0;
    }
    if ([scanner isAtEnd]) {
        return [self rationalWithNumber:whole];
    }
    // The only possible character that can come here is a '.'
    if (![scanner scanString:@"." intoString:NULL]) {
        // We encountered some other character other than a .
        return nil;
    }
    if ([scanner isAtEnd]) {
        // The . at the end of the number is useless, we represent this as x.0
        return [self rationalWithNumerator:whole*10 denominator:10 format:kRationalFormatDecimal];
    }
    long numDigitsLeft = str.length - scanner.scanLocation;
    assert(numDigitsLeft > 0);  // otherwise the scanner should have been at the end
    NSInteger fractional;
    if (![scanner scanInteger:&fractional]) {
        fractional = 0;
    }
    if (![scanner isAtEnd]) {
        // more non digit characters
        return nil;
    }
    if (fractional < 0) {
        // Can't have a -ve fractional
        return nil;
    }
    NSUInteger denominator = 1;
    for (int i = 0; i < numDigitsLeft; i++) {
        denominator *= 10;
    }
    Rational* r = [self rationalWithNumerator:(whole*denominator + fractional) denominator:denominator format:kRationalFormatDecimal];
    return r;
}

- (instancetype) initWithNumerator:(NSInteger)numerator denominator:(NSUInteger)denominator format:(RationalFormat) format
{
    self = [super init];
    if (self) {
        _numerator = numerator;
        _denominator = denominator;
        _format = format;
        _gcd = gcd(ABS(self.numerator), ABS(self.denominator));
    }
    return self;
}

- (Rational *)negation
{
    // negations retain the format
    Rational* neg = [Rational rationalWithNumerator:-_numerator denominator:_denominator format:_format];
    return neg;
}

- (Rational *)add:(Rational *)r
{
    if (self.denominator == r.denominator) {
        // Special case for common denominators to make the fractions look more normal
        return [Rational rationalWithNumerator:(r.numerator + self.numerator) denominator:r.denominator];
    }
    // worry about oveflow?, should we always reduce?
    NSUInteger d = self.denominator * r.denominator;
    NSInteger n = self.numerator * r.denominator + r.numerator * self.denominator;
    return [Rational rationalWithNumerator:n denominator:d];
}

- (Rational *)multiply:(Rational *)r
{
    NSUInteger d = self.denominator * r.denominator;
    NSInteger n = self.numerator * r.numerator;
    return [Rational rationalWithNumerator:n denominator:d];
}

- (Rational *)subtract:(Rational *)r
{
    return [self add:r.negation];
}

- (Rational *)reciprocal
{
    return [Rational rationalWithNumerator:self.denominator denominator:self.numerator];
}

- (Rational *)divideBy:(Rational *)r
{
    return [self multiply:r.reciprocal];
}

- (BOOL) isReduced
{
    return (_gcd == 1 && _denominator > 0);
}

- (Rational *)reduced
{
    if (self.isReduced) {
        return self;
    } else if (_gcd == 0) {
        return [Rational zero];
    }
    // In C dividing an signed int by an unsigned will cause both to become unsigned!!, so cast to signed first.
    NSInteger numerator = self.numerator/(NSInteger) _gcd;
    NSInteger denominator = self.denominator / (NSInteger) _gcd;
    if (denominator < 0) {
        denominator = -denominator;
        numerator = -numerator;
    }
    return [Rational rationalWithNumerator:numerator denominator:denominator];
}

- (float)floatValue
{
    return (float) _numerator / (float) _denominator;
}

- (BOOL)isInteger
{
    if (self.isReduced) {
        return (self.denominator == 1);
    } else {
        return self.reduced.isInteger;
    }
}

- (long)floor
{
    return self.numerator / self.denominator;
}

- (BOOL)isEqualToRational:(Rational *)r
{
    return (self.denominator == r.denominator && self.numerator == r.numerator);
}

- (BOOL) isEqual:(id) anObject
{
    if (self == anObject) {
        return YES;
    }
    if (!anObject || ![anObject isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToRational:anObject];
}

- (NSUInteger) hash
{
    const int prime = 31;
    return prime * self.denominator + self.numerator;
}

- (NSString *)description
{
    if (_format == kRationalFormatWhole || _denominator == 1) {
        return [NSString stringWithFormat:@"%ld", (long)self.numerator];
    } else if (_format == kRationalFormatDecimal) {
        // write it in decimal format.
        NSUInteger absNumerator = ABS(self.numerator);
        NSUInteger integerVal = absNumerator/self.denominator;
        NSUInteger decimalVal =  absNumerator - self.denominator*integerVal;
        NSString* sign = (self.numerator < 0) ? @"-" : @"";
        return [NSString stringWithFormat:@"%@%lu.%lu", sign, (unsigned long)integerVal, (unsigned long)decimalVal];
    } else {
        return [NSString stringWithFormat:@"%ld/%ld", (long)self.numerator, (long)self.denominator];
    }
}

- (BOOL)isEquivalent:(Rational *)r
{
    if ([self.reduced isEqualToRational:r.reduced]) {
        return YES;
    } else if (lroundf(self.floatValue * 100) ==  lroundf(r.floatValue*100)) {
        // Decimal expansions are close, then these are equivalent
        return YES;
    }
    return NO;
}

- (NSComparisonResult) compare:(Rational *)aNumber
{
    Rational* r = [self subtract:aNumber];
    if (r.numerator > 0) {
        return NSOrderedDescending;
    } else if (r.numerator < 0) {
        return NSOrderedAscending;
    } else {
        assert(r.numerator == 0);
        return NSOrderedSame;
    }
}

- (BOOL) isNegative
{
    return (self.numerator < 0);
}

- (BOOL) isPositive
{
    return self.numerator > 0;
}

- (BOOL) isZero
{
    return self.numerator == 0;
}

- (Rational *)absoluteValue
{
    return (self.isNegative) ? self.negation : self;
}

- (BOOL)isGreaterThan:(Rational *)r
{
    return ([self compare:r] == NSOrderedDescending);
}

- (BOOL) isLessThan:(Rational *)r
{
    return ([self compare:r] == NSOrderedAscending);
}

@end
