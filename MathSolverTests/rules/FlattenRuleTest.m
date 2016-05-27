//
//  FlattenRuleTest.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "FlattenRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTFlattenRule.h"

@implementation FlattenRuleTest {
    MTFlattenRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [[MTFlattenRule alloc] init];
}


static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"x+5+3" : @"(x + 5 + 3)",
             @"x+5*3" : @"(x + (5 * 3))",
             @"5x*3" : @"(5 * x * 3)",
             @"x*((1+3)+5)" : @"(x * (1 + 3 + 5))",
             @"(x+3)+(x+4+5)" : @"(x + 3 + x + 4 + 5)",
             @"5/3/4" : @"((5 / 3) / 4)",    // division doesn't flatten
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
