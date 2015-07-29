//
//  NBJSONModel.m
//  NBJSONModel
//
//  Created by NOVA8OSSA on 15/7/29.
//  Copyright (c) 2015年 NB. All rights reserved.
//

#import <objc/runtime.h>
#import "NBJSONModel.h"

#pragma mark - NBModelPropertyType

@interface NBModelPropertyType : NSObject

@property (nonatomic, copy) NSString *propertyName;
@property (nonatomic, strong) Class propertyClass;

- (instancetype)initWithName:(NSString *)name propertyAttributes:(NSString *)attributes;

@end

@implementation NBModelPropertyType

- (instancetype)initWithName:(NSString *)name propertyAttributes:(NSString *)attributes {
    
    self = [super init];
    if (self) {
        _propertyName = [name copy];
        
        NSString *typeInfo = [[attributes componentsSeparatedByString:@","] firstObject];
        typeInfo = [typeInfo substringWithRange:NSMakeRange(3, typeInfo.length - 4)];
        
        NSRange range = [typeInfo rangeOfString:@"<"];
        if (range.location != NSNotFound) {
            
            NSString *protocolName = [typeInfo substringFromIndex:range.location + 1];
            range = [protocolName rangeOfString:@">"];
            if (range.location != NSNotFound) {
                protocolName = [protocolName substringToIndex:range.location];
            }
            _propertyClass = NSClassFromString(protocolName);
        }else{
            _propertyClass = NSClassFromString(typeInfo);
        }
    }
    return self;
}

@end

#pragma mark - NSArray+NBJSONModel

@interface NSArray (NBJSONModel)

- (instancetype)arrayWithModelClass:(Class)modelClass;

@end

@implementation NSArray (NBJSONModel)

- (instancetype)arrayWithModelClass:(Class)modelClass {
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        if ([obj isKindOfClass:[NSArray class]]) {
            
            [array addObject:[obj arrayWithModelClass:modelClass]];
        }else if ([obj isKindOfClass:[NSDictionary class]]) {
            
            BOOL isModelClass = [modelClass isSubclassOfClass:[NBJSONModel class]];
            [array addObject:isModelClass ? [[modelClass alloc] initWithJSONDict:obj] : obj];
        }else{
            [array addObject:obj];
        }
    }
    return array;
}

@end

#pragma mark - NBJSONModel

static char NBCachedPropertyMapKey;

@implementation NBJSONModel

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self cachingProperties];
    }
    return self;
}
    
- (instancetype)initWithJSONDict:(NSDictionary *)dict {
    
    self = [self init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)cachingProperties {
    
    if ([self isKindOfClass:[NBJSONModel class]] && !objc_getAssociatedObject(self.class, &NBCachedPropertyMapKey)) {
        
        unsigned int count;
        objc_property_t *properties = class_copyPropertyList([self class], &count);
        NSMutableDictionary *propertyMap = [NSMutableDictionary dictionary];
        for (int i = 0; i < count; i++) {
            
            objc_property_t property = properties[i];
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
            NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
            
            // 只需要记录对象类型 T@"NSArray<NBJSONModel><...>"
            if ([propertyAttributes hasPrefix:@"T@"]) {
                NBModelPropertyType *propertyType = [[NBModelPropertyType alloc] initWithName:propertyName
                                                                           propertyAttributes:propertyAttributes];
                NSDictionary *keyMapper = [(NBJSONModel *)self jsonModelKeyMapper];
                NSString *jsonKey = [keyMapper objectForKey:propertyName];
                [propertyMap setObject:propertyType forKey:jsonKey ?: propertyName];
            }
        }
        objc_setAssociatedObject(self.class, &NBCachedPropertyMapKey, propertyMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (NSDictionary *)jsonModelKeyMapper {
    
    return @{};
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    NSDictionary *propertyMap = objc_getAssociatedObject(self.class, &NBCachedPropertyMapKey);
    NSString *propertyName = [[self jsonModelKeyMapper] objectForKey:key];
    propertyName = propertyName ?: key;
    NBModelPropertyType *propertyType = [propertyMap objectForKey:propertyName];
    Class class = propertyType.propertyClass;
    
    id objToSet = value;
    if ([value isKindOfClass:[NSArray class]] && class) {
        objToSet = [value arrayWithModelClass:propertyType.propertyClass];
    }else if ([value isKindOfClass:[NSDictionary class]] && class) {
        objToSet = [class isSubclassOfClass:[NBJSONModel class]] ? [[class alloc] initWithJSONDict:value] : value;
    }
    
    [super setValue:objToSet forKey:propertyName];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
    //NSLog(@"you missed json key -> %@", key);
}

- (void)setNilValueForKey:(NSString *)key {
    
    [self setValue:@(0) forKey:key];
    
    //NSLog(@"scalar property given a nil value");
}

@end
