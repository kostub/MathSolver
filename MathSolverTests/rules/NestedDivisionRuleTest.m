//
//  NestedDivisionRuleTest.m
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>

#import "MTNestedDivisionRule.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTMathListBuilder.h"


@interface NestedDivisionRuleTest : XCTestCase

@end

@implementation NestedDivisionRuleTest {
    MTNestedDivisionRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [MTNestedDivisionRule rule];
}

static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x*5" : @"(x * 5)",
             @"(5/2)/6" : @"(5 / (2 * 6))",
             @"(x/3)/x" : @"(x / (3 * x))",
             @"\\frac{3}{5}/2" : @"(3/5 / 2)",
             @"\\frac{3}{5}/2/5" : @"(3/5 / (2 * 5))",
             @"5/(2/6)" : @"((5 * 6) / 2)",
             @"x/(3/x)" : @"((x * x) / 3)",
             @"2/\\frac{3}{5}" : @"(2 / 3/5)",
             @"\\frac{3}{5}/(2/5)" : @"((3/5 * 5) / 2)",
             // double
             @"(5/2)/(6/4)" : @"(5 / (2 * (6 / 4)))",
             @"(x/3)/(x/2)" : @"(x / (3 * (x / 2)))",
             @"\\frac{3}{5}/\\frac{2}{3}" : @"(3/5 / 2/3)",
             @"\\frac{3}{5}/2/(5/4)" : @"(3/5 / (2 * (5 / 4)))",
             };
    
}

- (void) testRule
{
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [_rule apply:[parser parseToExpressionFromMathList:ml]];
        XCTAssertNotNil(expr, @"Rule returned nil for %@", testExpr);
        XCTAssertEqualObjects(expected, expr.stringValue, @"For %@", testExpr);
    }
}


@end
