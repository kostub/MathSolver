//
//  Tokenizer.h
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

@class MTSymbol;
@interface MTTokenizer : NSObject

- (id) initWithString:(NSString*) string;

// Returns nil when no more tokens left
- (MTSymbol*) getNextToken;

@end
