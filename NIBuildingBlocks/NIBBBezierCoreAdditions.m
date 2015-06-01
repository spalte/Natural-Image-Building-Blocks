/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "NIBBBezierCoreAdditions.h"


NIBBBezierCoreRef NIBBBezierCoreCreateCurveWithNodes(NIBBVectorArray vectors, CFIndex numVectors, NIBBBezierNodeStyle style)
{
    return NIBBBezierCoreCreateMutableCurveWithNodes(vectors, numVectors, style);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCurveWithNodes(NIBBVectorArray vectors, CFIndex numVectors, NIBBBezierNodeStyle style)
{
	NSInteger  i, j;
	CGFloat xi, yi, zi;
	NSInteger nb;
	CGFloat *px, *py, *pz;
	int ok;
    
	CGFloat *a, b, *c, *cx, *cy, *cz, *d, *g, *h;
	CGFloat bet, *gam;
	CGFloat aax, bbx, ccx, ddx, aay, bby, ccy, ddy, aaz, bbz, ccz, ddz; // coef of spline
    
    // get the new beziercore ready 
    NIBBMutableBezierCoreRef newBezierCore;
    NIBBVector control1;
    NIBBVector control2;
    NIBBVector lastEndpoint;
    NIBBVector endpoint;
    newBezierCore = NIBBBezierCoreCreateMutable();
    
    assert (numVectors >= 2);
    
    if (numVectors == 2) {
        NIBBBezierCoreAddSegment(newBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, vectors[0]);
        NIBBBezierCoreAddSegment(newBezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, vectors[1]);
        return newBezierCore;
    }
    
	// function spline S(x) = a x3 + bx2 + cx + d
	// with S continue, S1 continue, S2 continue.
	// smoothing of a closed polygon given by a list of points (x,y)
	// we compute a spline for x and a spline for y
	// where x and y are function of d where t is the distance between points
    
	// compute tridiag matrix
	//   | b1 c1 0 ...                   |   |  u1 |   |  r1 |
	//   | a2 b2 c2 0 ...                |   |  u2 |   |  r2 |
	//   |  0 a3 b3 c3 0 ...             | * | ... | = | ... |
	//   |                  ...          |   | ... |   | ... |
	//   |                an-1 bn-1 cn-1 |   | ... |   | ... |
	//   |                 0    an   bn  |   |  un |   |  rn |
	// bi = 4
	// resolution algorithm is taken from the book : Numerical recipes in C
    
	// initialization of different vectors
	// element number 0 is not used (except h[0])
	nb  = numVectors + 2;
	a   = malloc(nb*sizeof(double));	
	c   = malloc(nb*sizeof(double));	
	cx  = malloc(nb*sizeof(double));	
	cy  = malloc(nb*sizeof(double));	
	cz  = malloc(nb*sizeof(double));	
	d   = malloc(nb*sizeof(double));	
	g   = malloc(nb*sizeof(double));	
	gam = malloc(nb*sizeof(double));	
	h   = malloc(nb*sizeof(double));	
	px  = malloc(nb*sizeof(double));	
	py  = malloc(nb*sizeof(double));	
	pz  = malloc(nb*sizeof(double));	
    
	
	BOOL failed = NO;
	
	if( !a) failed = YES;
	if( !c) failed = YES;
	if( !cx) failed = YES;
	if( !cy) failed = YES;
	if( !cz) failed = YES;
	if( !d) failed = YES;
	if( !g) failed = YES;
	if( !gam) failed = YES;
	if( !h) failed = YES;
	if( !px) failed = YES;
	if( !py) failed = YES;
	if( !pz) failed = YES;
	
	if( failed)
	{
		free(a);
		free(c);
		free(cx);
		free(cy);
		free(cz);
		free(d);
		free(g);
		free(gam);
		free(h);
		free(px);
		free(py);
		free(pz);
		
        fprintf(stderr, "NIBBBezierCoreCreateMutableCurveWithNodes failed because it could not allocate enough memory\n");
		return NULL;
	}
	
	//initialisation
	for (i=0; i<nb; i++)
		h[i] = a[i] = cx[i] = d[i] = c[i] = cy[i] = cz[i] = g[i] = gam[i] = 0.0;
    
	// as a spline starts and ends with a line one adds two points
	// in order to have continuity in starting point
    if (style == NIBBBezierNodeOpenEndsStyle) {
        for (i=0; i<numVectors; i++)
        {
            px[i+1] = vectors[i].x;// * fZoom / 100;
            py[i+1] = vectors[i].y;// * fZoom / 100;
            pz[i+1] = vectors[i].z;// * fZoom / 100;
        }
        px[0] = 2.0*px[1] - px[2]; px[nb-1] = 2.0*px[nb-2] - px[nb-3];
        py[0] = 2.0*py[1] - py[2]; py[nb-1] = 2.0*py[nb-2] - py[nb-3];
        pz[0] = 2.0*pz[1] - pz[2]; pz[nb-1] = 2.0*pz[nb-2] - pz[nb-3];
    } else { // NIBBBezierNodeEndsMeetStyle
        for (i=0; i<numVectors; i++)
        {
            px[i+1] = vectors[i].x;// * fZoom / 100;
            py[i+1] = vectors[i].y;// * fZoom / 100;
            pz[i+1] = vectors[i].z;// * fZoom / 100;
        }
        px[0] = px[nb-3]; px[nb-1] = px[2];
        py[0] = py[nb-3]; py[nb-1] = py[2];
        pz[0] = pz[nb-3]; pz[nb-1] = pz[2];
    }

    
	// check all points are separate, if not do not smooth
	// this happens when the zoom factor is too small
	// so in this case the smooth is not useful
    
	ok=TRUE;
	if(nb<3) ok=FALSE;
    
//	for (i=1; i<nb; i++) 
//        if (px[i] == px[i-1] && py[i] == py[i-1] && pz[i] == pz[i-1]) {ok = FALSE; break;}
	if (ok == FALSE)
		failed = YES;
    
	if( failed)
	{
		free(a);
		free(c);
		free(cx);
		free(cy);
		free(cz);
		free(d);
		free(g);
		free(gam);
		free(h);
		free(px);
		free(py);
		free(pz);
		
        fprintf(stderr, "NIBBBezierCoreCreateMutableCurveWithNodes failed because some points overlapped\n");
		return NULL;
	}
    
	// define hi (distance between points) h0 distance between 0 and 1.
	// di distance of point i from start point
	for (i = 0; i<nb-1; i++)
	{
		xi = px[i+1] - px[i];
		yi = py[i+1] - py[i];
		zi = pz[i+1] - pz[i];
		h[i] = (double) sqrt(xi*xi + yi*yi + zi*zi);
		d[i+1] = d[i] + h[i];
	}
	
	// define ai and ci
	for (i=2; i<nb-1; i++) a[i] = 2.0 * h[i-1] / (h[i] + h[i-1]);
	for (i=1; i<nb-2; i++) c[i] = 2.0 * h[i] / (h[i] + h[i-1]);
    
	// define gi in function of x
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(di - di+1) - (yi+1 - yi+2)/(di+1 - di+2)]
	//                      / (di - di+2)
	for (i=1; i<nb-1; i++) 
		g[i] = 6.0 * ( ((px[i-1] - px[i]) / (d[i-1] - d[i])) - ((px[i] - px[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);
    
	// compute cx vector
	b=4; bet=4;
	cx[1] = g[1]/b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cx[j] = (g[j] - a[j] * cx[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cx[j] -= gam[j+1] * cx[j+1];
    
	// define gi in function of y
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(hi - hi+1) - (yi+1 - yi+2)/(hi+1 - hi+2)]
	//                      / (hi - hi+2)
	for (i=1; i<nb-1; i++)
		g[i] = 6.0 * ( ((py[i-1] - py[i]) / (d[i-1] - d[i])) - ((py[i] - py[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);
    
	// compute cy vector
	b = 4.0; bet = 4.0;
	cy[1] = g[1] / b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cy[j] = (g[j] - a[j] * cy[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cy[j] -= gam[j+1] * cy[j+1];
    
	// define gi in function of z
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(hi - hi+1) - (yi+1 - yi+2)/(hi+1 - hi+2)]
	//                      / (hi - hi+2)
	for (i=1; i<nb-1; i++)
		g[i] = 6.0 * ( ((pz[i-1] - pz[i]) / (d[i-1] - d[i])) - ((pz[i] - pz[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);
    
	// compute cz vector
	b = 4.0; bet = 4.0;
	cz[1] = g[1] / b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cz[j] = (g[j] - a[j] * cz[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cz[j] -= gam[j+1] * cz[j+1];
    
	// OK we have the cx and cy and cz vectors, from that we can compute the
	// coeff of the polynoms for x and y and z andfor each interval
	// S(x) (xi, xi+1)  = ai + bi (x-xi) + ci (x-xi)2 + di (x-xi)3
	// di = (ci+1 - ci) / 3 hi
	// ai = yi
	// bi = ((ai+1 - ai) / hi) - (hi/3) (ci+1 + 2 ci)
    
    lastEndpoint = NIBBVectorMake(px[1], py[1], pz[1]);
    NIBBBezierCoreAddSegment(newBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, lastEndpoint);
    
	// for each interval
	for (i=1; i<nb-2; i++)
	{
		// compute coef for x polynom
		ccx = cx[i];
		aax = px[i];
		ddx = (cx[i+1] - cx[i]) / (3.0 * h[i]);
		bbx = ((px[i+1] - px[i]) / h[i]) - (h[i] / 3.0) * (cx[i+1] + 2.0 * cx[i]);
        
		// compute coef for y polynom
		ccy = cy[i];
		aay = py[i];
		ddy = (cy[i+1] - cy[i]) / (3.0 * h[i]);
		bby = ((py[i+1] - py[i]) / h[i]) - (h[i] / 3.0) * (cy[i+1] + 2.0 * cy[i]);
        
		// compute coef for z polynom
		ccz = cz[i];
		aaz = pz[i];
		ddz = (cz[i+1] - cz[i]) / (3.0 * h[i]);
		bbz = ((pz[i+1] - pz[i]) / h[i]) - (h[i] / 3.0) * (cz[i+1] + 2.0 * cz[i]);
        
        //p.x = (aax + bbx * (double)j + ccx * (double)(j * j) + ddx * (double)(j * j * j));
        
        endpoint.x = aax + bbx*h[i] + ccx*h[i]*h[i] + ddx*h[i]*h[i]*h[i];
        control1.x = lastEndpoint.x + ((bbx*h[i]) / 3.0);
        control2.x = endpoint.x - (((bbx + 2.0*ccx*h[i] + 3.0*ddx*h[i]*h[i]) * h[i]) / 3.0);
        
        endpoint.y = aay + bby*h[i] + ccy*h[i]*h[i] + ddy*h[i]*h[i]*h[i];
        control1.y = lastEndpoint.y + ((bby*h[i]) / 3.0);
        control2.y = endpoint.y - (((bby + 2.0*ccy*h[i] + 3.0*ddy*h[i]*h[i]) * h[i]) / 3.0);
        
        endpoint.z = aaz + bbz*h[i] + ccz*h[i]*h[i] + ddz*h[i]*h[i]*h[i];
        control1.z = lastEndpoint.z + ((bbz*h[i]) / 3.0);
        control2.z = endpoint.z - (((bbz + 2.0*ccz*h[i] + 3.0*ddz*h[i]*h[i]) * h[i]) / 3.0);
        
        NIBBBezierCoreAddSegment(newBezierCore, NIBBCurveToBezierCoreSegmentType, control1, control2, endpoint);
        lastEndpoint = endpoint;
    }//endfor each interval
    
	// delete dynamic structures
	free(a);
	free(c);
	free(cx);
    free(cy);
    free(cz);
	free(d);
	free(g);
	free(gam);
	free(h);
	free(px);
	free(py);
	free(pz);
    
	return newBezierCore;
}

NIBBVector NIBBBezierCoreVectorAtStart(NIBBBezierCoreRef bezierCore)
{
    NIBBVector moveTo;
    
    if (NIBBBezierCoreSegmentCount(bezierCore) == 0) {
        return NIBBVectorZero;
    }
    
    NIBBBezierCoreGetSegmentAtIndex(bezierCore, 0, NULL, NULL, &moveTo);
    return moveTo;
}

NIBBVector NIBBBezierCoreVectorAtEnd(NIBBBezierCoreRef bezierCore)
{
    NIBBVector endPoint;
    
    if (NIBBBezierCoreSegmentCount(bezierCore) == 0) {
        return NIBBVectorZero;
    }
    
    NIBBBezierCoreGetSegmentAtIndex(bezierCore, NIBBBezierCoreSegmentCount(bezierCore) - 1, NULL, NULL, &endPoint);
    return endPoint;
}


NIBBVector NIBBBezierCoreTangentAtStart(NIBBBezierCoreRef bezierCore)
{
    NIBBVector moveTo;
    NIBBVector endPoint;
    NIBBVector control1;
    
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return NIBBVectorZero;
    }
    
    NIBBBezierCoreGetSegmentAtIndex(bezierCore, 0, NULL, NULL, &moveTo);
    
    if (NIBBBezierCoreGetSegmentAtIndex(bezierCore, 1, &control1, NULL, &endPoint) == NIBBCurveToBezierCoreSegmentType) {
        return NIBBVectorNormalize(NIBBVectorSubtract(endPoint, control1));
    } else {
        return NIBBVectorNormalize(NIBBVectorSubtract(endPoint, moveTo));
    }
}

NIBBVector NIBBBezierCoreTangentAtEnd(NIBBBezierCoreRef bezierCore)
{
    NIBBVector prevEndPoint;
    NIBBVector endPoint;
    NIBBVector control2;
    CFIndex segmentCount;
    
    segmentCount = NIBBBezierCoreSegmentCount(bezierCore);
    if (segmentCount < 2) {
        return NIBBVectorZero;
    }    
    
    if (NIBBBezierCoreGetSegmentAtIndex(bezierCore, segmentCount - 1, NULL, &control2, &endPoint) == NIBBCurveToBezierCoreSegmentType) {
        return NIBBVectorNormalize(NIBBVectorSubtract(endPoint, control2));
    } else {
        NIBBBezierCoreGetSegmentAtIndex(bezierCore, segmentCount - 2, NULL, NULL, &prevEndPoint);
        return NIBBVectorNormalize(NIBBVectorSubtract(endPoint, prevEndPoint));
    }    
}

CGFloat NIBBBezierCoreRelativePositionClosestToVector(NIBBBezierCoreRef bezierCore, NIBBVector vector, NIBBVectorPointer closestVector, CGFloat *distance)
{
    NIBBBezierCoreIteratorRef bezierIterator;
    NIBBBezierCoreRef flattenedBezier;
    NIBBVector start;
    NIBBVector end;
    NIBBVector segment;
	NIBBVector segmentDirection;
    NIBBVector translatedVector;
	NIBBVector bestVector;
	NIBBBezierCoreSegmentType segmentType;
    CGFloat tempDistance;
    CGFloat bestRelativePosition;
    CGFloat bestDistance;
    CGFloat projectedDistance;
    CGFloat segmentLength;
    CGFloat traveledDistance;
    
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return 0.0;
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezier = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezier, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezier = NIBBBezierCoreRetain(bezierCore);
    }

    bezierIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezier);
    
    bestDistance = CGFLOAT_MAX;
    bestRelativePosition = 0.0;
    traveledDistance = 0.0;
    
    NIBBBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
    
    while (!NIBBBezierCoreIteratorIsAtEnd(bezierIterator)) {
        start = end;
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
        
        segment = NIBBVectorSubtract(end, start);
        translatedVector = NIBBVectorSubtract(vector, start);
        segmentLength = NIBBVectorLength(segment);
		segmentDirection = NIBBVectorScalarMultiply(segment, 1.0/segmentLength);
        
        projectedDistance = NIBBVectorDotProduct(translatedVector, segmentDirection);
        
		if (segmentType != NIBBMoveToBezierCoreSegmentType) {
			if (projectedDistance >= 0 && projectedDistance <= segmentLength) {
				tempDistance = NIBBVectorLength(NIBBVectorSubtract(translatedVector, NIBBVectorScalarMultiply(segmentDirection, projectedDistance)));
				if (tempDistance < bestDistance) {
					bestDistance = tempDistance;
					bestRelativePosition = traveledDistance + projectedDistance;
					bestVector = NIBBVectorAdd(start, NIBBVectorScalarMultiply(segmentDirection, projectedDistance));
				}
			} else if (projectedDistance < 0) {
				tempDistance = NIBBVectorDistance(start, vector);
				if (tempDistance < bestDistance) {
					bestDistance = tempDistance;
					bestRelativePosition = traveledDistance;
					bestVector = start;
				} 
			} else {
				tempDistance = NIBBVectorDistance(end, vector);
				if (tempDistance < bestDistance) {
					bestDistance = tempDistance;
					bestRelativePosition = traveledDistance + segmentLength;
					bestVector = end;
				} 
			}
		
			traveledDistance += segmentLength;
		}
    }
    
    bestRelativePosition /= NIBBBezierCoreLength(flattenedBezier);    
    
    NIBBBezierCoreRelease(flattenedBezier);
    NIBBBezierCoreIteratorRelease(bezierIterator);
    
    if (distance) {
        *distance = bestDistance;
    }
	if (closestVector) {
		*closestVector = bestVector;
	}
    
    return bestRelativePosition;
}

CGFloat NIBBBezierCoreRelativePositionClosestToLine(NIBBBezierCoreRef bezierCore, NIBBLine line, NIBBVectorPointer closestVector, CGFloat *distance)
{
    NIBBBezierCoreIteratorRef bezierIterator;
    NIBBBezierCoreRef flattenedBezier;
    NIBBVector start;
    NIBBVector end;
    NIBBLine segment;
    NIBBVector closestPoint;
    NIBBVector bestVector;
	NIBBBezierCoreSegmentType segmentType;
    CGFloat mu;
    CGFloat tempDistance;
    CGFloat bestRelativePosition;
    CGFloat bestDistance;
    CGFloat traveledDistance;
    CGFloat segmentLength;

    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return 0.0;
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezier = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezier, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezier = NIBBBezierCoreRetain(bezierCore);
    }

    bezierIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezier);
    
    bestDistance = CGFLOAT_MAX;
    bestRelativePosition = 0.0;
    traveledDistance = 0.0;
    NIBBBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
    bestVector = end;

    while (!NIBBBezierCoreIteratorIsAtEnd(bezierIterator)) {
        start = end;
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
        
        segmentLength = NIBBVectorDistance(start, end);
        
        if (segmentLength > 0.0 && segmentType != NIBBMoveToBezierCoreSegmentType) {
            segment = NIBBLineMakeFromPoints(start, end);
            tempDistance = NIBBLineClosestPoints(segment, line, &closestPoint, NULL);
            
            if (tempDistance < bestDistance) {
                mu = NIBBVectorDotProduct(NIBBVectorSubtract(end, start), NIBBVectorSubtract(closestPoint, start)) / (segmentLength*segmentLength);
                
                if (mu < 0.0) {
                    tempDistance = NIBBVectorDistanceToLine(start, line);
                    if (tempDistance < bestDistance) {
                        bestDistance = tempDistance;
                        bestRelativePosition = traveledDistance;
                        bestVector = start;
                    }
                } else if (mu > 1.0) {
                    tempDistance = NIBBVectorDistanceToLine(end, line);
                    if (tempDistance < bestDistance) {
                        bestDistance = tempDistance;
                        bestRelativePosition = traveledDistance + segmentLength;
                        bestVector = end;
                    }
                } else {
                    bestDistance = tempDistance;
                    bestRelativePosition = traveledDistance + (segmentLength * mu);
                    bestVector = closestPoint;
                }
            }
            traveledDistance += segmentLength;
        }
    }
    
    bestRelativePosition /= NIBBBezierCoreLength(flattenedBezier);    

    NIBBBezierCoreRelease(flattenedBezier);
    NIBBBezierCoreIteratorRelease(bezierIterator);
    
    if (closestVector) {
        *closestVector = bestVector;
    }
    if (distance) {
        *distance = bestDistance;
    }
    
    return bestRelativePosition;
}

CFIndex NIBBBezierCoreGetVectorInfo(NIBBBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, NIBBVector initialNormal,
                                  NIBBVectorArray vectors, NIBBVectorArray tangents, NIBBVectorArray normals, CFIndex numVectors)
{
    NIBBBezierCoreRef flattenedBezierCore;
    NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVector nextVector;
    NIBBVector startVector;
    NIBBVector endVector;
    NIBBVector previousTangentVector;
    NIBBVector nextTangentVector;
    NIBBVector tangentVector;
    NIBBVector startTangentVector;
    NIBBVector endTangentVector;
    NIBBVector previousNormalVector;
    NIBBVector nextNormalVector;
    NIBBVector normalVector;
    NIBBVector startNormalVector;
    NIBBVector endNormalVector;
    NIBBVector segmentDirection;
    NIBBVector nextSegmentDirection;
    CGFloat segmentLength;
    CGFloat distanceTraveled;
    CGFloat extraDistance;
    CFIndex i;
    bool done;
	
    if (numVectors == 0 || NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
	assert(normals == NULL || NIBBBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
	assert(NIBBBezierCoreSubpathCount(bezierCore) == 1); // TODO! I should fix this to be able to handle moveTo as long as normals don't matter
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreSubdivide((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultSubdivideSegmentLength);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore);
    }    
    
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    extraDistance = startingDistance; // distance that was traveled past the last point
    done = false;
	i = 0;
    startVector = NIBBVectorZero;
    endVector = NIBBVectorZero;
    
    NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &startVector);
	NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endVector);
    segmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(endVector, startVector));
    segmentLength = NIBBVectorDistance(endVector, startVector);
    
    normalVector = NIBBVectorNormalize(NIBBVectorSubtract(initialNormal, NIBBVectorProject(initialNormal, segmentDirection)));
    if(NIBBVectorEqualToVector(normalVector, NIBBVectorZero)) {
        normalVector = NIBBVectorNormalize(NIBBVectorCrossProduct(NIBBVectorMake(-1.0, 0.0, 0.0), segmentDirection));
        if(NIBBVectorEqualToVector(normalVector, NIBBVectorZero)) {
            normalVector = NIBBVectorNormalize(NIBBVectorCrossProduct(NIBBVectorMake(0.0, 1.0, 0.0), segmentDirection));
        }
    }
    
    previousNormalVector = normalVector;
    tangentVector = segmentDirection;
    previousTangentVector = tangentVector;
    
	while (done == false) {
		distanceTraveled = extraDistance;
        
        if (NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
            nextNormalVector = normalVector;
            nextTangentVector = tangentVector;
            nextVector = endVector;
            done = true;
        } else {
            NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &nextVector);
            nextSegmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(nextVector, endVector));
            nextNormalVector = NIBBVectorBend(normalVector, segmentDirection, nextSegmentDirection);
            nextNormalVector = NIBBVectorSubtract(nextNormalVector, NIBBVectorProject(nextNormalVector, nextSegmentDirection)); // make sure the new vector is really normal
            nextNormalVector = NIBBVectorNormalize(nextNormalVector);
            
            nextTangentVector = nextSegmentDirection;
        }
        startNormalVector = NIBBVectorNormalize(NIBBVectorLerp(previousNormalVector, normalVector, 0.5)); 
        endNormalVector = NIBBVectorNormalize(NIBBVectorLerp(nextNormalVector, normalVector, 0.5)); 
        
        startTangentVector = NIBBVectorNormalize(NIBBVectorLerp(previousTangentVector, tangentVector, 0.5)); 
        endTangentVector = NIBBVectorNormalize(NIBBVectorLerp(nextTangentVector, tangentVector, 0.5)); 
        
		while(distanceTraveled < segmentLength)
		{
            if (vectors) {
                vectors[i] = NIBBVectorAdd(startVector, NIBBVectorScalarMultiply(segmentDirection, distanceTraveled));
            }
            if (tangents) {
                tangents[i] = NIBBVectorNormalize(NIBBVectorLerp(startTangentVector, endTangentVector, distanceTraveled/segmentLength));
                
            }
            if (normals) {
                normals[i] = NIBBVectorNormalize(NIBBVectorLerp(startNormalVector, endNormalVector, distanceTraveled/segmentLength));
            }
            i++;
            if (i >= numVectors) {
                NIBBBezierCoreIteratorRelease(bezierCoreIterator);
                return i;
            }
            
            distanceTraveled += spacing;
		}
		
		extraDistance = distanceTraveled - segmentLength;
        
        previousNormalVector = normalVector;
        normalVector = nextNormalVector;
        previousTangentVector = tangentVector;
        tangentVector = nextTangentVector;
        segmentDirection = nextSegmentDirection;
        startVector = endVector;
        endVector = nextVector;
        segmentLength = NIBBVectorDistance(startVector, endVector);
        
	}
	
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
	return i;
}

CFIndex NIBBBezierCoreGetProjectedVectorInfo(NIBBBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, NIBBVector projectionDirection,
                                  NIBBVectorArray vectors, NIBBVectorArray tangents, NIBBVectorArray normals, CGFloat *relativePositions, CFIndex numVectors)
{
    NIBBBezierCoreRef flattenedBezierCore;
    NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBBezierCoreRef projectedBezierCore;
    NIBBBezierCoreIteratorRef projectedBezierCoreIterator;
    NIBBVector nextVector;
    NIBBVector startVector;
    NIBBVector endVector;
    NIBBVector nextProjectedVector;
    NIBBVector startProjectedVector;
    NIBBVector endProjectedVector;
    NIBBVector previousTangentVector;
    NIBBVector nextTangentVector;
    NIBBVector tangentVector;
    NIBBVector startTangentVector;
    NIBBVector endTangentVector;
    NIBBVector previousNormalVector;
    NIBBVector nextNormalVector;
    NIBBVector normalVector;
    NIBBVector startNormalVector;
    NIBBVector endNormalVector;
    NIBBVector segmentDirection;
    NIBBVector projectedSegmentDirection;
    NIBBVector nextSegmentDirection;
    NIBBVector nextProjectedSegmentDirection;
    CGFloat segmentLength;
    CGFloat projectedSegmentLength;
    CGFloat distanceTraveled;
    CGFloat totalDistanceTraveled;
    CGFloat extraDistance;
    CGFloat bezierLength;
    CFIndex i;
    bool done;
	
    if (numVectors == 0 || NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
	assert(normals == NULL || NIBBBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
	assert(NIBBBezierCoreSubpathCount(bezierCore) == 1); // TODO! I should fix this to be able to handle moveTo as long as normals don't matter
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreSubdivide((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultSubdivideSegmentLength);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore);
    }    
    
    bezierLength = NIBBBezierCoreLength(flattenedBezierCore);
    projectedBezierCore = NIBBBezierCoreCreateCopyProjectedToPlane(flattenedBezierCore, NIBBPlaneMake(NIBBVectorZero, projectionDirection));
    
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    projectedBezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(projectedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    NIBBBezierCoreRelease(projectedBezierCore);
    projectedBezierCore = NULL;
    
    extraDistance = startingDistance; // distance that was traveled past the last point
    totalDistanceTraveled = startingDistance;
    done = false;
	i = 0;
    startVector = NIBBVectorZero;
    endVector = NIBBVectorZero;
    startProjectedVector = NIBBVectorZero;
    endProjectedVector = NIBBVectorZero;
    
    NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &startVector);
    NIBBBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &startProjectedVector);
	NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endVector);
	NIBBBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &endProjectedVector);
    segmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(endVector, startVector));
    projectedSegmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(endProjectedVector, startProjectedVector));
    segmentLength = NIBBVectorDistance(endVector, startVector);
    projectedSegmentLength = NIBBVectorDistance(endProjectedVector, startProjectedVector);
    
    normalVector = NIBBVectorNormalize(NIBBVectorCrossProduct(projectedSegmentDirection, projectionDirection));
    if (NIBBVectorIsZero(normalVector)) {
        normalVector = NIBBVectorANormalVector(projectionDirection);
    }
                      
    previousNormalVector = normalVector;
    tangentVector = segmentDirection;
    previousTangentVector = tangentVector;
    
	while (done == false) {
		distanceTraveled = extraDistance;
        
        if (NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
            nextNormalVector = normalVector;
            nextTangentVector = tangentVector;
            nextVector = endVector;
            done = true;
        } else {
            NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &nextVector);
            NIBBBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &nextProjectedVector);
            nextSegmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(nextVector, endVector));
            nextProjectedSegmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(nextProjectedVector, endProjectedVector));
            nextNormalVector = NIBBVectorNormalize(NIBBVectorCrossProduct(nextProjectedSegmentDirection, projectionDirection));
            if (NIBBVectorIsZero(nextNormalVector)) {
                nextNormalVector = NIBBVectorANormalVector(projectionDirection);
            }
            
            nextTangentVector = nextSegmentDirection;
        }
        startNormalVector = NIBBVectorNormalize(NIBBVectorLerp(previousNormalVector, normalVector, 0.5)); 
        endNormalVector = NIBBVectorNormalize(NIBBVectorLerp(nextNormalVector, normalVector, 0.5)); 
        
        startTangentVector = NIBBVectorNormalize(NIBBVectorLerp(previousTangentVector, tangentVector, 0.5)); 
        endTangentVector = NIBBVectorNormalize(NIBBVectorLerp(nextTangentVector, tangentVector, 0.5)); 
        
		while(distanceTraveled < projectedSegmentLength)
		{
            CGFloat segmentDistanceTraveled;
            segmentDistanceTraveled = distanceTraveled * (segmentLength/projectedSegmentLength);
            
            if (vectors) {
                vectors[i] = NIBBVectorAdd(startVector, NIBBVectorScalarMultiply(segmentDirection, segmentDistanceTraveled));
            }
            if (tangents) {
                tangents[i] = NIBBVectorNormalize(NIBBVectorLerp(startTangentVector, endTangentVector, distanceTraveled/projectedSegmentLength));
            }
            if (normals) {
                normals[i] = NIBBVectorNormalize(NIBBVectorLerp(startNormalVector, endNormalVector, distanceTraveled/projectedSegmentLength));
            }
            if (relativePositions) {
                relativePositions[i] = (totalDistanceTraveled + segmentDistanceTraveled) / bezierLength;
            }
            i++;
            if (i >= numVectors) {
                NIBBBezierCoreIteratorRelease(bezierCoreIterator);
                return i;
            }
            
            distanceTraveled += spacing;
		}
		
		extraDistance = distanceTraveled - projectedSegmentLength;
        
        totalDistanceTraveled += segmentLength;

        previousNormalVector = normalVector;
        normalVector = nextNormalVector;
        previousTangentVector = tangentVector;
        tangentVector = nextTangentVector;
        segmentDirection = nextSegmentDirection;
        startVector = endVector;
        endVector = nextVector;
        startProjectedVector = endProjectedVector;
        endProjectedVector = nextProjectedVector;
        segmentLength = NIBBVectorDistance(endVector, startVector);
        projectedSegmentLength = NIBBVectorDistance(endProjectedVector, startProjectedVector);
	}
	
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
	return i;
}

