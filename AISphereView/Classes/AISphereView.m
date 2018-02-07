//
//  AISphereView.m
//  AISphereView
//
//  Created by Mayqiyue on 02/02/2018.
//

#import "AISphereView.h"
#import "AIMatrix.h"

const CGFloat AIAnmationDuration = 2.5f;

@interface AISphereView ()
{
    AIPoint normalDirection;
    CGPoint last;
   
    CGFloat velocity;
   
    UITapGestureRecognizer *tapGesture;
    UIPanGestureRecognizer *panGesture;
    
    CADisplayLink *timer;
    CADisplayLink *inertia;
}

@property (nonatomic, strong) NSArray <__kindof UIView *>*items;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) UIView *lineContentView;
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*lines;
@property (nonatomic, strong) NSMutableArray *coordinate;

@property (nonatomic, assign) BOOL isMoving;

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

- (void)animateToCenter:(UIView *)centerView withItems:(NSArray <UIView *>*)items
{
    if (![self.subviews containsObject:centerView]) {
        self.centerView = centerView;
        self.centerView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        
        [self _internalAnimate:centerView withItems:items];
        return;
    }
    
    self.isMoving = true;
    panGesture.enabled = false;
    [self timerStop];

    NSMutableArray *oldViews = [NSMutableArray new];
    if (self.items) {
        [oldViews addObjectsFromArray:self.items];
    }
    if (self.centerView) {
        [oldViews addObject:self.centerView];
    }
    if (self.lineContentView) {
        [oldViews addObject:self.lineContentView];
    }
    [oldViews removeObject:centerView];
   
    CGFloat x, y, s;
    x = self.centerView.center.x - centerView.center.x;
    y = self.centerView.center.y - centerView.center.y;
    s = self.centerView.frame.size.width / centerView.frame.size.width;
    
    [UIView animateWithDuration:AIAnmationDuration animations:^{
        for (UIView *v in oldViews) {
            v.alpha = 0.0;
            v.center = CGPointMake(v.center.x + x/3.0, v.center.y + y/2.0f);
            v.transform = CGAffineTransformScale(v.transform, 1.0/s, 1.0/s);
        }
        centerView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        centerView.transform = CGAffineTransformScale(centerView.transform, s, s);
    } completion:^(BOOL finished) {
        [oldViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.centerView = centerView;
        [self _internalAnimate:centerView withItems:items];
    }];
}

- (void)_internalAnimate:(UIView *)centerView withItems:(NSArray <UIView *>*)items
{
    self.items = [NSMutableArray arrayWithArray:items];
    self.lines = [[NSMutableArray alloc] init];
    self.coordinate = [[NSMutableArray alloc] init];
    self.lineContentView = [UIView new];
    
    [self addSubview:self.lineContentView];
    [self addSubview:centerView];
    
    for (NSInteger i = 0; i < self.items.count; i ++) {
        CAShapeLayer *line = [CAShapeLayer layer];
        line.frame = self.bounds;
        line.opacity = 0.0;
        [self.lines addObject:line];
        [self.lineContentView.layer addSublayer:line];
        self.lineContentView.bounds = centerView.bounds;
        self.lineContentView.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
        
        UIView *view = self.items[i];
        [self addSubview:view];
        view.alpha = 0.0;
        view.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
    }
    
    CGFloat p1 = M_PI * (3 - sqrt(5));
    CGFloat p2 = 2. / self.items.count;
    
    for (NSInteger i = 0; i < self.items.count; i ++) {
        
        CGFloat y = i * p2 - 1 + (p2 / 2);
        CGFloat r = sqrt(1 - y * y);
        CGFloat p3 = i * p1;
        CGFloat x = cos(p3) * r;
        CGFloat z = sin(p3) * r;
        
        AIPoint point = AIPointMake(x, y, z);
        NSValue *value = [NSValue value:&point withObjCType:@encode(AIPoint)];
        [self.coordinate addObject:value];
    }
    
//    [UIView animateWithDuration:AIAnmationDuration animations:^{
//        for (NSInteger i = 0; i < self.items.count; i ++) {
//            NSValue *value = [self.coordinate objectAtIndex:i];
//            AIPoint point;
//            [value getValue:&point];
//            [self setTagOfPoint:point andIndex:i];
//        }
//        self.lineContentView.bounds = self.bounds;
//    } completion:^(BOOL finished) {
//        NSInteger a =  arc4random() % 10 - 5;
//        NSInteger b =  arc4random() % 10 - 5;
//        normalDirection = AIPointMake(a, b, 0);
//        panGesture.enabled = true;
//        self.isMoving = false;
//        [self timerStart];
//    }];
}

#pragma mark - set frame of point

- (void)updateFrameOfPoint:(NSInteger)index direction:(AIPoint)direction andAngle:(CGFloat)angle
{
    NSValue *value = [self.coordinate objectAtIndex:index];
    AIPoint point;
    [value getValue:&point];
    
    AIPoint rPoint = AIPointMakeRotation(point, direction, angle);
    value = [NSValue value:&rPoint withObjCType:@encode(AIPoint)];
    self.coordinate[index] = value;
    
    [self setTagOfPoint:rPoint andIndex:index];
}

- (void)setTagOfPoint:(AIPoint)point andIndex:(NSInteger)index
{
    UIView *view = [self.items objectAtIndex:index];
    view.center = CGPointMake((point.x + 1) * (self.frame.size.width / 2.), (point.y + 1) * self.frame.size.width / 2.);
    
    CGFloat transform = (point.z + 2) / 3;
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, transform, transform);
    view.layer.zPosition = transform;
    view.alpha = transform;
    view.userInteractionEnabled = NO;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f)];
    [path addLineToPoint:view.center];
    
    CAShapeLayer *line = [self.lines objectAtIndex:index];
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
    for (NSInteger i = 0; i < self.items.count; i ++) {
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
        for (NSInteger i = 0; i < self.items.count; i ++) {
            [self updateFrameOfPoint:i direction:normalDirection andAngle:angle];
        }
    }
    
}

#pragma mark - gesture selector

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture
{
    CGPoint current = [gesture locationInView:self];
    for (UIView *view in self.items) {
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
        
        for (NSInteger i = 0; i < self.items.count; i ++) {
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

@end

