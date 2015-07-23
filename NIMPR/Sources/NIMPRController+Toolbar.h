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

@interface NIMPRController (Toolbar)

- (id)toolClassForTag:(NIMPRToolTag)tag;

@end
