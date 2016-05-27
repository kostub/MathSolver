//
//  RationalTest.m
//
//  Created by Kostub Deshmukh on 9/6/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>

#import "MTRational.h"

@interface RationalTest : XCTestCase

@end

@implementation RationalTest

- (void) testCreate
{
    MTRational* r = [MTRational rationalWithNumerator:5 denominator:3];
    XCTAssertEqual(r.numerator, 5, @"");
    XCTAssertEqual(r.denominator, 3u, @"");
    
    r = [MTRational rationalWithNumerator:-5 denominator:3];
    XCTAssertEqual(r.numerator, -5, @"");
    XCTAssertEqual(r.denominator, 3u, @"");
    
    r = [MTRational rationalWithNumerator:5 denominator:-3];
    XCTAssertEqual(r.numerator, 5, @"");
    XCTAssertEqual(r.denominator, -3, @"");

    r = [MTRational rationalWithNumerator:0 denominator:3];
    XCTAssertEqual(r.numerator, 0, @"");
    XCTAssertEqual(r.denominator, 3u, @"");
    
    r = [MTRational rationalWithNumerator:5 denominator:0];
    XCTAssertNil(r, @"");
}

- (void) testNegation
{
    MTRational* r = [MTRational rationalWithNumerator:5 denominator:3];
    MTRational* rneg = r.negation;
    XCTAssertEqual(rneg.numerator, -5, @"");
    XCTAssertEqual(rneg.denominator, 3u, @"");
    
    MTRational* rnegneg = rneg.negation;
    XCTAssertEqualObjects(r, rnegneg, @"");
}

- (void) testReciprocal
{
    {
        MTRational* r = [MTRational rationalWithNumerator:5 denominator:3];
        MTRational* rrec = r.reciprocal;
        XCTAssertEqual(rrec.numerator, 3, @"");
        XCTAssertEqual(rrec.denominator, 5u, @"");
        
        MTRational* rrecrec = rrec.reciprocal;
        XCTAssertEqualObjects(r, rrecrec, @"");
    }
    
    {
        // Test that it preserves the -ve
        MTRational* r = [MTRational rationalWithNumerator:-5 denominator:3];
        MTRational* rrec = r.reciprocal;
        XCTAssertEqual(rrec.numerator, 3, @"");
        XCTAssertEqual(rrec.denominator, -5, @"");
        
        MTRational* rrecrec = rrec.reciprocal;
        XCTAssertEqualObjects(r, rrecrec, @"");
    }
}

- (void) testAdd
{
    {
        MTRational* p = [MTRational rationalWithNumerator:5 denominator:3];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:3];
        MTRational* added = [p add:q];
        XCTAssertEqual(added.numerator, 10, @"");
        XCTAssertEqual(added.denominator, 3u, @"");
        MTRational* commute = [q add:p];
        XCTAssertEqualObjects(added, commute, @"");
    }
    
    {
        // different denominators
        MTRational* p = [MTRational rationalWithNumerator:3 denominator:2];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:3];
        MTRational* added = [p add:q];
        XCTAssertEqual(added.numerator, 19, @"");
        XCTAssertEqual(added.denominator, 6u, @"");
        MTRational* commute = [q add:p];
        XCTAssertEqualObjects(added, commute, @"");
    }
    
    {
        // negative rationals
        MTRational* p = [MTRational rationalWithNumerator:-1 denominator:2];
        MTRational* q = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* added = [p add:q];
        XCTAssertEqual(added.numerator, 1, @"");
        XCTAssertEqual(added.denominator, 6u, @"");
        MTRational* commute = [q add:p];
        XCTAssertEqualObjects(added, commute, @"");
    }
}

- (void) testSubtract
{
    {
        MTRational* p = [MTRational rationalWithNumerator:5 denominator:3];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:3];
        MTRational* added = [p subtract:q];
        XCTAssertEqual(added.numerator, 0, @"");
        XCTAssertEqual(added.denominator, 3u, @"");
    }
    
    {
        // different denominators
        MTRational* p = [MTRational rationalWithNumerator:3 denominator:2];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:3];
        MTRational* added = [p subtract:q];
        XCTAssertEqual(added.numerator, -1, @"");
        XCTAssertEqual(added.denominator, 6u, @"");
    }
    
    {
        // negative rationals
        MTRational* p = [MTRational rationalWithNumerator:1 denominator:2];
        MTRational* q = [MTRational rationalWithNumerator:-2 denominator:3];
        MTRational* added = [p subtract:q];
        XCTAssertEqual(added.numerator, 7, @"");
        XCTAssertEqual(added.denominator, 6u, @"");
    }
}

