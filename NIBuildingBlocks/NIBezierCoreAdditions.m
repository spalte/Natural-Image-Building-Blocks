//  Copyright (c) 2015 OsiriX Foundation
//  Copyright (c) 2015 Spaltenstein Natural Image
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NIBezierCoreAdditions.h"


NIBezierCoreRef NIBezierCoreCreateCurveWithNodes(NIVectorArray vectors, CFIndex numVectors, NIBezierNodeStyle style)
{
    return NIBezierCoreCreateMutableCurveWithNodes(vectors, numVectors, style);
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableCurveWithNodes(NIVectorArray vectors, CFIndex numVectors, NIBezierNodeStyle style)
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
    NIMutableBezierCoreRef newBezierCore;
    NIVector control1;
    NIVector control2;
    NIVector lastEndpoint;
    NIVector endpoint;
    newBezierCore = NIBezierCoreCreateMutable();
    
    assert (numVectors >= 2);
    
    if (numVectors == 2) {
        NIBezierCoreAddSegment(newBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, vectors[0]);
        NIBezierCoreAddSegment(newBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, vectors[1]);
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
        
        fprintf(stderr, "NIBezierCoreCreateMutableCurveWithNodes failed because it could not allocate enough memory\n");
        return NULL;
    }
    
    //initialisation
    for (i=0; i<nb; i++)
        h[i] = a[i] = cx[i] = d[i] = c[i] = cy[i] = cz[i] = g[i] = gam[i] = 0.0;
    
    // as a spline starts and ends with a line one adds two points
    // in order to have continuity in starting point
    if (style == NIBezierNodeOpenEndsStyle) {
        for (i=0; i<numVectors; i++)
        {
            px[i+1] = vectors[i].x;// * fZoom / 100;
            py[i+1] = vectors[i].y;// * fZoom / 100;
            pz[i+1] = vectors[i].z;// * fZoom / 100;
        }
        px[0] = 2.0*px[1] - px[2]; px[nb-1] = 2.0*px[nb-2] - px[nb-3];
        py[0] = 2.0*py[1] - py[2]; py[nb-1] = 2.0*py[nb-2] - py[nb-3];
        pz[0] = 2.0*pz[1] - pz[2]; pz[nb-1] = 2.0*pz[nb-2] - pz[nb-3];
    } else { // NIBezierNodeEndsMeetStyle
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
        
        fprintf(stderr, "NIBezierCoreCreateMutableCurveWithNodes failed because some points overlapped\n");
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
    
    lastEndpoint = NIVectorMake(px[1], py[1], pz[1]);
    NIBezierCoreAddSegment(newBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, lastEndpoint);
    
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
        
        NIBezierCoreAddSegment(newBezierCore, NICurveToBezierCoreSegmentType, control1, control2, endpoint);
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

NIVector NIBezierCoreVectorAtStart(NIBezierCoreRef bezierCore)
{
    NIVector moveTo;
    
    if (NIBezierCoreSegmentCount(bezierCore) == 0) {
        return NIVectorZero;
    }
    
    NIBezierCoreGetSegmentAtIndex(bezierCore, 0, NULL, NULL, &moveTo);
    return moveTo;
}

NIVector NIBezierCoreVectorAtEnd(NIBezierCoreRef bezierCore)
{
    NIVector endPoint;
    
    if (NIBezierCoreSegmentCount(bezierCore) == 0) {
        return NIVectorZero;
    }
    
    NIBezierCoreGetSegmentAtIndex(bezierCore, NIBezierCoreSegmentCount(bezierCore) - 1, NULL, NULL, &endPoint);
    return endPoint;
}


NIVector NIBezierCoreTangentAtStart(NIBezierCoreRef bezierCore)
{
    NIVector moveTo;
    NIVector endPoint;
    NIVector control1;
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return NIVectorZero;
    }
    
    NIBezierCoreGetSegmentAtIndex(bezierCore, 0, NULL, NULL, &moveTo);
    
    if (NIBezierCoreGetSegmentAtIndex(bezierCore, 1, &control1, NULL, &endPoint) == NICurveToBezierCoreSegmentType) {
        return NIVectorNormalize(NIVectorSubtract(endPoint, control1));
    } else {
        return NIVectorNormalize(NIVectorSubtract(endPoint, moveTo));
    }
}

NIVector NIBezierCoreTangentAtEnd(NIBezierCoreRef bezierCore)
{
    NIVector prevEndPoint;
    NIVector endPoint;
    NIVector control2;
    CFIndex segmentCount;
    
    segmentCount = NIBezierCoreSegmentCount(bezierCore);
    if (segmentCount < 2) {
        return NIVectorZero;
    }
    
    if (NIBezierCoreGetSegmentAtIndex(bezierCore, segmentCount - 1, NULL, &control2, &endPoint) == NICurveToBezierCoreSegmentType) {
        return NIVectorNormalize(NIVectorSubtract(endPoint, control2));
    } else {
        NIBezierCoreGetSegmentAtIndex(bezierCore, segmentCount - 2, NULL, NULL, &prevEndPoint);
        return NIVectorNormalize(NIVectorSubtract(endPoint, prevEndPoint));
    }
}

CGFloat NIBezierCoreRelativePositionClosestToVector(NIBezierCoreRef bezierCore, NIVector vector, NIVectorPointer closestVector, CGFloat *distance)
{
    NIBezierCoreIteratorRef bezierIterator;
    NIBezierCoreRef flattenedBezier;
    NIVector start;
    NIVector end;
    NIVector segment;
    NIVector segmentDirection;
    NIVector translatedVector;
    NIVector bestVector;
    NIBezierCoreSegmentType segmentType;
    CGFloat tempDistance;
    CGFloat bestRelativePosition;
    CGFloat bestDistance;
    CGFloat projectedDistance;
    CGFloat segmentLength;
    CGFloat traveledDistance;
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return 0.0;
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezier = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezier, NIBezierDefaultFlatness);
    } else {
        flattenedBezier = NIBezierCoreRetain(bezierCore);
    }
    
    bezierIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezier);
    
    bestDistance = CGFLOAT_MAX;
    bestRelativePosition = 0.0;
    traveledDistance = 0.0;
    
    NIBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierIterator)) {
        start = end;
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
        
        segment = NIVectorSubtract(end, start);
        translatedVector = NIVectorSubtract(vector, start);
        segmentLength = NIVectorLength(segment);
        segmentDirection = NIVectorScalarMultiply(segment, 1.0/segmentLength);
        
        projectedDistance = NIVectorDotProduct(translatedVector, segmentDirection);
        
        if (segmentType != NIMoveToBezierCoreSegmentType) {
            if (projectedDistance >= 0 && projectedDistance <= segmentLength) {
                tempDistance = NIVectorLength(NIVectorSubtract(translatedVector, NIVectorScalarMultiply(segmentDirection, projectedDistance)));
                if (tempDistance < bestDistance) {
                    bestDistance = tempDistance;
                    bestRelativePosition = traveledDistance + projectedDistance;
                    bestVector = NIVectorAdd(start, NIVectorScalarMultiply(segmentDirection, projectedDistance));
                }
            } else if (projectedDistance < 0) {
                tempDistance = NIVectorDistance(start, vector);
                if (tempDistance < bestDistance) {
                    bestDistance = tempDistance;
                    bestRelativePosition = traveledDistance;
                    bestVector = start;
                }
            } else {
                tempDistance = NIVectorDistance(end, vector);
                if (tempDistance < bestDistance) {
                    bestDistance = tempDistance;
                    bestRelativePosition = traveledDistance + segmentLength;
                    bestVector = end;
                }
            }
            
            traveledDistance += segmentLength;
        }
    }
    
    bestRelativePosition /= NIBezierCoreLength(flattenedBezier);
    
    NIBezierCoreRelease(flattenedBezier);
    NIBezierCoreIteratorRelease(bezierIterator);
    
    if (distance) {
        *distance = bestDistance;
    }
    if (closestVector) {
        *closestVector = bestVector;
    }
    
    return bestRelativePosition;
}

