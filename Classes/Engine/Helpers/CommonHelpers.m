//
//  CommonHelpers.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "CommonHelpers.h"

@implementation CommonHelpers

//------------------- Color interpolation
//choose pallettes to interpolate and assign to final color vector
+ (void) InterpolateDaytimeColor: (GLKVector4*) result: (GLKVector4) v1: (GLKVector4) v2: (GLKVector4) v3: (GLKVector4) v4: (float) curTime
{
    float midday = 12 * 60;
	float evening = 18 * 60;
	float night1 = 24 * 60;
	float night2 = 0;
	float morning = 6 * 60;
	
    
    //OPTI - make it into one function where no need to recalculate pow for every color component
    if(curTime > midday && curTime <= evening)
	{
        /*
        result->r = [self ParabolicInterpolationUp: v1->r: v2->r: midday: evening: curTime];
		result->g = [self ParabolicInterpolationUp: v1->g: v2->g: midday: evening: curTime];
		result->b = [self ParabolicInterpolationUp: v1->b: v2->b: midday: evening: curTime];
         */
        float koef = 600;
        result->r = [self CubicInterpolation: v1.r: v2.r: midday: evening: curTime: koef];
		result->g = [self CubicInterpolation: v1.g: v2.g: midday: evening: curTime: koef];
		result->b = [self CubicInterpolation: v1.b: v2.b: midday: evening: curTime: koef];
    }else if (curTime > evening && curTime <= night1)
	{
        /*
        result->r = [self ParabolicInterpolationDown: v2->r: v3->r: evening: night1: curTime];
		result->g = [self ParabolicInterpolationDown: v2->g: v3->g: evening: night1: curTime];
		result->b = [self ParabolicInterpolationDown: v2->b: v3->b: evening: night1: curTime];
        */
        float koef = 0.01;
        result->r = [self CubicInterpolation: v2.r: v3.r: evening: night1: curTime: koef];
		result->g = [self CubicInterpolation: v2.g: v3.g: evening: night1: curTime: koef];
		result->b = [self CubicInterpolation: v2.b: v3.b: evening: night1: curTime: koef];
        
    }else if (curTime <= morning)
	{
        /*
        result->r = [self ParabolicInterpolationUp: v3->r: v4->r: night2: morning: curTime];
		result->g = [self ParabolicInterpolationUp: v3->g: v4->g: night2: morning: curTime];
		result->b = [self ParabolicInterpolationUp: v3->b: v4->b: night2: morning: curTime];
        */
        float koef = 600;
        result->r = [self CubicInterpolation: v3.r: v4.r: night2: morning: curTime: koef];
		result->g = [self CubicInterpolation: v3.g: v4.g: night2: morning: curTime: koef];
		result->b = [self CubicInterpolation: v3.b: v4.b: night2: morning: curTime: koef];
    }else if (curTime > morning && curTime <= midday)
	{
        /*
        result->r = [self ParabolicInterpolationDown: v4->r: v1->r: morning: midday: curTime];
		result->g = [self ParabolicInterpolationDown: v4->g: v1->g: morning: midday: curTime];
		result->b = [self ParabolicInterpolationDown: v4->b: v1->b: morning: midday: curTime];
        */
        float koef = 0.01;
        result->r = [self CubicInterpolation: v4.r: v1.r: morning: midday: curTime: koef];
		result->g = [self CubicInterpolation: v4.g: v1.g: morning: midday: curTime: koef];
		result->b = [self CubicInterpolation: v4.b: v1.b: morning: midday: curTime: koef];
    }
	result->a = 1.0;
    
}

//linear interpolation from v0 to v1 , t = {0.0 .. 1.0}
// Precise method which guarantees v = v1 when t = 1.
+ (float) Lerp: (float) v0 :  (float) v1 : (float) t
{
    return (1 - t) * v0 + t * v1;
}



//interpolate from value v1 to v2 in given time interval
+ (float) LinearInterpolation: (float) v1: (float) v2: (float) tstart: (float) tend: (float) t
{
    float i = (t - tstart) / (tend - tstart); // Interpolation amount between 0.0 - 1.0
    return v1 * (1.0f - i) + v2 * i; 
}

