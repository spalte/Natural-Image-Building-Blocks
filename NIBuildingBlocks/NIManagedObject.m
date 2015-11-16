//
//  StagManagedObject.m
//  Stag
//
//  Created by Alessandro Volz on 3/31/15.
//  Copyright (c) 2015 volz.io. All rights reserved.
//

#import "NIManagedObject.h"
#import "NIManagedObjectContext.h"
#import "NIDatabase.h"
#import "NIRecursiveLock.h"

//NSString* const NIManagedObjectIsBeingDeletedNotification = @"NIManagedObjectIsBeingDeletedNotification";

//@interface NIManagedObjectControllerFactory : NSObject {
//    Class _class;
//    NSMutableDictionary* _instances;
//    NIRecursiveLock* _lock;
//}
//
//@property(assign) Class class;
//@property(retain) NSMutableDictionary* instances;
//@property(retain) NIRecursiveLock* lock;
//
//- (id)initWithClass:(Class)class;
//- (id)controllerForObject:(NIManagedObject*)item;
//- (void)removeContollerForKey:(id)key;
//
//@end
//
//@interface NIManagedObjectController ()
//
//@property(retain) NIDatabase* database;
//@property(retain) NSManagedObjectID* objectID;
//@property(retain) NSMutableDictionary* instances;
//@property(retain) id key;
//@property(assign) NIManagedObjectControllerFactory* factory;
//@property(retain) NIRecursiveLock* lock;
//
//@end

@implementation NIManagedObject

- (instancetype)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context {
    if ((self = [super initWithEntity:entity insertIntoManagedObjectContext:context])) {
//       DebugLog(@"initializing %@ %lx (%@)", self.objectID.entity.name, (unsigned long)self, self.objectID.URIRepresentation);
//        NSThread* thread = [NSThread currentThread];
//        if (thread.operation)
//            [thread.operation addDatabase:self.database];
    }
    
    return self;
}

//- (void)didSave {
//    [super didSave];
//    NSThread* thread = [NSThread currentThread];
//    if (thread.operation)
//        [thread.operation addController:[self controller]];
//}

- (__kindof NIDatabase*)database {
    id context = [self managedObjectContext];
    if ([context isKindOfClass:NIManagedObjectContext.class])
        return [(NIManagedObjectContext*)context database];
    return nil;
}

//+ (Class)controllerClass {
//    return NIManagedObjectController.class;
//}

//- (void)dealloc {
////    DebugLog(@"deallocating %@ 0x%lx (%@)", self.objectID.entity.name, (unsigned long)self, self.objectID.URIRepresentation);
//    [super dealloc];
//}

//- (NIManagedObjectControllerFactory*)controllerFactory {
//    @synchronized (NIManagedObjectControllerFactory.class) {
//        static NSMutableDictionary* factories = nil;
//        if (!factories)
//            factories = [NSMutableDictionary dictionary];
//        
//        NIManagedObjectControllerFactory* factory = factories[self.entity.name];
//        if (!factory) {
//            Class class = self.class.controllerClass;
//            if ([class isSubclassOfClass:NIManagedObjectController.class])
//                factories[self.entity.name] = factory = [[NIManagedObjectControllerFactory alloc] initWithClass:self.class.controllerClass];
//            else {
//                if (class)
//                    NSLog(@"Warning: controller class %@ is not a subclass of %@", NSStringFromClass(class), NSStringFromClass(NIManagedObjectController.class));
//                else NSLog(@"Warning: no controller class for managed objects of class %@", NSStringFromClass(self.class));
//            }
//        }
//        
//        return factory;
//    }
//}

- (NSString*)objectId {
    return self.objectID.URIRepresentation.absoluteString;
}

//- (id)controller {
//    return [[self controllerFactory] controllerForObject:self];
//}

- (BOOL)hasValueForRelationshipNamed:(NSString*)key {
    return [self.database countObjectsForEntity:self.entity predicateFormat:@"SELF = %@ AND %@ != NIL", self, [NSExpression expressionForKeyPath:key]] != 0;
}

//- (void)prepareForDeletion {
//    [[NSNotificationCenter defaultCenter] postNotificationName:NIManagedObjectIsBeingDeletedNotification object:self];
//    [super prepareForDeletion];
//}

@end