CGFloat NIBezierCoreRelativePositionClosestToLine(NIBezierCoreRef bezierCore, NILine line, NIVectorPointer closestVector, CGFloat *distance)
{
    NIBezierCoreIteratorRef bezierIterator;
    NIBezierCoreRef flattenedBezier;
    NIVector start;
    NIVector end;
    NILine segment;
    NIVector closestPoint;
    NIVector bestVector;
    NIBezierCoreSegmentType segmentType;
    CGFloat mu;
    CGFloat tempDistance;
    CGFloat bestRelativePosition;
    CGFloat bestDistance;
    CGFloat traveledDistance;
    CGFloat segmentLength;
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return 0.0;
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezier = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezier, NIBezierDefaultFlatness);
    } else {
        flattenedBezier = NIBezierCoreRetain(bezierCore);
    }
    
    bezierIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezier);
    
    bestDistance = CGFLOAT_MAX;
    bestRelativePosition = 0.0;
    traveledDistance = 0.0;
    NIBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
    bestVector = end;
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierIterator)) {
        start = end;
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierIterator, NULL, NULL, &end);
        
        segmentLength = NIVectorDistance(start, end);
        
        if (segmentLength > 0.0 && segmentType != NIMoveToBezierCoreSegmentType) {
            segment = NILineMakeFromPoints(start, end);
            tempDistance = NILineClosestPoints(segment, line, &closestPoint, NULL);
            
            if (tempDistance < bestDistance) {
                mu = NIVectorDotProduct(NIVectorSubtract(end, start), NIVectorSubtract(closestPoint, start)) / (segmentLength*segmentLength);
                
                if (mu < 0.0) {
                    tempDistance = NIVectorDistanceToLine(start, line);
                    if (tempDistance < bestDistance) {
                        bestDistance = tempDistance;
                        bestRelativePosition = traveledDistance;
                        bestVector = start;
                    }
                } else if (mu > 1.0) {
                    tempDistance = NIVectorDistanceToLine(end, line);
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
    
    bestRelativePosition /= NIBezierCoreLength(flattenedBezier);
    
    NIBezierCoreRelease(flattenedBezier);
    NIBezierCoreIteratorRelease(bezierIterator);
    
    if (closestVector) {
        *closestVector = bestVector;
    }
    if (distance) {
        *distance = bestDistance;
    }
    
    return bestRelativePosition;
}

CFIndex NIBezierCoreGetVectorInfo(NIBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, NIVector initialNormal,
                                    NIVectorArray vectors, NIVectorArray tangents, NIVectorArray normals, CFIndex numVectors)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVector nextVector;
    NIVector startVector;
    NIVector endVector;
    NIVector previousTangentVector;
    NIVector nextTangentVector;
    NIVector tangentVector;
    NIVector startTangentVector;
    NIVector endTangentVector;
    NIVector previousNormalVector;
    NIVector nextNormalVector;
    NIVector normalVector;
    NIVector startNormalVector;
    NIVector endNormalVector;
    NIVector segmentDirection;
    NIVector nextSegmentDirection;
    CGFloat segmentLength;
    CGFloat distanceTraveled;
    CGFloat extraDistance;
    CFIndex i;
    bool done;
    
    if (numVectors == 0 || NIBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    assert(normals == NULL || NIBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
    assert(NIBezierCoreSubpathCount(bezierCore) == 1); // TODO! I should fix this to be able to handle moveTo as long as normals don't matter
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreSubdivide((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultSubdivideSegmentLength);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    extraDistance = startingDistance; // distance that was traveled past the last point
    done = false;
    i = 0;
    startVector = NIVectorZero;
    endVector = NIVectorZero;
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &startVector);
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endVector);
    segmentDirection = NIVectorNormalize(NIVectorSubtract(endVector, startVector));
    segmentLength = NIVectorDistance(endVector, startVector);
    
    normalVector = NIVectorNormalize(NIVectorSubtract(initialNormal, NIVectorProject(initialNormal, segmentDirection)));
    if(NIVectorEqualToVector(normalVector, NIVectorZero)) {
        normalVector = NIVectorNormalize(NIVectorCrossProduct(NIVectorMake(-1.0, 0.0, 0.0), segmentDirection));
        if(NIVectorEqualToVector(normalVector, NIVectorZero)) {
            normalVector = NIVectorNormalize(NIVectorCrossProduct(NIVectorMake(0.0, 1.0, 0.0), segmentDirection));
        }
    }
    
    previousNormalVector = normalVector;
    tangentVector = segmentDirection;
    previousTangentVector = tangentVector;
    
    while (done == false) {
        distanceTraveled = extraDistance;
        
        if (NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
            nextNormalVector = normalVector;
            nextTangentVector = tangentVector;
            nextVector = endVector;
            done = true;
        } else {
            NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &nextVector);
            nextSegmentDirection = NIVectorNormalize(NIVectorSubtract(nextVector, endVector));
            nextNormalVector = NIVectorBend(normalVector, segmentDirection, nextSegmentDirection);
            nextNormalVector = NIVectorSubtract(nextNormalVector, NIVectorProject(nextNormalVector, nextSegmentDirection)); // make sure the new vector is really normal
            nextNormalVector = NIVectorNormalize(nextNormalVector);
            
            nextTangentVector = nextSegmentDirection;
        }
        startNormalVector = NIVectorNormalize(NIVectorLerp(previousNormalVector, normalVector, 0.5));
        endNormalVector = NIVectorNormalize(NIVectorLerp(nextNormalVector, normalVector, 0.5));
        
        startTangentVector = NIVectorNormalize(NIVectorLerp(previousTangentVector, tangentVector, 0.5));
        endTangentVector = NIVectorNormalize(NIVectorLerp(nextTangentVector, tangentVector, 0.5));
        
        while(distanceTraveled < segmentLength)
        {
            if (vectors) {
                vectors[i] = NIVectorAdd(startVector, NIVectorScalarMultiply(segmentDirection, distanceTraveled));
            }
            if (tangents) {
                tangents[i] = NIVectorNormalize(NIVectorLerp(startTangentVector, endTangentVector, distanceTraveled/segmentLength));
                
            }
            if (normals) {
                normals[i] = NIVectorNormalize(NIVectorLerp(startNormalVector, endNormalVector, distanceTraveled/segmentLength));
            }
            i++;
            if (i >= numVectors) {
                NIBezierCoreIteratorRelease(bezierCoreIterator);
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
        segmentLength = NIVectorDistance(startVector, endVector);
        
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    return i;
}

CFIndex NIBezierCoreGetProjectedVectorInfo(NIBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, NIVector projectionDirection,
                                             NIVectorArray vectors, NIVectorArray tangents, NIVectorArray normals, CGFloat *relativePositions, CFIndex numVectors)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIBezierCoreRef projectedBezierCore;
    NIBezierCoreIteratorRef projectedBezierCoreIterator;
    NIVector nextVector;
    NIVector startVector;
    NIVector endVector;
    NIVector nextProjectedVector;
    NIVector startProjectedVector;
    NIVector endProjectedVector;
    NIVector previousTangentVector;
    NIVector nextTangentVector;
    NIVector tangentVector;
    NIVector startTangentVector;
    NIVector endTangentVector;
    NIVector previousNormalVector;
    NIVector nextNormalVector;
    NIVector normalVector;
    NIVector startNormalVector;
    NIVector endNormalVector;
    NIVector segmentDirection;
    NIVector projectedSegmentDirection;
    NIVector nextSegmentDirection;
    NIVector nextProjectedSegmentDirection;
    CGFloat segmentLength;
    CGFloat projectedSegmentLength;
    CGFloat distanceTraveled;
    CGFloat totalDistanceTraveled;
    CGFloat extraDistance;
    CGFloat bezierLength;
    CFIndex i;
    bool done;
    
    if (numVectors == 0 || NIBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    assert(normals == NULL || NIBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
    assert(NIBezierCoreSubpathCount(bezierCore) == 1); // TODO! I should fix this to be able to handle moveTo as long as normals don't matter
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreSubdivide((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultSubdivideSegmentLength);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    bezierLength = NIBezierCoreLength(flattenedBezierCore);
    projectedBezierCore = NIBezierCoreCreateCopyProjectedToPlane(flattenedBezierCore, NIPlaneMake(NIVectorZero, projectionDirection));
    
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    projectedBezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(projectedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    NIBezierCoreRelease(projectedBezierCore);
    projectedBezierCore = NULL;
    
    extraDistance = startingDistance; // distance that was traveled past the last point
    totalDistanceTraveled = startingDistance;
    done = false;
    i = 0;
    startVector = NIVectorZero;
    endVector = NIVectorZero;
    startProjectedVector = NIVectorZero;
    endProjectedVector = NIVectorZero;
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &startVector);
    NIBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &startProjectedVector);
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endVector);
    NIBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &endProjectedVector);
    segmentDirection = NIVectorNormalize(NIVectorSubtract(endVector, startVector));
    projectedSegmentDirection = NIVectorNormalize(NIVectorSubtract(endProjectedVector, startProjectedVector));
    segmentLength = NIVectorDistance(endVector, startVector);
    projectedSegmentLength = NIVectorDistance(endProjectedVector, startProjectedVector);
    
    normalVector = NIVectorNormalize(NIVectorCrossProduct(projectedSegmentDirection, projectionDirection));
    if (NIVectorIsZero(normalVector)) {
        normalVector = NIVectorANormalVector(projectionDirection);
    }
    
    previousNormalVector = normalVector;
    tangentVector = segmentDirection;
    previousTangentVector = tangentVector;
    
    while (done == false) {
        distanceTraveled = extraDistance;
        
        if (NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
            nextNormalVector = normalVector;
            nextTangentVector = tangentVector;
            nextVector = endVector;
            done = true;
        } else {
            NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &nextVector);
            NIBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &nextProjectedVector);
            nextSegmentDirection = NIVectorNormalize(NIVectorSubtract(nextVector, endVector));
            nextProjectedSegmentDirection = NIVectorNormalize(NIVectorSubtract(nextProjectedVector, endProjectedVector));
            nextNormalVector = NIVectorNormalize(NIVectorCrossProduct(nextProjectedSegmentDirection, projectionDirection));
            if (NIVectorIsZero(nextNormalVector)) {
                nextNormalVector = NIVectorANormalVector(projectionDirection);
            }
            
            nextTangentVector = nextSegmentDirection;
        }
        startNormalVector = NIVectorNormalize(NIVectorLerp(previousNormalVector, normalVector, 0.5));
        endNormalVector = NIVectorNormalize(NIVectorLerp(nextNormalVector, normalVector, 0.5));
        
        startTangentVector = NIVectorNormalize(NIVectorLerp(previousTangentVector, tangentVector, 0.5));
        endTangentVector = NIVectorNormalize(NIVectorLerp(nextTangentVector, tangentVector, 0.5));
        
        while(distanceTraveled < projectedSegmentLength)
        {
            CGFloat segmentDistanceTraveled;
            segmentDistanceTraveled = distanceTraveled * (segmentLength/projectedSegmentLength);
            
            if (vectors) {
                vectors[i] = NIVectorAdd(startVector, NIVectorScalarMultiply(segmentDirection, segmentDistanceTraveled));
            }
            if (tangents) {
                tangents[i] = NIVectorNormalize(NIVectorLerp(startTangentVector, endTangentVector, distanceTraveled/projectedSegmentLength));
            }
            if (normals) {
                normals[i] = NIVectorNormalize(NIVectorLerp(startNormalVector, endNormalVector, distanceTraveled/projectedSegmentLength));
            }
            if (relativePositions) {
                relativePositions[i] = (totalDistanceTraveled + segmentDistanceTraveled) / bezierLength;
            }
            i++;
            if (i >= numVectors) {
                NIBezierCoreIteratorRelease(bezierCoreIterator);
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
        segmentLength = NIVectorDistance(endVector, startVector);
        projectedSegmentLength = NIVectorDistance(endProjectedVector, startProjectedVector);
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    return i;
}

//CFIndex NIBezierCoreGetCollapsedVectorInfo(NIBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingPoint, NIVector collapsingDirection, // returns points that are spacing away from each other after the collapsing has occured, the returned points are not collapsed
//                                           NIVectorArray vectors, NIVectorArray tangents, NIVectorArray normals, CGFloat *relativePositions, CFIndex numVectors) // fills numVectors in the vector arrays, returns the actual number of vectors that were set in the arrays
//{
//    NIBezierCoreRef flattenedBezierCore;
//    NIBezierCoreRef projectedBezierCore;
//    NIBezierCoreIteratorRef bezierCoreIterator;
//    NIBezierCoreIteratorRef projectedBezierCoreIterator;
//    NIVector start;
//    NIVector end;
//    NIVector projectedStart;
//    NIVector projectedEnd;
//    NIVector segmentDirection;
//    NIVector projectedSegmentDirection;
//    CGFloat length;
//    CGFloat distanceTraveled;
//    CGFloat totalDistanceTraveled;
//    CGFloat extraDistance;
//    CGFloat segmentLength;
//    CGFloat projectedSegmentLength;
//    CFIndex i;
//
//    if (NIBezierCoreHasCurve(bezierCore)) {
//        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
//        NIBezierCoreSubdivide((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultSubdivideSegmentLength);
//        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
//    } else {
//        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
//    }
//
//    projectedBezierCore = NIBezierCoreCreateCopyProjectedToPlane(flattenedBezierCore, NIPlaneMake(NIVectorZero, collapsingDirection));
//
//    length = NIBezierCoreLength(flattenedBezierCore);
//    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
//    projectedBezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(projectedBezierCore);
//    NIBezierCoreRelease(flattenedBezierCore);
//    flattenedBezierCore = NULL;
//    NIBezierCoreRelease(projectedBezierCore);
//    projectedBezierCore = NULL;
//
//    distanceTraveled = 0;
//    totalDistanceTraveled = 0;
//    extraDistance = 0;
//    i = 0;
//    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
//    NIBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &projectedEnd);
//
//    while (!NIBezierCoreIteratorIsAtEnd(bezierIterator)) {
//        start = end;
//        projectedStart = projectedEnd;
//        NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
//        NIBezierCoreIteratorGetNextSegment(projectedBezierCoreIterator, NULL, NULL, &projectedEnd);
//
//        segmentDirection = NIVectorNormalize(NIVectorSubtract(end, start));
//        projectedSegmentDirection = NIVectorNormalize(NIVectorSubtract(projectedEnd, projectedStart));
//        projectedSegmentLength = NIVectorDistance(projectedStart, projectedEnd);
//        segmentLength = NIVectorDistance(start, end);
//        distanceTraveled = extraDistance;
//
//		while(distanceTraveled < segmentLength)
//		{
//            if (vectors) {
//                vectors[i] = NIVectorAdd(start, NIVectorScalarMultiply(segmentDirection, distanceTraveled * (segmentLength / projectedSegmentLength)));
//            }
//            if (tangents) {
//                tangents[i] = segmentDirection;
//                tangents[i] = NIVectorNormalize(NIVectorAdd(NIVectorScalarMultiply(startTangentVector, 1.0-distanceTraveled/segmentLength), NIVectorScalarMultiply(endTangentVector, distanceTraveled/segmentLength)));
//
//            }
//            if (normals) {
//                normals[i] = NIVectorNormalize(NIVectorAdd(NIVectorScalarMultiply(startNormalVector, 1.0-distanceTraveled/segmentLength), NIVectorScalarMultiply(endNormalVector, distanceTraveled/segmentLength)));
//            }
//            i++;
//            if (i >= numVectors) {
//                NIBezierCoreIteratorRelease(bezierCoreIterator);
//                NIBezierCoreIteratorRelease(projectedBezierCoreIterator);
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
//    NIBezierCoreIteratorRelease(bezierCoreIterator);
//    NIBezierCoreIteratorRelease(projectedBezierCoreIterator);
//}

NIVector NIBezierCoreNormalAtEndWithInitialNormal(NIBezierCoreRef bezierCore, NIVector initialNormal)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVector normalVector;
    NIVector segment;
    NIVector prevSegment;
    NIVector start;
    NIVector end;
    
    assert(NIBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return initialNormal;
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &start);
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
    prevSegment = NIVectorSubtract(end, start);
    
    normalVector = NIVectorNormalize(NIVectorSubtract(initialNormal, NIVectorProject(initialNormal, prevSegment)));
    if(NIVectorEqualToVector(normalVector, NIVectorZero)) {
        normalVector = NIVectorNormalize(NIVectorCrossProduct(NIVectorMake(-1.0, 0.0, 0.0), prevSegment));
        if(NIVectorEqualToVector(normalVector, NIVectorZero)) {
            normalVector = NIVectorNormalize(NIVectorCrossProduct(NIVectorMake(0.0, 1.0, 0.0), prevSegment));
        }
    }
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        start = end;
        NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &end);
        
        segment = NIVectorSubtract(end, start);
        normalVector = NIVectorBend(normalVector, prevSegment, segment);
        normalVector = NIVectorSubtract(normalVector, NIVectorProject(normalVector, segment)); // make sure the new vector is really normal
        normalVector = NIVectorNormalize(normalVector);
        
        prevSegment = segment;
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    return normalVector;
}

NIBezierCoreRef NIBezierCoreCreateOutline(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector initialNormal)
{
    return NIBezierCoreCreateMutableOutline(bezierCore, distance, spacing, initialNormal);
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableOutline(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector initialNormal)
{
    NIBezierCoreRef flattenedBezierCore;
    NIMutableBezierCoreRef outlineBezier;
    NIVector endpoint;
    NIVector endpointNormal;
    CGFloat length;
    NSInteger i;
    NSUInteger numVectors;
    NIVectorArray vectors;
    NIVectorArray normals;
    NIVectorArray scaledNormals;
    NIVectorArray side;
    
    assert(NIBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return NULL;
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreSubdivide((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultSubdivideSegmentLength);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    length = NIBezierCoreLength(flattenedBezierCore);
    
    if (spacing * 2 >= length) {
        NIBezierCoreRelease(flattenedBezierCore);
        return NULL;
    }
    
    numVectors = length/spacing + 1.0;
    
    vectors = malloc(numVectors * sizeof(NIVector));
    normals = malloc(numVectors * sizeof(NIVector));
    scaledNormals = malloc(numVectors * sizeof(NIVector));
    side = malloc(numVectors * sizeof(NIVector));
    outlineBezier = NIBezierCoreCreateMutable();
    
    numVectors = NIBezierCoreGetVectorInfo(flattenedBezierCore, spacing, 0, initialNormal, vectors, NULL, normals, numVectors);
    NIBezierCoreGetSegmentAtIndex(flattenedBezierCore, NIBezierCoreSegmentCount(flattenedBezierCore) - 1, NULL, NULL, &endpoint);
    endpointNormal = NIVectorNormalize(NIVectorSubtract(normals[numVectors-1], NIVectorProject(normals[numVectors-1], NIBezierCoreTangentAtEnd(flattenedBezierCore))));
    endpointNormal = NIVectorScalarMultiply(endpointNormal, distance);
    
    memcpy(scaledNormals, normals, numVectors * sizeof(NIVector));
    NIVectorScalarMultiplyVectors(distance, scaledNormals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIVector));
    NIVectorAddVectors(side, scaledNormals, numVectors);
    
    NIBezierCoreAddSegment(outlineBezier, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[i]);
    }
    NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorAdd(endpoint, endpointNormal));
    
    memcpy(scaledNormals, normals, numVectors * sizeof(NIVector));
    NIVectorScalarMultiplyVectors(-distance, scaledNormals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIVector));
    NIVectorAddVectors(side, scaledNormals, numVectors);
    
    NIBezierCoreAddSegment(outlineBezier, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[i]);
    }
    NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorAdd(endpoint, NIVectorInvert(endpointNormal)));
    
    free(vectors);
    free(normals);
    free(scaledNormals);
    free(side);
    
    NIBezierCoreRelease(flattenedBezierCore);
    
    return outlineBezier;
}

