//
//  CancelCommonFactorsRuleTest.m
//
//  Created by Kostub Deshmukh on 7/17/14.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>

#import "MTCancelCommonFactorsRule.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTMathListBuilder.h"
#import "MTCanonicalizer.h"

@interface CancelCommonFactorsRuleTest : XCTestCase

@end

@implementation CancelCommonFactorsRuleTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x*5" : @"(x * 5)",
             @"x*5*3" : @"(x * 5 * 3)",
             @"x+5+y" : @"(x + 5 + y)",
             @"5x/5" : @"(x / 1)",
             @"(5x/x)" : @"(5 / 1)",
             @"x/(5x)" : @"(1 / 5)",
             @"2/(2x)" : @"(1 / x)",
             @"5xy/(3x)" : @"((5 * y) / 3)",
             @"6xy/(3xz)" : @"((6 * y) / (3 * z))",
             };
    
}

- (void) testRule
{
    MTCancelCommonFactorsRule* rule = [MTCancelCommonFactorsRule rule];
    MTExpressionCanonicalizer* canonicalizer = [MTCanonicalizerFactory getExpressionCanonicalizer];
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [rule apply:[canonicalizer normalize:[parser parseToExpressionFromMathList:ml]]];
        XCTAssertNotNil(expr, @"Rule returned nil for %@", testExpr);
        XCTAssertEqualObjects(expected, expr.stringValue, @"For %@", testExpr);
    }
}

@end
