//
//  AIPoint.h
//  Pods
//
//  Created by Mayqiyue on 04/02/2018.
//

#ifndef AIPoint_h
#define AIPoint_h

struct AIPoint {
    CGFloat x;
    CGFloat y;
    CGFloat z;
};

typedef struct AIPoint AIPoint;
typedef struct AIPoint AIPostion;


AIPoint AIPointMake(CGFloat x, CGFloat y, CGFloat z) {
    AIPoint point;
    point.x = x;
    point.y = y;
    point.z = z;
    return point;
}

#endif /* AIPoint_h */