- (void) testMultiply
{
    {
        MTRational* p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:2];
        MTRational* mult = [p multiply:q];
        XCTAssertEqual(mult.numerator, 10, @"");
        XCTAssertEqual(mult.denominator, 6u, @"");
        MTRational* commute = [q multiply:p];
        XCTAssertEqualObjects(mult, commute, @"");
    }

    {
        // negative rationals
        MTRational* p = [MTRational rationalWithNumerator:-1 denominator:2];
        MTRational* q = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* mult = [p multiply:q];
        XCTAssertEqual(mult.numerator, -2, @"");
        XCTAssertEqual(mult.denominator, 6u, @"");
        MTRational* commute = [q multiply:p];
        XCTAssertEqualObjects(mult, commute, @"");
    }
}

- (void) testDivideBy
{
    {
        MTRational* p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:2];
        MTRational* mult = [p divideBy:q];
        XCTAssertEqual(mult.numerator, 4, @"");
        XCTAssertEqual(mult.denominator, 15u, @"");
    }
    
    {
        // negative rationals
        MTRational* p = [MTRational rationalWithNumerator:-1 denominator:2];
        MTRational* q = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* mult = [p divideBy:q];
        XCTAssertEqual(mult.numerator, -3, @"");
        XCTAssertEqual(mult.denominator, 4u, @"");
    }
}

- (void) testReduced
{
    {
        // already reduced
        MTRational *p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertEqualObjects(p, reduced, @"");
    }
    {
        // negative
        MTRational *p = [MTRational rationalWithNumerator:-2 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertEqualObjects(p, reduced, @"");        
    }
    {
        // negative denominator
        MTRational *p = [MTRational rationalWithNumerator:2 denominator:-3];
        MTRational *reduced = p.reduced;
        XCTAssertEqual(reduced.numerator, -2, @"");
        XCTAssertEqual(reduced.denominator, 3, @"");
    }
    {
        // zero
        MTRational *p = [MTRational rationalWithNumerator:0 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertEqual(reduced.numerator, 0, @"");
        XCTAssertEqual(reduced.denominator, 1u, @"");
    }
    
    {
        // unreduced
        MTRational *p = [MTRational rationalWithNumerator:9 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertEqual(reduced.numerator, 3, @"");
        XCTAssertEqual(reduced.denominator, 1u, @"");
    }
    
    {
        // unreduced -ve
        MTRational *p = [MTRational rationalWithNumerator:-10 denominator:20];
        MTRational *reduced = p.reduced;
        XCTAssertEqual(reduced.numerator, -1, @"");
        XCTAssertEqual(reduced.denominator, 2u, @"");
    }
    
    {
        // unreduced -ve denominator
        MTRational *p = [MTRational rationalWithNumerator:10 denominator:-20];
        MTRational *reduced = p.reduced;
        XCTAssertEqual(reduced.numerator, -1, @"");
        XCTAssertEqual(reduced.denominator, 2u, @"");
    }
}

- (void) testEquivalence
{
    {
        // already reduced
        MTRational *p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertTrue([p isEquivalent:reduced], @"");
        XCTAssertTrue([reduced isEquivalent:p], @"");
    }
    {
        // negative
        MTRational *p = [MTRational rationalWithNumerator:-2 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertTrue([p isEquivalent:reduced], @"");
        XCTAssertTrue([reduced isEquivalent:p], @"");
    }
    {
        // negative denominator
        MTRational *p = [MTRational rationalWithNumerator:2 denominator:-3];
        MTRational *reduced = p.reduced;
        XCTAssertTrue([p isEquivalent:reduced], @"");
        XCTAssertTrue([reduced isEquivalent:p], @"");
    }
    {
        // zero
        MTRational *p = [MTRational rationalWithNumerator:0 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertTrue([p isEquivalent:reduced], @"");
        XCTAssertTrue([reduced isEquivalent:p], @"");
    }
    
    {
        // unreduced
        MTRational *p = [MTRational rationalWithNumerator:9 denominator:3];
        MTRational *reduced = p.reduced;
        XCTAssertTrue([p isEquivalent:reduced], @"");
        XCTAssertTrue([reduced isEquivalent:p], @"");
    }
    
    {
        // unreduced -ve
        MTRational *p = [MTRational rationalWithNumerator:-10 denominator:20];
        MTRational *reduced = p.reduced;
        XCTAssertTrue([p isEquivalent:reduced], @"");
        XCTAssertTrue([reduced isEquivalent:p], @"");
    }
    
    {
        // unreduced
        MTRational *p = [MTRational rationalWithNumerator:6 denominator:8];
        MTRational *q = [MTRational rationalWithNumerator:15 denominator:20];
        XCTAssertTrue([p isEquivalent:q], @"");
        XCTAssertTrue([q isEquivalent:p], @"");
    }
    
    {
        // decimals
        MTRational *p = [MTRational rationalWithNumerator:1 denominator:3];
        MTRational *q = [MTRational rationalFromDecimalRepresentation:@"0.33"];
        XCTAssertTrue([p isEquivalent:q], @"");
        XCTAssertTrue([q isEquivalent:p], @"");
    }
    {
        // decimals
        MTRational *p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational *q = [MTRational rationalFromDecimalRepresentation:@"0.67"];
        XCTAssertTrue([p isEquivalent:q], @"");
        XCTAssertTrue([q isEquivalent:p], @"");
    }
    {
        // decimals
        MTRational *p = [MTRational rationalFromDecimalRepresentation:@"0.103"]; // 0.103
        MTRational *q = [MTRational rationalFromDecimalRepresentation:@"0.104"]; // 0.104
        XCTAssertTrue([p isEquivalent:q], @"");
        XCTAssertTrue([q isEquivalent:p], @"");
    }
    {
        // These round differently
        MTRational *p = [MTRational rationalFromDecimalRepresentation:@"0.106"]; // 0.106
        MTRational *q = [MTRational rationalFromDecimalRepresentation:@"0.104"]; // 0.104
        XCTAssertFalse([p isEquivalent:q], @"");
        XCTAssertFalse([q isEquivalent:p], @"");
    }
}

- (void) testCompare
{
    {
        MTRational* p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:3];
        XCTAssertEqual([p compare:q], NSOrderedAscending, @"");
        XCTAssertEqual([q compare:p], NSOrderedDescending, @"");
    }
    
    {
        // different denominators
        MTRational* p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* q = [MTRational rationalWithNumerator:5 denominator:7];
        XCTAssertEqual([p compare:q], NSOrderedAscending, @"");
        XCTAssertEqual([q compare:p], NSOrderedDescending, @"");
    }
    
    {
        // same
        MTRational* p = [MTRational rationalWithNumerator:2 denominator:3];
        MTRational* q = [MTRational rationalWithNumerator:8 denominator:12];
        XCTAssertEqual([p compare:q], NSOrderedSame, @"");
        XCTAssertEqual([q compare:p], NSOrderedSame, @"");
    }    
}

- (void) testParseCorrectly
{
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@"5"];
        MTRational* expected = [MTRational rationalWithNumber:5];
        XCTAssertEqualObjects(testCase, expected, @"");
    }
    
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@"5."];
        MTRational* expected = [MTRational rationalWithNumerator:50 denominator:10];
        XCTAssertEqualObjects(testCase, expected, @"");
    }
    
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@"5.1"];
        MTRational* expected = [MTRational rationalWithNumerator:51 denominator:10];
        XCTAssertEqualObjects(testCase, expected, @"");
    }
    
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@"25.144"];
        MTRational* expected = [MTRational rationalWithNumerator:25144 denominator:1000];
        XCTAssertEqualObjects(testCase, expected, @"");
    }
    
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@"0.14"];
        MTRational* expected = [MTRational rationalWithNumerator:14 denominator:100];
        XCTAssertEqualObjects(testCase, expected, @"");
    }
    
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@".14"];
        MTRational* expected = [MTRational rationalWithNumerator:14 denominator:100];
        XCTAssertEqualObjects(testCase, expected, @"");
    }

}

