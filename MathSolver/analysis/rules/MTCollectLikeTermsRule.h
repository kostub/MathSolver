//
//  CollectLikeTermsRule.h
//
//  Created by Kostub Deshmukh on 7/19/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTRule.h"
#import "MTExpression.h"

// Collects all terms with the same variables together and adds their coefficients.
@interface MTCollectLikeTermsRule : MTRule

- (MTExpression*) applyToTopLevelNode:(MTExpression *)expr withChildren:(NSArray *)args;

@end
