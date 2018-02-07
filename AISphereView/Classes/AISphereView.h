//
//  AISphereView.h
//  AISphereView
//
//  Created by Mayqiyue on 02/02/2018.
//

#import <UIKit/UIKit.h>

@class AISphereView;

@protocol AISphereViewDataSource <NSObject>

- (CGSize)sizeOfSphereCenterView;
- (UIView *)sphereCenterView;
- (NSUInteger)numberOfSphereItemViews;
- (UIView *)sphereView:(AISphereView *)sphereView itemViewAtIndex:(NSUInteger)index;
- (CGSize)sphereView:(AISphereView *)sphereView sizeForItemViewAtIndex:(NSUInteger)index;

@end

@protocol AISphereViewDelegate <NSObject>

@optional
- (void)sphereView:(AISphereView *)sphereView didSelectItem:(UIView *)view;

@end

@interface AISphereView : UIView

@property (nonatomic, weak  ) id<AISphereViewDataSource> dataSource;
@property (nonatomic, weak  ) id<AISphereViewDelegate> delegate;

- (void)reloadData;

- (void)animateSphereItemViewToCenter:(UIView *)view;

@end