//parabolic interpolation between v1 and v2
//slow than fast change
+ (float) ParabolicInterpolationUp: (float) v1: (float) v2: (float) tstart: (float) tend: (float) t
{
    float deltaV = v2 - v1;
    float deltaT = tend - tstart;
    
    return (deltaV / (deltaT*deltaT)) * (t - tstart) * (t - tstart) + v1;
}
//fast then slow change
+ (float) ParabolicInterpolationDown: (float) v1: (float) v2: (float) tstart: (float) tend: (float) t
{
    float deltaV = v2 - v1;
    float deltaT = tend - tstart;
    
    return -(deltaV / (deltaT*deltaT)) * (t - tend) * (t - tend) + v2;
}

//qubic interpolation - slow at beginning koef > 1 , fast at beginning 0 < koef < 1 (koef must be big, like 10 000)
+ (float) CubicInterpolation: (float) v1: (float) v2: (float) tstart: (float) tend: (float) t: (float) koef
{
    float deltaV = v2 - v1;
    float deltaT = tend - tstart;
    float exponent = (t - tstart) / deltaT;
    
    return v1 + (deltaV / (koef - 1)) * (pow(koef,exponent)  - 1);
}

#pragma mark - Math functions

//convert color from 0.0 - 1.0 to 0 - 255
+ (SColor) UnNormalizeColor:(GLKVector4) color
{
    return SColorMake(color.r * 255, color.g * 255, color.b * 255, color.a * 255);
}

//make sure does not go above 1.0
+ (void) TrimColor:(GLKVector4*) color
{
    if(color->r > 1.0) color->r = 1.0;
    if(color->g > 1.0) color->g = 1.0;
    if(color->b > 1.0) color->b = 1.0;
    if(color->a > 1.0) color->a = 1.0;
}

#pragma mark - Random functions

//random number from 0.0 - 1.0
+ (float) RandomFloat
{
    //return arc4random_uniform(1001) / 1000.0;
    return [self RandomInRange: 0.0: 1.0: 1000];
}

//random number between low and height (with step of 1)
+ (float) RandomInRange: (float) low: (float) high
{
    return arc4random_uniform(high - low + 1) + low;
}

//random number between low and height (with step of 1)
+ (int) RandomInRangeInt: (int) low: (int) high
{
    return arc4random_uniform(high - low + 1) + low;
}

//to give random step, use multiplier (multiplier 10 would give step 0.1)
+ (float) RandomInRange: (float) low: (float) high: (float) multiplier
{
    //NOTE : arc4random_uniform take int not float so what is left after comma is thrown off
    low *= multiplier;
    high *= multiplier;
    //NSLog(@"==== %f %f",low, high);
    return (arc4random_uniform(high - low + 1) + low) / multiplier;
}

//random vertex in circle location (randomize x and z) at height
//CAUNTION Infinite loop used
+ (GLKVector3) RandomInCircle: (GLKVector3) center: (float) radius: (float) height
{
    GLKVector3 result;
   // float randomStep = 0.5; //randomized values step (if 0.5 then  0,0.5,1.0,1.5 ... )
    float multiplier = 1000; //step is 0.001 in this case
    int counter = 0;
    center.y = 0;
    
    while (true)
    {
        //randomize in quad
        float startX = [self RandomInRange: -radius : radius : multiplier] + center.x;
        float startZ = [self RandomInRange: -radius : radius : multiplier] + center.z;
        result = GLKVector3Make(startX, 0, startZ); //center of obj
        //if out of cicrcle, re randomize
        if(GLKVector3Distance(result, center) < radius)
        {
            result.y = height;
            break;
        }
        
        counter++;
        //NSLog(@"%d", counter);
        if(counter > 3000)
        {
            [self Log:@"INFINITE LOOP STUCK! RandomInCircle"];
            break;
        }
    }
    
    return result;
}