NIBezierCoreRef NIBezierCoreCreateOutlineWithNormal(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector projectionNormal)
{
    return NIBezierCoreCreateMutableOutlineWithNormal(bezierCore, distance, spacing, projectionNormal);
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableOutlineWithNormal(NIBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, NIVector projectionNormal)
{
    NIBezierCoreRef flattenedBezierCore;
    NIMutableBezierCoreRef outlineBezier;
    NIVector endpoint;
    NIVector endpointNormal;
    CGFloat length;
    NSInteger i;
    NSUInteger numVectors;
    NIVectorArray vectors;
    NIVectorArray tangents;
    NIVectorArray normals;
    NIVectorArray side;
    
    assert(NIBezierCoreSubpathCount(bezierCore) == 1); // this only works when there is a single subpath
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return NULL;
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreSubdivide((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultSubdivideSegmentLength);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    length = NIBezierCoreLength(flattenedBezierCore);
    
    if (spacing * 2 >= length) {
        NIBezierCoreRelease(flattenedBezierCore);
        return NULL;
    }
    
    numVectors = length/spacing + 1.0;
    
    vectors = malloc(numVectors * sizeof(NIVector));
    tangents = malloc(numVectors * sizeof(NIVector));
    normals = malloc(numVectors * sizeof(NIVector));
    side = malloc(numVectors * sizeof(NIVector));
    outlineBezier = NIBezierCoreCreateMutable();
    
    numVectors = NIBezierCoreGetVectorInfo(flattenedBezierCore, spacing, 0, NIVectorZero, vectors, tangents, NULL, numVectors);
    endpoint = NIBezierCoreVectorAtEnd(flattenedBezierCore);
    endpointNormal = NIVectorScalarMultiply(NIVectorNormalize(NIVectorCrossProduct(projectionNormal, NIBezierCoreTangentAtEnd(flattenedBezierCore))), distance);
    
    memcpy(normals, tangents, numVectors * sizeof(NIVector));
    NIVectorCrossProductVectors(projectionNormal, normals, numVectors);
    NIVectorNormalizeVectors(normals, numVectors);
    NIVectorScalarMultiplyVectors(distance, normals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIVector));
    NIVectorAddVectors(side, normals, numVectors);
    
    NIBezierCoreAddSegment(outlineBezier, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[i]);
    }
    NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorAdd(endpoint, endpointNormal));
    
    NIVectorScalarMultiplyVectors(-1.0, normals, numVectors);
    
    memcpy(side, vectors, numVectors * sizeof(NIVector));
    NIVectorAddVectors(side, normals, numVectors);
    
    NIBezierCoreAddSegment(outlineBezier, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[0]);
    for (i = 1; i < numVectors; i++) {
        NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, side[i]);
    }
    NIBezierCoreAddSegment(outlineBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorAdd(endpoint, NIVectorInvert(endpointNormal)));
    
    free(vectors);
    free(normals);
    free(tangents);
    free(side);
    
    NIBezierCoreRelease(flattenedBezierCore);
    
    return outlineBezier;
}

