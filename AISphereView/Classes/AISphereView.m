//
//  AISphereView.m
//  AISphereView
//
//  Created by Mayqiyue on 02/02/2018.
//

#import "AISphereView.h"
#import "AIMatrix.h"

const CGFloat AIAnmationDuration = 0.5;

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
    _lineColor = [UIColor redColor];
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
   
    CGFloat x = self.centerView.center.x - centerView.center.x;
    CGFloat y = self.centerView.center.y - centerView.center.y;
    CGFloat s = self.centerView.frame.size.width / centerView.frame.size.width;
    if (fabs(x) > fabs(y)) {
        CGFloat r = y / x;
        x = self.frame.size.width/2.0f * (x > 0 ? 1 : -1);
        y = x * r;
    }
    else {
        CGFloat r = x / y;
        y = self.frame.size.width/2.0f * (y > 0 ? 1 : -1);
        x = y * r;
    }
   
    [UIView animateWithDuration:AIAnmationDuration animations:^{
        for (UIView *v in oldViews) {
            v.alpha = 0;
            v.center = CGPointMake(v.center.x + x, v.center.y + y);
            v.transform = CGAffineTransformScale(v.transform, 1.3/s, 1.3/s);
        }
    } completion:^(BOOL finished) {
        [oldViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.centerView = centerView;
        [self _internalAnimate:centerView withItems:items];
    }];
    
    [UIView animateWithDuration:AIAnmationDuration * 1.5 animations:^{
        centerView.alpha = 1.0;
        centerView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        centerView.transform = CGAffineTransformScale(centerView.transform, s, s);
    } completion:^(BOOL finished) {
    }];
}

- (void)_internalAnimate:(UIView *)centerView withItems:(NSArray <UIView *>*)items
{
    self.items = [NSMutableArray arrayWithArray:items];
    self.lines = [[NSMutableArray alloc] init];
    self.coordinate = [[NSMutableArray alloc] init];
    self.lineContentView = [[UIView alloc] initWithFrame:self.bounds];
    
    [self addSubview:self.lineContentView];
    [self addSubview:centerView];

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
    
    for (NSInteger i = 0; i < self.items.count; i ++) {
        CAShapeLayer *line = [CAShapeLayer layer];
        line.frame = self.bounds;
        line.opacity = 0.0;
        [self.lines addObject:line];
    }
    
    for (NSInteger i = 0; i < self.items.count; i ++) {
        NSValue *value = self.coordinate[i];
        AIPoint point;
        [value getValue:&point];
        
        CAShapeLayer *layer = self.lines[i];
        [self.lineContentView.layer addSublayer:layer];
        [self drawLineForPoint:point atIndex:i];
        
        UIView *view = self.items[i];
        [self addSubview:view];
        view.alpha = 0.0;
        view.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
        view.transform = CGAffineTransformMakeScale(0.2, 0.2);
    }

    self.lineContentView.transform = CGAffineTransformMakeScale(centerView.frame.size.width/self.bounds.size.width, centerView.frame.size.width/self.bounds.size.width);
    
    [UIView animateWithDuration:AIAnmationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        for (NSInteger i = 0; i < self.items.count; i ++) {
            NSValue *value = [self.coordinate objectAtIndex:i];
            AIPoint point;
            [value getValue:&point];
            [self setTagOfPoint:point andIndex:i];
        }
        self.lineContentView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        NSInteger a =  arc4random() % 10 - 5;
        NSInteger b =  arc4random() % 10 - 5;
        normalDirection = AIPointMake(a, b, 0);
        panGesture.enabled = true;
        self.isMoving = false;
        [self timerStart];
    }];
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
    AIPostion p = [self actualPostionOf:point atIndex:index];
    
    UIView *view = [self.items objectAtIndex:index];
    view.center = CGPointMake(p.x, p.y);
    
    CGFloat transform = p.z;
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, transform, transform);
    view.layer.zPosition = transform;
    view.alpha = transform;
    view.userInteractionEnabled = NO;
    
    [self drawLineForPoint:point atIndex:index];
}

- (void)drawLineForPoint:(AIPoint)point atIndex:(NSUInteger)index
{
    AIPostion p = [self actualPostionOf:point atIndex:index];
    
    CAShapeLayer *line = [self.lines objectAtIndex:index];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(line.bounds.size.width/2.0f, line.bounds.size.height/2.0f)];
    [path addLineToPoint:CGPointMake(p.x, p.y)];
    
    line.path = path.CGPath;
    line.fillColor = [UIColor clearColor].CGColor;
    line.strokeColor = self.lineColor.CGColor;
    line.lineWidth = 2.0;
    line.opacity = p.z;
    [line setNeedsDisplay];
}

- (AIPostion)actualPostionOf:(AIPoint)point atIndex:(NSInteger)index
{
    return AIPointMake((point.x + 1) * (self.frame.size.width / 2.0), (point.y + 1) * (self.frame.size.width / 2.0), (point.z + 2)/3.0);
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