//random vertex in circle location sector (randomize x and z) at height
//values will be randomized between radiusLower and radiusUpper
//CAUNTION Infinite loop used
+ (GLKVector3) RandomInCircleSector: (GLKVector3) center : (float) radiusLower : (float) radiusUpper : (float) height
{
    GLKVector3 result;
    float multiplier = 1000; //step is 0.001 in this case
    int counter = 0;
   // NSLog(@"%f",FLT_MAX / 1000);
    center.y = 0;
    
    while (true)
    {
        //randomize in quad
        float startX = [self RandomInRange: -radiusUpper : radiusUpper : multiplier] + center.x;
        float startZ = [self RandomInRange: -radiusUpper : radiusUpper : multiplier] + center.z;
        result = GLKVector3Make(startX, 0, startZ); //center of obj
        //if out of cicrcle, re randomize
        if(GLKVector3Distance(result, center) < radiusUpper && GLKVector3Distance(result, center) > radiusLower)
        {
            result.y = height;
            break;
        }
        
        counter++;
        if(counter > 3000)
        {
            [self Log:@"INFINITE LOOP STUCK! RandomInCircleSector"];
            break;
        }
    }
    
    return result;
}

//return random location value within rectangle (works in x,z plane)
/*
+ (GLKVector3) RandomInRect: (CGRect) rect
{
    GLKVector3 pos;
    float multiplier = 10; //step is 0.1 in this case
    
    pos.x = [self RandomInRange:rect.origin.x:(rect.origin.x+rect.size.width):multiplier];
    pos.y = 0;
    pos.z = [self RandomInRange:rect.origin.y:(rect.origin.y+rect.size.height):multiplier];
    
    return pos;
}
*/

//random coordinates on given circle line, y is nilled
+ (GLKVector3) RandomOnCircleLine: (SCircle) cr
{
    GLKVector3 pos;
    float randomAngle = [self RandomInRange: 0 : PI_BY_2 : 1000];
    
    pos.y = 0;
    pos.x = cr.radius * cosf(randomAngle) + cr.center.x;
    pos.z = cr.radius * sinf(randomAngle) + cr.center.z;
    return pos;
}

#pragma mark - Math functions

//point on circle, by the angle (radians), (angle 0 = point on negative x axis, clockwise winding)
+ (GLKVector3) PointOnCircle: (SCircle) cr: (float) angle
{
    GLKVector3 pos; 
    pos.y = 0;
    pos.x = cr.radius * cosf(angle) + cr.center.x;
    pos.z = cr.radius * sinf(angle) + cr.center.z;
    return pos;
}


//find analogue of old value (from old range) in the new range
+ (float) ValueInNewRange: (float) oldMin: (float) oldMax: (float) newMin: (float) newMax: (float) oldVal
{
    float oldRange = oldMax - oldMin;
    float newRange = newMax - newMin;
    return (((oldVal - oldMin) * newRange) / oldRange) + newMin;
}

//find analogue of old value (from old range) in the new range
//Limited differs from original function - when oldVal is passed greater or smaller than oldMin or oldMax, returned value still stays between (newMin, newMax)
+ (float) ValueInNewRangeLimited: (float) oldMin: (float) oldMax: (float) newMin: (float) newMax: (float) oldVal
{
    if(oldVal > oldMax) oldVal = oldMax;
    if(oldVal < oldMin) oldVal = oldMin;
    
    return [self ValueInNewRange: oldMin : oldMax : newMin : newMax : oldVal];
}


//return avarage of two values
+ (float) Avarage:(float) v1: (float) v2
{
    return (v1 + v2) / 2;
}

//swap 2 floats
+ (void) Swap: (float*) a: (float*) b
{
    float x;
    x = *a;
    *a = *b;
    *b = x;    
}


//distane between 2 points ir 2d
+ (float) DistanceCGP: (CGPoint) p1 : (CGPoint) p2
{
    float xd = p2.x-p1.x;
    float yd = p2.y-p1.y;
    return sqrt(xd*xd + yd*yd);
}

//distance between two point in hirzinotal plane
+ (float) DistanceInHorizPLane: (GLKVector3) point1 : (GLKVector3) point2
{
    point1.y = 0.0;
    point2.y = 0.0;
    
    return GLKVector3Distance(point1, point2);
}

