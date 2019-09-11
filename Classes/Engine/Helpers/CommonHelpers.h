//
//  CommonHelpers.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// All kind of helper function, that are used more than once, used without intance

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"

@interface CommonHelpers : NSObject
+ (SColor) UnNormalizeColor:(GLKVector4) color;
+ (void) TrimColor:(GLKVector4*) color;
+ (float) RandomFloat;
+ (float) RandomInRange: (float) low : (float) high;
+ (int)   RandomInRangeInt: (int) low : (int) high;
+ (float) RandomInRange: (float) low : (float) high : (float) multiplier;
+ (GLKVector3) RandomInCircle: (GLKVector3) center : (float) radius : (float) height;
+ (GLKVector3) RandomInCircleSector: (GLKVector3) center : (float) radiusLower : (float) radiusUpper : (float) height;
//+ (GLKVector3) RandomInRect: (CGRect) rect;
+ (GLKVector3) RandomOnCircleLine: (SCircle) cr;
+ (GLKVector3) PointOnCircle: (SCircle) cr : (float) angle;
+ (float) ValueInNewRange: (float) oldMin : (float) oldMax : (float) newMin : (float) newMax : (float) oldVal;
+ (float) ValueInNewRangeLimited: (float) oldMin: (float) oldMax: (float) newMin: (float) newMax: (float) oldVal;
+ (float) Avarage:(float) v1 : (float) v2;
+ (void) InterpolateDaytimeColor: (GLKVector4*) result: (GLKVector4) v1: (GLKVector4) v2: (GLKVector4) v3: (GLKVector4) v4: (float) curTime;
+ (float) Lerp: (float) v0 :  (float) v1 : (float) t;
+ (float) LinearInterpolation: (float) v1 : (float) v2 : (float) tstart : (float) tend : (float) t;
+ (float) ParabolicInterpolationUp: (float) v1 : (float) v2 : (float) tstart : (float) tend : (float) t;
+ (float) ParabolicInterpolationDown: (float) v1 : (float) v2 : (float) tstart : (float) tend : (float) t;
+ (float) CubicInterpolation: (float) v1 : (float) v2 : (float) tstart : (float) tend : (float) t : (float) koef;
+ (float) DistanceCGP: (CGPoint) p1 : (CGPoint) p2;
+ (float) DistanceInHorizPLane: (GLKVector3) point1 : (GLKVector3) point2;
+ (void) Swap: (float*) a : (float*) b;
+ (BOOL) RayAABBIntersect1D:(float) min : (float) max : (float) a : (float) b : (float) d : (float*) t0 : (float*) t1;
+ (BOOL) IntersectLineAABB: (GLKVector3) A : (GLKVector3) B : (GLKVector3) Min : (GLKVector3) Max : (float) distance;
+ (BOOL) PointInAABB:(GLKVector3) p : (GLKVector3) Min : (GLKVector3) Max;
+ (BOOL) PointInSphere: (GLKVector3) sc : (float) radius : (GLKVector3) point;
+ (BOOL) IntersectLineSphere: (GLKVector3) sc : (float) radius : (GLKVector3) l0 : (GLKVector3) l1 : (float) maxDist;
+ (BOOL) PointInCircle: (GLKVector3) cc : (float) radius : (GLKVector3) point;
+ (BOOL) CirclesColliding: (GLKVector3) cc1 : (float) radius1 : (GLKVector3) cc2 : (float) radius2;
+ (BOOL) SpheresColliding: (GLKVector3) sp1 : (float) radius1 : (GLKVector3) sp2 : (float) radius2;
+ (GLKVector3) PointOnLine: (GLKVector3) p1 : (GLKVector3) p2 : (float) dist;
+ (void) LoadCylinderBillboard:(float*) m;
+ (void) LoadSphereBillboard: (float*) m;
+ (GLKMatrix4) LoadCylinderBillboardReturn:(GLKMatrix4) m;
+ (GLKVector3) VectorMatrixMultiply:(GLKVector3) v : (float*) m;
+ (void) RotateY: (GLKVector3*)vector : (float)angle;
+ (void) RotateY: (GLKVector3*)vector : (float)angle : (GLKVector3) rotationPoint;
+ (void) RotateX: (GLKVector3*)vector : (float)angle;
+ (void) RotateX: (GLKVector3*)vector : (float)angle : (GLKVector3) rotationPoint;
+ (void) RotateZ: (GLKVector3*)vector : (float)angle;
+ (void) RotateZ: (GLKVector3*)vector : (float)angle : (GLKVector3) rotationPoint;
+ (GLKVector3) RotateZRet: (GLKVector3)vector: (float) angle;
+ (GLKVector3) RotateToNormal :(GLKVector3)vector : (GLKVector3) object : (GLKVector3)currNormal : (GLKVector3)desiredNormal;
+ (float) AngleBetweenVectors: (GLKVector3)vector1 : (GLKVector3)vector2;
+ (float) AngleBetweenVectors180: (GLKVector3) vector1 : (GLKVector3) vector2;
+ (float) AngleBetweenVectorAndX: (GLKVector3) vector;
+ (float) AngleBetweenVectorAndZ: (GLKVector3) vector;
+ (GLKVector3) GetVectorFrom2Points: (GLKVector3) originPoint : (GLKVector3) directionPoint : (BOOL) onHorizontalPlane;
+ (float) AngleBetweenVectorAndHorizontalPlane: (GLKVector3) vector;
+ (void) RotateVectorByHorizontalPLane: (GLKVector3*) vector : (float) angle;
+ (float) SinFast: (float) angle;
+ (float) CosFast: (float) angle;
+ (void) RotateXFast: (GLKVector3*)vector : (float)angle;
+ (void) RotateXFast: (GLKVector3*)vector : (float)angle : (GLKVector3) rotationPoint;
+ (float) ConvertToRelative: (float) points;
+ (CGRect) CGRRelativeToPoints: (CGRect) relativeRect : (CGSize) screenSizeInPoints;
+ (float) ConvertToNormalRadians: (float) angle;
+ (void) Log: (NSString*) text;
@end