CGFloat NIBezierCoreLengthToSegmentAtIndex(NIBezierCoreRef bezierCore, CFIndex index, CGFloat flatness) // the length up to and including the segment at index
{
    NIMutableBezierCoreRef shortBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIBezierCoreSegmentType segmentType;
    NIBezierCoreRef flattenedShortBezierCore;
    NIVector endpoint;
    NIVector control1;
    NIVector control2;
    CGFloat length;
    CFIndex i;
    
    assert(index < NIBezierCoreSegmentCount(bezierCore));
    
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(bezierCore);
    shortBezierCore = NIBezierCoreCreateMutable();
    
    for (i = 0; i <= index; i++) {
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
        NIBezierCoreAddSegment(shortBezierCore, segmentType, control1, control2, endpoint);
    }
    
    flattenedShortBezierCore = NIBezierCoreCreateFlattenedMutableCopy(shortBezierCore, flatness);
    length = NIBezierCoreLength(flattenedShortBezierCore);
    
    NIBezierCoreRelease(shortBezierCore);
    NIBezierCoreRelease(flattenedShortBezierCore);
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    
    return length;
}

CFIndex NIBezierCoreSegmentLengths(NIBezierCoreRef bezierCore, CGFloat *lengths, CFIndex numLengths, CGFloat flatness) // returns the number of lengths set
{
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIMutableBezierCoreRef segmentBezierCore;
    NIMutableBezierCoreRef flatenedSegmentBezierCore;
    NIVector prevEndpoint;
    NIVector control1;
    NIVector control2;
    NIVector endpoint;
    NIBezierCoreSegmentType segmentType;
    CFIndex i;
    
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(bezierCore);
    
    if (numLengths > 0 && NIBezierCoreSegmentCount(bezierCore) > 0) {
        lengths[0] = 0.0;
    } else {
        return 0;
    }
    
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
    
    for (i = 1; i < MIN(numLengths, NIBezierCoreSegmentCount(bezierCore)); i++) {
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
        
        segmentBezierCore = NIBezierCoreCreateMutable();
        NIBezierCoreAddSegment(segmentBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, prevEndpoint);
        NIBezierCoreAddSegment(segmentBezierCore, segmentType, control1, control2, endpoint);
        
        flatenedSegmentBezierCore = NIBezierCoreCreateFlattenedMutableCopy(segmentBezierCore, flatness);
        lengths[i] = NIBezierCoreLength(flatenedSegmentBezierCore);
        
        NIBezierCoreRelease(segmentBezierCore);
        NIBezierCoreRelease(flatenedSegmentBezierCore);
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    
    return i;
}

CFIndex NIBezierCoreCountIntersectionsWithPlane(NIBezierCoreRef bezierCore, NIPlane plane)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVector endpoint;
    NIVector prevEndpoint;
    NIBezierCoreSegmentType segmentType;
    NSInteger count;
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreSubdivide((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultSubdivideSegmentLength);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    count = 0;
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        if (segmentType != NIMoveToBezierCoreSegmentType && NIPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
            count++;
        }
        prevEndpoint = endpoint;
    }
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    return count;
}


