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
#import "Expression.h"

// Utility functions for modifing expressions.
@interface ExpressionUtil : NSObject

// Negate an expression by multiplying it by -1
+ (FXOperator*) negate:(Expression*) expr;

// Convert a variable to an operator by multiplying it by 1
+ (FXOperator*) toOperator:(Expression*) var;

// Returns true if the expression is of the form Nxyz, N is returned as the coefficient, x,y,z are returned as variables.
// If the expression is not of the required form return false. The returned variables are sorted by name.
// Either argument could be nil
+ (BOOL) expression: (Expression*) oper getCoefficent:(Rational**) c variables:(NSArray**) vars;
// Returns true if the expression is of the form Nxyz, returns |N|xyz by stripping away the -ve sign from N if any.
// If the expression is not of the required form return the original expression.
+ (Expression*) absoluteValue:(Expression*) expr;
// Formats an expression of the form Nxyz as Nxyz. If the expression is not of the required form, return nil.
+ (NSString*) formatAsString:(Expression*) expr;

// Returns true if expr is equivalent to other after doing top level calculations.
+ (BOOL) isEquivalentUptoCalculation:(Expression*) expr toExpression:(Expression*) other;

// Finds an expression in the given array which is equivalent (upto calculation) to expr.
+ (Expression*) getExpressionEquivalentTo:(Expression*) expr in:(NSArray*) array;

+ (BOOL) isEquivalentUptoCalculationAndRearrangement:(NSArray*) array1 :(NSArray*) array2;

// Find the difference between the children of two operators. Returns true if there is a difference. Note: This only makes sense for operators with the same type, if this function
// is called with operators of different types, then it returns true with removedChildren and addedChildren as nil.
// removedChildren and addedChildren could be nil and in that case the children are not returned.
+ (BOOL) diffOperator:(FXOperator*) first with:(FXOperator*) second removedChildren:(NSArray**) removedChildren addedChildren:(NSArray**) addedChildren;

// Returns true if expr is a subset of oper, i.e. if expr is a child of oper or all children of expr are children of
// oper. Returns true only for proper subsets. If difference is not nil, the set difference is returned in difference.
+ (BOOL) isExpression:(Expression*) expr subsetOf:(FXOperator*) oper difference:(NSArray**) difference;

// Get the identity for the given operator.
+ (FXNumber*) getIdentity:(char) operatorType;

// Get an expression combining the expressions with the given operator. If there are no exprs, then this returns the identity for the operator.
// If there is only one expr, then that is returned for the expression.
+ (Expression*) combineExpressions:(NSArray*) exprs withOperatorType:(char) operatorType;

// Return a set of all the variables in the expression
+ (NSSet*) getVariablesInExpression:(Expression*) expr;

// Returns true if expression expr contains the variable var.
+ (BOOL) expression:(Expression*)expr containsVariable:(FXVariable*) var;

// Get the leading term for an expression in normal form.
+ (Expression*) getLeadingTerm:(Expression*) expr;

// Check whether the expression is a given operator
+ (BOOL) isDivision:(Expression*) expr;
+ (BOOL) isMultiplication:(Expression*) expr;
+ (BOOL) isAddition:(Expression*) expr;

@end
