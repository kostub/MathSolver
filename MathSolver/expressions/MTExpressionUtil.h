//
//  ExpressionUtil.h
//
//  Created by Kostub Deshmukh on 7/29/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "MTExpression.h"

// Utility functions for modifing expressions.
@interface MTExpressionUtil : NSObject

// Negate an expression by multiplying it by -1
+ (MTOperator*) negate:(MTExpression*) expr;

// Convert a variable to an operator by multiplying it by 1
+ (MTOperator*) toOperator:(MTExpression*) var;

// Returns true if the expression is of the form Nxyz, N is returned as the coefficient, x,y,z are returned as variables.
// If the expression is not of the required form return false. The returned variables are sorted by name.
// Either argument could be nil
+ (BOOL) expression: (MTExpression*) oper getCoefficent:(MTRational**) c variables:(NSArray**) vars;
// Returns true if the expression is of the form Nxyz, returns |N|xyz by stripping away the -ve sign from N if any.
// If the expression is not of the required form return the original expression.
+ (MTExpression*) absoluteValue:(MTExpression*) expr;
// Formats an expression of the form Nxyz as Nxyz. If the expression is not of the required form, return nil.
+ (NSString*) formatAsString:(MTExpression*) expr;

// Returns true if expr is equivalent to other after doing top level calculations.
+ (BOOL) isEquivalentUptoCalculation:(MTExpression*) expr toExpression:(MTExpression*) other;

// Finds an expression in the given array which is equivalent (upto calculation) to expr.
+ (MTExpression*) getExpressionEquivalentTo:(MTExpression*) expr in:(NSArray*) array;

+ (BOOL) isEquivalentUptoCalculationAndRearrangement:(NSArray*) array1 :(NSArray*) array2;

// Find the difference between the children of two operators. Returns true if there is a difference. Note: This only makes sense for operators with the same type, if this function
// is called with operators of different types, then it returns true with removedChildren and addedChildren as nil.
// removedChildren and addedChildren could be nil and in that case the children are not returned.
+ (BOOL) diffOperator:(MTOperator*) first with:(MTOperator*) second removedChildren:(NSArray**) removedChildren addedChildren:(NSArray**) addedChildren;

// Returns true if expr is a subset of oper, i.e. if expr is a child of oper or all children of expr are children of
// oper. Returns true only for proper subsets. If difference is not nil, the set difference is returned in difference.
+ (BOOL) isExpression:(MTExpression*) expr subsetOf:(MTOperator*) oper difference:(NSArray**) difference;

// Get the identity for the given operator.
+ (MTNumber*) getIdentity:(char) operatorType;

// Get an expression combining the expressions with the given operator. If there are no exprs, then this returns the identity for the operator.
// If there is only one expr, then that is returned for the expression.
+ (MTExpression*) combineExpressions:(NSArray*) exprs withOperatorType:(char) operatorType;

// Return a set of all the variables in the expression
+ (NSSet*) getVariablesInExpression:(MTExpression*) expr;

// Returns true if expression expr contains the variable var.
+ (BOOL) expression:(MTExpression*)expr containsVariable:(MTVariable*) var;

// Get the leading term for an expression in normal form.
+ (MTExpression*) getLeadingTerm:(MTExpression*) expr;

// Check whether the expression is a given operator
+ (BOOL) isDivision:(MTExpression*) expr;
+ (BOOL) isMultiplication:(MTExpression*) expr;
+ (BOOL) isAddition:(MTExpression*) expr;

@end