//CFIndex NIBBBezierCoreGetCollapsedVectorInfo(NIBBBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingPoint, NIBBVector collapsingDirection, // returns points that are spacing away from each other after the collapsing has occured, the returned points are not collapsed
//                                           NIBBVectorArray vectors, NIBBVectorArray tangents, NIBBVectorArray normals, CGFloat *relativePositions, CFIndex numVectors) // fills numVectors in the vector arrays, returns the actual number of vectors that were set in the arrays
//{
//    NIBBBezierCoreRef flattenedBezierCore;
//    NIBBBezierCoreRef projectedBezierCore;
//    NIBBBezierCoreIteratorRef bezierCoreIterator;
//    NIBBBezierCoreIteratorRef projectedBezierCoreIterator;
//    NIBBVector start;
//    NIBBVector end;
//    NIBBVector projectedStart;
//    NIBBVector projectedEnd;
//    NIBBVector segmentDirection;
//    NIBBVector projectedSegmentDirection;
//    CGFloat length;
//    CGFloat distanceTraveled;
//    CGFloat totalDistanceTraveled;
//    CGFloat extraDistance;
//    CGFloat segmentLength;
//    CGFloat projectedSegmentLength;
//    CFIndex i;
//    
//    if (NIBBBezierCoreHasCurve(bezierCore)) {
//        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
//        NIBBBezierCoreSubdivide((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultSubdivideSegmentLength);
//        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
//    } else {
//        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore);
//    }
//
//    projectedBezierCore = NIBBBezierCoreCreateCopyProjectedToPlane(flattenedBezierCore, NIBBPlaneMake(NIBBVectorZero, collapsingDirection));
//    
//    length = NIBBBezierCoreLength(flattenedBezierCore);
//    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
//    projectedBezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(projectedBezierCore);
//    NIBBBezierCoreRelease(flattenedBezierCore);
//    flattenedBezierCore = NULL;
//    NIBBBezierCoreRelease(projectedBezierCore);
//    projectedBezierCore = NULL;
//    
//    distanceTraveled = 0;
//    totalDistanceTraveled = 0;
//    extraDistance = 0;
//    i = 0;
//    NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
//    NIBBBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &projectedEnd);
//    
//    while (!NIBBBezierCoreIteratorIsAtEnd(bezierIterator)) {
//        start = end;
//        projectedStart = projectedEnd;
//        NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
//        NIBBBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &projectedEnd);
//
//        segmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(end, start));
//        projectedSegmentDirection = NIBBVectorNormalize(NIBBVectorSubtract(projectedEnd, projectedStart));
//        projectedSegmentLength = NIBBVectorDistance(projectedStart, projectedEnd);
//        segmentLength = NIBBVectorDistance(start, end);
//        distanceTraveled = extraDistance;
//        
//		while(distanceTraveled < segmentLength)
//		{
//            if (vectors) {
//                vectors[i] = NIBBVectorAdd(start, NIBBVectorScalarMultiply(segmentDirection, distanceTraveled * (segmentLength / projectedSegmentLength)));
//            }
//            if (tangents) {
//                tangents[i] = segmentDirection;
//                tangents[i] = NIBBVectorNormalize(NIBBVectorAdd(NIBBVectorScalarMultiply(startTangentVector, 1.0-distanceTraveled/segmentLength), NIBBVectorScalarMultiply(endTangentVector, distanceTraveled/segmentLength)));
//                
//            }
//            if (normals) {
//                normals[i] = NIBBVectorNormalize(NIBBVectorAdd(NIBBVectorScalarMultiply(startNormalVector, 1.0-distanceTraveled/segmentLength), NIBBVectorScalarMultiply(endNormalVector, distanceTraveled/segmentLength)));
//            }
//            i++;
//            if (i >= numVectors) {
//                NIBBBezierCoreIteratorRelease(bezierCoreIterator);
//                NIBBBezierCoreIteratorRelease(projectedBezierCoreIterator);
//                return i;
//            }
//            
//            distanceTraveled += spacing;
//            totalDistanceTraveled += spacing;
//		}
//        
//
//		extraDistance = distanceTraveled - segmentLength;
//        
//    }
//        
//    // iterate over each segment. Collapse the segment by subtracting the projection of the segment onto the collapsing direction.
//    // do the w
//    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
//    NIBBBezierCoreIteratorRelease(projectedBezierCoreIterator);
//}

