//
//  Tokenizer.m
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTTokenizer.h"
#import "MTSymbol.h"
#import "MTExpression.h"

@implementation MTTokenizer {
    NSString* _string;
    int _current;
}

- (id) initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        _string = string;
        _current = 0;
    }
    return self;
}

- (MTSymbol*) getNextToken
{
    NSUInteger length = [_string length];
    // safety check
    if (_current >= length) {
        return nil;
    }
    
    // skip spaces
    unichar ch;
    do {
        ch = [_string characterAtIndex:_current];
        ++_current;
    } while(ch == ' ' && _current < length);
    
    int offset = _current - 1;
    
    switch (ch) {
        case ' ':
            // we are still at a space and _current has gone past the end, so no more characters are left.
            return nil;
        case 0x00D7:
            return [MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTMultiplication] offset:NSMakeRange(offset, 1)];
        case '+':
        case '-':
        case '*':
        case '/':
            return [MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:ch] offset:NSMakeRange(offset, 1)];
        case '(':
            return [MTSymbol symbolWithType:kMTSymbolTypeOpenParen value:nil offset:NSMakeRange(offset, 1)];
        case ')':
            return [MTSymbol symbolWithType:kMTSymbolTypeClosedParen value:nil offset:NSMakeRange(offset, 1)];
            
        default:
            break;
    }
    if (ch >= '0' && ch <= '9') {
        unsigned int value = 0;
        _current--;  // set current to the current character since it will be incremented the first time in the loop.
        do {
            value *= 10;
            value += (ch - '0');
            _current++;
            if (_current < length) {
                ch = [_string characterAtIndex:_current];
            } else {
                ch = 0;
            }
        } while(ch >= '0' && ch <= '9');
        return [MTSymbol symbolWithType:kMTSymbolTypeNumber value:[NSNumber numberWithUnsignedInt:value] offset:NSMakeRange(offset, 1)];  // note this is not really 1
    } else if(ch >= 'a' && ch <= 'z') {
        return [MTSymbol symbolWithType:kMTSymbolTypeVariable value:[NSNumber numberWithUnsignedShort:ch] offset:NSMakeRange(offset, 1)];
    }
    // throw exception?
    [NSException raise:@"ParseError" format:@"Unknown type of character: %c", ch];
    return nil;
}

@end