- (void) testParseFail
{
    NSArray* testCases = @[@"-5", @"-5.", @"-5.1", @"-0.14", @"-.14", @"", @" ", @" 5", @"5 ", @"5,3", @"5 3", @"5.-3", @"a", @"5.a", @"5.3a", @"5.3 ", @"5. 3"];
    for (NSString* str in testCases) {
        MTRational* r = [MTRational rationalFromDecimalRepresentation:str];
        XCTAssertNil(r, @"%@", str);
    }
}

- (void) testPrint
{
    {
        MTRational* testCase = [MTRational rationalWithNumerator:2 denominator:3];
        XCTAssertEqualObjects(testCase.description, @"2/3", @"");
    }
    {
        MTRational* testCase = [MTRational rationalWithNumerator:2 denominator:3];
        XCTAssertEqualObjects(testCase.negation.description, @"-2/3", @"");
    }
    {
        MTRational* testCase = [MTRational rationalWithNumerator:-2 denominator:3];
        XCTAssertEqualObjects(testCase.description, @"-2/3", @"");
    }
    {
        MTRational* testCase = [MTRational rationalWithNumber:5];
        XCTAssertEqualObjects(testCase.description, @"5", @"");
    }
    {
        MTRational* testCase = [MTRational rationalWithNumber:-5];
        XCTAssertEqualObjects(testCase.description, @"-5", @"");
    }
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@"4.2"];
        XCTAssertEqualObjects(testCase.description, @"4.2", @"");
    }
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@".2"];
        XCTAssertEqualObjects(testCase.description, @"0.2", @"");
    }
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@"4.2"];
        XCTAssertEqualObjects(testCase.negation.description, @"-4.2", @"");
    }
    {
        MTRational* testCase = [MTRational rationalFromDecimalRepresentation:@".2"];
        XCTAssertEqualObjects(testCase.negation.description, @"-0.2", @"");
    }
    {
        MTRational* testCase = [MTRational rationalWithNumerator:6 denominator:3];
        XCTAssertEqualObjects(testCase.description, @"6/3", @"");
    }
}
@end
