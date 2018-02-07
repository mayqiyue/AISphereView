//
//  AISphereView.m
//  AISphereView
//
//  Created by Mayqiyue on 02/02/2018.
//

#import "AISphereView.h"
#import "AIMatrix.h"

@interface AISphereView ()
{
    NSMutableArray <UIView *>*items;
    NSMutableArray <CAShapeLayer *>*lines;
    NSMutableArray *coordinate;
    AIPoint normalDirection;
    CGPoint last;
   
    CGFloat velocity;
   
    UIView *centerView;
    UIView *lineContentView;
    
    UITapGestureRecognizer *tapGesture;
    UIPanGestureRecognizer *panGesture;
    
    CADisplayLink *timer;
    CADisplayLink *inertia;
}

@end

@implementation AISphereView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tapGesture];
    
    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGesture];

    inertia = [CADisplayLink displayLinkWithTarget:self selector:@selector(inertiaStep)];
    [inertia addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoTurnRotation)];
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)reloadData
{
    if (![self ifDataSourceValid]) {
        return;
    }
    
    [lineContentView removeFromSuperview];
    [items makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [centerView removeFromSuperview];

    lineContentView = [UIView new];
    lineContentView.frame = self.bounds;
    [self addSubview:lineContentView];
    
    items = [[NSMutableArray alloc] init];
    lines = [[NSMutableArray alloc] init];
    coordinate = [[NSMutableArray alloc] init];
    
    NSUInteger count = [self.dataSource numberOfSphereItemViews];
    for (NSUInteger i = 0; i < count; i ++) {
        CAShapeLayer *line = [CAShapeLayer layer];
        line.frame = self.bounds;
        line.opacity = 0.0;
        [lines addObject:line];
        [lineContentView.layer addSublayer:line];
        
        UIView *view = [self.dataSource sphereView:self itemViewAtIndex:i];
        CGSize size = [self.dataSource sphereView:self sizeForItemViewAtIndex:i];
        view.frame = CGRectMake(0, 0, size.width, size.height);
        view.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
        [items addObject:view];
        [self addSubview:view];
    }
    
    UIView *view = [self.dataSource sphereCenterView];
    CGSize size = [self.dataSource sizeOfSphereCenterView];
    view.frame = CGRectMake(0, 0, size.width, size.height);
    view.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
    [self insertSubview:view aboveSubview:lineContentView];
    centerView = view;

    CGFloat p1 = M_PI * (3 - sqrt(5));
    CGFloat p2 = 2. / items.count;
    
    for (NSInteger i = 0; i < items.count; i ++) {
        CGFloat y = i * p2 - 1 + (p2 / 2);
        CGFloat r = sqrt(1 - y * y);
        CGFloat p3 = i * p1;
        CGFloat x = cos(p3) * r;
        CGFloat z = sin(p3) * r;
        
        
        AIPoint point = AIPointMake(x, y, z);
        NSValue *value = [NSValue value:&point withObjCType:@encode(AIPoint)];
        [coordinate addObject:value];
        
    }
    
    [UIView animateWithDuration:0.25 delay:0. options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self setTagOfPoint:point andIndex:i];
    } completion:^(BOOL finished) {
    }];
    
    NSInteger a =  arc4random() % 10 - 5;
    NSInteger b =  arc4random() % 10 - 5;
    normalDirection = AIPointMake(a, b, 0);
    [self timerStart];
}

- (void)animateSphereItemViewToCenter:(UIView *)itemView
{
    [self timerStop];
    panGesture.enabled = false;

    CGFloat x = centerView.center.x - itemView.center.x;
    CGFloat y = centerView.center.y - itemView.center.y;
    CGFloat s = centerView.frame.size.width / itemView.frame.size.width;
    
    NSMutableArray *array = [NSMutableArray new];
    [array addObjectsFromArray:items];
    [array addObject:lineContentView];
    [array removeObject:itemView];
    
    [UIView animateWithDuration:0.3 animations:^{
        itemView.center = centerView.center;
        itemView.transform = CGAffineTransformScale(itemView.transform, s, s);
    } completion:^(BOOL finished) {
        panGesture.enabled = true;
        [self reloadData];
    }];
    
    [UIView animateWithDuration:0.25 animations:^{
        for (UIView *v in array) {
            v.alpha = 0.0;
            v.center = CGPointMake(v.center.x + x/3.0, v.center.y + y/2.0f);
            v.transform = CGAffineTransformScale(v.transform, 1.0/s, 1.0/s);
        }
    } completion:^(BOOL finished) {
    }];
}