// ray-aabb test along one axis
+(BOOL) RayAABBIntersect1D: (float) min: (float) max: (float) a: (float) b: (float) d: (float*) t0: (float*) t1
{
	const float threshold = 1.0e-6f;
    
	if (fabs(d) < threshold)
	{
		if (d > 0.0f)
		{
			return !(b < min || a > max);
		}
		else
		{
			return !(a < min || b > max);
		}
	}
    
	float u0, u1;
    
	u0 = (min - a) / (d);
	u1 = (max - a) / (d);
    
	if (u0 > u1) 
	{
		[self Swap:&u0: &u1];
	}
    
	if (u1 < *t0 || u0 > *t1)
	{
		return NO;
	}
    
	*t0 = fmax(u0, *t0);
	*t1 = fmin(u1, *t1);
    
	if (*t1 < *t0)
	{
		return NO;
	}
    
	return YES; 
}

//ray - AABB intersection
//A line origin, B - some other point on line, Min - AABBmin, max AABBmax, distance - maximal distance from origin to check
+(BOOL) IntersectLineAABB: (GLKVector3) A: (GLKVector3) B: (GLKVector3) Min: (GLKVector3) Max: (float) distance
{
    //strech point to distance from origin
	B = [self PointOnLine:A:B:distance];
    
    //GLKVector3 S = A;
	GLKVector3 D = GLKVector3Subtract(B,A);
    
	float t0 = 0.0f, t1 = 1.0f;
    
	if (![self RayAABBIntersect1D:Min.x: Max.x: A.x: B.x: D.x: &t0: &t1]) 
	{
		return NO;
	}
	
	if (![self RayAABBIntersect1D:Min.y: Max.y: A.y: B.y: D.y: &t0: &t1]) 
	{
		return NO;
	}
    
	if (![self RayAABBIntersect1D:Min.z: Max.z: A.z: B.z: D.z: &t0: &t1]) 
	{
		return NO;
	}
    
    //enter exit coordinates if needed
    //A  = GLKVector3Add(S, GLKVector3MultiplyScalar(D, t0));
    //B  = GLKVector3Add(S, GLKVector3MultiplyScalar(D, t1));
    
	return YES;
}

//weather poiunt p is inside AABB
+ (BOOL) PointInAABB:(GLKVector3) p: (GLKVector3) Min: (GLKVector3) Max
{
    if (GLKVector3AllGreaterThanOrEqualToVector3(p,Min) && GLKVector3AllGreaterThanOrEqualToVector3(Max,p))
    {
        return YES;
    }else 
    {
        return NO;
    }
}

//weather line (l0-l1) intersects sphere with center sc and radius
//maxDist - maximum distance from viewer to be checked
+ (BOOL) IntersectLineSphere: (GLKVector3) sc: (float) radius: (GLKVector3) l0: (GLKVector3) l1: (float) maxDist
{
    //object must be no further than max distance from viewer
    float distance = GLKVector3Distance(l0,sc); //[self DistanceBetween:l0:sc];
    
    if(distance <= maxDist)
    {
        GLKVector3 d = GLKVector3Subtract(l0,l1);
        float a = GLKVector3DotProduct(d,d); 
        float b = 2 * d.x * (l0.x-sc.x) + 2 * d.y * (l0.y-sc.y) + 2 * d.z * (l0.z-sc.z);  //2*dx*(x0-cx) +  2*dy*(y0-cy) +  2*dz*(z0-cz);
        float c = GLKVector3DotProduct(sc,sc) + 
        GLKVector3DotProduct(l0,l0) 
        - 2 * GLKVector3DotProduct(sc,l0) - radius*radius; //cx*cx + cy*cy + cz*cz + x0*x0 + y0*y0 + z0*z0 +-2*(cx*x0 + cy*y0 + cz*z0) - R*R;
        
        float disc = b * b - 4 * a * c;
        
        //NSLog(@"%f %f %f %f", a,b,c,distance);
        
        if (b < 0.0f || disc < 0.0f) //if b < 0, object is from behind
        {
            return NO;
        }else
        {
            return YES;
        }
    }else
        return NO;
}

+ (BOOL) PointInSphere: (GLKVector3) sc: (float) radius: (GLKVector3) point
{

    //Calculate the squared distance from the point to the center of the sphere
    GLKVector3 distanceV = GLKVector3Subtract(sc, point);
    float fDistSq = GLKVector3DotProduct(distanceV,distanceV); 
    
    //Calculate if the squared distance between the sphere's center and the point
    //is less than the squared radius of the sphere
    if(fDistSq < (radius * radius))
    {
        return  YES;
    }
    
    return NO;
}

