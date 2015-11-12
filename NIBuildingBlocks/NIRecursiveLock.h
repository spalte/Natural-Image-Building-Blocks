//
//  NIRecursiveLock.h
//  NIBuildingBlocks
//
//  Created by Alessandro Volz on 11/10/15.
//  Copyright © 2015 Spaltenstein Natural Image. All rights reserved.
//

#import <Foundation/Foundation.h>

/* NIRecursiveLock requires unlocks to come from the same thread as the corresponding locks, throws a NSGenericException when not.
 */
@interface NIRecursiveLock : NSRecursiveLock {
    NSMutableArray* _lockers;
}

@end
