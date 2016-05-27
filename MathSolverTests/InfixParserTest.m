//
//  InfixParserTest.m
//
//  Created by Kostub Deshmukh on 7/15/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "InfixParserTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTMathListBuilder.h"

@implementation InfixParserTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x+5+3" : @"((x + 5) + 3)",
             @"x+5*3" : @"(x + (5 * 3))",
             @"5x" : @"(5 * x)",
             @"5x*3" : @"((5 * x) * 3)",
             @"(x+5)" : @"(x + 5)",
             @"(x+5)*3" : @"((x + 5) * 3)",
             @"x*((1/3)+5)" : @"(x * ((1 / 3) + 5))",
             @"x(3+x)" : @"(x * (3 + x))",
             @"5(3+x)" : @"(5 * (3 + x))",
             @"(x+1)(3+x)" : @"((x + 1) * (3 + x))",
             @"(x+1)3" : @"((x + 1) * 3)",
             @"(x+1)x" : @"((x + 1) * x)",
             @"3xx" : @"((3 * x) * x)",
             @"5xy" : @"((5 * x) * y)",
             @"x-3" : @"(x - 3)",
             @"x-3+x" : @"((x - 3) + x)",
             @"x-3x" : @"(x - (3 * x))",
             @"-3" : @"-3",
             @"-x" : @"(_ x)",
             @"-3 + x" : @"(-3 + x)",
             @"-3x" : @"(-3 * x)",
             @"x + (-3)" : @"(x + -3)",
             @"x * -3" : @"(x * -3)",
             @"-(x+3)" : @"(_ (x + 3))",
             @"(5x - 3)/(2y + 1) - (-3x - 3)(1-(-2z))" : @"((((5 * x) - 3) / ((2 * y) + 1)) - (((-3 * x) - 3) * (1 - (-2 * z))))",
             @"3x/0" : @"((3 * x) / 0)",
             };
    
}

static NSDictionary* getTestData2() {
    return @{
             @"\\frac{1}{2}": @"1/2",
             @"x+\\frac{1}{2}": @"(x + 1/2)",
             @"x+\\frac{1}{2}+3": @"((x + 1/2) + 3)",
             @"x+\\frac{1}{2}*3": @"(x + (1/2 * 3))",
             @"\\frac{1}{2}x": @"(1/2 * x)",
             @"\\frac{1}{2}x + \\frac{2}{3}": @"((1/2 * x) + 2/3)",
             @"-\\frac{1}{2}": @"-1/2",
             @"\\frac{-1}{2}": @"-1/2",
             @"\\frac{1}{-2}": @"1/-2",
             @"(x)\\frac{1}{2}": @"(x * 1/2)",
             @"\\frac{1}{2}(3)": @"(1/2 * 3)",
             @"0.2": @"0.2",
             @"x+0.2": @"(x + 0.2)",
             @"x+0.2+3": @"((x + 0.2) + 3)",
             @"x+0.2*3": @"(x + (0.2 * 3))",
             @"0.2x": @"(0.2 * x)",
             @"0.2x + 0.5": @"((0.2 * x) + 0.5)",
             @"-0.2": @"-0.2",
             @"(x)0.2": @"(x * 0.2)",
             @"0.5(3)" : @"(0.5 * 3)",
             @"\\frac{5x}{2}" : @"((5 * x) / 2)",
             @"\\frac{5x}{2}-\\frac{2}{3}" : @"(((5 * x) / 2) - 2/3)",
             @"\\frac{2}{3} - \\frac{5x}{2}" : @"(2/3 - ((5 * x) / 2))",
             @"5." : @"5.0",
             @"2 \\frac{1}{2}" : @"5/2",
             @"\\frac{3x}{0}" : @"((3 * x) / 0)",
             @"3x \\div 0" : @"((3 * x) / 0)",
             };
}

- (void) testParseExpressionFromString
{
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTExpression* expr = [parser parseFromString:testExpr];
        XCTAssertNotNil(expr, @"%@", desc);
        XCTAssertFalse(parser.hasError, @"Expr: %@ Error:%@ ", testExpr, parser.error.localizedDescription);
        XCTAssertEqualObjects(expected, expr.stringValue, @"%@", desc);
    }
}

- (void) testParseExpressionFromMathList
{
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [parser parseToExpressionFromMathList:ml];
        XCTAssertNotNil(expr, @"%@", desc);
        XCTAssertFalse(parser.hasError, @"Expr: %@ Error:%@ ", testExpr, parser.error.localizedDescription);
        XCTAssertEqualObjects(expected, expr.stringValue, @"%@", desc);
    }
}

- (void) testParseAdditionalExpressionsFromMathList
{
    NSDictionary* dict = getTestData2();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [parser parseToExpressionFromMathList:ml];
        XCTAssertNotNil(expr, @"%@", desc);
        XCTAssertFalse(parser.hasError, @"Expr: %@ Error:%@ ", testExpr, parser.error.localizedDescription);
        XCTAssertEqualObjects(expected, expr.stringValue, @"%@", desc);
    }
}

