//
//  NIMPRAnnotation.h
//  NIMPR
//
//  Created by Alessandro Volz on 7/8/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIAnnotatedGeneratorRequestView.h"

extern NSString* const NIAnnotationChangeNotification; // to observe an annotation's changes you can either observe these notifications or observe the annotation's changed property

@interface NIAnnotation : NSObject {
    NSColor* _color;
//    NSDictionary* _userInfo;
    NSMutableDictionary* _changes;
}

@property(retain, nonatomic) NSColor* color;

+ (NSColor*)defaultColor;
+ (void)setDefaultColor:(NSColor*)color;

@property(readonly) BOOL annotation; // the value of this property is always YES, but you can observe it in order to observe changes in the annotation's properties
+ (NSSet*)keyPathsForValuesAffectingAnnotation;

- (void)drawInView:(NIAnnotatedGeneratorRequestView*)view;

//- (NSArray*)handles;

@end
