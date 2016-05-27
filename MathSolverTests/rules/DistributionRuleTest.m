//
//  DistributionRuleTest.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "DistributionRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTDistributionRule.h"
#import "MTFlattenRule.h"

@implementation DistributionRuleTest {
    MTDistributionRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [[MTDistributionRule alloc] init];
}


static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"5+3+x" : @"((5 + 3) + x)",
             @"x+5*3" : @"(x + (5 * 3))",
             @"5*3x" : @"((5 * 3) * x)",
             @"(x+5)*3" : @"((x * 3) + (5 * 3))",
             @"x*((1+3)+5)" : @"((x * (1 + 3)) + (x * 5))",
             @"x(3+x)" : @"((x * 3) + (x * x))",
             @"5(3+x)" : @"((5 * 3) + (5 * x))",
             @"(x+1)(3+x)" : @"((x * (3 + x)) + (1 * (3 + x)))",
             @"3(1 + x) + 2(x + 2)": @"(((3 * 1) + (3 * x)) + ((2 * x) + (2 * 2)))",
             @"3(1 + 2(1 + x))": @"((3 * 1) + (3 * ((2 * 1) + (2 * x))))"
             };
             
}

static NSDictionary* getTestDataForFlatten() {
    return @{
             @"3*(1+2+3)": @"((3 * 1) + (3 * 2) + (3 * 3))",
             @"(1+2+3)x": @"((1 * x) + (2 * x) + (3 * x))",
             @"3 * (2 + x) * 5": @"((3 * 2 * 5) + (3 * x * 5))",
             @"3(2 + x)(1 + x)": @"((3 * 2 * (1 + x)) + (3 * x * (1 + x)))",
             };
    
}

- (void) testRule
{
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [[MTInfixParser alloc] init];
        MTExpression* expr = [_rule apply:[parser parseFromString:testExpr]];
        XCTAssertNotNil(expr, @"Rule returned nil");
        XCTAssertEqualObjects(expected, expr.stringValue, @"Matching the string representation");
    }
}


- (void)testRuleAfterFlatten
{
    NSDictionary* dict = getTestDataForFlatten();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [[MTInfixParser alloc] init];
        MTFlattenRule *flatten = [[MTFlattenRule alloc] init];
        MTExpression* expr = [_rule apply:[flatten apply:[parser parseFromString:testExpr]]];
        XCTAssertNotNil(expr, @"Rule returned nil");
        XCTAssertEqualObjects(expected, expr.stringValue, @"Matching the string representation");
    }
}

@end