//@implementation NIManagedObjectController
//
//@synthesize database = _database;
//@synthesize objectID = _objectID;
//@synthesize instances = _instances;
//@synthesize key = _key;
//@synthesize factory = _factory;
//@synthesize lock = _lock;
//
//- (id)initWithObject:(NIManagedObject*)object {
//    if ((self = [super init])) {
//        self.objectID = object.objectID;
////        DebugLog(@"initializing %@ controller %lx (%@)", self.objectID.entity.name, (unsigned long)self, self.objectID.URIRepresentation);
//        self.database = object.database;
//        self.instances = [NSMutableDictionary dictionary];
//        [self addInstance:object];
//        self.lock = [[NIRecursiveLock alloc] init];
//    }
//    
//    return self;
//}
//
//- (id)initWithObject:(NIManagedObject*)object key:(id)key factory:(NIManagedObjectControllerFactory*)factory {
//    if ((self = [self initWithObject:object])) {
//        self.key = key;
//        self.factory = factory;
//    }
//    
//    return self;
//}
//
//- (void)addInstance:(id)obj {
//    [self.lock lock];
//    @try {
//        NSMutableSet* set = self.objects;
//        [set addObject:obj];
//        if (set.count > 1)
//            NSLog(@"Warning: there'll be more than one instance");
//    } @catch (...) {
//        @throw;
//    } @finally {
//        [self.lock unlock];
//    }
//}
//
//- (NSMutableSet*)objectsForThread:(NSThread*)thread {
//    id key = [NSValue valueWithPointer:(__bridge const void*)thread];
//    
//    [self.lock lock];
//    @try {
//        NSMutableSet* set = self.instances[key];
//        if (!set) {
//            set = (self.instances[key] = [NSMutableSet set]);
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeThreadWillExit:) name:NSThreadWillExitNotification object:thread];
////            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeThreadWillExit:) name:NIOperationWillExitNotification object:thread];
//        }
//        return set;
//    } @catch (...) {
//        @throw;
//    } @finally {
//        [self.lock unlock];
//    }
//}
//
//- (NSMutableSet*)objects {
//    return [self objectsForThread:[NSThread currentThread]];
//}
//
//- (id)object {
//    [self.lock lock];
//    @try {
//        NSMutableSet* set = self.objects;
//        if (set.count > 1)
//            NSLog(@"Warning: there's more than one instance");
//        
//        id object = set.anyObject;
//        if (object)
//            return object;
//        
//        object = [self.database objectWithID:self.objectID];
//        if (object)
//            [self addInstance:object];
//        
//        return object;
//    } @catch (...) {
//        @throw;
//    } @finally {
//        [self.lock unlock];
//    }
//}
//
//- (void)observeThreadWillExit:(NSNotification*)n {
//    @autoreleasepool {
//        NSMutableArray* inst = [NSMutableArray array];
//        for (id obj in [self objectsForThread:n.object])
//            [inst addObject:[NSString stringWithFormat:@"%lx", (unsigned long)obj]];
////        DebugLog(@"removing %@ instances (%@) from controller %lx (%@)", self.objectID.entity.name, [inst componentsJoinedByString:@", "], (unsigned long)self, self.objectID.URIRepresentation);
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:n.object];
////        [[NSNotificationCenter defaultCenter] removeObserver:self name:NIOperationWillExitNotification object:n.object];
//        NSThread* thread = n.object;
//        [self.lock lock];
//        @try {
//            [self.instances removeObjectForKey:[NSValue valueWithPointer:(__bridge const void*)thread]];
//        } @catch (...) {
//            @throw;
//        } @finally {
//            [self.lock unlock];
//        }
//    }
//}
//
//- (void)dealloc {
//    //    DebugLog(@"deallocating %@ controller 0x%lx (%@)", self.objectID.entity.name, (unsigned long)self, self.objectID.URIRepresentation);
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self.factory removeContollerForKey:self.key];
//    self.database = nil;
//    self.objectID = nil;
//    self.instances = nil;
//    self.key = nil;
//    self.lock = nil;
//    self.factory = nil;
//    [super dealloc];
//}
//
//- (id)refreshObject {
//    return [self refreshObject:NO];
//}
//
//- (id)refreshObject:(BOOL)merge {
////    DebugLog(@"refreshing %@ controller %lx (%@)", self.objectID.entity.name, (unsigned long)self, self.objectID.URIRepresentation);
//    [self.database refreshObject:self.object mergeChanges:merge];
//    return self;
//}
//
//@end
//
//@implementation NIManagedObjectControllerFactory
//
//@synthesize class = _class;
//@synthesize instances = _instances;
//@synthesize lock = _lock;
//
//- (id)initWithClass:(Class)class {
//    if ((self = [super init])) {
//        self.class = class;
//        self.instances = [NSMutableDictionary dictionary];
//        self.lock = [[NIRecursiveLock alloc] init];
//    }
//    
//    return self;
//}
//
//- (void)dealloc {
//    self.class = nil;
//    self.instances = nil;
//    self.lock = nil;
//    [super dealloc];
//}
//
//- (id)controllerForObject:(NIManagedObject*)object {
//    if (!object)
//        return nil;
//    
//    if (object.objectID.isTemporaryID)
//        [object.database save]; // otherwise its objectID will change
//    NSURL* k = object.objectID.URIRepresentation;
//    
//    id controller = nil;
//    
//    [self.lock lock];
//    @try {
//        controller = [self.instances[k] pointerValue];
//        if (!controller)
//            self.instances[k] = [NSValue valueWithPointer:(__bridge const void*)(controller = [[self.class alloc] initWithObject:object key:k factory:self])];
//    } @catch (...) {
//        @throw;
//    } @finally {
//        [self.lock unlock];
//    }
//    
//    [controller addInstance:object];
//    
//    return controller;
//}
//
//- (void)removeContollerForKey:(id)key {
//    [self.lock lock];
//    @try {
//        [self.instances removeObjectForKey:key];
//    } @catch (...) {
//        @throw;
//    } @finally {
//        [self.lock unlock];
//    }
//}
//
//@end
