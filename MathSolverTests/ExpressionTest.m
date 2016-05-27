//
//  ExpressionTest.m
//
//  Created by Kostub Deshmukh on 7/21/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//
#import <XCTest/XCTest.h>

#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTFlattenRule.h"
#import "MTMathList.h"
#import "MTMathListBuilder.h"

@interface ExpressionTest : XCTestCase

@end

@implementation ExpressionTest {
    MTFlattenRule* _flatten;
}

- (void) setUp
{
    [super setUp];
    _flatten = [MTFlattenRule rule];
}

- (MTExpression*) parseExpression:(NSString*) expr {
    MTInfixParser *parser = [MTInfixParser new];
    MTMathList* ml = [MTMathListBuilder buildFromString:expr];
    return [_flatten apply:[parser parseToExpressionFromMathList:ml]];
}

static NSDictionary* getTestData() {
    return @{
             @"5" : @0,
             @"x" : @1,
             @"4*2" : @0,
             @"5x" : @1,
             @"5xy": @2,
             @"5xx" : @2,
             @"1 + 3" : @0,
             @"1 + x" : @1,
             @"1 + x + y" : @1,
             @"1 + x + xy" : @2,
             @"(1 + x)x" : @2,
             @"2(1 + x)" : @1,
             @"2x(1 + x) + 3xy(1+xy(1+z))" : @5,
             };
    
}

- (void)testDegree
{
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSNumber* expected = [dict valueForKey:testExpr];
        MTExpression* expr = [self parseExpression:testExpr];
        NSNumber *degree = @(expr.degree);
        XCTAssertEqualObjects(degree, expected, @"For expression %@", testExpr);
    }
}

static NSArray* getTestDataForRearrangement() {
    return @[
             @[@"x + y", @"y + x", @YES],
             @[@"5x", @"x*5", @YES],
             @[@"x", @"x", @YES],
             @[@"x+y+z", @"z+x+y", @YES],
             @[@"5", @"5", @YES],
             @[@"x(a+b)", @"(a+b)x", @YES],
             @[@"x(a+b)", @"(b+a)x", @NO],  // doesn't recurse
             @[@"x + x", @"x", @NO],  // each x is accounted for separately
             @[@"5x + x", @"x", @NO],
             @[@"x + y", @"x + y + z", @NO], // extra term
             ];
}

- (void) testEqualsUptoRearragement
{
    NSArray* testData = getTestDataForRearrangement();
    for (NSArray* testCase in testData) {
        MTExpression* expr1 = [self parseExpression:testCase[0]];
        MTExpression* expr2 = [self parseExpression:testCase[1]];
        BOOL equals = [expr1 isEqualUptoRearrangement:expr2];
        NSString* desc = [NSString stringWithFormat:@"Error for expr1:%@ expr2:%@", testCase[0], testCase[1]];
        XCTAssertEqualObjects([NSNumber numberWithBool:equals], testCase[2], @"%@", desc);
        BOOL equals2 = [expr2 isEqualUptoRearrangement:expr1];
        XCTAssertEqualObjects([NSNumber numberWithBool:equals2], testCase[2], @"%@", desc);
    }
}

static NSArray* getTestDataForRearrangementRecursive() {
    return @[
             @[@"x + y", @"y + x", @YES],
             @[@"5x", @"x*5", @YES],
             @[@"x", @"x", @YES],
             @[@"x+y+z", @"z+x+y", @YES],
             @[@"5", @"5", @YES],
             @[@"x(a+b)", @"(a+b)x", @YES],
             @[@"x(a+b)", @"(b+a)x", @YES],
             @[@"(x+x)(a+b)", @"(b+a)x", @NO],
             @[@"x + x", @"x", @NO],  // each x is accounted for separately
             @[@"5x + x", @"x", @NO],
             @[@"x + y", @"x + y + z", @NO], // extra term
             ];
}

- (void) testEqualsUptoRearragementRecursive
{
    NSArray* testData = getTestDataForRearrangementRecursive();
    for (NSArray* testCase in testData) {
        MTExpression* expr1 = [self parseExpression:testCase[0]];
        MTExpression* expr2 = [self parseExpression:testCase[1]];
        BOOL equals = [expr1 isEqualUptoRearrangementRecursive:expr2];
        NSString* desc = [NSString stringWithFormat:@"Error for expr1:%@ expr2:%@", testCase[0], testCase[1]];
        XCTAssertEqualObjects([NSNumber numberWithBool:equals], testCase[2], @"%@", desc);
        BOOL equals2 = [expr2 isEqualUptoRearrangementRecursive:expr1];
        XCTAssertEqualObjects([NSNumber numberWithBool:equals2], testCase[2], @"%@", desc);
    }
}

static NSArray* getTestDataForEquivalence() {
    return @[
             @[@"5", @"y", @NO],
             @[@"5x", @"x", @NO ],
             @[@"\\frac{1}{3}", @"0.33", @YES],
             @[@"\\frac{1}{3}x", @"0.33x", @YES],
             @[@"5x", @"5y", @NO],
             @[@"5x", @"x*5", @NO],
             @[@"x(0.101+b)", @"x(0.102+b)", @YES],
             @[@"x + y", @"x + y + z", @NO], // extra term
             ];
}

- (void) testEquivalence
{
    NSArray* testData = getTestDataForEquivalence();
    for (NSArray* testCase in testData) {
        MTExpression* expr1 = [self parseExpression:testCase[0]];
        MTExpression* expr2 = [self parseExpression:testCase[1]];
        BOOL equiv = [expr1 isEquivalent:expr2];
        NSString* desc = [NSString stringWithFormat:@"Error for expr1:%@ expr2:%@", testCase[0], testCase[1]];
        XCTAssertEqualObjects([NSNumber numberWithBool:equiv], testCase[2], @"%@", desc);
        BOOL equiv2 = [expr2 isEquivalent:expr1];
        XCTAssertEqualObjects([NSNumber numberWithBool:equiv2], testCase[2], @"%@", desc);
    }
}
@end
