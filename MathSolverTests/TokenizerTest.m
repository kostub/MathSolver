//
//  TokenizerTest.m
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "TokenizerTest.h"
#import "MTTokenizer.h"
#import "MTSymbol.h"

@implementation TokenizerTest

- (void) checkSymbol: (MTSymbol *) symbol type:(enum MTSymbolType) type value:(unichar) value
{
    XCTAssertEqual(symbol.type, type, @"Type does not match %d", symbol.type);
    XCTAssertEqual(symbol.charValue, value, @"Value does not match %c", symbol.charValue);
}

- (void) checkSymbol:(MTSymbol *) symbol value:(unsigned int) value
{
    XCTAssertEqual(symbol.type, kMTSymbolTypeNumber, @"Type does not match %d", symbol.type);
    XCTAssertEqual(symbol.intValue, value, @"Value does not match %d", symbol.intValue);
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSimpleExpression
{
    MTTokenizer *tokenizer = [[MTTokenizer alloc] initWithString:@"x+5"];
    MTSymbol *s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeVariable value:'x'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeOperator value:'+'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s value:5];
    s = [tokenizer getNextToken];
    XCTAssertNil(s, @"Tokens not finshed when expected");
}

- (void)testLongNumber
{
    MTTokenizer *tokenizer = [[MTTokenizer alloc] initWithString:@"513"];
    MTSymbol *s = [tokenizer getNextToken];
    [self checkSymbol:s value:513];
    s = [tokenizer getNextToken];
    XCTAssertNil(s, @"Tokens not finshed when expected");
}

- (void)testSpacesHandledCorrectly
{
    MTTokenizer *tokenizer = [[MTTokenizer alloc] initWithString:@"x + 5"];
    MTSymbol *s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeVariable value:'x'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeOperator value:'+'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s value:5];
    s = [tokenizer getNextToken];
    XCTAssertNil(s, @"Tokens not finshed when expected");
}


- (void)testSpacesAtBeginningAndEnd
{
    MTTokenizer *tokenizer = [[MTTokenizer alloc] initWithString:@"  x+5  "];
    MTSymbol *s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeVariable value:'x'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeOperator value:'+'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s value:5];
    s = [tokenizer getNextToken];
    XCTAssertNil(s, @"Tokens not finshed when expected");
}

- (void)testComplexExpressionWithParens
{
    MTTokenizer *tokenizer = [[MTTokenizer alloc] initWithString:@"51x + (12y * 4) / 3"];
    MTSymbol *s = [tokenizer getNextToken];
    [self checkSymbol:s value:51];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeVariable value:'x'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeOperator value:'+'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeOpenParen value:0];
    s = [tokenizer getNextToken];
    [self checkSymbol:s value:12];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeVariable value:'y'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeOperator value:'*'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s value:4];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeClosedParen value:0];
    s = [tokenizer getNextToken];
    [self checkSymbol:s type:kMTSymbolTypeOperator value:'/'];
    s = [tokenizer getNextToken];
    [self checkSymbol:s value:3];
    s = [tokenizer getNextToken];
    XCTAssertNil(s, @"Tokens not finshed when expected");
    NSLog(@"done");
}

@end
