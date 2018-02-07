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
    [self.sphereView animateToCenter:[self sphereCenterView] withItems:views];

    [self.view addSubview:self.button];
    self.button.translatesAutoresizingMaskIntoConstraints = false;
    [self.button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    [self.button.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = true;
    [self.button.heightAnchor constraintEqualToConstant:44].active = true;
    [self.button.widthAnchor constraintEqualToConstant:100].active = true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (AISphereView *)sphereView {
    if (!_sphereView) {
        _sphereView = [[AISphereView alloc] initWithFrame:CGRectMake(0, 100, 375, 375)];
        _sphereView.delegate = self;
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
    view.backgroundColor = [UIColor redColor];
    view.layer.cornerRadius = 50;
    view.clipsToBounds = true;
    view.text = @(index).stringValue;
    return view;
}

- (void)sphereView:(AISphereView *)sphereView didSelectItem:(UIView *)view {
    NSUInteger i = 3 + arc4random() % 10;
    NSMutableArray *views = [NSMutableArray new];
    for (NSUInteger j = 0; j < i; j ++) {
        [views addObject:[self itemViewAtIndex:j]];
    }
    [self.sphereView animateToCenter:view withItems:views];
}

- (void)buttonAction:(id)sender {
    NSUInteger i = 3 + arc4random() % 10;
    NSMutableArray *views = [NSMutableArray new];
    for (NSUInteger j = 0; j < i; j ++) {
        [views addObject:[self itemViewAtIndex:j]];
    }
    [self.sphereView animateToCenter:[self sphereCenterView] withItems:views];
}

- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_button setTitle:@"RESET" forState:UIControlStateNormal];
        [_button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    return _button;
}
@end

