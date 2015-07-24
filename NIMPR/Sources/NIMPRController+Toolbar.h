//
//  NIMPRController+Toolbar.h
//  NIMPR
//
//  Created by Alessandro Volz on 5/26/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIMPRController.h"

extern NSString* const NIMPRControllerToolbarItemIdentifierTools;
extern NSString* const NIMPRControllerToolbarItemIdentifierAnnotationTools;
extern NSString* const NIMPRControllerToolbarItemIdentifierProjection;
extern NSString* const NIMPRControllerToolbarItemIdentifierLayouts;

@class NIMPRToolRecord;
@class NIMPRLayoutRecord;

@interface NIMPRController (Toolbar)

+ (NSArray*)navigationTools; // returns an array of NIMPRToolRecord instances
+ (NSArray*)annotationTools; // returns an array of NIMPRToolRecord instances
+ (NIMPRToolRecord*)defaultTool;

+ (NSArray*)layouts; // returns an array of NIMPRLayoutRecord instances
+ (NIMPRLayoutRecord*)defaultLayout;

- (id)toolClassForTag:(NIMPRToolTag)tag;

@end

@interface NIMPRToolRecord : NSObject {
    NSString* _label;
    NSImage* _image;
    NIMPRToolTag _tag;
    Class _handler;
    NSMenu* _submenu;
}

@property(retain) NSString* label;
@property(retain) NSImage* image;
@property NIMPRToolTag tag;
@property Class handler;
@property(retain) NSMenu* submenu;

+ (instancetype)recordWithLabel:(NSString*)label image:(NSImage*)image tag:(NIMPRToolTag)tag handler:(Class)handler;

@end

@interface NIMPRLayoutRecord : NSObject {
    NSString* _label;
    NSImage* _image;
    NIMPRLayoutTag _tag;
//    void (^_handler)();
}

@property(retain) NSString* label;
@property(retain) NSImage* image;
@property NIMPRLayoutTag tag;
//@property(copy) void (^handler)();

+ (instancetype)recordWithLabel:(NSString*)label image:(NSImage*)image tag:(NIMPRLayoutTag)tag;

@end