NIBBVector NIBBBezierCoreNormalAtEndWithInitialNormal(NIBBBezierCoreRef bezierCore, NIBBVector initialNormal)
{
    NIBBBezierCoreRef flattenedBezierCore;
    NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVector normalVector;
    NIBBVector segment;
    NIBBVector prevSegment;
    NIBBVector start;
    NIBBVector end;
    
	assert(NIBBBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath

    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return initialNormal;
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore);
    }
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    
    NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &start);
    NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
    prevSegment = NIBBVectorSubtract(end, start);
    
    normalVector = NIBBVectorNormalize(NIBBVectorSubtract(initialNormal, NIBBVectorProject(initialNormal, prevSegment)));
    if(NIBBVectorEqualToVector(normalVector, NIBBVectorZero)) {
        normalVector = NIBBVectorNormalize(NIBBVectorCrossProduct(NIBBVectorMake(-1.0, 0.0, 0.0), prevSegment));
        if(NIBBVectorEqualToVector(normalVector, NIBBVectorZero)) {
            normalVector = NIBBVectorNormalize(NIBBVectorCrossProduct(NIBBVectorMake(0.0, 1.0, 0.0), prevSegment));
        }
    }
    
    while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        start = end;
        NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
        
        segment = NIBBVectorSubtract(end, start);
        normalVector = NIBBVectorBend(normalVector, prevSegment, segment);
        normalVector = NIBBVectorSubtract(normalVector, NIBBVectorProject(normalVector, segment)); // make sure the new vector is really normal
        normalVector = NIBBVectorNormalize(normalVector);

        prevSegment = segment;
    }
    
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    return normalVector;
}

