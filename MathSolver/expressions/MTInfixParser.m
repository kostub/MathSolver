//
//  InfixParser.m
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTInfixParser.h"
#import "MTExpression.h"
#import "MTTokenizer.h"
#import "MTSymbol.h"
#import "MTMathList.h"
#import "MTMathListIndex.h"

// Returns the precedence of different supported operators
static int precedence(char op) {
    switch (op) {
        case '+':
        case '-':
            return 1;
        case '*':
        case '/':
            return 2;
        case '_':      // unary minus
            return 3;
        default:
            return 0;
    }
}

NSString *const MTParseErrorDomain = @"ParseError";
NSString *const MTParseErrorOffset = @"ParseErrorOffset";

@implementation MTInfixParser {
    NSMutableArray *_expressionStack;
    NSMutableArray *_operatorStack;
    NSError *_error;
    MTExpression* _lhs;
    MTSymbol* _relation;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self clear];
    }
    return self;
}

- (void) clear
{
    _lhs = nil;
    _relation = nil;
    _error = nil;
    _expressionStack = [NSMutableArray array];
    _operatorStack = [NSMutableArray array];
}

#pragma mark - Error

- (BOOL) hasError
{
    return (_error != nil);
}

- (NSError*) error
{
    return _error;
}


- (void) setError:(enum MTParserErrors) code offset:(long) offset description:(NSString*) description, ... NS_FORMAT_FUNCTION(3, 4)
{
    va_list args;
    va_start(args, description);
    [self setError:code text:[[NSString alloc] initWithFormat:description arguments:args] index:[MTMathListIndex level0Index:offset]];
}

- (void)setError:(enum MTParserErrors) code text:(NSString*) text index:(MTMathListIndex*) index
{
    NSDictionary *errorDictionary;
    if (index) {
        errorDictionary = @{ NSLocalizedDescriptionKey : text,
                             MTParseErrorOffset : index};
    } else {
        errorDictionary = @ { NSLocalizedDescriptionKey : text };
    }
    _error = [NSError errorWithDomain:MTParseErrorDomain code:code userInfo:errorDictionary];
}

#pragma mark - String

- (MTExpression*) parseFromString:(NSString*) string
{
    [self clear];
    MTTokenizer *tok = [[MTTokenizer alloc] initWithString:string];
    MTSymbol *next = nil;
    MTSymbol *previous = nil;
    while ((next = [tok getNextToken]) != nil) {
        // Modified shunting yard algorithm to build an AST
        switch (next.type) {
                
            case kMTSymbolTypeNumber: {
                MTRational* value = [MTRational rationalWithNumber:[next.value intValue]];
                if (![self handleNumber:next previous:previous value:value]) {
                    return nil;
                }
                break;
            }
            
            case kMTSymbolTypeVariable:
                if (![self handleVariable:next previous:previous]) {
                    return nil;
                }
                break;
                
            case kMTSymbolTypeOperator:
                if (next.charValue == kMTSubtraction && (previous == nil || previous.type == kMTSymbolTypeOpenParen || previous.type == kMTSymbolTypeOperator)) {
                    // this is a unary minus. Switch the symbol to it.
                    next = [MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTUnaryMinus] offset:next.offset];
                }
                if (![self handleOperator:next]) {
                    return nil;
                }
                break;
                
            case kMTSymbolTypeOpenParen:
                if (![self handleOpenParen:next previous:previous]) {
                    return nil;
                }
                break;
                
            case kMTSymbolTypeClosedParen: {
                if (![self handleCloseParen:next]) {
                    return nil;
                }
                break;
            }
                
            default:
                [NSException raise:@"ParseError" format:@"Unknown type of token from the tokenizer: %d", next.type];
        }
        previous = next;
    }
    
    if (![self popOperatorStack]) {
        return nil;
    }
    
    if ([_expressionStack count] != 1) {
        MTExpression *expr = [_expressionStack lastObject];
        [self setError:MTParserMissingOperator text:@"You may be missing a +, - or *" index:expr.range.start];
        return nil;
    } else {
        MTExpression* expr = [_expressionStack lastObject];
        DLog(@"Parsing %@ to %@", string, expr.stringValue);
        return expr;
    }
}

#pragma mark - MathList