CFIndex NIBezierCoreIntersectionsWithPlane(NIBezierCoreRef bezierCore, NIPlane plane, NIVectorArray intersections, CGFloat *relativePositions, CFIndex numVectors)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVector endpoint;
    NIVector prevEndpoint;
    NIVector intersection;
    NIBezierCoreSegmentType segmentType;
    CGFloat length;
    CGFloat distance;
    NSInteger count;
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return 0;
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreSubdivide((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultSubdivideSegmentLength);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    length = NIBezierCoreLength(flattenedBezierCore);
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    distance = 0.0;
    count = 0;
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator) && count < numVectors) {
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        if (NIPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
            if (segmentType != NIMoveToBezierCoreSegmentType) {
                intersection = NILineIntersectionWithPlane(NILineMakeFromPoints(prevEndpoint, endpoint), plane);
                if (intersections) {
                    intersections[count] = intersection;
                }
                if (relativePositions) {
                    relativePositions[count] = (distance + NIVectorDistance(prevEndpoint, intersection))/length;
                }
                count++;
            }
        }
        distance += NIVectorDistance(prevEndpoint, endpoint);
        prevEndpoint = endpoint;
    }
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    return count;
}


NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyWithEndpointsAtPlaneIntersections(NIBezierCoreRef bezierCore, NIPlane plane)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIMutableBezierCoreRef newBezierCore;
    NIBezierCoreSegmentType segmentType;
    NIVector endpoint;
    NIVector prevEndpoint;
    NIVector intersection;
    
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return NIBezierCoreCreateMutableCopy(bezierCore);
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    newBezierCore = NIBezierCoreCreateMutable();
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
    NIBezierCoreAddSegment(newBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, prevEndpoint);
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        if (segmentType != NIMoveToBezierCoreSegmentType && NIPlaneIsBetweenVectors(plane, endpoint, prevEndpoint)) {
            intersection = NILineIntersectionWithPlane(NILineMakeFromPoints(prevEndpoint, endpoint), plane);
            NIBezierCoreAddSegment(newBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, intersection);
        }
        
        NIBezierCoreAddSegment(newBezierCore, segmentType, NIVectorZero, NIVectorZero, endpoint);
        prevEndpoint = endpoint;
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    return newBezierCore;
}

