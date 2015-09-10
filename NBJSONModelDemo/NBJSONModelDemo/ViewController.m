//
//  ViewController.m
//  NBJSONModelDemo
//
//  Created by NOVA8OSSA on 15/7/29.
//  Copyright (c) 2015年 NB. All rights reserved.
//

#import "ViewController.h"
#import "NBPerson.h"

@interface ViewController () {
    
    NBPerson *adam;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSDictionary *dict = @{@"name": @"adam",
                           @"spouse": @{@"name": [NSNull null],
                                        @"spouse": @"adam",
                                        @"age": [NSNull null],
                                        @"kids": @[@{@"name": @"Cain", @"spouse": @"unknow", @"age": @(6), @"kids": @[]},
                                                   @{@"name": @"Abel", @"spouse": @"unknow", @"age": @(7), @"kids": @[]},
                                                   @{@"name": @"Seth", @"spouse": @"unknow", @"age": @(8), @"kids": @[]}]},
                           
                           @"age": @(930),
                           @"kids": @[@{@"name": @"Cain", @"spouse": @"unknow", @"age": @(6), @"kids": @[]},
                                      @{@"name": @"Abel", @"spouse": @"unknow", @"age": @(7), @"kids": @[]},
                                      @{@"name": @"Seth", @"spouse": @"unknow", @"age": @(8), @"kids": @[]}]};
    adam = [[NBPerson alloc] initWithJSONDict:dict];
    NSLog(@"%@", [adam jsonDict]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