NIBBBezierCoreRef NIBBBezierCoreCreateOutline(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector initialNormal)
{
    return NIBBBezierCoreCreateMutableOutline(bezierCore, distance, spacing, initialNormal);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableOutline(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector initialNormal)
{
    NIBBBezierCoreRef flattenedBezierCore;
    NIBBMutableBezierCoreRef outlineBezier;
    NIBBVector endpoint;
    NIBBVector endpointNormal;
    CGFloat length;
    NSInteger i;
    NSUInteger numVectors;
    NIBBVectorArray vectors;
    NIBBVectorArray normals;
    NIBBVectorArray scaledNormals;
    NIBBVectorArray side;
    
	assert(NIBBBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
    
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return NULL;
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreSubdivide((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultSubdivideSegmentLength);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
    
    length = NIBBBezierCoreLength(flattenedBezierCore);
    
    if (spacing * 2 >= length) {
        NIBBBezierCoreRelease(flattenedBezierCore);
        return NULL;
    }
    
    numVectors = length/spacing + 1.0;
    
    vectors = malloc(numVectors * sizeof(NIBBVector));
    normals = malloc(numVectors * sizeof(NIBBVector));
    scaledNormals = malloc(numVectors * sizeof(NIBBVector));
    side = malloc(numVectors * sizeof(NIBBVector));
    outlineBezier = NIBBBezierCoreCreateMutable();
    
    numVectors = NIBBBezierCoreGetVectorInfo(flattenedBezierCore, spacing, 0, initialNormal, vectors, NULL, normals, numVectors);
    NIBBBezierCoreGetSegmentAtIndex(flattenedBezierCore, NIBBBezierCoreSegmentCount(flattenedBezierCore) - 1, NULL, NULL, &endpoint);
    endpointNormal = NIBBVectorNormalize(NIBBVectorSubtract(normals[numVectors-1], NIBBVectorProject(normals[numVectors-1], NIBBBezierCoreTangentAtEnd(flattenedBezierCore))));
    endpointNormal = NIBBVectorScalarMultiply(endpointNormal, distance);
    
    memcpy(scaledNormals, normals, numVectors * sizeof(NIBBVector));
    NIBBVectorScalarMultiplyVectors(distance, scaledNormals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIBBVector));
    NIBBVectorAddVectors(side, scaledNormals, numVectors);
    
    NIBBBezierCoreAddSegment(outlineBezier, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[i]);
    }
    NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, NIBBVectorAdd(endpoint, endpointNormal));
    
    memcpy(scaledNormals, normals, numVectors * sizeof(NIBBVector));
    NIBBVectorScalarMultiplyVectors(-distance, scaledNormals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIBBVector));
    NIBBVectorAddVectors(side, scaledNormals, numVectors);
    
    NIBBBezierCoreAddSegment(outlineBezier, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[i]);
    }
    NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, NIBBVectorAdd(endpoint, NIBBVectorInvert(endpointNormal)));
    
    free(vectors);
    free(normals);
    free(scaledNormals);
    free(side);
    
    NIBBBezierCoreRelease(flattenedBezierCore);
    
    return outlineBezier;
}

