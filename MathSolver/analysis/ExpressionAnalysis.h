//
//  ExpressionAnalysis.h
//
//  Created by Kostub Deshmukh on 6/6/15.
//  Copyright (c) 2015 MathChat, Inc.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.

#import <Foundation/Foundation.h>

#import "ExpressonInfo.h"

@interface ExpressionAnalysis : NSObject

+ (BOOL)hasCheckableAnswer:(ExpressionInfo*) start;

+ (BOOL) isExpressionFinalStep:(ExpressionInfo*) expressionInfo forEntityType:(MathEntityType) originalEntityType;

@end
