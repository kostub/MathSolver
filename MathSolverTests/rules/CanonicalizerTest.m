//
//  CanonicalizerTest.m
//
//  Created by Kostub Deshmukh on 9/10/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "CanonicalizerTest.h"
#import "MTCanonicalizer.h"
#import "MTInfixParser.h"
#import "MTMathListBuilder.h"

@implementation CanonicalizerTest

// test expressions
static NSArray* getTestExpressions() {
    return @[
             @[ @"x", @"x", @"x" ],
             @[ @"5", @"5", @"5" ],
             @[ @"\\frac13", @"1/3", @"1/3" ],
             @[ @"\\frac26", @"2/6", @"1/3" ],
             @[ @"5x", @"(5 * x)", @"(5 * x)" ],
             @[ @"x+3", @"(x + 3)", @"(x + 3)" ],
             @[ @"x - 3", @"(x + -3)", @"(x + -3)"],
             @[ @"x+y+4", @"(x + y + 4)", @"(x + y + 4)"],
             @[ @"2(x + 3) - 4(x - \\frac12)", @"((2 * (x + 3)) + (-4 * (x + -1/2)))", @"((-2 * x) + 8)"],
             @[ @"3 / (3+5)", @"(3 / (3 + 5))", @"3/8"],
             @[ @"3x / (3+5)", @"((3 * x) / (3 + 5))", @"(3/8 * x)"],
             @[ @"3 / (5x) + 6", @"((3 / (5 * x)) + 6)", @"(((6 * x) + 3/5) / x)"],
             @[ @"3 / (5 - 5) + 6", @"((3 / (5 + -5)) + 6)", @"(null)"],
             @[ @"3 / (2x - \\frac{x}{2} * 4)", @"(3 / ((2 * x) + (-1 * (x / 2) * 4)))", @"(null)"],
             @[ @"(x/3)/x", @"((x / 3) / x)", @"1/3"],
             @[ @"5/(2/6)", @"(5 / (2 / 6))", @"15"],
             @[ @"x/(3/x)", @"(x / (3 / x))", @"(1/3 * x * x)"],
             @[ @"(5/2)/(6/4)", @"((5 / 2) / (6 / 4))", @"5/3"],
             @[ @"(x/3)/(x/2)", @"((x / 3) / (x / 2))", @"2/3"],
             @[ @"x + 1/x", @"(x + (1 / x))", @"(((x * x) + 1) / x)"],
             @[ @"x + 1/x + 2/y", @"(x + (1 / x) + (2 / y))", @"(((x * x * y) + (2 * x) + y) / (x * y))"],
             @[ @"1/x + 2/x", @"((1 / x) + (2 / x))", @"(3 / x)"],
             @[ @"1/2 * 2", @"((1 / 2) * 2)", @"1"],
             @[ @"x * (3/2) * (y/3)", @"(x * (3 / 2) * (y / 3))", @"(1/2 * x * y)"],
             @[ @"((x/3) + x)/(2(x+1)) + 2x/(x+1) + (1/y)/(1 + 1/y)",
                @"((((x / 3) + x) / (2 * (x + 1))) + ((2 * x) / (x + 1)) + ((1 / y) / (1 + (1 / y))))",
                @"(((8/3 * x * y) + (11/3 * x) + 1) / ((x * y) + x + y + 1))"],
             @[ @"1/(-x)", @"(1 / (-1 * x))", @"(-1 / x)"],
             ];
}

- (void) testExpressionCanonicalizer
{
    MTInfixParser *parser = [MTInfixParser new];
    MTExpressionCanonicalizer* canonicalizer = [MTCanonicalizerFactory getExpressionCanonicalizer];
    NSArray* array = getTestExpressions();
    for (NSArray* testCase in array) {
        NSString* testExpr = testCase[0];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [parser parseToExpressionFromMathList:ml];
        
        // normalize
        MTExpression* normalized = [canonicalizer normalize:expr];
        MTExpression* normalForm = [canonicalizer normalForm:normalized];
        XCTAssertEqualObjects(normalized.stringValue, testCase[1], @"%@", desc);
        XCTAssertEqualObjects(normalForm.stringValue, testCase[2], @"%@", desc);
    }
}

// test expressions
static NSArray* getTestEquations() {
    return @[
             @[ @"x = 0", @"x = 0", @"x = 0" ],
             @[ @"x = 3", @"x = 3", @"(x + -3) = 0" ],
             @[ @"5x - 3 = 4x - 1", @"((5 * x) + -3) = ((4 * x) + -1)", @"(x + -2) = 0"],
             @[ @"3x = 0", @"(3 * x) = 0", @"x = 0" ],
             @[ @"3x + 5 = 2", @"((3 * x) + 5) = 2", @"(x + 1) = 0"],
             @[ @"3x - 5 = x - 1", @"((3 * x) + -5) = (x + -1)", @"(x + -2) = 0"],
             @[ @"(x + 3)(2x - 1) = 2x - 5", @"((x + 3) * ((2 * x) + -1)) = ((2 * x) + -5)", @"((x * x) + (3/2 * x) + 1) = 0"],
             @[ @"x(3y + 2z) = 3", @"(x * ((3 * y) + (2 * z))) = 3", @"((x * y) + (2/3 * x * z) + -1) = 0"],
             @[ @"3 = 2", @"3 = 2", @"1 = 0" ],
             @[ @"x/0 + 2 = 1", @"((x / 0) + 2) = 1", @"(null) = 0"],
             @[ @"x + 1/x = 2", @"(x + (1 / x)) = 2", @"((x * x) + (-2 * x) + 1) = 0"],
             @[ @"(5x + 8(x+1))/(2x + 3) = 9", @"(((5 * x) + (8 * (x + 1))) / ((2 * x) + 3)) = 9", @"(x + 19/5) = 0" ],
             ];
}
- (void) testEquationCanonicalizer
{
    MTInfixParser *parser = [MTInfixParser new];
    MTEquationCanonicalizer* canonicalizer = [MTCanonicalizerFactory getEquationCanonicalizer];
    NSArray* array = getTestEquations();
    for (NSArray* testCase in array) {
        NSString* testExpr = testCase[0];
        NSString* desc = [NSString stringWithFormat:@"Error for %@", testExpr];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTEquation* eq = [parser parseToEquationFromMathList:ml];
        XCTAssertNotNil(eq, @"%@", desc);
        
        // normalize
        MTEquation* normalized = [canonicalizer normalize:eq];
        MTEquation* normalForm = [canonicalizer normalForm:normalized];
        XCTAssertEqualObjects(normalized.stringValue, testCase[1], @"%@", desc);
        XCTAssertEqualObjects(normalForm.stringValue, testCase[2], @"%@", desc);
    }
}
@end