//cc and point should be in same height
+ (BOOL) PointInCircle: (GLKVector3) cc: (float) radius: (GLKVector3) point
{
    //we are interesed only in 2D plane
    cc.y = 0;
    point.y = 0;
    
    if(GLKVector3Distance(cc, point) < radius)
    {
        return YES;
    }
    
    return NO;
}

//returns true if the circles are touching, or false if they are not
+ (BOOL) CirclesColliding: (GLKVector3) cc1 : (float) radius1 : (GLKVector3) cc2 : (float) radius2
{
    //compare the distance to combined radii
    float dx = cc2.x - cc1.x;
    float dy = cc2.z - cc1.z;
    float radii = radius1 + radius2;
    if ((dx * dx)  + (dy * dy) < radii * radii)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

//returns true if the sphere are touching, or false if they are not
+ (BOOL) SpheresColliding: (GLKVector3) sp1 : (float) radius1 : (GLKVector3) sp2 : (float) radius2
{
    return GLKVector3Distance(sp1, sp2) <= (radius1 + radius2);
}


//find point on line p1,p2 in some distance from p2
+ (GLKVector3) PointOnLine: (GLKVector3) p1: (GLKVector3) p2: (float) dist
{
    GLKVector3 result;
    float k;
    //C = B - k(A - B). k = (the distance you want) / (distance from A to B)
   
    k = dist / GLKVector3Distance(p1,p2); //[self DistanceBetween:p1:p2];
    result = GLKVector3Subtract( p2 , GLKVector3MultiplyScalar( GLKVector3Subtract(p1, p2), k));
    
    return result;
}

//null all transformations for object to always face camera (this is not real billboard but cheat)
+ (void) LoadSphereBillboard: (float*) m
{
	m[0] = 1; m[4] = 0; m[8] = 0;
	m[1] = 0; m[5] = 1; m[9] = 0;
	m[2] = 0; m[6] = 0; m[10] = 1;
}

//leavue up-vector unchanged (this is not real billboard but cheat)
+ (void) LoadCylinderBillboard:(float*) m
{	
	m[0] = 1; m[8] = 0;
	m[1] = 0; m[9] = 0;
	m[2] = 0; m[10] = 1;
}
+ (GLKMatrix4) LoadCylinderBillboardReturn:(GLKMatrix4) m
{
	m.m[0] = 1; m.m[8] = 0;
	m.m[1] = 0; m.m[9] = 0;
	m.m[2] = 0; m.m[10] = 1;
    
    return m;
}

//multiple vector y matrix, and return vector
//4th vector value is added which is 1
+ (GLKVector3) VectorMatrixMultiply:(GLKVector3) v: (float*) m
{
    GLKVector4 result;
    
    float v1[4] = {v.x,v.y,v.z,1};
    
    result.v[0] = m[0] * v1[0] + m[4] * v1[1] + m[8] * v1[2] + m[12] * v1[3]; 
    result.v[1] = m[1] * v1[0] + m[5] * v1[1] + m[9] * v1[2] + m[13] * v1[3]; 
    result.v[2] = m[2] * v1[0] + m[6] * v1[1] + m[10] * v1[2] + m[14] * v1[3]; 
    result.v[3] = m[3] * v1[0] + m[7] * v1[1] + m[11] * v1[2] + m[15] * v1[3];
    
    return GLKVector3Make(result.v[0], result.v[1], result.v[2]);
}

/*
//rotate given vector about Y axis by given angle, position - position of object in space
+ (GLKVector3) RotateVertexY:(GLKVector3) v: (float) angle: (GLKVector3) position
{
    GLKMatrix4 rotMat, transMat, transMatBack, resultMat;
    
    //replace with GLKMatrix4MakeTranslation below
    
    //move to 0 coordinates
    transMat = GLKMatrix4Translate(GLKMatrix4Identity, -position.x, 0, -position.z);
    //rotate by angle
    rotMat = GLKMatrix4RotateY(GLKMatrix4Identity, angle);
    //move back to initial position
    transMatBack = GLKMatrix4Translate(GLKMatrix4Identity, position.x, 0, position.z);
    
    resultMat = GLKMatrix4Multiply(rotMat,transMat);
    resultMat = GLKMatrix4Multiply(transMatBack,resultMat);
   
    return [self VectorMatrixMultiply:v:resultMat.m];
}
*/
/*
//rotate given vector about X axis by given angle, position - position of object in space
+ (GLKVector3) RotateVertexX:(GLKVector3) v: (float) angle: (GLKVector3) position
{
    GLKMatrix4 rotMat, transMat, transMatBack, resultMat;
    
    //replace with GLKMatrix4MakeTranslation below
    
    //move to 0 coordinates
    transMat = GLKMatrix4Translate(GLKMatrix4Identity, 0, -position.y, -position.z);
    //rotate by angle
    rotMat = GLKMatrix4RotateX(GLKMatrix4Identity, angle);
    //move back to initial position
    transMatBack = GLKMatrix4Translate(GLKMatrix4Identity, 0, position.y, position.z);
    
    resultMat = GLKMatrix4Multiply(rotMat,transMat);
    resultMat = GLKMatrix4Multiply(transMatBack,resultMat);
    
    return [self VectorMatrixMultiply:v:resultMat.m];
}
*/
/*
 ----------------- x
 |
 |
 |
 |
 |
 |
 z
 */
//rotate vector about y axis (radians) (anti-clock wise)
+ (void) RotateY: (GLKVector3*) vector : (float) angle
{
    float tx, tz; //temporary coordinates
    
    float sinAngle = sinf(angle);
    float cosAngle = cosf(angle);
    
	//rotate vector by degrees
	tx = cosAngle * vector->x + sinAngle * vector->z; 
    tz = cosAngle * vector->z - sinAngle * vector->x;	 
    
	//assign to passed vector temoprary values
	vector->x = tx;
    vector->z = tz;
}

//rotate vector about y axis on rotation point
+ (void) RotateY: (GLKVector3*) vector : (float) angle : (GLKVector3) rotationPoint
{
    *vector = GLKVector3Subtract(*vector, rotationPoint);
    [self RotateY: vector : angle];
    *vector = GLKVector3Add(*vector, rotationPoint);
}

//rotate vector about x axis (radians)
+ (void) RotateX: (GLKVector3*) vector: (float)angle
{
    float ty, tz; //temporary coordinates
    
	float sinAngle = sinf(angle);
    float cosAngle = cosf(angle);
    
    ty = cosAngle * vector->y - sinAngle * vector->z;
    tz = sinAngle * vector->y + cosAngle * vector->z;
    
	//assign to passed vector t
	vector->y = ty;
    vector->z = tz;
}


//rotate vector about x axis on rotation point
+ (void) RotateX: (GLKVector3*)vector: (float)angle: (GLKVector3) rotationPoint
{
    *vector = GLKVector3Subtract(*vector, rotationPoint);
    [self RotateX:vector :angle];
    *vector = GLKVector3Add(*vector, rotationPoint);
}

//rotate vector about z axis (radians)
+ (void) RotateZ: (GLKVector3*)vector: (float)angle
{
    float ty, tx; //temporary coordinates
    
	float sinAngle = sinf(angle);
    float cosAngle = cosf(angle);
    
    tx = cosAngle * vector->x - sinAngle * vector->y;
    ty = sinAngle * vector->x + cosAngle * vector->y;
    
	//assign to passed vector t
	vector->y = ty;
    vector->x = tx;
}

//rotate vector about z axis (radians) and return without changing parameter
+ (GLKVector3) RotateZRet: (GLKVector3) vector: (float) angle
{
    float ty, tx; //temporary coordinates
    
	float sinAngle = sinf(angle);
    float cosAngle = cosf(angle);
    
    tx = cosAngle * vector.x - sinAngle * vector.y;
    ty = sinAngle * vector.x + cosAngle * vector.y;
    
    return GLKVector3Make(tx, ty, vector.z);
}

//rotate vector about x axis on rotation point
+ (void) RotateZ: (GLKVector3*)vector: (float)angle: (GLKVector3) rotationPoint
{
    *vector = GLKVector3Subtract(*vector, rotationPoint);
    [self RotateZ:vector :angle];
    *vector = GLKVector3Add(*vector, rotationPoint);
}



//rotate vertex of current normal to desired normal
//normals should be normalized
+ (GLKVector3) RotateToNormal: (GLKVector3)vector : (GLKVector3) object : (GLKVector3)currNormal : (GLKVector3)desiredNormal
{
    //Rotation axis = normalize(crossproduct(currentNormal, desiredNormal))
    //Rotation angle = acos(dotproduct(normalize(currentNormal), normalize(desiredNormal)).
    
    GLKMatrix4 rotMat, transMat, transMatBack, resultMat;

    float angle = acosf(GLKVector3DotProduct(currNormal, desiredNormal));
    GLKVector3 axis = GLKVector3Normalize(GLKVector3CrossProduct(currNormal, desiredNormal));
    
    //move to 0 coordinates
    transMat = GLKMatrix4Translate(GLKMatrix4Identity, -object.x, -object.y, -object.z);
    //rotate by angle
    rotMat = GLKMatrix4RotateWithVector3(GLKMatrix4Identity, angle, axis);
    //move back to initial position
    transMatBack = GLKMatrix4Translate(GLKMatrix4Identity, object.x, object.y, object.z);

    resultMat = GLKMatrix4Multiply(rotMat,transMat);
    resultMat = GLKMatrix4Multiply(transMatBack,resultMat);

    return [self VectorMatrixMultiply:vector:resultMat.m];
}


//angle between two vectors (in horizontal plane) (from 0 - 2*PI)
//both vectors should be normalised
+ (float) AngleBetweenVectors: (GLKVector3)vector1: (GLKVector3)vector2
{
    float angle;
    
    float ang1 = [self AngleBetweenVectorAndX: vector1];
    float ang2 = [self AngleBetweenVectorAndX: vector2];
    
    angle = fabs(ang1 -  ang2);

    return angle;
}


//angle between 2 vectors from 0 to PI, both vectors hould be normalized before
+ (float) AngleBetweenVectors180: (GLKVector3) vector1 : (GLKVector3) vector2
{
    return acosf( GLKVector3DotProduct(vector1, vector2) );
}


/*
 ----------------- x
 |
 |
 |
 |
 |
 |
 z
 */
//full angle between vector and X axis (radians) (anti-clockwise direction)
//vector should be normalized
//2d calculations (x,z - based)
//used only in Z-based function AngleBetweenVectorAndZ
+ (float) AngleBetweenVectorAndX: (GLKVector3) vector
{
    float angle;
    float x = vector.x;
    float y = vector.z;
    
    if(x == 0)
    {
        if(y == 0){
            angle = 0;
        }else {
            if(y > 0){
                angle = M_PI / 2.;
            }
            else {
                angle = (3 * M_PI) / 2.;
            }
        }
    }else 
    {
        if(x > 0){
            if(y < 0){
                angle = atanf(y/x) + 2 * M_PI;
            }else {
                angle = atanf(y/x);
            }
        }else {
            angle = atanf(y/x) + M_PI;
        }
    }

    return angle;
}

/*
  ----------------- x
 |
 |
 |
 |
 |
 |
 z
*/
//full angle between vector and Z axis (radians) (anti-clockwise direction)
//vector should be normalized
//2d calculations (x,z - based)
+ (float) AngleBetweenVectorAndZ: (GLKVector3) vector
{
    float angle;
    
    angle = [self AngleBetweenVectorAndX:vector];
    
    angle = M_PI / 2 - angle;
    if(angle < 0)
    {
        angle += 2 * M_PI;
    }
    
    return angle;
}


//get origin vector from 2 points, it is also normlaized
//vector goes from originPoint to directionPoint
//onHorizontalPlane - if true , vector will be put hoizontal (y=0)
+ (GLKVector3) GetVectorFrom2Points: (GLKVector3) originPoint : (GLKVector3) directionPoint : (BOOL) onHorizontalPlane
{
    GLKVector3 vector = GLKVector3Subtract(directionPoint, originPoint);
    if(onHorizontalPlane)
    {
        vector.y = 0;
    }
    
    //#BUG - Normlize shos nan value when length is 0 , fixed here but potentioall error other places where normalize is used
    if(!fequal(GLKVector3Length(vector), 0.0)) // in case length is 0 dont normalize, error acuurs
    {
        vector = GLKVector3Normalize(vector);
    }
    return vector;
}

//get angle between vector and horizontal plane
+ (float) AngleBetweenVectorAndHorizontalPlane: (GLKVector3) vector
{
    //rotate to origin where x=0
    float yAngle = [CommonHelpers AngleBetweenVectorAndZ: vector];
    [CommonHelpers RotateY: &vector :-yAngle];
    return atanf(vector.y / vector.z);
}

//rotate given origin vector by given angle around horizontal plane and return it
+ (void) RotateVectorByHorizontalPLane: (GLKVector3*) vector : (float) angle
{
    //1. rotate vector paralel to z axis (in normal position)
    float yAngle = [CommonHelpers AngleBetweenVectorAndZ: *vector];
    [CommonHelpers RotateY: vector :-yAngle];
    
    //2. rotate by given angle around x axis
    [CommonHelpers RotateX: vector :angle];
    
    //3. return back to previous orientation
    [CommonHelpers RotateY: vector :yAngle];
}



#pragma mark - Approx. math functions

//alternative/faster sin, cosine
+ (float) SinFast: (float) angle
{
    float result;

    //wrap angle from -PI to PI
    if(angle < -M_PI || angle > M_PI)
    {
        angle = M_PI * (1 + 2 * floorf(angle / PI_BY_2)) - angle;
    }
    
    //NSLog(@"%f", angle);
    
    if (angle < 0)
    {
        result = 1.27323954 * angle + .405284735 * angle * angle;
    }
    else
    {
        result = 1.27323954 * angle - 0.405284735 * angle * angle;
    }
    
    return result;
}

//sin(x + PI/2) = cos(x)
+ (float) CosFast: (float) angle
{
    return [self SinFast: angle + M_PI_2];
}

//rotation using aproximated fast sin/cos
//rotate vector about x axis (radians)
+ (void) RotateXFast: (GLKVector3*)vector: (float)angle
{
    float ty, tz; //temporary coordinates
    
	float sinAngle = [self SinFast:angle];
    float cosAngle = [self CosFast:angle];
    
    ty = cosAngle * vector->y - sinAngle * vector->z;
    tz = sinAngle * vector->y + cosAngle * vector->z;
    
	//assign to passed vector t
	vector->y = ty;
    vector->z = tz;
}

//rotate vector about x axis on rotation point
+ (void) RotateXFast: (GLKVector3*)vector: (float)angle: (GLKVector3) rotationPoint
{
    *vector = GLKVector3Subtract(*vector, rotationPoint);
    [self RotateXFast:vector :angle];
    *vector = GLKVector3Add(*vector, rotationPoint);
}

#pragma mark - Convertion / screen

//convert value given in point space to relative space
+ (float) ConvertToRelative: (float) points
{
    return points  / [[SingleGraph sharedSingleGraph] screen].points.size.height;
}

//convert relative rect into points rect and return
+ (CGRect) CGRRelativeToPoints: (CGRect) relativeRect : (CGSize) screenSizeInPoints
{
    CGRect pointsRect;
    
    pointsRect.origin.x = relativeRect.origin.x * screenSizeInPoints.height;
    pointsRect.origin.y = relativeRect.origin.y * screenSizeInPoints.height;
    pointsRect.size.width  = relativeRect.size.width * screenSizeInPoints.height;
    pointsRect.size.height = relativeRect.size.height * screenSizeInPoints.height;
    
    return pointsRect;
}

#pragma mark - Coordinate system

//convert angle that goes over bounds into normal 0 - 2*PI range
+ (float) ConvertToNormalRadians: (float) angle
{
    float retVal = angle;
    if(angle > PI_BY_2 || angle < -PI_BY_2)
    {
        retVal = fmodf(angle, PI_BY_2);
    }
    
    return retVal;
}


#pragma mark - Utilities

//write error data to screen , is turned off if not in debug mode
+ (void) Log: (NSString*) text
{
    if(DEBUG_ON)
    {
        NSLog(@"ERROR!: %@ ", text);
    }
}

@end