NIBezierCoreRef NIBezierCoreCreateCopyProjectedToPlane(NIBezierCoreRef bezierCore, NIPlane plane)
{
    return NIBezierCoreCreateMutableCopyProjectedToPlane(bezierCore, plane);
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyProjectedToPlane(NIBezierCoreRef bezierCore, NIPlane plane)
{
    NIBezierCoreIteratorRef bezierIterator;
    NIMutableBezierCoreRef projectedBezier;
    NIVector control1;
    NIVector control2;
    NIVector endpoint;
    NIBezierCoreSegmentType segmentType;
    
    projectedBezier = NIBezierCoreCreateMutable();
    
    bezierIterator = NIBezierCoreIteratorCreateWithBezierCore(bezierCore);
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierIterator)) {
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierIterator, &control1, &control2, &endpoint);
        
        control1 = NILineIntersectionWithPlane(NILineMake(control1, plane.normal), plane);
        control2 = NILineIntersectionWithPlane(NILineMake(control2, plane.normal), plane);
        endpoint = NILineIntersectionWithPlane(NILineMake(endpoint, plane.normal), plane);
        
        NIBezierCoreAddSegment(projectedBezier, segmentType, control1, control2, endpoint);
    }
    NIBezierCoreIteratorRelease(bezierIterator);
    return projectedBezier;
}

NIPlane NIBezierCoreLeastSquaresPlane(NIBezierCoreRef bezierCore)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVectorArray endpoints;
    NIPlane plane;
    CFIndex segmentCount;
    CFIndex i;
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    segmentCount = NIBezierCoreSegmentCount(flattenedBezierCore);
    endpoints = malloc(segmentCount * sizeof(NIVector));
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    for (i = 0; !NIBezierCoreIteratorIsAtEnd(bezierCoreIterator); i++) {
        NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoints[i]);
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    
    plane = NIPlaneLeastSquaresPlaneFromPoints(endpoints, segmentCount);
    
    free(endpoints);
    return plane;
}

CGFloat NIBezierCoreMeanDistanceToPlane(NIBezierCoreRef bezierCore, NIPlane plane)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVector endpoint;
    CGFloat totalDistance;
    CFIndex segmentCount;
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    endpoint = NIVectorZero;
    segmentCount = NIBezierCoreSegmentCount(flattenedBezierCore);
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    totalDistance = 0;
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        totalDistance += NIVectorDistanceToPlane(endpoint, plane);
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    
    return totalDistance / (CGFloat)segmentCount;
}

bool NIBezierCoreIsPlanar(NIBezierCoreRef bezierCore, NIPlanePointer bezierCorePlane)
{
    NIPlane plane;
    CGFloat meanDistance;
    bool isPlanar;
    
    plane = NIBezierCoreLeastSquaresPlane(bezierCore);
    meanDistance = NIBezierCoreMeanDistanceToPlane(bezierCore, plane);
    
    isPlanar = meanDistance < 1.0;
    
    if (isPlanar && bezierCorePlane) {
        *bezierCorePlane = plane;
    }
    
    return isPlanar;
}

