//
//  ReorderTermsRuleTest.m
//
//  Created by Kostub Deshmukh on 7/21/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ReorderTermsRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTFlattenRule.h"
#import "MTReorderTermsRule.h"

@implementation ReorderTermsRuleTest

static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"5+x" : @"(x + 5)",
             @"3 + x + 2" : @"(x + 2 + 3)",
             @"3 + 2*3" : @"(3 + (2 * 3))",
             @"2*3 + 3" : @"(3 + (2 * 3))",
             @"x + 3 + 2*3" : @"(x + 3 + (2 * 3))",
             @"2*3 + 3 + x" : @"(x + 3 + (2 * 3))",
             @"3x" : @"(3 * x)",
             @"x*3" : @"(3 * x)",
             @"x + y" : @"(x + y)",
             @"y + x" : @"(x + y)",
             @"1 + y + x": @"(x + y + 1)",
             @"x + 2y" : @"(x + (2 * y))",
             @"2y + x" : @"(x + (2 * y))",
             @"2x + y" : @"((2 * x) + y)",
             @"y + 2x" : @"((2 * x) + y)",
             @"y + (x*3)" : @"((3 * x) + y)",
             @"5xy" : @"(5 * x * y)",
             @"5yx" : @"(5 * x * y)",
             @"yx*5" : @"(5 * x * y)",
             @"5xx" : @"(5 * x * x)",
             @"1 + 2y + 3x" : @"((3 * x) + (2 * y) + 1)",
             @"3x + 1 + 2y" : @"((3 * x) + (2 * y) + 1)",
             @"3x + 3xy + 2y + 3xx + yy" : @"((3 * x * x) + (3 * x * y) + (y * y) + (3 * x) + (2 * y))",
             @"yy + 3yx + 3x + 2y + 3xx" : @"((3 * x * x) + (3 * x * y) + (y * y) + (3 * x) + (2 * y))",
             @"yyx + 3zzx + 3xxz + 2xxx + 3yyz + zzz" : @"((2 * x * x * x) + (3 * x * x * z) + (x * y * y) + (3 * x * z * z) + (3 * y * y * z) + (z * z * z))",
             // These are weird ones and should never occur in practice
             @"5(x+1)x" : @"(5 * x * (x + 1))",
             @"5(x+1)x + xx" : @"((x * x) + (5 * x * (x + 1)))",
             @"xx + 5(x+1)x" : @"((x * x) + (5 * x * (x + 1)))",
             @"5(x+1)x + x(x + 2)" : @"((5 * x * (x + 1)) + (x * (x + 2)))",
             };
    
}

- (void)testRule
{
    MTReorderTermsRule* rule = [[MTReorderTermsRule alloc] init];
    MTFlattenRule *flatten = [[MTFlattenRule alloc] init];
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTExpression* expr = [rule apply:[flatten apply:[parser parseFromString:testExpr]]];
        XCTAssertNotNil(expr, @"Rule returned nil");
        XCTAssertEqualObjects(expr.stringValue, expected, @"For expression %@", testExpr);
    }
}

@end