NIBBBezierCoreRef NIBBBezierCoreCreateOutlineWithNormal(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector projectionNormal)
{
    return NIBBBezierCoreCreateMutableOutlineWithNormal(bezierCore, distance, spacing, projectionNormal);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableOutlineWithNormal(NIBBBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIBBVector projectionNormal)
{
    NIBBBezierCoreRef flattenedBezierCore;
    NIBBMutableBezierCoreRef outlineBezier;
    NIBBVector endpoint;
    NIBBVector endpointNormal;
    CGFloat length;
    NSInteger i;
    NSUInteger numVectors;
    NIBBVectorArray vectors;
    NIBBVectorArray tangents;
    NIBBVectorArray normals;
    NIBBVectorArray side;
    
	assert(NIBBBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
    
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return NULL;
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreSubdivide((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultSubdivideSegmentLength);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
    
    length = NIBBBezierCoreLength(flattenedBezierCore);
    
    if (spacing * 2 >= length) {
        NIBBBezierCoreRelease(flattenedBezierCore);
        return NULL;
    }
    
    numVectors = length/spacing + 1.0;
    
    vectors = malloc(numVectors * sizeof(NIBBVector));
    tangents = malloc(numVectors * sizeof(NIBBVector));
    normals = malloc(numVectors * sizeof(NIBBVector));
    side = malloc(numVectors * sizeof(NIBBVector));
    outlineBezier = NIBBBezierCoreCreateMutable();
    
    numVectors = NIBBBezierCoreGetVectorInfo(flattenedBezierCore, spacing, 0, NIBBVectorZero, vectors, tangents, NULL, numVectors);
    endpoint = NIBBBezierCoreVectorAtEnd(flattenedBezierCore);
    endpointNormal = NIBBVectorScalarMultiply(NIBBVectorNormalize(NIBBVectorCrossProduct(projectionNormal, NIBBBezierCoreTangentAtEnd(flattenedBezierCore))), distance);
    
    memcpy(normals, tangents, numVectors * sizeof(NIBBVector));
    NIBBVectorCrossProductVectors(projectionNormal, normals, numVectors);
    NIBBVectorNormalizeVectors(normals, numVectors);
    NIBBVectorScalarMultiplyVectors(distance, normals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIBBVector));
    NIBBVectorAddVectors(side, normals, numVectors);
    
    NIBBBezierCoreAddSegment(outlineBezier, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[i]);
    }
    NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, NIBBVectorAdd(endpoint, endpointNormal));
    
    NIBBVectorScalarMultiplyVectors(-1.0, normals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIBBVector));
    NIBBVectorAddVectors(side, normals, numVectors);
    
    NIBBBezierCoreAddSegment(outlineBezier, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, side[i]);
    }
    NIBBBezierCoreAddSegment(outlineBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, NIBBVectorAdd(endpoint, NIBBVectorInvert(endpointNormal)));
    
    free(vectors);
    free(normals);
    free(tangents);
    free(side);
    
    NIBBBezierCoreRelease(flattenedBezierCore);
    
    return outlineBezier;
}