bool NIBezierCoreGetBoundingPlanesForNormal(NIBezierCoreRef bezierCore, NIVector normal, NIPlanePointer topPlanePtr, NIPlanePointer bottomPlanePtr)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVector endpoint;
    CGFloat z;
    CGFloat minZ;
    CGFloat maxZ;
    NIPlane topPlane;
    NIPlane bottomPlane;
    
    assert(NIVectorIsZero(normal) == false);
    
    minZ = CGFLOAT_MAX;
    maxZ = -CGFLOAT_MAX;
    
    topPlane.normal = NIVectorNormalize(normal);
    topPlane.point = NIVectorZero;
    bottomPlane.normal = topPlane.normal;
    bottomPlane.point = NIVectorZero;
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    NIBezierCoreRelease(flattenedBezierCore);
    flattenedBezierCore = NULL;
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        
        z = NIVectorDotProduct(endpoint, normal);
        
        if (z < minZ) {
            minZ = z;
            bottomPlane.point = endpoint;
        }
        
        if (z > maxZ) {
            maxZ = z;
            topPlane.point = endpoint;
        }
    }
    
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    
    if (topPlanePtr) {
        *topPlanePtr = topPlane;
    }
    
    if (bottomPlanePtr) {
        *bottomPlanePtr = bottomPlane;
    }
    
    return true;
}