// test equations
static NSDictionary* getEquationTests() {
    return @{
             @"x=0": @"x = 0",
             @"x=3": @"x = 3",
             @"5x+2 = \\frac{1}{3}": @"((5 * x) + 2) = 1/3",
             @"2(3y+z) - 0.3x = 2x + \\frac32": @"((2 * ((3 * y) + z)) - (0.3 * x)) = ((2 * x) + 3/2)"
             };
}

- (void) testParseEquations
{
    NSDictionary* dict = getEquationTests();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTEquation* eq = [parser parseToEquationFromMathList:ml];
        XCTAssertNotNil(eq, @"%@", desc);
        XCTAssertFalse(parser.hasError, @"Expr: %@ Error:%@ ", testExpr, parser.error.localizedDescription);
        XCTAssertEqualObjects(expected, eq.stringValue, @"%@", desc);
    }
}

// test failed equations
static NSArray* getFailedExpressionTests() {
    return @[
             @[@"+5", @(MTParserNotEnoughArguments), @0],
             @[@"(5x", @(MTParserMismatchParens), @0],
             @[@"5x)", @(MTParserMismatchParens), @2],
             @[@"x 5", @(MTParserMissingOperator), @1],
             @[@"x = 5", @(MTParserMultipleRelations), @1],
             @[@"\\frac{3}{0}", @(MTParserDivisionByZero), @0],
             @[@"\\frac{\\square}{3}", @(MTParserPlaceholderPresent), @0],
             @[@"5. \\frac{1}{2}", @(MTParserMissingOperator), @2],
             @[@"3 \\frac{\\frac{1}{2}}{3}", @(MTParserMissingOperator), @1],
             @[@"3 \\frac{3}{\\frac{1}{2}}", @(MTParserMissingOperator), @1],
             @[@"\\frac{3}{1} \\frac{1}{2}", @(MTParserMissingOperator), @1],
             @[@"3 \\frac{1}{2} \\frac{1}{2}", @(MTParserMissingOperator), @2],
             @[@"3..5", @(MTParserInvalidNumber), @0],
             @[@"3.5.2", @(MTParserInvalidNumber), @0],
             ];
}

- (void) testFailedExpressions
{
    MTInfixParser *parser = [MTInfixParser new];
    NSArray* array = getFailedExpressionTests();
    for (NSArray* testCase in array) {
        NSString* testExpr = testCase[0];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [parser parseToExpressionFromMathList:ml];
        XCTAssertNil(expr, @"%@", desc);
        XCTAssertTrue(parser.hasError, @"%@", desc);
        NSError* error = parser.error;
        XCTAssertEqual(error.domain, MTParseError, @"%@", desc);
        XCTAssertEqualObjects(@(error.code), testCase[1], @"%@", desc);
        MTMathListIndex* index = [error.userInfo objectForKey:MTParseErrorOffset];
        if (!index) {
            XCTAssertEqualObjects([NSNull null], testCase[2], @"%@", desc);
        } else {
            XCTAssertEqualObjects(@(index.atomIndex), testCase[2], @"%@", desc);
        }
    }
}

// test failed equations
static NSArray* getFailedEquationTests() {
    return @[
             @[ @"5x", @(MTParserEquationExpected), [NSNull null]],
             @[ @"5x = 3y = 2z", @(MTParserMultipleRelations), @5],
             @[ @"\\frac{2=3}{42}", @(MTParserMultipleRelations), @0],
             @[ @"= x + 2", @(MTParserMissingExpression), @0],
             @[ @"x + 2 =", @(MTParserMissingExpression), @3],
             @[ @"x + = 3", @(MTParserNotEnoughArguments), @1],
             @[ @"x = +3", @(MTParserNotEnoughArguments), @2],
             @[ @"x + (3 = 5) * 2", @(MTParserMismatchParens), @2],
             @[ @"x 2 = 3", @(MTParserMissingOperator), @1],
             @[ @"3 = x 2", @(MTParserMissingOperator), @3],
             ];
}
- (void) testFailedEquations
{
    MTInfixParser *parser = [MTInfixParser new];
    NSArray* array = getFailedEquationTests();
    for (NSArray* testCase in array) {
        NSString* testExpr = testCase[0];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTEquation* eq = [parser parseToEquationFromMathList:ml];
        XCTAssertNil(eq, @"%@", desc);
        XCTAssertTrue(parser.hasError, @"%@", desc);
        NSError* error = parser.error;
        XCTAssertEqual(error.domain, MTParseError, @"%@", desc);
        XCTAssertEqualObjects(@(error.code), testCase[1], @"%@", desc);
        MTMathListIndex* index = [error.userInfo objectForKey:MTParseErrorOffset];
        if (!index) {
            XCTAssertEqualObjects([NSNull null], testCase[2], @"%@", desc);
        } else {
            XCTAssertEqualObjects(@(index.atomIndex), testCase[2], @"%@", desc);
        }
    }
}

@end
