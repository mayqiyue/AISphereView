//
//  AIViewController.m
//  AISphereView
//
//  Created by mayqiyue on 02/02/2018.
//  Copyright (c) 2018 mayqiyue. All rights reserved.
//

#import "AIViewController.h"
#import <AISphereView/AISphereView.h>

@interface AIViewController () <AISphereViewDelegate>

@property (nonatomic, strong) AISphereView *sphereView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) NSMutableArray *stack;
@end

@implementation AIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.sphereView];
   
    NSUInteger i = 3 + arc4random() % 10;
    NSMutableArray *views = [NSMutableArray new];
    for (NSUInteger j = 0; j < i; j ++) {
        [views addObject:[self itemViewAtIndex:j]];
    }
    [self.sphereView pushToCenter:[self sphereCenterView] withItems:views];

    [self.view addSubview:self.button];
    self.button.translatesAutoresizingMaskIntoConstraints = false;
    [self.button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    [self.button.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = true;
    [self.button.heightAnchor constraintEqualToConstant:44].active = true;
    [self.button.widthAnchor constraintEqualToConstant:100].active = true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (AISphereView *)sphereView {
    if (!_sphereView) {
        _sphereView = [[AISphereView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width)];
        _sphereView.delegate = self;
        _sphereView.lineColor = [UIColor greenColor];
    }
    return _sphereView;
}

- (UIView *)sphereCenterView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 76, 76)];
    view.backgroundColor = [UIColor blueColor];
    view.layer.cornerRadius = 38;
    return view;
}

- (UIView *)itemViewAtIndex:(NSUInteger)index {
    UILabel *view = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    view.backgroundColor = [UIColor colorWithRed:arc4random()%255 / 255.0 green:arc4random()%255 / 255.0 blue:arc4random()%255 / 255.0 alpha:1];
    view.layer.cornerRadius = 50;
    view.clipsToBounds = true;
    view.text = @(index).stringValue;
    return view;
}

#pragma mark - SphereView delegate

- (void)sphereView:(AISphereView *)sphereView didSelectItem:(UIView *)view {
    NSUInteger i = 3 + arc4random() % 10;
    NSMutableArray *views = [NSMutableArray new];
    for (NSUInteger j = 0; j < i; j ++) {
        [views addObject:[self itemViewAtIndex:j]];
    }
    [self.stack addObject:@(self.sphereView.items.count)];
    [self.sphereView pushToCenter:view withItems:views];
}

- (void)sphereView:(AISphereView *)sphereView pushAnimationCompletion:(BOOL)finished {
}

- (void)sphereView:(AISphereView *)sphereView popAnimationCompletion:(BOOL)finished {
    [self.stack removeLastObject];
//    self.button.userInteractionEnabled = sphereView.stackDepth > 0;
    [self.button setTitle:sphereView.stackDepth > 0 ? @"isInTop" : @"Back" forState:UIControlStateNormal];
}

#pragma mark -

- (void)buttonAction:(id)sender {
    NSUInteger i = [self.stack.lastObject unsignedIntegerValue];
    NSMutableArray *views = [NSMutableArray new];
    for (NSUInteger j = 0; j < i; j ++) {
        UIView *view = [self itemViewAtIndex:j];
        [views addObject:view];
    }
    [self.sphereView popToCenter:[self sphereCenterView] withItems:views];
}

- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_button setTitle:@"Back" forState:UIControlStateNormal];
        [_button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    return _button;
}

- (NSMutableArray *)stack {
    if (!_stack) {
        _stack = [[NSMutableArray alloc] init];
    }
    return _stack;
}
@end

