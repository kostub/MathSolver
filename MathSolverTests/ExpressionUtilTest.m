//
//  ExpressionUtilTest.m
//
//  Created by Kostub Deshmukh on 7/29/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ExpressionUtilTest.h"
#import "MTExpressionUtil.h"
#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTFlattenRule.h"

@implementation ExpressionUtilTest {
    MTFlattenRule* _flatten;
}

- (void) setUp
{
    [super setUp];
    _flatten = [MTFlattenRule rule];
}

- (MTExpression*) parseExpression:(NSString*) expr {
    MTInfixParser *parser = [MTInfixParser new];
    return [_flatten apply:[parser parseFromString:expr]];
}

- (NSArray*) parseExpressionArray:(NSArray*) exprs {
    // build an array of variables
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:exprs.count];
    for (NSString* expr in exprs) {
        [array addObject:[self parseExpression:expr]];
    }
    return array;
}

static NSArray* getTestData() {
    return @[
             @[@"x + y", @NO],
             @[@"5", @YES, @5, @[]],
             @[@"x", @YES, @1, @[@"x"]],
             @[@"5x", @YES, @5, @[@"x"]],
             @[@"5(x+1)", @NO],
             @[@"5x*3", @NO],
             @[@"xy", @YES, @1, @[@"x", @"y"]],
             @[@"5xx", @YES, @5, @[@"x", @"x"]],
             @[@"5yx", @YES, @5, @[@"x", @"y"]],  // variables are sorted
             ];
}

static NSArray* getTestDataForDiff() {
    return @[
             @[@"2*3", @"2+3", @YES, [NSNull null], [NSNull null]],
             @[@"2*3", @"3*2", @NO, @[], @[]],
             @[@"2+3", @"3+2", @NO, @[], @[]],
             @[@"2+3+4", @"2+3", @YES, @[], @[@"4"]],
             @[@"2+3", @"2+3+4", @YES, @[@"4"], @[]],
             @[@"2+3*4", @"2+4*3", @YES, @[@"4*3"], @[@"3*4"]],
             @[@"2+2", @"2+4", @YES, @[@"4"], @[@"2"]],
             @[@"-2*-2*-2", @"4*-2", @YES, @[@"4"], @[@"-2", @"-2"]],
             ];
}

- (void) testGetCoeffientAndVariables
{
    NSArray* testData = getTestData();
    for (NSArray* testCase in testData) {
        MTExpression* expr = [self parseExpression:testCase[0]];
        MTRational* coeff;
        NSArray* vars;
        BOOL val = [MTExpressionUtil expression:expr getCoefficent:&coeff variables:&vars];
        NSString* desc = [NSString stringWithFormat:@"Error for expr:%@", testCase[0]];
        XCTAssertEqualObjects([NSNumber numberWithBool:val], testCase[1], @"%@", desc);
        if (val) {
            XCTAssertEqual(coeff.denominator, 1u, @"%@", desc);
            XCTAssertEqualObjects([NSNumber numberWithInt:coeff.numerator], testCase[2], @"%@", desc);
            // build an array of variables
            NSArray* expectedVars = [self parseExpressionArray:testCase[3]];
            XCTAssertEqualObjects(vars, expectedVars, @"%@", desc);
        }
    }
}

- (void) testDiffOperator
{
    NSArray* testData = getTestDataForDiff();
    for (NSArray* testCase in testData) {
        MTExpression* first = [self parseExpression:testCase[0]];
        MTExpression* second = [self parseExpression:testCase[1]];
        NSArray* added, *removed;
        BOOL diff = [MTExpressionUtil diffOperator:(MTOperator*)first with:(MTOperator*)second removedChildren:&removed addedChildren:&added];
        NSString* desc = [NSString stringWithFormat:@"Error for diff:%@ and %@", testCase[0], testCase[1]];
        XCTAssertEqualObjects([NSNumber numberWithBool:diff], testCase[2], @"%@", desc);
        if (testCase[3] == [NSNull null]) {
            XCTAssertNil(added, @"%@", desc);
            XCTAssertNil(removed, @"%@", desc);
        } else {
            NSArray* expectedAdded = [self parseExpressionArray:testCase[3]];
            NSArray* expectedRemoved = [self parseExpressionArray:testCase[4]];
            XCTAssertEqualObjects(added, expectedAdded, @"%@", desc);
            XCTAssertEqualObjects(removed, expectedRemoved, @"%@", desc);
        }
    }
}

@end