#pragma mark - set frame of point

- (void)updateFrameOfPoint:(NSInteger)index direction:(AIPoint)direction andAngle:(CGFloat)angle
{
    NSValue *value = [coordinate objectAtIndex:index];
    AIPoint point;
    [value getValue:&point];
    
    AIPoint rPoint = AIPointMakeRotation(point, direction, angle);
    value = [NSValue value:&rPoint withObjCType:@encode(AIPoint)];
    coordinate[index] = value;
    
    [self setTagOfPoint:rPoint andIndex:index];
}

- (void)setTagOfPoint:(AIPoint)point andIndex:(NSInteger)index
{
    UIView *view = [items objectAtIndex:index];
    view.center = CGPointMake((point.x + 1) * (self.frame.size.width / 2.), (point.y + 1) * self.frame.size.width / 2.);
    
    CGFloat transform = (point.z + 2) / 3;
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, transform, transform);
    view.layer.zPosition = transform;
    view.alpha = transform;
    view.userInteractionEnabled = NO;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f)];
    [path addLineToPoint:view.center];
    
    CAShapeLayer *line = [lines objectAtIndex:index];
    line.path = path.CGPath;
    line.fillColor = [UIColor clearColor].CGColor;
    line.strokeColor = [UIColor redColor].CGColor;
    line.lineWidth = 2.0;
    line.opacity = transform;
    [line setNeedsDisplay];
}

#pragma mark - autoTurnRotation

- (void)timerStart
{
    timer.paused = NO;
}

- (void)timerStop
{
    timer.paused = YES;
}

- (void)autoTurnRotation
{
    for (NSInteger i = 0; i < items.count; i ++) {
        [self updateFrameOfPoint:i direction:normalDirection andAngle:0.002];
    }
    
}

#pragma mark - inertia

- (void)inertiaStart
{
    [self timerStop];
    inertia.paused = NO;
}

- (void)inertiaStop
{
    [self timerStart];
    inertia.paused = YES;
}

- (void)inertiaStep
{
    if (velocity <= 0) {
        [self inertiaStop];
    }else {
        velocity -= 70.;
        CGFloat angle = velocity / self.frame.size.width * 2. * inertia.duration;
        for (NSInteger i = 0; i < items.count; i ++) {
            [self updateFrameOfPoint:i direction:normalDirection andAngle:angle];
        }
    }
    
}

#pragma mark - gesture selector

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture
{
    CGPoint current = [gesture locationInView:self];
    for (UIView *view in items) {
        if (CGRectContainsPoint(view.frame, current)) {
            if ([self.delegate respondsToSelector:@selector(sphereView:didSelectItem:)]) {
                [self.delegate sphereView:self didSelectItem:view];
            }
            break;
        }
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        last = [gesture locationInView:self];
        [self timerStop];
        [self inertiaStop];
        
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint current = [gesture locationInView:self];
        AIPoint direction = AIPointMake(last.y - current.y, current.x - last.x, 0);
        
        CGFloat distance = sqrt(direction.x * direction.x + direction.y * direction.y);
        
        CGFloat angle = distance / (self.frame.size.width / 2.);
        
        for (NSInteger i = 0; i < items.count; i ++) {
            [self updateFrameOfPoint:i direction:direction andAngle:angle];
        }
        normalDirection = direction;
        last = current;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocityP = [gesture velocityInView:self];
        velocity = sqrt(velocityP.x * velocityP.x + velocityP.y * velocityP.y);
        [self inertiaStart];
        
    }
}

#pragma mark -

- (BOOL)ifDataSourceValid
{
    if (![self.dataSource respondsToSelector:@selector(numberOfSphereItemViews)]) {
        NSAssert(0, @"numberOfSphereItemViews not implemented");
        return false;
    }
    if (![self.dataSource respondsToSelector:@selector(sphereView:itemViewAtIndex:)]) {
        NSAssert(0, @"sphereView:itemViewAtIndex: not implemented");
        return false;
    }
    if (![self.dataSource respondsToSelector:@selector(sphereView:sizeForItemViewAtIndex:)]) {
        NSAssert(0, @"sphereView:sizeForItemViewAtIndex: not implemented");
        return false;
    }
    if (![self.dataSource respondsToSelector:@selector(sizeOfSphereCenterView)]) {
        NSAssert(0, @"sizeOfSphereCenterView not implemented");
        return false;
    }
    if (![self.dataSource respondsToSelector:@selector(sphereCenterView)]) {
        NSAssert(0, @"sphereCenterView not implemented");
        return false;
    }
    return true;
}

@end
