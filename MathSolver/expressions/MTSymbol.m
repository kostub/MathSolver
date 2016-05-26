//
//  Symbol.m
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTSymbol.h"


@interface MTSymbol ()

@property (nonatomic) enum MTSymbolType type;
@property (nonatomic) NSNumber* value;
@property (nonatomic) NSRange offset;

@end

@implementation MTSymbol

+ (id) symbolWithType:(enum MTSymbolType)type value:(NSNumber *)value offset:(NSRange)offset
{
    MTSymbol *sym = [[MTSymbol alloc] init];
    sym.type = type;
    sym.value = value;
    sym.offset = offset;
    return sym;
}

- (unichar) charValue
{
    return [self.value unsignedShortValue];
}

- (unsigned int) intValue
{
    return [self.value unsignedIntValue];
}

@end
