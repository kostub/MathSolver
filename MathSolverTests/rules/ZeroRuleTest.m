//
//  ZeroRuleTest.m
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ZeroRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTZeroRule.h"

@implementation ZeroRuleTest {
    MTZeroRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [[MTZeroRule alloc] init];
}


static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x+5*3" : @"(x + (5 * 3))",
             @"x+5*0" : @"(x + 0)",
             @"0x" : @"0",
             @"0*3x" : @"0",
             @"x*((0*3)+5)" : @"(x * (0 + 5))",
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


@end
