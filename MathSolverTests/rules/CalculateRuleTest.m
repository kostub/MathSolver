//
//  CalculateRuleTest.m
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "CalculateRuleTest.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTCalculateRule.h"
#import "MTFlattenRule.h"
#import "MTMathListBuilder.h"

@implementation CalculateRuleTest {
    MTCalculateRule* _rule;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _rule = [[MTCalculateRule alloc] init];
}

static NSDictionary* getTestData() {
    return @{
             @"5" : @"5",
             @"x" : @"x",
             @"x+5" : @"(x + 5)",
             @"5+3+x" : @"(8 + x)",
             @"x+5*3" : @"(x + 15)",
             @"5*3x" : @"(15 * x)",
             @"x*((1+3)+5)" : @"(x * 9)",
             @"(5+3)*(2+1*7+3)" : @"96",
             @"x+5/1" : @"(x + 5)",
             @"x/1" : @"(x * 1)",
             @"x/\\frac{5}{5}" : @"(x * 5/5)",
             @"x*(3/1+5)" : @"(x * 8)",
             @"3x/3" : @"(x * 3/3)",
             @"(5+3)/2*(2+3*4/3+3)": @"216/6",
             };
    
}


- (void)testFlattenedExpression
{
    MTInfixParser *parser = [[MTInfixParser alloc] init];
    MTFlattenRule *flatten = [[MTFlattenRule alloc] init];
    MTExpression* expr = [_rule apply:[flatten apply:[parser parseFromString:@"(x+3)+(x+4+5)"]]];
    XCTAssertNotNil(expr, @"Rule returned nil");
    XCTAssertEqualObjects(@"(x + x + 12)", expr.stringValue, @"Matching the string representation");
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

- (void)testApplyInnerMost
{
    MTInfixParser *parser = [[MTInfixParser alloc] init];
    MTExpression* expr = [_rule applyInnerMost:[parser parseFromString:@"(5+16)*7+2*2"] onlyFirst:false];
    XCTAssertNotNil(expr, @"Rule returned nil");
    XCTAssertEqualObjects(@"((21 * 7) + 4)", expr.stringValue, @"Matching the string representation");
}

- (void)testApplyInnerMostFirst
{
    MTInfixParser *parser = [[MTInfixParser alloc] init];
    MTExpression* expr = [_rule applyInnerMost:[parser parseFromString:@"(5+16)*7+2*2"] onlyFirst:true];
    XCTAssertNotNil(expr, @"Rule returned nil");
    XCTAssertEqualObjects(@"((21 * 7) + (2 * 2))", expr.stringValue, @"Matching the string representation");
}

@end
