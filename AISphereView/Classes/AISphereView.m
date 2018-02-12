//
//  AISphereView.m
//  AISphereView
//
//  Created by Mayqiyue on 02/02/2018.
//

#import "AISphereView.h"
#import "AIMatrix.h"

const CGFloat AIAnmationDuration = 0.3;

@interface AICoodinateStackItem : NSObject

@property (nonatomic, assign) NSUInteger index;

@property (nonatomic, assign) CGFloat scale; // scale for transform
@property (nonatomic, strong) NSArray <NSValue *>*beforeAnimPoints;
@property (nonatomic, strong) NSArray <NSValue *>*afterAnimPoints;

@property (nonatomic, assign) AIPoint ca; // point after animation of prior center view.


@end

@implementation AICoodinateStackItem
@end

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

@property (nonatomic, strong) NSMutableArray *coordinateStack;

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

    _coordinateStack = [NSMutableArray new];
}

- (void)dealloc
{
}

#pragma mark - Public

- (void)pushToCenter:(UIView *)centerView withItems:(NSArray <UIView *>*)items
{
    if (self.isMoving) {
        return;
    }
    if (![self.subviews containsObject:centerView]) {
        self.centerView = centerView;
        self.centerView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        
        [self _internalAnimate:centerView withItems:items];
        return;
    }
    self.isMoving = true;
    
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

    self.lineContentView.alpha = 0.0;
    CGFloat s = self.centerView.frame.size.width / centerView.frame.size.width;
    
    AICoodinateStackItem *stackItem = [AICoodinateStackItem new];
    stackItem.beforeAnimPoints = [self.coordinate copy];
    stackItem.index = [self.items indexOfObject:centerView];
    stackItem.scale = s;
    [self.coordinateStack addObject:stackItem];

    [UIView animateWithDuration:AIAnmationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        for (UIView *v in oldViews) {
            CGFloat x = v.center.x - centerView.center.x;
            CGFloat y = v.center.y - centerView.center.y;
            if (fabs(x) > fabs(y)) {
                CGFloat r = y / x;
                x = self.frame.size.width/2.0f * (x > 0 ? 1 : -1) * 0.8;
                y = x * r;
            }
            else {
                CGFloat r = x / y;
                y = self.frame.size.width/2.0f * (y > 0 ? 1 : -1) * 0.8;
                x = y * r;
            }
            
            v.alpha = 0;
            v.center = CGPointMake(v.center.x + x, v.center.y + y);
            v.transform = CGAffineTransformScale(v.transform, 1.5/s, 1.5/s);
        }
        
        NSMutableArray *array = [NSMutableArray new];
        for (UIView *view in self.items) {
            AIPoint p = AIPointMake(view.center.x, view.center.y, view.layer.zPosition);
            NSValue *value = [NSValue value:&p withObjCType:@encode(AIPoint)];
            [array addObject:value];
        }
        stackItem.afterAnimPoints = array;
        stackItem.ca = AIPointMake(self.centerView.center.x, self.centerView.center.y, self.centerView.layer.zPosition);
    } completion:^(BOOL finished) {
        [oldViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.centerView = centerView;
        [self _internalAnimate:centerView withItems:items];
    }];
    
    [UIView animateWithDuration:AIAnmationDuration * 1.8 animations:^{
        centerView.alpha = 1.0;
        centerView.layer.zPosition = 0;
        centerView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        centerView.transform = CGAffineTransformScale(centerView.transform, s, s);
    } completion:^(BOOL finished) {
    }];
}

