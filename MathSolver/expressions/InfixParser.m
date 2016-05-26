//
//  InfixParser.m
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "InfixParser.h"
#import "Expression.h"
#import "Tokenizer.h"
#import "Symbol.h"
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

NSString *const FXParseError = @"ParseError";
NSString *const FXParseErrorOffset = @"FXParseErrorOffset";

@implementation InfixParser {
    NSMutableArray *_expressionStack;
    NSMutableArray *_operatorStack;
    NSError *_error;
    Expression* _lhs;
    Symbol* _relation;
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


- (void) setError:(enum FXParserErrors) code offset:(long) offset description:(NSString*) description, ... NS_FORMAT_FUNCTION(3, 4)
{
    va_list args;
    va_start(args, description);
    [self setError:code text:[[NSString alloc] initWithFormat:description arguments:args] index:[MTMathListIndex level0Index:offset]];
}

- (void)setError:(enum FXParserErrors) code text:(NSString*) text index:(MTMathListIndex*) index
{
    NSDictionary *errorDictionary;
    if (index) {
        errorDictionary = @{ NSLocalizedDescriptionKey : text,
                             FXParseErrorOffset : index};
    } else {
        errorDictionary = @ { NSLocalizedDescriptionKey : text };
    }
    _error = [NSError errorWithDomain:FXParseError code:code userInfo:errorDictionary];
}

#pragma mark - String

- (Expression*) parseFromString:(NSString*) string
{
    [self clear];
    Tokenizer *tok = [[Tokenizer alloc] initWithString:string];
    Symbol *next = nil;
    Symbol *previous = nil;
    while ((next = [tok getNextToken]) != nil) {
        // Modified shunting yard algorithm to build an AST
        switch (next.type) {
                
            case kNumber: {
                Rational* value = [Rational rationalWithNumber:[next.value intValue]];
                if (![self handleNumber:next previous:previous value:value]) {
                    return nil;
                }
                break;
            }
            
            case kVariable:
                if (![self handleVariable:next previous:previous]) {
                    return nil;
                }
                break;
                
            case kOperator:
                if (next.charValue == kSubtraction && (previous == nil || previous.type == kOpenParen || previous.type == kOperator)) {
                    // this is a unary minus. Switch the symbol to it.
                    next = [Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:kUnaryMinus] offset:next.offset];
                }
                if (![self handleOperator:next]) {
                    return nil;
                }
                break;
                
            case kOpenParen:
                if (![self handleOpenParen:next previous:previous]) {
                    return nil;
                }
                break;
                
            case kClosedParen: {
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
        Expression *expr = [_expressionStack lastObject];
        [self setError:FXParserMissingOperator text:@"You may be missing a +, - or *" index:expr.range.start];
        return nil;
    } else {
        Expression* expr = [_expressionStack lastObject];
        DLog(@"Parsing %@ to %@", string, expr.stringValue);
        return expr;
    }
}

#pragma mark - MathList

- (id<MathEntity>) parseFromMathList:(MTMathList*) mathList expectedEntityType:(MathEntityType)entityType
{
    [self clear];

    MTMathList* finalized = mathList.finalized;
    Symbol *previous = nil;

    for(MTMathAtom* atom in finalized.atoms) {
        // Modified shunting yard algorithm to build an AST
        unichar charValue = 0;
        if (atom.nucleus.length == 1) {
            charValue = [atom.nucleus characterAtIndex:0];
        }
        Symbol* next = nil;
        if (atom.subScript || atom.superScript) {
            [self setError:FXParserUnsupportedOperation text:@"Cannot handle subscripts or superscripts." index:[MTMathListIndex level0Index:atom.indexRange.location]];
            return nil;
        }
        switch (atom.type) {                
            case kMTMathAtomNumber: {
                next = [Symbol symbolWithType:kNumber value:nil offset:atom.indexRange];
                Rational* value = [Rational rationalFromDecimalRepresentation:atom.nucleus];
                if (value == nil) {
                    [self setError:FXParserInvalidNumber offset:atom.indexRange.location description:@"Cannot parse number: %@", atom.nucleus];
                    return nil;
                }
                if (![self handleNumber:next previous:previous value:value]) {
                    return nil;
                }
                break;
            }
                
            case kMTMathAtomVariable: {
                next = [Symbol symbolWithType:kVariable value:[NSNumber numberWithUnsignedShort:charValue] offset:atom.indexRange];
                if (![self handleVariable:next previous:previous]) {
                    return nil;
                }
                break;
            }
                
            case kMTMathAtomUnaryOperator:
                if (charValue == kSubtraction) {
                    next = [Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:kUnaryMinus] offset:atom.indexRange];
                    if (![self handleOperator:next]) {
                        return nil;
                    }
                    break;
                } else {
                    [self setError:FXParserNotEnoughArguments text:[NSString stringWithFormat:@"Not enough arguments for %C", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                    return nil;
                }
                
            case kMTMathAtomBinaryOperator: {
                if (charValue == 0x00D7) {
                    charValue = kMultiplication;
                } else if (charValue == 0x00F7) {
                    charValue = kDivision;
                }
                if (charValue == kMultiplication || charValue == kAddition || charValue == kSubtraction || charValue == kDivision) {
                    next = [Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:charValue] offset:atom.indexRange];
                    if (![self handleOperator:next]) {
                        return nil;
                    }
                } else {
                    [self setError:FXParserUnsupportedOperation text:[NSString stringWithFormat:@"Unsupported operator %C ", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                    return nil;
                }
                
                break;
            }
                
            case kMTMathAtomOpen: {
                if (charValue == '(') {
                    next = [Symbol symbolWithType:kOpenParen value:nil offset:atom.indexRange];
                    if (![self handleOpenParen:next previous:previous]) {
                        return nil;
                    }
                } else {
                    [self setError:FXParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                }
                break;
            }
                
            case kMTMathAtomClose: {
                if (charValue == ')') {
                    next = [Symbol symbolWithType:kClosedParen value:nil offset:atom.indexRange];
                    if (![self handleCloseParen:next]) {
                        return nil;
                    }
                } else {
                    [self setError:FXParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                }
                break;
            }
                
            case kMTMathAtomFraction: {
                // Treat fractions same as numbers
                next = [Symbol symbolWithType:kNumber value:[NSNumber numberWithUnsignedInt:0] offset:atom.indexRange];
                if (![self handleFraction:(MTFraction*)atom previous:previous]) {
                    return nil;
                }
                break;
            }
                
            case kMTMathAtomPlaceholder: {
                // placeholder elements are not allowed
                [self setError:FXParserPlaceholderPresent text:@"You need to enter text here at the shown spot" index:[MTMathListIndex level0Index:atom.indexRange.location]];
                return nil;
            }
                
            case kMTMathAtomRelation: {
                if (charValue == '=') {
                    next = [Symbol symbolWithType:kRelation value:[NSNumber numberWithUnsignedShort:charValue] offset:atom.indexRange];
                    if (![self handleRelation:next]) {
                        return nil;
                    }
                } else {
                    [self setError:FXParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                }
                break;
            }
    
            case kMTMathAtomLargeOperator:
            case kMTMathAtomOrdinary:
            case kMTMathAtomPunctuation:
            case kMTMathAtomRadical:
                [self setError:FXParserInvalidCharacter text:[NSString stringWithFormat:@"Unknown character %c", charValue] index:[MTMathListIndex level0Index:atom.indexRange.location]];
                return nil;
        }
        previous = next;
    }
    
    if (![self popOperatorStack]) {
        return nil;
    }

    if ([_expressionStack count] == 0) {
        [self setError:FXParserMissingExpression offset:(mathList.atoms.count - 1) description:@"Missing expression"];
        return nil;
    } else if ([_expressionStack count] > 1) {
        Expression *expr = [_expressionStack lastObject];
        [self setError:FXParserMissingOperator text:@"You may be missing a +, - or *" index:expr.range.start];
        return nil;
    } else if (_lhs) {
        assert(_relation);
        if (entityType == kFXExpression) {
            // This shouldn't have been an equation
            [self setError:FXParserMultipleRelations offset:_relation.offset.location description:@"You cannot have a %c here", _relation.charValue];
            return nil;
        }
        // this is an equation
        Equation *eq = [Equation equationWithRelation:_relation.charValue lhs:_lhs rhs:[_expressionStack lastObject]];
        return eq;
    } else {
        if (entityType == kFXEquation) {
            // We wanted an equation but only got an expression
            [self setError:FXParserEquationExpected text:@"You need to enter an equation" index:nil];
            return nil;
        }
        Expression* expr = [_expressionStack lastObject];
        return expr;
    }
}

- (Expression *)parseToExpressionFromMathList:(MTMathList *)mathList
{
    id<MathEntity> entity = [self parseFromMathList:mathList expectedEntityType:kFXExpression];
    if (entity) {
        NSAssert([entity isKindOfClass:[Expression class]], @"Expected an expression for %@", mathList);
        return (Expression*) entity;
    }
    return nil;
}

- (Equation *)parseToEquationFromMathList:(MTMathList *)mathList
{
    id<MathEntity> entity = [self parseFromMathList:mathList expectedEntityType:kFXEquation];
    if (entity) {
        NSAssert([entity isKindOfClass:[Equation class]], @"Expected an equation for %@", mathList);
        return (Equation*) entity;
    }
    return nil;
}

#pragma mark - Handling different Symbols

- (BOOL) handleNumber:(Symbol*) next previous:(Symbol*) previous value:(Rational*) value
{
    if (value == nil) {
        
    }
    if (previous != nil && previous.type == kClosedParen) {
        // insert a multiplication operator
        if (![self handleOperator:[Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:kMultiplication] offset:next.offset]]) {
            return false;
        }
    }
    FXNumber *expr = [FXNumber numberWithValue:value range:[MTMathListRange makeRangeForRange:next.offset]];
    [_expressionStack addObject:expr];
    return true;
}

- (BOOL) handleVariable:(Symbol*) next previous:(Symbol*) previous
{
    if (previous != nil && (previous.type == kNumber || previous.type == kClosedParen || previous.type == kVariable)) {
        // insert a multiplication operator
        if (![self handleOperator:[Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:kMultiplication] offset:next.offset]]) {
            return false;
        }
    }
    FXVariable *expr = [FXVariable variableWithName:next.charValue range:[MTMathListRange makeRangeForRange:next.offset]];
    [_expressionStack addObject:expr];
    return true;
}

- (BOOL) handleOperator:(Symbol *) operator
{
    while ([_operatorStack count] > 0) {
        Symbol *s = [_operatorStack lastObject];
        if (s.type == kOperator && precedence(s.charValue) >= precedence(operator.charValue)) {
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

- (BOOL) handleRelation:(Symbol *) relation
{
    // empty all operators
    if (![self popOperatorStack]) {
        return NO;
    }
    if ([_expressionStack count] == 0) {
        [self setError:FXParserMissingExpression offset:relation.offset.location description:@"Missing left hand side expression"];
        return NO;
    } else if ([_expressionStack count] > 1) {
        Expression *expr = [_expressionStack lastObject];
        [self setError:FXParserMissingOperator text:@"You may be missing a +, - or *" index:expr.range.start];
        return NO;
    } else if (_lhs) {
        // can't have 2 relations in the same equation
        [self setError:FXParserMultipleRelations offset:relation.offset.location description:@"You cannot have a %c here", relation.charValue];
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

- (BOOL) handleOpenParen:(Symbol*) next previous:(Symbol*) previous
{
    if (previous != nil && (previous.type == kNumber || previous.type == kVariable || previous.type == kClosedParen)) {
        // insert a multiplication operator
        if (![self handleOperator:[Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:kMultiplication] offset:next.offset]]) {
            return false;
        }
    }
    [_operatorStack addObject:next];
    return true;
}

- (BOOL) handleCloseParen:(Symbol *)next
{
    BOOL found = NO;
    while ([_operatorStack count] > 0) {
        Symbol *s = [_operatorStack lastObject];
        if (s.type == kOpenParen) {
            [_operatorStack removeLastObject];
            found = YES;
            break;
        } else if (s.type == kOperator) {
            [_operatorStack removeLastObject];
            // error while adding operator
            if (![self addOperatorToExpressionStack:s]) {
                return false;
            }
        }
    }
    
    if (!found) {
        [self setError:FXParserMismatchParens text:@"No matching parenthesis for )" index:[MTMathListIndex level0Index:next.offset.location]];
        return false;
    }
    return true;
}

- (BOOL) handleFraction:(MTFraction*) frac previous:(Symbol*) previous
{
    // same rules as numbers apply
    if (previous != nil && previous.type == kClosedParen) {
        // insert a multiplication operator
        if (![self handleOperator:[Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:kMultiplication] offset:frac.indexRange]]) {
            return false;
        }
    }

    InfixParser *parser = [InfixParser new];
    Expression* numerator = (Expression*) [parser parseFromMathList:frac.numerator expectedEntityType:kFXExpression];
    if (parser.hasError) {
        // Twiddle offsets to be in the numerator
        NSError* error = parser.error;
        MTMathListIndex* fracIndex = [MTMathListIndex indexAtLocation:frac.indexRange.location withSubIndex:[error.userInfo objectForKey:FXParseErrorOffset] type:kMTSubIndexTypeNumerator];
        [self setError:parser.error.code text:error.localizedDescription index:fracIndex];
        return false;
    }
    Expression* denominator = (Expression*)[parser parseFromMathList:frac.denominator expectedEntityType:kFXExpression];
    if (parser.hasError) {
        // Twiddle offsets to be in the denominator
        NSError* error = parser.error;
        MTMathListIndex* fracIndex = [MTMathListIndex indexAtLocation:frac.indexRange.location withSubIndex:[error.userInfo objectForKey:FXParseErrorOffset] type:kMTSubIndexTypeDenominator];
        [self setError:parser.error.code text:error.localizedDescription index:fracIndex];
        return false;
    }
    
    if (numerator.expressionType == kFXNumber && denominator.expressionType == kFXNumber) {
        Rational* n = numerator.expressionValue;
        Rational* d = denominator.expressionValue;
        
        if (n.format == kRationalFormatWhole && d.format == kRationalFormatWhole) {
            // This is a fraction. For whole numbers, denominator is always 1.
            Rational* rat = [Rational rationalWithNumerator:n.numerator denominator:d.numerator];
            // d could be 0 in which case rat is null
            if (!rat) {
                // division by 0
                MTMathListIndex* fracIndex = [MTMathListIndex indexAtLocation:frac.indexRange.location withSubIndex:[MTMathListIndex level0Index:0] type:kMTSubIndexTypeDenominator];
                [self setError:FXParserDivisionByZero text:@"Cannot divide by 0" index:fracIndex];
                return false;
            }
            MTMathListRange* range = [MTMathListRange makeRangeForIndex:frac.indexRange.location];
            if (previous && previous.type == kNumber) {
                // get the last number from the expression stack.
                FXNumber* expr = [_expressionStack lastObject];
                if (expr.expressionType == kFXNumber) {
                    Rational* prev = expr.expressionValue;
                    if (prev.format == kRationalFormatWhole) {
                        // if the previous is a whole number, then this becomes a mixed fraction, so add the fractional part.
                        [_expressionStack removeLastObject];
                        rat = [prev add:rat];
                        range = [range unionRange:expr.range];
                    }
                }
            }
            FXNumber *expr = [FXNumber numberWithValue:rat range:range];
            [_expressionStack addObject:expr];
            return true;
        }
    }
    // not a fraction, so divide
    [_expressionStack addObject:[numerator expressionWithRange:[MTMathListRange makeRangeForIndex:frac.indexRange.location]]];
    // insert a division operator
    if (![self handleOperator:[Symbol symbolWithType:kOperator value:[NSNumber numberWithUnsignedShort:kDivision] offset:frac.indexRange]]) {
        return false;
    }
    [_expressionStack addObject:[denominator expressionWithRange:[MTMathListRange makeRangeForIndex:frac.indexRange.location]]];
    
    return true;   
}

#pragma mark - Operators

- (BOOL) addOperatorToExpressionStack:(Symbol*) operator
{
    // all operators are except _ are binary
    if (operator.charValue == '_' && [_expressionStack count] >= 1) {
        Expression* arg = [_expressionStack lastObject];
        [_expressionStack removeLastObject];
        if (arg.range.start.atomIndex > operator.offset.location) {
            if (arg.expressionType == kFXNumber && [arg.expressionValue isPositive]) {
                // If it is just a -num then make it to a FXNumber
                FXNumber* num = (FXNumber*) arg;
                Rational* value = num.value;
                [_expressionStack addObject:[FXNumber numberWithValue:value.negation range:[MTMathListRange makeRangeForRange:operator.offset]]];
            } else {
                // The argument should come after the operator, otherwise we are missing the argument for the operator
                FXOperator *op = [FXOperator unaryOperatorWithType:operator.charValue arg:arg range:[MTMathListRange makeRangeForRange:operator.offset]];
                [_expressionStack addObject:op];
            }
            return YES;
        }
    } else if ([_expressionStack count] >= 2) {
        Expression* arg2 = [_expressionStack lastObject];
        [_expressionStack removeLastObject];
        Expression* arg1 = [_expressionStack lastObject];
        [_expressionStack removeLastObject];
        if (arg1.range.start.atomIndex > operator.offset.location) {
            // There should have been an operator to combine these two, which is missing
            [self setError:FXParserMissingOperator text:@"You may be missing a +, - or *" index:arg2.range.start];
            return NO;
        } else if (operator.offset.location <= arg2.range.start.atomIndex) {
            // the operator should come in between the 2 arguments, otherwise it is missing arguments.
            FXOperator *op = [FXOperator operatorWithType:operator.charValue args:arg1:arg2];
            [_expressionStack addObject:op];
            return YES;
        }
    }
    // else
    unichar ch = operator.charValue;
    if (ch == kUnaryMinus) {
        // switch the unary minus back to the subtract sign for display.
        ch = kSubtraction;
    }
    [self setError:FXParserNotEnoughArguments
              text:[NSString stringWithFormat:@"Not enough arguments for %C", ch]
             index:[MTMathListIndex level0Index:operator.offset.location]];
    return NO;
}

- (BOOL) popOperatorStack
{
    // all tokens are done
    while ([_operatorStack count] > 0) {
        Symbol *s = [_operatorStack lastObject];
        if (s.type == kOpenParen) {
            [_operatorStack removeLastObject];
            [self setError:FXParserMismatchParens text:@"No matching parenthesis for (" index:[MTMathListIndex level0Index:s.offset.location]];
            return false;
        }  else if (s.type == kOperator) {
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
