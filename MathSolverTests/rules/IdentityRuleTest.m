//
//  IdentityRuleTest.m
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "IdentityRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTIdentityRule.h"
#import "MTFlattenRule.h"

@implementation IdentityRuleTest {
    MTIdentityRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [[MTIdentityRule alloc] init];
}


static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x+0" : @"x",
             @"0+x" : @"x",
             @"0+3+x" : @"(3 + x)",
             @"x+3+0" : @"(x + 3)",
             @"x+5*3" : @"(x + (5 * 3))",
             @"1x" : @"x",
             @"1*3x" : @"(3 * x)",
             @"x*((0+3)+5)" : @"(x * (3 + 5))",
             };
    
}

static NSDictionary* getTestDataForFlatten() {
    return @{
             @"3*(1+0+3)": @"(3 * (1 + 3))",
             @"(1*2*3) + x": @"((2 * 3) + x)",
             };
    
}

- (void) testRule
{
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [MTInfixParser new];
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
        MTInfixParser *parser = [MTInfixParser new];
        MTFlattenRule *flatten = [[MTFlattenRule alloc] init];
        MTExpression* expr = [_rule apply:[flatten apply:[parser parseFromString:testExpr]]];
        XCTAssertNotNil(expr, @"Rule returned nil");
        XCTAssertEqualObjects(expected, expr.stringValue, @"Matching the string representation");
    }
}

@end
