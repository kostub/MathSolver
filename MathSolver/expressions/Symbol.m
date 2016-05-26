//
//  Symbol.m
//
//  Created by Kostub Deshmukh on 7/14/13.
//  Copyright (c) 2013 Math FX.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "Symbol.h"


@interface Symbol ()

@property (nonatomic) enum Type type;
@property (nonatomic) NSNumber* value;
@property (nonatomic) NSRange offset;

@end

@implementation Symbol

+ (id) symbolWithType:(enum Type)type value:(NSNumber *)value offset:(NSRange)offset
{
    Symbol *sym = [[Symbol alloc] init];
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
