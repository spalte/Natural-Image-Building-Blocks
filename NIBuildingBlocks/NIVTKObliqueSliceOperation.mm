//  Copyright (c) 2017 Volz.io
//  Copyright (c) 2017 Spaltenstein Natural Image
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
//
//  Created by Alessandro Volz on 12/27/16.

#import "NIVTKObliqueSliceOperation.h"
#import "NIGeneratorOperationPrivate.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winconsistent-missing-override"
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#import <VTK/vtkSmartPointer.h>
#import <VTK/vtkImageImport.h>
#import <VTK/vtkTransform.h>
#import <VTK/vtkImageReslice.h>
#import <VTK/vtkImageSlabReslice.h>
#import <VTK/vtkImageData.h>
#pragma clang diagnostic pop

@interface NIVTKVolumeData : NIVolumeData

- (instancetype)initWithImageData:(vtkSmartPointer<vtkImageData>)imageData modelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform outOfBoundsValue:(float)outOfBoundsValue;

@end

@implementation NIVTKObliqueSliceOperation

- (void)main {
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [self start];
    }];
    
    [_fillOperations addObject:op];
    
    [[[self class] _fillQueueForQualityOfService:self.qualityOfService] addOperation:op];
}

- (void)start {
    const NIVolumeData *data = self.volumeData;
    const NIAffineTransform modelToVoxelTransform = data.modelToVoxelTransform, sliceToModelTransform = self.request.sliceToModelTransform, sliceToVoxelTransform = NIAffineTransformConcat(sliceToModelTransform, modelToVoxelTransform);
    
    // we use vtkImageImport to map the input NIVolumeData to VTK, without copying any of the data itself
    
    vtkSmartPointer<vtkImageImport> voxels = vtkSmartPointer<vtkImageImport>::New();
    voxels->SetWholeExtent(0, (int)data.pixelsWide-1, 0, (int)data.pixelsHigh-1, 0, (int)data.pixelsDeep-1);
    voxels->SetDataExtentToWholeExtent();
    voxels->SetDataScalarTypeToFloat();
    voxels->SetImportVoidPointer((void *)data.floatData.bytes);

    // we use vtkImageReslice for thin slices and vtkImageSlabReslice for thick slices
    
    vtkSmartPointer<vtkImageReslice> reslice;
    if (self.request.projectionMode == NIProjectionModeNone || self.request.slabWidth == 0)
        reslice = vtkSmartPointer<vtkImageReslice>::New();
    else {
        vtkSmartPointer<vtkImageSlabReslice> slabReslice = vtkSmartPointer<vtkImageSlabReslice>::New();
        slabReslice->SetSlabThickness(NIVectorLength(NIVectorApplyTransformToDirectionalVector(NIVectorMake(0, 0, self.request.slabWidth), sliceToVoxelTransform)));
        switch (self.request.projectionMode) {
            case NIProjectionModeMean:
                slabReslice->SetSlabModeToMean(); break;
            case NIProjectionModeMIP:
                slabReslice->SetSlabModeToMax(); break;
            case NIProjectionModeMinIP:
                slabReslice->SetSlabModeToMin(); break;
            default:
                break;
        }
        
        reslice = slabReslice;
    }
    
    reslice->SetInputConnection(voxels->GetOutputPort());
    reslice->SetBackgroundLevel(data.outOfBoundsValue);
    reslice->SetOutputScalarType(VTK_FLOAT);
    reslice->SetOutputDimensionality(2);
    reslice->SetOutputExtent(0, (int)self.request.pixelsWide-1, 0, (int)self.request.pixelsHigh-1, 0, 0);
    reslice->SetOutputOrigin(0, 0, 0);
    
    switch (self.request.interpolationMode) {
        case NIInterpolationModeNearestNeighbor:
            reslice->SetInterpolationModeToNearestNeighbor(); break;
        case NIInterpolationModeLinear:
            reslice->SetInterpolationModeToLinear(); break;
        case NIInterpolationModeCubic:
            reslice->SetInterpolationModeToCubic(); break;
        default:
            break;
    }
    
    // VTK reslicers don't let us just provide linear transforms: the SetResliceTransform method doesn't behave as one might expect. Instead, we build a ResliceAxes matrix.
    
    NIVector dir[4] = { NIVectorXBasis, NIVectorYBasis, NIVectorZBasis, NIVectorZero };
    for (size_t i = 0; i < 3; ++i)
        dir[i] = NIVectorApplyTransformToDirectionalVector(dir[i], sliceToVoxelTransform);
    dir[3] = NIVectorApplyTransform(dir[3], sliceToVoxelTransform);
    
    vtkSmartPointer<vtkMatrix4x4> axes = vtkSmartPointer<vtkMatrix4x4>::New();
    double elements[16] = { // this is quite confusing: the vtkMatrix4x4 documentation tells "many of the methods take an array of 16 doubles in row-major format"; the vtkImageReslice SetResliceAxes documentation says "The first column of the matrix specifies the x-axis vector (the fourth element must be set to zero), the second column specifies the y-axis, and the third column the z-axis. The fourth column is the origin of the axes (the fourth element must be set to one)"
        dir[0].x, dir[1].x, dir[2].x, dir[3].x,
        dir[0].y, dir[1].y, dir[2].y, dir[3].y,
        dir[0].z, dir[1].z, dir[2].z, dir[3].z,
        0, 0, 0, 1 };
    axes->DeepCopy(elements);
    
    reslice->SetResliceAxes(axes);
    
    // that's it: have VTK generate the output data and store it as a NIVTKVolumeData
    
    reslice->Update();
    
    self.generatedVolume = [[[NIVTKVolumeData alloc] initWithImageData:reslice->GetOutput() modelToVoxelTransform:NIAffineTransformInvert(sliceToModelTransform) outOfBoundsValue:data.outOfBoundsValue] autorelease];
    
    // let NIBB know we're done
    
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _operationExecuting = NO;
    _operationFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end

@implementation NIVTKVolumeData

- (instancetype)initWithImageData:(vtkSmartPointer<vtkImageData>)imageData modelToVoxelTransform:(NIAffineTransform)modelToVoxelTransform outOfBoundsValue:(float)outOfBoundsValue {
    int *ide = imageData->GetExtent();
    NSUInteger width = ide[1]-ide[0]+1, height = ide[3]-ide[2]+1;
    return [super initWithData:[[[NSData alloc] initWithBytesNoCopy:imageData->GetScalarPointer() length:(width*height*sizeof(float)) deallocator:^(void * _Nonnull bytes, NSUInteger length) {
        imageData->GetExtent(); // don't delete this dummy call: it ensures the vtkImageData instance is kept alive until the execution of this deallocator
    }] autorelease] pixelsWide:width pixelsHigh:height pixelsDeep:1 modelToVoxelTransform:modelToVoxelTransform outOfBoundsValue:outOfBoundsValue];
}

@end
