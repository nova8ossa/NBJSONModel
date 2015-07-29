//
//  NBPerson.h
//  TestJSONModel
//
//  Created by NOVA8OSSA on 15/7/29.
//  Copyright (c) 2015年 NB. All rights reserved.
//

#import "NBJSONModel.h"

@protocol NBPerson <NSObject>

@end

@interface NBPerson : NBJSONModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, strong) NBPerson *spouse;
@property (nonatomic, strong) NSArray<NBPerson> *children;

@end
