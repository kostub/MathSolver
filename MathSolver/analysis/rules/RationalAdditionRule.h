//
//  RationalAdditionRule.h
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "Rule.h"

// Rule for adding rational functions. Does
// a/b + c => (a + b*c) / b
// TODO: Optimize by pulling out the common factors before adding.
@interface RationalAdditionRule : Rule

@end