CGFloat NIBBBezierCoreLengthToSegmentAtIndex(NIBBBezierCoreRef bezierCore, CFIndex index, CGFloat flatness) // the length up to and including the segment at index
{
    NIBBMutableBezierCoreRef shortBezierCore;
    NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBBezierCoreSegmentType segmentType;
	NIBBBezierCoreRef flattenedShortBezierCore;
    NIBBVector endpoint;
    NIBBVector control1;
    NIBBVector control2;
    CGFloat length;
    CFIndex i;
    
    assert(index < NIBBBezierCoreSegmentCount(bezierCore));
    
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(bezierCore);
    shortBezierCore = NIBBBezierCoreCreateMutable();
    
    for (i = 0; i <= index; i++) {
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
        NIBBBezierCoreAddSegment(shortBezierCore, segmentType, control1, control2, endpoint);
    }
    
	flattenedShortBezierCore = NIBBBezierCoreCreateFlattenedMutableCopy(shortBezierCore, flatness);
    length = NIBBBezierCoreLength(flattenedShortBezierCore);
	
    NIBBBezierCoreRelease(shortBezierCore);
	NIBBBezierCoreRelease(flattenedShortBezierCore);
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    
    return length;
}

CFIndex NIBBBezierCoreSegmentLengths(NIBBBezierCoreRef bezierCore, CGFloat *lengths, CFIndex numLengths, CGFloat flatness) // returns the number of lengths set
{
	NIBBBezierCoreIteratorRef bezierCoreIterator;
	NIBBMutableBezierCoreRef segmentBezierCore;
	NIBBMutableBezierCoreRef flatenedSegmentBezierCore;
	NIBBVector prevEndpoint;
	NIBBVector control1;
	NIBBVector control2;
	NIBBVector endpoint;
	NIBBBezierCoreSegmentType segmentType;
	CFIndex i;

	bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(bezierCore);
	
	if (numLengths > 0 && NIBBBezierCoreSegmentCount(bezierCore) > 0) {
		lengths[0] = 0.0;
	} else {
		return 0;
	}

	
	NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
	
	for (i = 1; i < MIN(numLengths, NIBBBezierCoreSegmentCount(bezierCore)); i++) {
		segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
		
		segmentBezierCore = NIBBBezierCoreCreateMutable();
		NIBBBezierCoreAddSegment(segmentBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, prevEndpoint);
		NIBBBezierCoreAddSegment(segmentBezierCore, segmentType, control1, control2, endpoint);
		
		flatenedSegmentBezierCore = NIBBBezierCoreCreateFlattenedMutableCopy(segmentBezierCore, flatness);
		lengths[i] = NIBBBezierCoreLength(flatenedSegmentBezierCore);
		
		NIBBBezierCoreRelease(segmentBezierCore);
		NIBBBezierCoreRelease(flatenedSegmentBezierCore);
	}
	
	NIBBBezierCoreIteratorRelease(bezierCoreIterator);

	return i;
}

CFIndex NIBBBezierCoreCountIntersectionsWithPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane)
{
	NIBBBezierCoreRef flattenedBezierCore;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVector endpoint;
    NIBBVector prevEndpoint;
	NIBBBezierCoreSegmentType segmentType;
    NSInteger count;
    
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreSubdivide((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultSubdivideSegmentLength);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
	bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
	count = 0;
	
	NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
	
	while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
		segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
		if (segmentType != NIBBMoveToBezierCoreSegmentType && NIBBPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
			count++;
		}
		prevEndpoint = endpoint;
	}
	NIBBBezierCoreIteratorRelease(bezierCoreIterator);
	return count;
}


CFIndex NIBBBezierCoreIntersectionsWithPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane, NIBBVectorArray intersections, CGFloat *relativePositions, CFIndex numVectors)
{
	NIBBBezierCoreRef flattenedBezierCore;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVector endpoint;
    NIBBVector prevEndpoint;
	NIBBVector intersection;
	NIBBBezierCoreSegmentType segmentType;
    CGFloat length;
	CGFloat distance;
    NSInteger count;
    
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreSubdivide((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultSubdivideSegmentLength);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
    length = NIBBBezierCoreLength(flattenedBezierCore);
	bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
	distance = 0.0; 
	count = 0;
	
	NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
	
	while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator) && count < numVectors) {
		segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
		if (NIBBPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
			if (segmentType != NIBBMoveToBezierCoreSegmentType) {
				intersection = NIBBLineIntersectionWithPlane(NIBBLineMakeFromPoints(prevEndpoint, endpoint), plane);
				if (intersections) {
					intersections[count] = intersection;
				}
				if (relativePositions) {
					relativePositions[count] = (distance + NIBBVectorDistance(prevEndpoint, intersection))/length;
				}
				count++;
			}
		}
		distance += NIBBVectorDistance(prevEndpoint, endpoint);
		prevEndpoint = endpoint;
	}
	NIBBBezierCoreIteratorRelease(bezierCoreIterator);
	return count;	
}


NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyWithEndpointsAtPlaneIntersections(NIBBBezierCoreRef bezierCore, NIBBPlane plane)
{
    NIBBBezierCoreRef flattenedBezierCore;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBMutableBezierCoreRef newBezierCore;
	NIBBBezierCoreSegmentType segmentType;
    NIBBVector endpoint;
    NIBBVector prevEndpoint;
	NIBBVector intersection;
    
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return NIBBBezierCoreCreateMutableCopy(bezierCore);
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    newBezierCore = NIBBBezierCoreCreateMutable();
    
    NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
    NIBBBezierCoreAddSegment(newBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, prevEndpoint);

    while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
		segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
		if (segmentType != NIBBMoveToBezierCoreSegmentType && NIBBPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
            intersection = NIBBLineIntersectionWithPlane(NIBBLineMakeFromPoints(prevEndpoint, endpoint), plane);
            NIBBBezierCoreAddSegment(newBezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, intersection);
		}
        
        NIBBBezierCoreAddSegment(newBezierCore, segmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
		prevEndpoint = endpoint;
	}
    
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    return newBezierCore;
}