- (void)popToCenter:(UIView *)centerView withItems:(NSArray <UIView *>*)items;
{
    if (self.isMoving) {
        return;
    }

    AICoodinateStackItem *stackTop = self.coordinateStack.lastObject;
    if (!stackTop) {
        return;
    }
    self.isMoving = true;
    NSAssert(items.count == stackTop.beforeAnimPoints.count, @"The items count %ld not equal to stack's count %ld", items.count, stackTop.beforeAnimPoints.count);
    NSAssert(stackTop.beforeAnimPoints.count == stackTop.beforeAnimPoints.count, @"The points count not the same");

    //Animations 1
    UIView *cview = self.centerView;
    [UIView animateWithDuration:AIAnmationDuration * 1.5 delay:AIAnmationDuration * 0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
        AIPoint p;
        NSValue *value = [stackTop.beforeAnimPoints objectAtIndex:stackTop.index];
        [value getValue:&p];
        p = [self actualPostionOf:p];
        
        cview.center = CGPointMake(p.x, p.y);
        cview.transform = CGAffineTransformScale(CGAffineTransformIdentity, p.z, p.z);
        cview.layer.zPosition = p.z;
        cview.alpha = p.z;
    } completion:^(BOOL finished) {
    }];

    //Animations 2
    [UIView animateWithDuration:AIAnmationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        for (NSInteger i = 0; i < self.items.count; i ++) {
            UIView *view = [self.items objectAtIndex:i];
            view.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0);
            view.transform = CGAffineTransformMakeScale(0.1, 0.1);
            view.alpha = 0.0f;
        }
        self.lineContentView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.lineContentView.alpha = 0.1;
    } completion:^(BOOL finished) {
        self.lineContentView.transform = CGAffineTransformIdentity;
        self.lineContentView.alpha = 0.3;
        
        [self.items makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.lines makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        [self.lines removeAllObjects];
        self.items = items;
        self.centerView = centerView;
        self.coordinate = stackTop.beforeAnimPoints.mutableCopy;
 
        for (NSInteger i = 0; i < items.count; i ++) {
            CAShapeLayer *line = [CAShapeLayer layer];
            line.frame = self.bounds;
            line.opacity = 0.0;
            [self.lines addObject:line];
            [self.lineContentView.layer addSublayer:line];
        }

        for (NSInteger i = 0; i < items.count; i ++) {
            UIView *view = items[i];
            
            [self addSubview:view];

            NSValue *value = [stackTop.afterAnimPoints objectAtIndex:i];
            AIPoint p;
            [value getValue:&p];
            
            view.center = CGPointMake(p.x, p.y);
            view.layer.zPosition = p.z;
            view.transform = CGAffineTransformScale(CGAffineTransformScale(CGAffineTransformIdentity, p.z, p.z), 1.5/stackTop.scale, 1.5/stackTop.scale);
            view.alpha = p.z;
            if (i == stackTop.index) {
                view.hidden = YES;
            }
        }
        [self addSubview:centerView];
        AIPoint p = stackTop.ca;
        centerView.center = CGPointMake(p.x, p.y);
        centerView.layer.zPosition = p.z;
        centerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.5/stackTop.scale, 1.5/stackTop.scale);
        centerView.alpha = p.z;
        
        self.lineContentView.center = centerView.center;

        //Animations 3
        [UIView animateWithDuration:AIAnmationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.lineContentView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
            self.lineContentView.alpha = 1.0;
            for (NSInteger i = 0; i < items.count; i ++) {
                {
                    NSValue *value = [stackTop.beforeAnimPoints objectAtIndex:i];
                    AIPoint p;
                    [value getValue:&p];
                    [self drawLineForPoint:[self actualPostionOf:p] atIndex:i];
                }
            }
            
            for (NSInteger i = 0; i < items.count; i ++) {
                UIView *view = items[i];
                
                NSValue *value = [stackTop.beforeAnimPoints objectAtIndex:i];
                AIPoint p; [value getValue:&p];
                p = [self actualPostionOf:p];
                
                view.center = CGPointMake(p.x, p.y);
                view.layer.zPosition = p.z;
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, p.z, p.z);
                view.alpha = p.z;
            }
            centerView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
            centerView.layer.zPosition = 0;
            centerView.transform = CGAffineTransformIdentity;
            centerView.alpha = 1.0;
            
        } completion:^(BOOL finished) {
            items[stackTop.index].hidden = false;
            [cview removeFromSuperview];

            self.isMoving = false;
            [self.coordinateStack removeLastObject];
            normalDirection = AIPointMake(arc4random() % 10 - 5, arc4random() % 10 - 5, 0);
            if ([self.delegate respondsToSelector:@selector(sphereView:popAnimationCompletion:)]) {
                [self.delegate sphereView:self popAnimationCompletion:finished];
            }
        }];
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
        [self drawLineForPoint:[self actualPostionOf:point] atIndex:i];
        
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
        normalDirection = AIPointMake(arc4random() % 10 - 5, arc4random() % 10 - 5, 0);
        self.isMoving = false;

        if ([self.delegate respondsToSelector:@selector(sphereView:pushAnimationCompletion:)]) {
            [self.delegate sphereView:self pushAnimationCompletion:finished];
        }
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
    AIPostion p = [self actualPostionOf:point];
    
    UIView *view = [self.items objectAtIndex:index];
    view.center = CGPointMake(p.x, p.y);
    
    CGFloat transform = p.z;
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity, transform, transform);
    view.layer.zPosition = transform;
    view.alpha = transform;
    view.userInteractionEnabled = NO;
 
    [self drawLineForPoint:p atIndex:index];
}

- (void)drawLineForPoint:(AIPoint)point atIndex:(NSUInteger)index
{
    CAShapeLayer *line = [self.lines objectAtIndex:index];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(line.bounds.size.width/2.0f, line.bounds.size.height/2.0f)];
    [path addLineToPoint:CGPointMake(point.x, point.y)];
    
    line.path = path.CGPath;
    line.fillColor = [UIColor clearColor].CGColor;
    line.strokeColor = self.lineColor.CGColor;
    line.lineWidth = 2.0;
    line.opacity = point.z;
    [line setNeedsDisplay];
}

- (AIPostion)actualPostionOf:(AIPoint)point
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

- (void)setIsMoving:(BOOL)isMoving
{
    _isMoving = isMoving;
    panGesture.enabled = !isMoving;
    self.userInteractionEnabled = !isMoving;
    if (isMoving) {
        [self timerStop];
    }
    else {
        [self timerStart];
    }
}

- (NSUInteger)stackDepth
{
    return  self.coordinateStack.count;
}

@end