- (id<MTMathEntity>) parseFromMathList:(MTMathList*) mathList expectedEntityType:(MTMathEntityType)entityType
{
    [self clear];

    MTMathList* finalized = mathList.finalized;
    MTSymbol *previous = nil;

    for(MTMathAtom* atom in finalized.atoms) {
        // Modified shunting yard algorithm to build an AST
        unichar charValue = 0;
        if (atom.nucleus.length == 1) {
            charValue = [atom.nucleus characterAtIndex:0];
        }
        MTSymbol* next = nil;
        if (atom.subScript || atom.superScript) {
            [self setError:MTParserUnsupportedOperation text:@"Cannot handle subscripts or superscripts." index:[MTMathListIndex level0Index:atom.indexRange.location]];
            return nil;
        }
        switch (atom.type) {                
            case kMTMathAtomNumber: {
                next = [MTSymbol symbolWithType:kMTSymbolTypeNumber value:nil offset:atom.indexRange];
                MTRational* value = [MTRational rationalFromDecimalRepresentation:atom.nucleus];
                if (value == nil) {
                    [self setError:MTParserInvalidNumber offset:atom.indexRange.location description:@"Cannot parse number: %@", atom.nucleus];
                    return nil;
                }
                if (![self handleNumber:next previous:previous value:value]) {
                    return nil;
                }
                break;
            }
                
            case kMTMathAtomVariable: {
                next = [MTSymbol symbolWithType:kMTSymbolTypeVariable value:[NSNumber numberWithUnsignedShort:charValue] offset:atom.indexRange];
                if (![self handleVariable:next previous:previous]) {
                    return nil;
                }
                break;
            }
                
            case kMTMathAtomUnaryOperator: {
                if (charValue == 0x2212) {
                    charValue = kMTSubtraction;
                }
                if (charValue == kMTSubtraction) {
                    next = [MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTUnaryMinus] offset:atom.indexRange];
                    if (![self handleOperator:next]) {
                        return nil;
                    }
                } else {
                    [self setError:MTParserNotEnoughArguments text:[NSString stringWithFormat:@"Not enough arguments for %C", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                    return nil;
                }
                break;
            }
                
            case kMTMathAtomBinaryOperator: {
                if (charValue == 0x00D7) {
                    charValue = kMTMultiplication;
                } else if (charValue == 0x00F7) {
                    charValue = kMTDivision;
                } else if (charValue == 0x2212) {
                    charValue = kMTSubtraction;
                }
                if (charValue == kMTMultiplication || charValue == kMTAddition || charValue == kMTSubtraction || charValue == kMTDivision) {
                    next = [MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:charValue] offset:atom.indexRange];
                    if (![self handleOperator:next]) {
                        return nil;
                    }
                } else {
                    [self setError:MTParserUnsupportedOperation text:[NSString stringWithFormat:@"Unsupported operator %C ", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                    return nil;
                }
                
                break;
            }
                
            case kMTMathAtomOpen: {
                if (charValue == '(') {
                    next = [MTSymbol symbolWithType:kMTSymbolTypeOpenParen value:nil offset:atom.indexRange];
                    if (![self handleOpenParen:next previous:previous]) {
                        return nil;
                    }
                } else {
                    [self setError:MTParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                }
                break;
            }
                
            case kMTMathAtomClose: {
                if (charValue == ')') {
                    next = [MTSymbol symbolWithType:kMTSymbolTypeClosedParen value:nil offset:atom.indexRange];
                    if (![self handleCloseParen:next]) {
                        return nil;
                    }
                } else {
                    [self setError:MTParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                }
                break;
            }
                
            case kMTMathAtomFraction: {
                // Treat fractions same as numbers
                next = [MTSymbol symbolWithType:kMTSymbolTypeNumber value:[NSNumber numberWithUnsignedInt:0] offset:atom.indexRange];
                if (![self handleFraction:(MTFraction*)atom previous:previous]) {
                    return nil;
                }
                break;
            }
                
            case kMTMathAtomPlaceholder: {
                // placeholder elements are not allowed
                [self setError:MTParserPlaceholderPresent text:@"You need to enter text here at the shown spot" index:[MTMathListIndex level0Index:atom.indexRange.location]];
                return nil;
            }
                
            case kMTMathAtomRelation: {
                if (charValue == '=') {
                    next = [MTSymbol symbolWithType:kMTSymbolTypeRelation value:[NSNumber numberWithUnsignedShort:charValue] offset:atom.indexRange];
                    if (![self handleRelation:next]) {
                        return nil;
                    }
                } else {
                    [self setError:MTParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                }
                break;
            }

            case kMTMathAtomOrdinary: {
                // The division slash '/' gets parsed as ordinary in LaTeX
                if (charValue == kMTDivision) {
                    next = [MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:charValue] offset:atom.indexRange];
                    if (![self handleOperator:next]) {
                        return nil;
                    }
                } else {
                    [self setError:MTParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                    return nil;
                }
                break;
            }
    
            case kMTMathAtomLargeOperator:
            case kMTMathAtomPunctuation:
            case kMTMathAtomRadical:
                [self setError:MTParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                return nil;
        }
        previous = next;
    }
    
    if (![self popOperatorStack]) {
        return nil;
    }

    if ([_expressionStack count] == 0) {
        [self setError:MTParserMissingExpression offset:(mathList.atoms.count - 1) description:@"Missing expression"];
        return nil;
    } else if ([_expressionStack count] > 1) {
        MTExpression *expr = [_expressionStack lastObject];
        [self setError:MTParserMissingOperator text:@"You may be missing a +, - or *" index:expr.range.start];
        return nil;
    } else if (_lhs) {
        assert(_relation);
        if (entityType == kMTExpression) {
            // This shouldn't have been an equation
            [self setError:MTParserMultipleRelations offset:_relation.offset.location description:@"You cannot have a %c here", _relation.charValue];
            return nil;
        }
        // this is an equation
        MTEquation *eq = [MTEquation equationWithRelation:_relation.charValue lhs:_lhs rhs:[_expressionStack lastObject]];
        return eq;
    } else {
        if (entityType == kMTEquation) {
            // We wanted an equation but only got an expression
            [self setError:MTParserEquationExpected text:@"You need to enter an equation" index:nil];
            return nil;
        }
        MTExpression* expr = [_expressionStack lastObject];
        return expr;
    }
}

- (MTExpression *)parseToExpressionFromMathList:(MTMathList *)mathList
{
    id<MTMathEntity> entity = [self parseFromMathList:mathList expectedEntityType:kMTExpression];
    if (entity) {
        NSAssert([entity isKindOfClass:[MTExpression class]], @"Expected an expression for %@", mathList);
        return (MTExpression*) entity;
    }
    return nil;
}

- (MTEquation *)parseToEquationFromMathList:(MTMathList *)mathList
{
    id<MTMathEntity> entity = [self parseFromMathList:mathList expectedEntityType:kMTEquation];
    if (entity) {
        NSAssert([entity isKindOfClass:[MTEquation class]], @"Expected an equation for %@", mathList);
        return (MTEquation*) entity;
    }
    return nil;
}

#pragma mark - Handling different Symbols

- (BOOL) handleNumber:(MTSymbol*) next previous:(MTSymbol*) previous value:(MTRational*) value
{
    if (value == nil) {
        
    }
    if (previous != nil && previous.type == kMTSymbolTypeClosedParen) {
        // insert a multiplication operator
        if (![self handleOperator:[MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTMultiplication] offset:next.offset]]) {
            return false;
        }
    }
    MTNumber *expr = [MTNumber numberWithValue:value range:[MTMathListRange makeRangeForRange:next.offset]];
    [_expressionStack addObject:expr];
    return true;
}

- (BOOL) handleVariable:(MTSymbol*) next previous:(MTSymbol*) previous
{
    if (previous != nil && (previous.type == kMTSymbolTypeNumber || previous.type == kMTSymbolTypeClosedParen || previous.type == kMTSymbolTypeVariable)) {
        // insert a multiplication operator
        if (![self handleOperator:[MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTMultiplication] offset:next.offset]]) {
            return false;
        }
    }
    MTVariable *expr = [MTVariable variableWithName:next.charValue range:[MTMathListRange makeRangeForRange:next.offset]];
    [_expressionStack addObject:expr];
    return true;
}

- (BOOL) handleOperator:(MTSymbol *) operator
{
    while ([_operatorStack count] > 0) {
        MTSymbol *s = [_operatorStack lastObject];
        if (s.type == kMTSymbolTypeOperator && precedence(s.charValue) >= precedence(operator.charValue)) {
            [_operatorStack removeLastObject];
            if (![self addOperatorToExpressionStack:s]) {
                // If there is an error adding it to the stack, return false.
                return NO;
            }
        } else {
            break;
        }
    }
    [_operatorStack addObject:operator];
    return YES;
}

- (BOOL) handleRelation:(MTSymbol *) relation
{
    // empty all operators
    if (![self popOperatorStack]) {
        return NO;
    }
    if ([_expressionStack count] == 0) {
        [self setError:MTParserMissingExpression offset:relation.offset.location description:@"Missing left hand side expression"];
        return NO;
    } else if ([_expressionStack count] > 1) {
        MTExpression *expr = [_expressionStack lastObject];
        [self setError:MTParserMissingOperator text:@"You may be missing a +, - or *" index:expr.range.start];
        return NO;
    } else if (_lhs) {
        // can't have 2 relations in the same equation
        [self setError:MTParserMultipleRelations offset:relation.offset.location description:@"You cannot have a %c here", relation.charValue];
        return NO;
    } else {
        // No lhs and there is only one expression
        _lhs = [_expressionStack lastObject];
        [_expressionStack removeLastObject];
        assert(_expressionStack.count == 0);
        _relation = relation;
        return YES;
    }
}

- (BOOL) handleOpenParen:(MTSymbol*) next previous:(MTSymbol*) previous
{
    if (previous != nil && (previous.type == kMTSymbolTypeNumber || previous.type == kMTSymbolTypeVariable || previous.type == kMTSymbolTypeClosedParen)) {
        // insert a multiplication operator
        if (![self handleOperator:[MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTMultiplication] offset:next.offset]]) {
            return false;
        }
    }
    [_operatorStack addObject:next];
    return true;
}

- (BOOL) handleCloseParen:(MTSymbol *)next
{
    BOOL found = NO;
    while ([_operatorStack count] > 0) {
        MTSymbol *s = [_operatorStack lastObject];
        if (s.type == kMTSymbolTypeOpenParen) {
            [_operatorStack removeLastObject];
            found = YES;
            break;
        } else if (s.type == kMTSymbolTypeOperator) {
            [_operatorStack removeLastObject];
            // error while adding operator
            if (![self addOperatorToExpressionStack:s]) {
                return false;
            }
        }
    }
    
    if (!found) {
        [self setError:MTParserMismatchParens text:@"No matching parenthesis for )" index:[MTMathListIndex level0Index:next.offset.location]];
        return false;
    }
    return true;
}

- (BOOL) handleFraction:(MTFraction*) frac previous:(MTSymbol*) previous
{
    // same rules as numbers apply
    if (previous != nil && previous.type == kMTSymbolTypeClosedParen) {
        // insert a multiplication operator
        if (![self handleOperator:[MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTMultiplication] offset:frac.indexRange]]) {
            return false;
        }
    }

    MTInfixParser *parser = [MTInfixParser new];
    MTExpression* numerator = (MTExpression*) [parser parseFromMathList:frac.numerator expectedEntityType:kMTExpression];
    if (parser.hasError) {
        // Twiddle offsets to be in the numerator
        NSError* error = parser.error;
        MTMathListIndex* fracIndex = [MTMathListIndex indexAtLocation:frac.indexRange.location withSubIndex:[error.userInfo objectForKey:MTParseErrorOffset] type:kMTSubIndexTypeNumerator];
        [self setError:parser.error.code text:error.localizedDescription index:fracIndex];
        return false;
    }
    MTExpression* denominator = (MTExpression*)[parser parseFromMathList:frac.denominator expectedEntityType:kMTExpression];
    if (parser.hasError) {
        // Twiddle offsets to be in the denominator
        NSError* error = parser.error;
        MTMathListIndex* fracIndex = [MTMathListIndex indexAtLocation:frac.indexRange.location withSubIndex:[error.userInfo objectForKey:MTParseErrorOffset] type:kMTSubIndexTypeDenominator];
        [self setError:parser.error.code text:error.localizedDescription index:fracIndex];
        return false;
    }
    
    if (numerator.expressionType == kMTExpressionTypeNumber && denominator.expressionType == kMTExpressionTypeNumber) {
        MTRational* n = numerator.expressionValue;
        MTRational* d = denominator.expressionValue;
        
        if (n.format == kMTRationalFormatWhole && d.format == kMTRationalFormatWhole) {
            // This is a fraction. For whole numbers, denominator is always 1.
            MTRational* rat = [MTRational rationalWithNumerator:n.numerator denominator:d.numerator];
            // d could be 0 in which case rat is null
            if (!rat) {
                // division by 0
                MTMathListIndex* fracIndex = [MTMathListIndex indexAtLocation:frac.indexRange.location withSubIndex:[MTMathListIndex level0Index:0] type:kMTSubIndexTypeDenominator];
                [self setError:MTParserDivisionByZero text:@"Cannot divide by 0" index:fracIndex];
                return false;
            }
            MTMathListRange* range = [MTMathListRange makeRangeForIndex:frac.indexRange.location];
            if (previous && previous.type == kMTSymbolTypeNumber) {
                // get the last number from the expression stack.
                MTNumber* expr = [_expressionStack lastObject];
                if (expr.expressionType == kMTExpressionTypeNumber) {
                    MTRational* prev = expr.expressionValue;
                    if (prev.format == kMTRationalFormatWhole) {
                        // if the previous is a whole number, then this becomes a mixed fraction, so add the fractional part.
                        [_expressionStack removeLastObject];
                        rat = [prev add:rat];
                        range = [range unionRange:expr.range];
                    }
                }
            }
            MTNumber *expr = [MTNumber numberWithValue:rat range:range];
            [_expressionStack addObject:expr];
            return true;
        }
    }
    // not a fraction, so divide
    [_expressionStack addObject:[numerator expressionWithRange:[MTMathListRange makeRangeForIndex:frac.indexRange.location]]];
    // insert a division operator
    if (![self handleOperator:[MTSymbol symbolWithType:kMTSymbolTypeOperator value:[NSNumber numberWithUnsignedShort:kMTDivision] offset:frac.indexRange]]) {
        return false;
    }
    [_expressionStack addObject:[denominator expressionWithRange:[MTMathListRange makeRangeForIndex:frac.indexRange.location]]];
    
    return true;   
}

#pragma mark - Operators

- (BOOL) addOperatorToExpressionStack:(MTSymbol*) operator
{
    // all operators are except _ are binary
    if (operator.charValue == '_' && [_expressionStack count] >= 1) {
        MTExpression* arg = [_expressionStack lastObject];
        [_expressionStack removeLastObject];
        if (arg.range.start.atomIndex > operator.offset.location) {
            if (arg.expressionType == kMTExpressionTypeNumber && [arg.expressionValue isPositive]) {
                // If it is just a -num then make it to a FXNumber
                MTNumber* num = (MTNumber*) arg;
                MTRational* value = num.value;
                [_expressionStack addObject:[MTNumber numberWithValue:value.negation range:[MTMathListRange makeRangeForRange:operator.offset]]];
            } else {
                // The argument should come after the operator, otherwise we are missing the argument for the operator
                MTOperator *op = [MTOperator unaryOperatorWithType:operator.charValue arg:arg range:[MTMathListRange makeRangeForRange:operator.offset]];
                [_expressionStack addObject:op];
            }
            return YES;
        }
    } else if ([_expressionStack count] >= 2) {
        MTExpression* arg2 = [_expressionStack lastObject];
        [_expressionStack removeLastObject];
        MTExpression* arg1 = [_expressionStack lastObject];
        [_expressionStack removeLastObject];
        if (arg1.range.start.atomIndex > operator.offset.location) {
            // There should have been an operator to combine these two, which is missing
            [self setError:MTParserMissingOperator text:@"You may be missing a +, - or *" index:arg2.range.start];
            return NO;
        } else if (operator.offset.location <= arg2.range.start.atomIndex) {
            // the operator should come in between the 2 arguments, otherwise it is missing arguments.
            MTOperator *op = [MTOperator operatorWithType:operator.charValue args:arg1:arg2];
            [_expressionStack addObject:op];
            return YES;
        }
    }
    // else
    unichar ch = operator.charValue;
    if (ch == kMTUnaryMinus) {
        // switch the unary minus back to the subtract sign for display.
        ch = kMTSubtraction;
    }
    [self setError:MTParserNotEnoughArguments
              text:[NSString stringWithFormat:@"Not enough arguments for %C", ch]
             index:[MTMathListIndex level0Index:operator.offset.location]];
    return NO;
}

- (BOOL) popOperatorStack
{
    // all tokens are done
    while ([_operatorStack count] > 0) {
        MTSymbol *s = [_operatorStack lastObject];
        if (s.type == kMTSymbolTypeOpenParen) {
            [_operatorStack removeLastObject];
            [self setError:MTParserMismatchParens text:@"No matching parenthesis for (" index:[MTMathListIndex level0Index:s.offset.location]];
            return false;
        }  else if (s.type == kMTSymbolTypeOperator) {
            [_operatorStack removeLastObject];
            if (![self addOperatorToExpressionStack:s]) {
                return false;
            }
        } else {
            // shouldn't be anything else
            [NSException raise:@"ParseError" format:@"Unknown type of symbol on stack: %d", s.type];
        }
    }
    return true;
}


@end
