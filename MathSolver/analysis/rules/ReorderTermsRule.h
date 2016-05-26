//
//  ReorderTermsRule.h
//
//  Created by Kostub Deshmukh on 7/21/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "Rule.h"

// Reorder the terms in descending order of degree and then by lexicographic order.
// This should only be used for one level deep trees. The results for multilevel expression trees are not guaranteed to be what you expect.
@interface ReorderTermsRule : Rule

- (Expression*) applyToTopLevelNode:(Expression *)expr withChildren:(NSArray *)args;

@end
