//
//  CombineLikeTermsRuleTest.m
//
//  Created by Kostub Deshmukh on 7/20/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "CollectLikeTermsRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTCollectLikeTermsRule.h"
#import "MTFlattenRule.h"
#import "MTDistributionRule.h"
#import "MTCanonicalizer.h"

@implementation CollectLikeTermsRuleTest {
    MTCollectLikeTermsRule* _rule;
    MTExpressionCanonicalizer* _canonicalizer;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [[MTCollectLikeTermsRule alloc] init];
    _canonicalizer = [MTCanonicalizerFactory getExpressionCanonicalizer];
}


static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"5+3+x" : @"((5 + 3) + x)",    // does not trigger CLT
             @"x+5*3" : @"(x + (5 * 3))",
             @"5*3x" : @"((5 * 3) * x)",
             @"(x+5)*3" : @"((x + 5) * 3)",
             @"4x + 3x" : @"(7 * x)",
             @"4x + 3" : @"((4 * x) + 3)",
             @"4(x+1) + 3x" : @"((4 * (x + 1)) + (3 * x))",
             @"4(x+1) + 3(x+1)" : @"((4 * (x + 1)) + (3 * (x + 1)))",
             @"2*(2x + 5x)" : @"(2 * (7 * x))",
             @"x + 2x + 3x" : @"(6 * x)",
             };
    
}

static NSDictionary* getTestDataForFlatten() {
    return @{
             @"5+3+x" : @"(5 + 3 + x)",    // does not trigger CLT
             @"3*(x + 2x + 3)": @"(3 * (3 + (3 * x)))",
             @"x + 2x + 3 + 5": @"(8 + (3 * x))",
             @"2*3*x + 2*x": @"((2 * 3 * x) + (2 * x))",
             @"2x + 5y + 3x*y + 2x*x + y*x + 3y*y + 2y + 4 + 3x*x + 5 + 3y*y + x": @"(9 + (3 * x) + (4 * x * y) + (7 * y) + (5 * x * x) + (6 * y * y))",
             @"4x - 2x" : @"(2 * x)",
             @"-4x + 3x" : @"(-1 * x)",
             @"4x - 5x" : @"(-1 * x)",
             @"4xy - 3xy" : @"(1 * x * y)",
             @"4xy - 5xy" : @"(-1 * x * y)",
             @"4xy - xy" : @"(3 * x * y)",
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


- (void)testRuleAfterNormalize
{
    NSDictionary* dict = getTestDataForFlatten();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTExpression* expr = [_rule apply:[_canonicalizer normalize:[parser parseFromString:testExpr]]];
        XCTAssertNotNil(expr, @"Rule returned nil");
        XCTAssertEqualObjects(expected, expr.stringValue, @"Matching the string representation");
    }
}

- (void)testRuleAfterDistribution
{
    MTInfixParser *parser = [[MTInfixParser alloc] init];
    MTDistributionRule *distribute = [[MTDistributionRule alloc] init];
    MTFlattenRule *flatten = [[MTFlattenRule alloc] init];
    MTExpression* expr = [_rule apply:[flatten apply:[distribute apply:[parser parseFromString:@"x(x+1) + x(x+1) + 3x + 1"]]]];
    XCTAssertNotNil(expr, @"Rule returned nil");
    XCTAssertEqualObjects(@"(1 + (5 * x) + (2 * x * x))", expr.stringValue, @"Matching the string representation");
}

@end
