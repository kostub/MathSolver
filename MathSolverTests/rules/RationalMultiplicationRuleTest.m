//
//  RationalMultiplicationRuleTest.m
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <XCTest/XCTest.h>

#import "MTRationalMultiplicationRule.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTMathListBuilder.h"
#import "MTCanonicalizer.h"


@interface RationalMultiplicationRuleTest : XCTestCase

@end

@implementation RationalMultiplicationRuleTest

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
             @"x*5*3" : @"(x * 5 * 3)",
             @"1/2 * 2" :@"((1 * 2) / 2)",
             @"x/2 * y" : @"((x * y) / 2)",
             @"x * (3/2) * y" : @"((x * 3 * y) / 2)",
             @"x * (3/2) * (y/3)" : @"((x * 3 * y) / (2 * 3))",
             };
    
}

- (void) testRule
{
    MTRationalMultiplicationRule* rule = [MTRationalMultiplicationRule rule];
    MTExpressionCanonicalizer* canonicalizer = [MTCanonicalizerFactory getExpressionCanonicalizer];
    NSDictionary* dict = getTestData();
    for (NSString* testExpr in dict) {
        NSString* expected = [dict valueForKey:testExpr];
        MTInfixParser *parser = [MTInfixParser new];
        MTMathList* ml = [MTMathListBuilder buildFromString:testExpr];
        MTExpression* expr = [rule apply:[canonicalizer normalize:[parser parseToExpressionFromMathList:ml]]];
        XCTAssertNotNil(expr, @"Rule returned nil for %@", testExpr);
        XCTAssertEqualObjects(expected, expr.stringValue, @"For %@", testExpr);
    }
}

@end