NIBBBezierCoreRef NIBBBezierCoreCreateCopyProjectedToPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane)
{
    return NIBBBezierCoreCreateMutableCopyProjectedToPlane(bezierCore, plane);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyProjectedToPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane)
{
    NIBBBezierCoreIteratorRef bezierIterator;
    NIBBMutableBezierCoreRef projectedBezier;
    NIBBVector control1;
    NIBBVector control2;
    NIBBVector endpoint;
    NIBBBezierCoreSegmentType segmentType;
    
    projectedBezier = NIBBBezierCoreCreateMutable();
    
    bezierIterator = NIBBBezierCoreIteratorCreateWithBezierCore(bezierCore);
    
    while (!NIBBBezierCoreIteratorIsAtEnd(bezierIterator)) {
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierIterator, &control1, &control2, &endpoint);
        
        control1 = NIBBLineIntersectionWithPlane(NIBBLineMake(control1, plane.normal), plane);
        control2 = NIBBLineIntersectionWithPlane(NIBBLineMake(control2, plane.normal), plane);
        endpoint = NIBBLineIntersectionWithPlane(NIBBLineMake(endpoint, plane.normal), plane);
        
        NIBBBezierCoreAddSegment(projectedBezier, segmentType, control1, control2, endpoint);
    }
    NIBBBezierCoreIteratorRelease(bezierIterator);
    return projectedBezier;
}

NIBBPlane NIBBBezierCoreLeastSquaresPlane(NIBBBezierCoreRef bezierCore)
{
    NIBBBezierCoreRef flattenedBezierCore;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVectorArray endpoints;
    NIBBPlane plane;
    CFIndex segmentCount;
    CFIndex i;

    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
    
    segmentCount = NIBBBezierCoreSegmentCount(flattenedBezierCore);
    endpoints = malloc(segmentCount * sizeof(NIBBVector));
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    for (i = 0; !NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator); i++) {
        NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoints[i]);
    }
    
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    
    plane = NIBBPlaneLeastSquaresPlaneFromPoints(endpoints, segmentCount);
    
    free(endpoints);
    return plane;
}

CGFloat NIBBBezierCoreMeanDistanceToPlane(NIBBBezierCoreRef bezierCore, NIBBPlane plane)
{
    NIBBBezierCoreRef flattenedBezierCore;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVector endpoint;
    CGFloat totalDistance;
    CFIndex segmentCount;
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
    
    endpoint = NIBBVectorZero;
    segmentCount = NIBBBezierCoreSegmentCount(flattenedBezierCore);
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    totalDistance = 0;
    
    while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        totalDistance += NIBBVectorDistanceToPlane(endpoint, plane);
    }
    
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    
    return totalDistance / (CGFloat)segmentCount;
}

bool NIBBBezierCoreIsPlanar(NIBBBezierCoreRef bezierCore, NIBBPlanePointer bezierCorePlane)
{
    NIBBPlane plane;
    CGFloat meanDistance;
	bool isPlanar;
    
    plane = NIBBBezierCoreLeastSquaresPlane(bezierCore);
    meanDistance = NIBBBezierCoreMeanDistanceToPlane(bezierCore, plane);
    
    isPlanar = meanDistance < 1.0;
	
	if (isPlanar && bezierCorePlane) {
		*bezierCorePlane = plane;
	}
	
	return isPlanar;
}

bool NIBBBezierCoreGetBoundingPlanesForNormal(NIBBBezierCoreRef bezierCore, NIBBVector normal, NIBBPlanePointer topPlanePtr, NIBBPlanePointer bottomPlanePtr)
{
    NIBBBezierCoreRef flattenedBezierCore;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVector endpoint;
    CGFloat z;
    CGFloat minZ;
    CGFloat maxZ;
    NIBBPlane topPlane;
    NIBBPlane bottomPlane;
    
    assert(NIBBVectorIsZero(normal) == false);
    
    minZ = CGFLOAT_MAX;
    maxZ = -CGFLOAT_MAX;
    
    topPlane.normal = NIBBVectorNormalize(normal);
    topPlane.point = NIBBVectorZero;
    bottomPlane.normal = topPlane.normal;
    bottomPlane.point = NIBBVectorZero;

    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore); 
    }
    
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBBBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;

    while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        
        z = NIBBVectorDotProduct(endpoint, normal);
        
        if (z < minZ) {
            minZ = z;
            bottomPlane.point = endpoint;
        }
        
        if (z > maxZ) {
            maxZ = z;
            topPlane.point = endpoint;
        }
    }
    
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    
    if (topPlanePtr) {
        *topPlanePtr = topPlane;
    }
    
    if (bottomPlanePtr) {
        *bottomPlanePtr = bottomPlane;
    }
    
    return true;
}


