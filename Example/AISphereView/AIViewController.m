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

@end

@implementation AIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.sphereView];
    [self.sphereView reloadData];
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
    return CGSizeMake(100, 100);
}

- (CGSize)sphereView:(AISphereView *)sphereView sizeForItemViewAtIndex:(NSUInteger)index {
    return CGSizeMake(76, 76);
}

- (UIView *)sphereCenterView {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor blueColor];
    return view;
}

- (NSUInteger)numberOfSphereItemViews {
    return 10;
}

- (UIView *)sphereView:(AISphereView *)sphereView itemViewAtIndex:(NSUInteger)index {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor redColor];
    return view;
}

- (void)sphereView:(AISphereView *)sphereView didSelectItem:(UIView *)view {
    [UIView animateWithDuration:0.3 animations:^{
        view.transform = CGAffineTransformMakeScale(2., 2.);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            view.transform = CGAffineTransformMakeScale(1., 1.);
        } completion:^(BOOL finished) {
        }];
    }];
}

@end

