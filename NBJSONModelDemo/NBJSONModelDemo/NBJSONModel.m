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
@property (nonatomic, copy) NSString *jsonName;
@property (nonatomic, copy) NSString *className;

- (instancetype)initWithAttributes:(NSString *)attributes;

@end

@implementation NBModelPropertyType

- (instancetype)initWithAttributes:(NSString *)attributes {
    
    self = [super init];
    if (self) {
        
        NSString *typeInfo = [[attributes componentsSeparatedByString:@","] firstObject];
        if ([typeInfo hasPrefix:@"T@"]) {
            typeInfo = [typeInfo substringWithRange:NSMakeRange(3, typeInfo.length - 4)];
            
            NSRange range = [typeInfo rangeOfString:@"<"];
            if (range.location != NSNotFound) {
                
                NSString *protocolName = [typeInfo substringFromIndex:range.location + 1];
                range = [protocolName rangeOfString:@">"];
                if (range.location != NSNotFound) {
                    protocolName = [protocolName substringToIndex:range.location];
                }
                _className = [protocolName copy];
            }else{
                _className = [typeInfo copy];
            }
        }else{
            _className = [typeInfo copy];
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
        
        Class class = [self class];
        NSMutableDictionary *propertyMap = [NSMutableDictionary dictionary];
        while (class != [NBJSONModel class]) {
            
            unsigned int count;
            objc_property_t *properties = class_copyPropertyList(class, &count);
            NSDictionary *keyMapper = [(NBJSONModel *)self modelJSONKeyMapper];
            for (int i = 0; i < count; i++) {
                
                objc_property_t property = properties[i];
                NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
                NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
                
                NBModelPropertyType *propertyType = [[NBModelPropertyType alloc] initWithAttributes:propertyAttributes];
                propertyType.propertyName = propertyName;
                propertyType.jsonName = [keyMapper objectForKey:propertyName] ?: propertyName;
                [propertyMap setObject:propertyType forKey:propertyType.jsonName];
            }
            free(properties);
            class = [class superclass];
        }
        objc_setAssociatedObject(self.class, &NBCachedPropertyMapKey, propertyMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (NSDictionary *)jsonDict {
    
    NSDictionary *propertyMap = objc_getAssociatedObject(self.class, &NBCachedPropertyMapKey);
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *property in propertyMap) {
        
        NBModelPropertyType *propertyType = [propertyMap objectForKey:property];
        id obj = [self valueForKey:propertyType.propertyName];
        
        if ([obj isKindOfClass:[NBJSONModel class]]) {
            
            [dict setObject:[obj jsonDict] forKey:propertyType.jsonName];
        }else if ([obj isKindOfClass:[NSArray class]] && [NSClassFromString(propertyType.className) isSubclassOfClass:[NBJSONModel class]]) {
            
            NSArray *items = (NSArray *)obj;
            NSMutableArray *jsonList = [NSMutableArray array];
            for (id item in items) {
                [jsonList addObject:[item jsonDict]];
            }
            [dict setObject:jsonList forKey:propertyType.jsonName];
        }else {
            if (obj) {
                [dict setValue:obj forKey:propertyType.jsonName];
            }
        }
    }
    
    return dict;
}


- (NSDictionary *)modelJSONKeyMapper {
    
    return @{};
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    NSDictionary *propertyMap = objc_getAssociatedObject(self.class, &NBCachedPropertyMapKey);
    NBModelPropertyType *propertyType = [propertyMap objectForKey:key];
    NSString *propertyName = propertyType.propertyName;
    Class class = NSClassFromString(propertyType.className);
    
    id objToSet = value;
    if ([value isKindOfClass:[NSArray class]] && class) {
        
        objToSet = [value arrayWithModelClass:class];
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