NIBBBezierCoreRef NIBBBezierCoreCreateCopyByReversing(NIBBBezierCoreRef bezierCore)
{
    return NIBBBezierCoreCreateMutableCopyByReversing(bezierCore);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyByReversing(NIBBBezierCoreRef bezierCore)
{
    NIBBBezierCoreRandomAccessorRef bezierAccessor;
    NIBBMutableBezierCoreRef reversedBezier;
    bool needsClose;
    bool needsMove;
    long i = 0;
    NIBBBezierCoreSegmentType segmentType;
    NIBBVector control1;
    NIBBVector control2;
    NIBBVector endpoint;
    NIBBBezierCoreSegmentType prevSegmentType;
    NIBBVector prevControl1;
    NIBBVector prevControl2;
    NIBBVector prevEndpoint;
    
    bezierAccessor = NIBBBezierCoreRandomAccessorCreateWithBezierCore(bezierCore);
    reversedBezier = NIBBBezierCoreCreateMutable();
    
    // check empty bezierPath special case
    if (NIBBBezierCoreRandomAccessorSegmentCount(bezierAccessor) == 0) {
        NIBBBezierCoreRandomAccessorRelease(bezierAccessor);
        return reversedBezier;
    }
    
    // check for the special case of a bezier with just a moveto
    if (NIBBBezierCoreRandomAccessorSegmentCount(bezierAccessor) == 1) {
        segmentType = NIBBBezierCoreRandomAccessorGetSegmentAtIndex(bezierAccessor, i, &control1, &control2, &endpoint);
        assert(segmentType == NIBBMoveToBezierCoreSegmentType);
        NIBBBezierCoreAddSegment(reversedBezier, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
        NIBBBezierCoreRandomAccessorRelease(bezierAccessor);
        return reversedBezier;
    }
    
    needsClose = false;
    needsMove = true;
    
    prevSegmentType = NIBBBezierCoreRandomAccessorGetSegmentAtIndex(bezierAccessor, NIBBBezierCoreRandomAccessorSegmentCount(bezierAccessor) - 1, &prevControl1, &prevControl2, &prevEndpoint);
    
    for (i = NIBBBezierCoreRandomAccessorSegmentCount(bezierAccessor) - 2; i >= 0; i--) {
        segmentType = NIBBBezierCoreRandomAccessorGetSegmentAtIndex(bezierAccessor, i, &control1, &control2, &endpoint);
        
        if (needsMove && prevSegmentType != NIBBCloseBezierCoreSegmentType) {
            NIBBBezierCoreAddSegment(reversedBezier, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, prevEndpoint);
            needsMove = false;
        }
        
        switch (prevSegmentType) {
            case NIBBCloseBezierCoreSegmentType:
                needsClose = true;
                break;
            case NIBBLineToBezierCoreSegmentType:
                NIBBBezierCoreAddSegment(reversedBezier, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
                break;
            case NIBBCurveToBezierCoreSegmentType:
                NIBBBezierCoreAddSegment(reversedBezier, NIBBCurveToBezierCoreSegmentType, prevControl2, prevControl1, endpoint);
                break;
            case NIBBMoveToBezierCoreSegmentType:
                if (needsClose) {
                    NIBBBezierCoreAddSegment(reversedBezier, NIBBCloseBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, NIBBVectorZero);
                }
                NIBBBezierCoreAddSegment(reversedBezier, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
                needsClose = false;
                needsMove = true;
                break;
            default:
                break;
        }
        
        prevSegmentType = segmentType;
        prevControl1 = control1;
        prevControl2 = control2;
        prevEndpoint = endpoint;
    }
    
    assert(prevSegmentType == NIBBMoveToBezierCoreSegmentType);
    
    NIBBBezierCoreRandomAccessorRelease(bezierAccessor);
    NIBBBezierCoreCheckDebug(reversedBezier);
        
    return reversedBezier;
}

CFArrayRef NIBBBezierCoreCopySubpaths(NIBBBezierCoreRef bezierCore)
{
    CFMutableArrayRef subpaths = CFArrayCreateMutable(NULL, 0, &kNIBBBezierCoreArrayCallBacks);
    NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBMutableBezierCoreRef subpath = NULL;
    NIBBBezierCoreSegmentType segmentType;
    NIBBVector control1;
    NIBBVector control2;
    NIBBVector endpoint;
    
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(bezierCore);
    
    while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
        
        if (segmentType == NIBBMoveToBezierCoreSegmentType) {
            subpath = NIBBBezierCoreCreateMutable();
            CFArrayAppendValue(subpaths, subpath);
            NIBBBezierCoreRelease(subpath);
        }
        
        NIBBBezierCoreAddSegment(subpath, segmentType, control1, control2, endpoint);
    }
    
    return subpaths;
}

NIBBBezierCoreRef NIBBBezierCoreCreateCopyByClipping(NIBBBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition)
{
    return NIBBBezierCoreCreateMutableCopyByClipping(bezierCore, startRelativePosition, endRelativePosition);
}

NIBBMutableBezierCoreRef NIBBBezierCoreCreateMutableCopyByClipping(NIBBBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition)
{
    NIBBBezierCoreRef flattenedBezierCore;
	NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBMutableBezierCoreRef newBezierCore;
	NIBBBezierCoreSegmentType segmentType;
    CGFloat distanceTraveled = 0;
    CGFloat segmentLength = 0;
    CGFloat startPosition;
    CGFloat endPosition;
    CGFloat length;
    NIBBVector endpoint;
    NIBBVector prevEndpoint;
    NIBBVector lerpPoint;
    bool needsMoveto = false;
    
    assert(startRelativePosition >= 0.0 && startRelativePosition <= 1.0);
    assert(endRelativePosition >= 0.0 && endRelativePosition <= 1.0);
    
    if (startRelativePosition == 0 && endRelativePosition == 1.0) {
        return NIBBBezierCoreCreateMutableCopy(bezierCore);
    }
    if (endRelativePosition == 0 && startRelativePosition == 1.0) {
        return NIBBBezierCoreCreateMutableCopy(bezierCore);
    }
    if (startRelativePosition == endRelativePosition) {
        return NIBBBezierCoreCreateMutableCopy(bezierCore);
    }
    if (NIBBBezierCoreSegmentCount(bezierCore) < 2) {
        return NIBBBezierCoreCreateMutableCopy(bezierCore);
    }
    
    if (NIBBBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(bezierCore);
        NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBBBezierCoreRetain(bezierCore);
    }
    
    length = NIBBBezierCoreLength(flattenedBezierCore);
    startPosition = startRelativePosition * length;
    endPosition = endRelativePosition * length;
    
    bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    newBezierCore = NIBBBezierCoreCreateMutable();
    
    NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
    while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the start
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        if(segmentType == NIBBLineToBezierCoreSegmentType || segmentType == NIBBCloseBezierCoreSegmentType) {
            segmentLength = NIBBVectorDistance(endpoint, prevEndpoint);
            
            if (segmentLength && distanceTraveled + segmentLength > startPosition) {
                lerpPoint = NIBBVectorLerp(prevEndpoint, endpoint, (startPosition - distanceTraveled)/segmentLength);
                NIBBBezierCoreAddSegment(newBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, lerpPoint);
                break;
            }
            distanceTraveled += segmentLength;
        }
        prevEndpoint = endpoint;
	}
    
    if (NIBBBezierCoreSegmentCount(newBezierCore) < 1 && startPosition < endPosition) { // for whatever reason an endpoint was not added, add the last point
        NIBBBezierCoreAddSegment(newBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
    }
    
    if (startPosition > endPosition) { // go all the way around
        if (NIBBBezierCoreSegmentCount(newBezierCore) == 1) {
            NIBBBezierCoreAddSegment(newBezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
        }
        
        needsMoveto = true;
        while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the start
            segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
            if (NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator) && segmentType == NIBBCloseBezierCoreSegmentType) {
                NIBBBezierCoreAddSegment(newBezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
                needsMoveto = false;
            } else {
                NIBBBezierCoreAddSegment(newBezierCore, segmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
            }
            prevEndpoint = endpoint;
        }
        
        NIBBBezierCoreIteratorRelease(bezierCoreIterator);
        bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
        NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
        if (needsMoveto) {
            NIBBBezierCoreAddSegment(newBezierCore, NIBBMoveToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, prevEndpoint);
        }
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        segmentLength = NIBBVectorDistance(endpoint, prevEndpoint);
        distanceTraveled = 0;
    }
    
    if (segmentLength && distanceTraveled + segmentLength > endPosition) { // the end is on the active segment
        lerpPoint = NIBBVectorLerp(prevEndpoint, endpoint, (endPosition - distanceTraveled)/segmentLength);
        NIBBBezierCoreAddSegment(newBezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, lerpPoint);
    } else {
        NIBBBezierCoreAddSegment(newBezierCore, segmentType, NIBBVectorZero, NIBBVectorZero, endpoint); // if the end was not on the active segment, close out the segment
        while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the end
            segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
            if(segmentType == NIBBLineToBezierCoreSegmentType || segmentType == NIBBCloseBezierCoreSegmentType) {
                segmentLength = NIBBVectorDistance(endpoint, prevEndpoint);
                
                if (segmentLength && distanceTraveled + segmentLength > endPosition) {
                    lerpPoint = NIBBVectorLerp(prevEndpoint, endpoint, (endPosition - distanceTraveled)/segmentLength);
                    NIBBBezierCoreAddSegment(newBezierCore, NIBBLineToBezierCoreSegmentType, NIBBVectorZero, NIBBVectorZero, lerpPoint);
                    break;
                } else {
                    NIBBBezierCoreAddSegment(newBezierCore, segmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
                }
                distanceTraveled += segmentLength;
            } else {
                NIBBBezierCoreAddSegment(newBezierCore, segmentType, NIBBVectorZero, NIBBVectorZero, endpoint);
            }
            prevEndpoint = endpoint;
        }
    }
    
    NIBBBezierCoreRelease(flattenedBezierCore);
    NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    return newBezierCore;
}


CGFloat NIBBBezierCoreSignedAreaUsingNormal(NIBBBezierCoreRef bezierCore, NIBBVector normal)
{ // Yes I know this could be way faster by projecting in 2D tralala tralala
    CGFloat signedArea = 0;
    
    NIBBMutableBezierCoreRef flattenedBezierCore;
    NIBBBezierCoreRef subpathBezierCore;
    NIBBBezierCoreIteratorRef bezierCoreIterator;
    NIBBVector prevEndpoint;
    NIBBVector endPoint;
    NIBBBezierCoreSegmentType segmentType;
    CFArrayRef subPaths;
    CFIndex i;
    
    subPaths = NIBBBezierCoreCopySubpaths(bezierCore);
    normal = NIBBVectorNormalize(normal);
    
    for (i = 0; i < CFArrayGetCount(subPaths); i++) {
        subpathBezierCore = CFArrayGetValueAtIndex(subPaths, i);
        
        if(NIBBBezierCoreGetSegmentAtIndex(subpathBezierCore, NIBBBezierCoreSegmentCount(subpathBezierCore)-1, NULL, NULL, NULL) != NIBBCloseBezierCoreSegmentType) {
            continue;
        }
        
        if (NIBBBezierCoreHasCurve(subpathBezierCore)) {
            flattenedBezierCore = NIBBBezierCoreCreateMutableCopy(subpathBezierCore);
            NIBBBezierCoreFlatten((NIBBMutableBezierCoreRef)flattenedBezierCore, NIBBBezierDefaultFlatness);
        } else {
            flattenedBezierCore = NIBBBezierCoreRetain(subpathBezierCore);
        }
        
        bezierCoreIterator = NIBBBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
        NIBBBezierCoreRelease(flattenedBezierCore);
        flattenedBezierCore = NULL;
        segmentType = NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
        assert(segmentType == NIBBMoveToBezierCoreSegmentType);
        
        while (!NIBBBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the start
            NIBBBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endPoint);
            
            signedArea += NIBBVectorDotProduct(NIBBVectorCrossProduct(prevEndpoint, endPoint), normal);
            
            prevEndpoint = endPoint;
        }
        
        NIBBBezierCoreIteratorRelease(bezierCoreIterator);
    }
    
    CFRelease(subPaths);
    
    return signedArea*0.5;
}
















