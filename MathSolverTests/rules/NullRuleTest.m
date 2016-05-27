//
//  NullRuleTest.m
//
//  Created by Kostub Deshmukh on 7/15/14.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>

#import "MTNullRule.h"
#import "MTExpression.h"
#import "MTInfixParser.h"

@interface NullRuleTest : XCTestCase

@end

@implementation NullRuleTest{
    MTNullRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [MTNullRule rule];
}


static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x+5*3" : @"(x + (5 * 3))",
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

- (void) testRuleWithNull
{
    MTOperator* op = [MTOperator operatorWithType:kMTAddition args:[MTNull null] :[MTVariable variableWithName:'x']];
    MTExpression* expr = [_rule apply:op];
    XCTAssertNotNil(expr, @"Rule returned nil");
    XCTAssertEqualObjects([MTNull null], expr, @"Expected null");
}
@end
