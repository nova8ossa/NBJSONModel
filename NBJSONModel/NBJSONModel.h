//
//  NBJSONModel.h
//  NBJSONModel
//
//  Created by NOVA8OSSA on 15/7/29.
//  Copyright (c) 2015年 NB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBJSONModel : NSObject <NSCoding>

- (instancetype)initWithJSONDict:(NSDictionary *)dict;

- (NSDictionary *)jsonDict;

- (NSDictionary *)modelJSONKeyMapper;

@end
