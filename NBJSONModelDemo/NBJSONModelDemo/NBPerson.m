//
//  NBPerson.m
//  TestJSONModel
//
//  Created by NOVA8OSSA on 15/7/29.
//  Copyright (c) 2015年 NB. All rights reserved.
//

#import "NBPerson.h"

@implementation NBPerson

- (NSDictionary *)jsonModelKeyMapper {
    
    return @{@"kids": @"children"};
}

@end
