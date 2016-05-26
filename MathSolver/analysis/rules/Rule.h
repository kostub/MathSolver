//
//  Rule.h
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

@class Expression;

@interface Rule : NSObject

// create a rule
+ (instancetype) rule;

// Does a recursive post-order traversal of the expression, applying the rule.
- (Expression*) apply:(Expression*) expr;

// Apply the rule only to the top level node. Subclasses need to implement this method. The children already have the rule applied to them.
- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray*) args;

// Apply the rule to the inner most level. Only make one application if onlyFirst is true.
- (Expression*) applyInnerMost:(Expression *)expr onlyFirst:(BOOL) onlyFirst;

@end
