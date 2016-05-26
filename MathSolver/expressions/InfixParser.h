//
//  InfixParser.h
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "Expression.h"

@class MTMathList;


FOUNDATION_EXPORT NSString *const FXParseError;
FOUNDATION_EXPORT NSString *const FXParseErrorOffset;

// A Simple parser that parses an infix string into an abstract syntax tree using the shunting yard algorithm
// http://en.wikipedia.org/wiki/Shunting-yard_algorithm
@interface InfixParser : NSObject

// Create a parser with the string to parse
- (id) init;

// Tokenizes and parses the string or mathlist as an expression. Returns nil on error
- (Expression*) parseFromString:(NSString*) string;
// If expectsEquation is false, then parsing an equation returns an error, if it is true then there is an error
// if an equation isn't found.
- (id<MathEntity>) parseFromMathList:(MTMathList*) mathList expectedEntityType:(MathEntityType) entityType;

- (Expression*) parseToExpressionFromMathList:(MTMathList*) mathList;
- (Equation*) parseToEquationFromMathList:(MTMathList*) mathList;

// Returns true if the parsing has an error.
- (BOOL) hasError;

// Get the error associated with the parsing
- (NSError *) error;

enum FXParserErrors {
    FXParserMismatchParens = 1,
    FXParserNotEnoughArguments,
    FXParserMissingOperator,
    FXParserInvalidCharacter,
    FXParserDivisionByZero,
    FXParserPlaceholderPresent,
    FXParserMultipleRelations,
    FXParserEquationExpected,
    FXParserMissingExpression,
    FXParserUnsupportedOperation,
    FXParserInvalidNumber,
};

@end
