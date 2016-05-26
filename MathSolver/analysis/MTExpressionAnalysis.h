//
//  ExpressionAnalysis.h
//
//  Created by Kostub Deshmukh on 6/6/15.
//  Copyright (c) 2015 MathChat, Inc.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.

#import <Foundation/Foundation.h>

#import "MTExpressionInfo.h"

@interface MTExpressionAnalysis : NSObject

+ (BOOL)hasCheckableAnswer:(MTExpressionInfo*) start;

+ (BOOL) isExpressionFinalStep:(MTExpressionInfo*) expressionInfo forEntityType:(MTMathEntityType) originalEntityType;

@end
