//
//  AIViewController.m
//  AISphereView
//
//  Created by mayqiyue on 02/02/2018.
//  Copyright (c) 2018 mayqiyue. All rights reserved.
//

#import "AIViewController.h"
#import <AISphereView/AISphereView.h>

@interface AIViewController () <AISphereViewDataSource, AISphereViewDelegate>

@property (nonatomic, strong) AISphereView *sphereView;
@property (nonatomic, strong) UIButton *button;

@end

@implementation AIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.sphereView];
    [self.sphereView reloadData];
    
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
        _sphereView.dataSource = self;
        _sphereView.delegate = self;
    }
    return _sphereView;
}

- (CGSize)sizeOfSphereCenterView {
    return CGSizeMake(76, 76);
}

- (CGSize)sphereView:(AISphereView *)sphereView sizeForItemViewAtIndex:(NSUInteger)index {
    return CGSizeMake(100, 100);
}

- (UIView *)sphereCenterView {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor blueColor];
    view.layer.cornerRadius = 38;
    return view;
}

- (NSUInteger)numberOfSphereItemViews {
    return 10;
}

- (UIView *)sphereView:(AISphereView *)sphereView itemViewAtIndex:(NSUInteger)index {
    UILabel *view = [UILabel new];
    view.backgroundColor = [UIColor redColor];
    view.layer.cornerRadius = 50;
    view.clipsToBounds = true;
    view.text = @(index).stringValue;
    return view;
}

- (void)sphereView:(AISphereView *)sphereView didSelectItem:(UIView *)view {
    [self.sphereView animateSphereItemViewToCenter:view];
}

- (void)buttonAction:(id)sender {
    [self.sphereView reloadData];
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

