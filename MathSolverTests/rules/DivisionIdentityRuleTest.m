//
//  DivisionIdentityRuleTest.m
//
//  Created by Kostub Deshmukh on 7/17/14.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>

#import "MTDivisionIdentityRule.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTMathListBuilder.h"

@interface DivisionIdentityRuleTest : XCTestCase

@end

@implementation DivisionIdentityRuleTest

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
             @"(5/2)" : @"(5 / 2)",
             @"(5/1)" : @"5",
             @"1/x"  : @"(1 / x)",
             @"(x/1)" : @"x",
             @"(x + 1) / 1" : @"(x + 1)",
             };
    
}

- (void) testRule
{
    MTDivisionIdentityRule* rule = [MTDivisionIdentityRule rule];
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [rule apply:[parser parseToExpressionFromMathList:ml]];
        XCTAssertNotNil(expr, @"Rule returned nil for %@", testExpr);
        XCTAssertEqualObjects(expected, expr.stringValue, @"For %@", testExpr);
    }
}
@end
