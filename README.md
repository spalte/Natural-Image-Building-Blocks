The majority of the source code of the Natural Image Building Blocks is copyrighted by Spaltenstein Natural Image, volz.io, Michael Hilker and Andreas Holzamer, and is licensed under the MIT license. The remainder of the code, however, is copyrighted by the OsiriX Foundation and distributed under the LGPL 2.1 license. For this reason, the Natural Image Building Blocks as a whole is distributed under the LGPL 2.1 license, which can be found in the file named lgpl-2.1.txt. The licenses applicable to individual source code files can be found at the top of the given files.

Documentation is Copyright (c) 2016 by Spaltenstein Natural Image and licensed under a Creative Commons Attribution 4.0 International License.

#Natural Image Building Blocks#
The Natural Image Building Blocks are meant to be a set of classes developers can use to implement medical imaging interfaces in MacOS. They are distributed as a LGPL 2.1 licensed Framework that can be included in either stand-alone applications or in OsiriX plugins. This document describes the classes of the public API of the Framework. An effort will be made to ensure that future versions of the Framework will maintain source-code and binary compatibility for the objects described below. All other classes are considered private and may change drastically from version to version. Objects that are not included in the NIBuildingBlocks.h header are particularly prone to change between versions.

**NIVolumeData**  
NIVolumeData provides a means to reference a volume of data stored as floats, that is positioned in space. An NIVolumeData is initialized with an array of floats along with the width, height and depth of the volume in pixels. This array of floats is tightly packed and no extra row padding may be added. During initialization, the user also needs to provide an affine transform that will describe the position of the volume in space and the pixel spacing.

**NIGeneratorRequest / NIObliqueSliceGeneratorRequest**  
NIGeneratorRequests define a rectangular slice through space. Subclasses of NIGeneratorRequest define different types of slices that can be defined. Currently the only supported subclass is NIObliqueSliceGeneratorRequest, which defines a planar slice with arbitrary orientation. 

**NIGeneratorRequestView**  
This subclass of NSView is the primary way to display and interact with medical images. The image displayed by the NIGeneratorRequestView is defined by providing an NIGeneratorRequest. When provided with a new NIGeneratorRequest, the NIGeneratorRequestView will use Core Animation to animate from the previously provided NIGeneratorRequest, to the newly provided NIGeneratorRequest. To avoid the animation, use the standard -[CATransaction setDisableActions:YES] strategy as explained in Apple’s Core Animation documentation. The NIGeneratorRequestView provides a KVO observable property named presentedGeneratorRequest that is continuously updated during animations, and represents the NIGeneratorRequest displayed by the NIGeneratorRequestView.

When displaying the NIGeneratorRequest, the NIGeneratorView will use -[NIGeneratorRequest generatorRequestResizedToPixelsWide: pixelsHigh:] to obtain an NIGeneratorRequest with appropriate dimensions to fit the view, taking into account the size of the view and the screen resolution when using a retina display. 

The NIGeneratorRequestView must be provided with at least one NIVolumeData from which it will access pixel data. The NIGeneratorRequestView will provide a separate **NIVolumeDataProperty** for each NIVolumeData added. This NIVolumeDataProperty object can be used to set attributes such as Window Level, Window Width, CLUT, or interpolation mode that is to be used when displaying the image generated from this NIVolumeData. Multiple NIVolumeData objects can be added in order to display a fusion between modalities for example.

To draw the intersection between planes in a NIGeneratorRequestView, an **NIIntersection** object can be created and added to the NIGeneratorRequestView. The NIGeneratorRequestView will then draw an intersection line that corresponds to the intersection of the displayed image and the object specified by setting the NIIntersection’s intersectingObject property. By binding the NIIntersection’s intersectingObject to another view’s presentedGeneratorRequest it is possible to display an intersection line that stays up to date.

**NIGenerator**  
NIGenerator is the used to make a new NIVolumeData that represents the slice (possibly thick-slab) defined by a NIGeneratorRequest using the data provided by an NIVolumeData. The NIGenerator is used internally by the NIGeneratorRequestView to generate the images that are displayed. The NIGenerator can also be used directly to build image that will be used outside of the NIGeneratorRequestView, such as images that are to be embedded in reports.

**NIFloatImageRep**  
NIFloatImageRep is a subclass of NSImageRep. It is easy to get an NIFloatImageRep that represents a z-plane of a NIVolumeData using the appropriate category method. The NIFloatImageRep can be used to apply a Window Level, Window Width, invert, or apply a CLUT to underlying float data. An NIFloatImageRep also knows how to draw standard image annotations such as orientation labels, scale bars, and the image rim. A CLUT can be either a NSGradient, or a single NSColor. The NIFloatImageRep is meant to be used either directly as an NSImageRep, or just transiently to retrieve windowed byte data, or RGBA data after a CLUT has been applied. 

**NIGeometry**  
NIGeometry.h defines 3D types such as NIVector, NILine, NIPlane, NIAffineTransform and a host of geometric functions that can be used with these types.

**NIBezierPath**  
NIBezierPath defines a 3D path made of piecewise line and cubic bezier segments. The API is meant to be similar to that of NSBezierPath.

**NIStorage**  
NIStorage provides a simple mechanism to store small amounts of data locally using a key-value mechanism.

**OsiriXIntegration**  
OsiriXIntegration.h defines functions that are available when the Framework is loaded in the context of an OsiriX Plugin. Upon initialization, the plugin will determine if OsiriX classes exist in the Obj-C runtime, and if so, will install a handful of functions that will be useful to plugin authors. For example, getting a NIVolumeData that represents the data displayed by a ViewerController. 

#Sample Source Code#
**SimplePlugin**  
A very simple OsiriX plugin that opens a volume and shows how to use the most common Natural Image Building Blocks APIs.