NIBezierCoreRef NIBezierCoreCreateCopyByReversing(NIBezierCoreRef bezierCore)
{
    return NIBezierCoreCreateMutableCopyByReversing(bezierCore);
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyByReversing(NIBezierCoreRef bezierCore)
{
    NIBezierCoreRandomAccessorRef bezierAccessor;
    NIMutableBezierCoreRef reversedBezier;
    bool needsClose;
    bool needsMove;
    long i = 0;
    NIBezierCoreSegmentType segmentType;
    NIVector control1;
    NIVector control2;
    NIVector endpoint;
    NIBezierCoreSegmentType prevSegmentType;
    NIVector prevControl1;
    NIVector prevControl2;
    NIVector prevEndpoint;
    
    bezierAccessor = NIBezierCoreRandomAccessorCreateWithBezierCore(bezierCore);
    reversedBezier = NIBezierCoreCreateMutable();
    
    // check empty bezierPath special case
    if (NIBezierCoreRandomAccessorSegmentCount(bezierAccessor) == 0) {
        NIBezierCoreRandomAccessorRelease(bezierAccessor);
        return reversedBezier;
    }
    
    // check for the special case of a bezier with just a moveto
    if (NIBezierCoreRandomAccessorSegmentCount(bezierAccessor) == 1) {
        segmentType = NIBezierCoreRandomAccessorGetSegmentAtIndex(bezierAccessor, i, &control1, &control2, &endpoint);
        assert(segmentType == NIMoveToBezierCoreSegmentType);
        NIBezierCoreAddSegment(reversedBezier, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
        NIBezierCoreRandomAccessorRelease(bezierAccessor);
        return reversedBezier;
    }
    
    needsClose = false;
    needsMove = true;
    
    prevSegmentType = NIBezierCoreRandomAccessorGetSegmentAtIndex(bezierAccessor, NIBezierCoreRandomAccessorSegmentCount(bezierAccessor) - 1, &prevControl1, &prevControl2, &prevEndpoint);
    
    for (i = NIBezierCoreRandomAccessorSegmentCount(bezierAccessor) - 2; i >= 0; i--) {
        segmentType = NIBezierCoreRandomAccessorGetSegmentAtIndex(bezierAccessor, i, &control1, &control2, &endpoint);
        
        if (needsMove && prevSegmentType != NICloseBezierCoreSegmentType) {
            NIBezierCoreAddSegment(reversedBezier, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, prevEndpoint);
            needsMove = false;
        }
        
        switch (prevSegmentType) {
            case NICloseBezierCoreSegmentType:
                needsClose = true;
                break;
            case NILineToBezierCoreSegmentType:
                NIBezierCoreAddSegment(reversedBezier, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
                break;
            case NICurveToBezierCoreSegmentType:
                NIBezierCoreAddSegment(reversedBezier, NICurveToBezierCoreSegmentType, prevControl2, prevControl1, endpoint);
                break;
            case NIMoveToBezierCoreSegmentType:
                if (needsClose) {
                    NIBezierCoreAddSegment(reversedBezier, NICloseBezierCoreSegmentType, NIVectorZero, NIVectorZero, NIVectorZero);
                }
                NIBezierCoreAddSegment(reversedBezier, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
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
    
    assert(prevSegmentType == NIMoveToBezierCoreSegmentType);
    
    NIBezierCoreRandomAccessorRelease(bezierAccessor);
    NIBezierCoreCheckDebug(reversedBezier);
    
    return reversedBezier;
}

CFArrayRef NIBezierCoreCopySubpaths(NIBezierCoreRef bezierCore)
{
    CFMutableArrayRef subpaths = CFArrayCreateMutable(NULL, 0, &kNIBezierCoreArrayCallBacks);
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIMutableBezierCoreRef subpath = NULL;
    NIBezierCoreSegmentType segmentType;
    NIVector control1;
    NIVector control2;
    NIVector endpoint;
    
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(bezierCore);
    
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) {
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
        
        if (segmentType == NIMoveToBezierCoreSegmentType) {
            subpath = NIBezierCoreCreateMutable();
            CFArrayAppendValue(subpaths, subpath);
            NIBezierCoreRelease(subpath);
        }
        
        NIBezierCoreAddSegment(subpath, segmentType, control1, control2, endpoint);
    }
    
    return subpaths;
}

NIBezierCoreRef NIBezierCoreCreateCopyByClipping(NIBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition)
{
    return NIBezierCoreCreateMutableCopyByClipping(bezierCore, startRelativePosition, endRelativePosition);
}

NIMutableBezierCoreRef NIBezierCoreCreateMutableCopyByClipping(NIBezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition)
{
    NIBezierCoreRef flattenedBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIMutableBezierCoreRef newBezierCore;
    NIBezierCoreSegmentType segmentType = NIMoveToBezierCoreSegmentType;
    CGFloat distanceTraveled = 0;
    CGFloat segmentLength = 0;
    CGFloat startPosition;
    CGFloat endPosition;
    CGFloat length;
    NIVector endpoint;
    NIVector prevEndpoint;
    NIVector lerpPoint;
    bool needsMoveto = false;
    
    assert(startRelativePosition >= 0.0 && startRelativePosition <= 1.0);
    assert(endRelativePosition >= 0.0 && endRelativePosition <= 1.0);
    
    if (startRelativePosition == 0 && endRelativePosition == 1.0) {
        return NIBezierCoreCreateMutableCopy(bezierCore);
    }
    if (endRelativePosition == 0 && startRelativePosition == 1.0) {
        return NIBezierCoreCreateMutableCopy(bezierCore);
    }
    if (startRelativePosition == endRelativePosition) {
        return NIBezierCoreCreateMutableCopy(bezierCore);
    }
    if (NIBezierCoreSegmentCount(bezierCore) < 2) {
        return NIBezierCoreCreateMutableCopy(bezierCore);
    }
    
    if (NIBezierCoreHasCurve(bezierCore)) {
        flattenedBezierCore = NIBezierCoreCreateMutableCopy(bezierCore);
        NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
    } else {
        flattenedBezierCore = NIBezierCoreRetain(bezierCore);
    }
    
    length = NIBezierCoreLength(flattenedBezierCore);
    startPosition = startRelativePosition * length;
    endPosition = endRelativePosition * length;
    
    bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
    newBezierCore = NIBezierCoreCreateMutable();
    
    NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
    while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the start
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        if(segmentType == NILineToBezierCoreSegmentType || segmentType == NICloseBezierCoreSegmentType) {
            segmentLength = NIVectorDistance(endpoint, prevEndpoint);
            
            if (segmentLength && distanceTraveled + segmentLength > startPosition) {
                lerpPoint = NIVectorLerp(prevEndpoint, endpoint, (startPosition - distanceTraveled)/segmentLength);
                NIBezierCoreAddSegment(newBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, lerpPoint);
                break;
            }
            distanceTraveled += segmentLength;
        }
        prevEndpoint = endpoint;
    }
    
    if (NIBezierCoreSegmentCount(newBezierCore) < 1 && startPosition < endPosition) { // for whatever reason an endpoint was not added, add the last point
        NIBezierCoreAddSegment(newBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
    }
    
    if (startPosition > endPosition) { // go all the way around
        if (NIBezierCoreSegmentCount(newBezierCore) == 1) {
            NIBezierCoreAddSegment(newBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
        }
        
        needsMoveto = true;
        while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the start
            segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
            if (NIBezierCoreIteratorIsAtEnd(bezierCoreIterator) && segmentType == NICloseBezierCoreSegmentType) {
                NIBezierCoreAddSegment(newBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, endpoint);
                needsMoveto = false;
            } else {
                NIBezierCoreAddSegment(newBezierCore, segmentType, NIVectorZero, NIVectorZero, endpoint);
            }
            prevEndpoint = endpoint;
        }
        
        NIBezierCoreIteratorRelease(bezierCoreIterator);
        bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
        NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
        if (needsMoveto) {
            NIBezierCoreAddSegment(newBezierCore, NIMoveToBezierCoreSegmentType, NIVectorZero, NIVectorZero, prevEndpoint);
        }
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
        segmentLength = NIVectorDistance(endpoint, prevEndpoint);
        distanceTraveled = 0;
    }
    
    if (segmentLength && distanceTraveled + segmentLength > endPosition) { // the end is on the active segment
        lerpPoint = NIVectorLerp(prevEndpoint, endpoint, (endPosition - distanceTraveled)/segmentLength);
        NIBezierCoreAddSegment(newBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, lerpPoint);
    } else {
        NIBezierCoreAddSegment(newBezierCore, segmentType, NIVectorZero, NIVectorZero, endpoint); // if the end was not on the active segment, close out the segment
        while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the end
            segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endpoint);
            if(segmentType == NILineToBezierCoreSegmentType || segmentType == NICloseBezierCoreSegmentType) {
                segmentLength = NIVectorDistance(endpoint, prevEndpoint);
                
                if (segmentLength && distanceTraveled + segmentLength > endPosition) {
                    lerpPoint = NIVectorLerp(prevEndpoint, endpoint, (endPosition - distanceTraveled)/segmentLength);
                    NIBezierCoreAddSegment(newBezierCore, NILineToBezierCoreSegmentType, NIVectorZero, NIVectorZero, lerpPoint);
                    break;
                } else {
                    NIBezierCoreAddSegment(newBezierCore, segmentType, NIVectorZero, NIVectorZero, endpoint);
                }
                distanceTraveled += segmentLength;
            } else {
                NIBezierCoreAddSegment(newBezierCore, segmentType, NIVectorZero, NIVectorZero, endpoint);
            }
            prevEndpoint = endpoint;
        }
    }
    
    NIBezierCoreRelease(flattenedBezierCore);
    NIBezierCoreIteratorRelease(bezierCoreIterator);
    return newBezierCore;
}


CGFloat NIBezierCoreSignedAreaUsingNormal(NIBezierCoreRef bezierCore, NIVector normal)
{ // Yes I know this could be way faster by projecting in 2D tralala tralala
    CGFloat signedArea = 0;
    
    NIMutableBezierCoreRef flattenedBezierCore;
    NIBezierCoreRef subpathBezierCore;
    NIBezierCoreIteratorRef bezierCoreIterator;
    NIVector prevEndpoint;
    NIVector endPoint;
    NIBezierCoreSegmentType segmentType;
    CFArrayRef subPaths;
    CFIndex i;
    
    subPaths = NIBezierCoreCopySubpaths(bezierCore);
    normal = NIVectorNormalize(normal);
    
    for (i = 0; i < CFArrayGetCount(subPaths); i++) {
        subpathBezierCore = CFArrayGetValueAtIndex(subPaths, i);
        
        if(NIBezierCoreGetSegmentAtIndex(subpathBezierCore, NIBezierCoreSegmentCount(subpathBezierCore)-1, NULL, NULL, NULL) != NICloseBezierCoreSegmentType) {
            continue;
        }
        
        if (NIBezierCoreHasCurve(subpathBezierCore)) {
            flattenedBezierCore = NIBezierCoreCreateMutableCopy(subpathBezierCore);
            NIBezierCoreFlatten((NIMutableBezierCoreRef)flattenedBezierCore, NIBezierDefaultFlatness);
        } else {
            flattenedBezierCore = NIBezierCoreRetain(subpathBezierCore);
        }
        
        bezierCoreIterator = NIBezierCoreIteratorCreateWithBezierCore(flattenedBezierCore);
        NIBezierCoreRelease(flattenedBezierCore);
        flattenedBezierCore = NULL;
        segmentType = NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &prevEndpoint);
        assert(segmentType == NIMoveToBezierCoreSegmentType);
        
        while (!NIBezierCoreIteratorIsAtEnd(bezierCoreIterator)) { // find the start
            NIBezierCoreIteratorGetNextSegment(bezierCoreIterator, NULL, NULL, &endPoint);
            
            signedArea += NIVectorDotProduct(NIVectorCrossProduct(prevEndpoint, endPoint), normal);
            
            prevEndpoint = endPoint;
        }
        
        NIBezierCoreIteratorRelease(bezierCoreIterator);
    }
    
    CFRelease(subPaths);
    
    return signedArea*0.5;
}
















