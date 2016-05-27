//
//  RemoveNegativesRuleTest.m
//
//  Created by Kostub Deshmukh on 7/18/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "RemoveNegativesRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTRemoveNegativesRule.h"

@implementation RemoveNegativesRuleTest {
    MTRemoveNegativesRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [[MTRemoveNegativesRule alloc] init];
}

static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x+5+3" : @"((x + 5) + 3)",
             @"x+5*3" : @"(x + (5 * 3))",
             @"5x*3" : @"((5 * x) * 3)",
             @"x*((1/3)+5)" : @"(x * ((1 / 3) + 5))",
             @"x-3" : @"(x + -3)",
             @"3-x" : @"(3 + (-1 * x))",
             @"x-3+x" : @"((x + -3) + x)",
             @"x-3x" : @"(x + (-3 * x))",
             @"-3" : @"-3",
             @"-x" : @"(-1 * x)",
             @"-3 + x" : @"(-3 + x)",
             @"-3x" : @"(-3 * x)",
             @"x + (-3)" : @"(x + -3)",
             @"x * -3" : @"(x * -3)",
             @"-(x+3)" : @"(-1 * (x + 3))",
             @"-xy" : @"((-1 * x) * y)",
             @"-3xy" : @"((-3 * x) * y)",
             @"x - 3xy" : @"(x + ((-3 * x) * y))",
             @"x - xy" : @"(x + (-1 * (x * y)))",
             @"3-(2+x)x" : @"(3 + (-1 * ((2 + x) * x)))",
             @"(5x - 3)/(2x + 1) - (-3x - 3)(1-(-2x))" : @"((((5 * x) + -3) / ((2 * x) + 1)) + (-1 * (((-3 * x) + -3) * (1 + (2 * x)))))",
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


@end
