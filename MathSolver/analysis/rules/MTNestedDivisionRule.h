//
//  NestedDivisionRule.h
//
//  Created by Kostub Deshmukh on 7/16/14.
//  Copyright (c) 2014 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTRule.h"

// If there is a division inside a division, this converts the second division to a multiplication
// e.g. (a/b) / c => a / (b*c)
// and  a / (b/c) => (a*c) / b
@interface MTNestedDivisionRule : MTRule

@end
