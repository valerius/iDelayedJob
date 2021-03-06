//
//  NLDelayableJob.m
//  iDelayedJob
//
//  Created by James Whitfield on 04/08/2015.
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//


#import "JSONKit.h"
#import "NLDelayableJob.h"
#import "NLDelayedJobManager.h"
#import "NLDelayableJobAbility.h"

@implementation NLJobDescriptor {}
@synthesize code = _code;
@synthesize error = _error;
@synthesize job = _job;

- (id)initWithJob:(NLDelayableJob *)job {
    if (self = [super init]) {
        _job = job;
    }
    return self;
}

- (void)setError:(NSString *)message {
    _job.last_error = message;
}

@end

@interface NLDelayableJob ()
- (NSComparisonResult)priorityCompare:(NLDelayableJob *)job;
@end

@implementation NLDelayableJob {
    NSMutableArray *_params;
    NLJobDescriptor *_descriptor;
}
+ (void)initialize {
    [super initialize];
    [NLDelayedJobManager registerJob:[self class]];
}

column_imp(string, handler)
column_imp(string, queue)
column_imp(string, parameters)
column_imp(integer, priority)
column_imp(integer, attempts)
column_imp(string, last_error)
column_imp(date, run_at)
column_imp(date, locked_at)
column_imp(boolean, locked)
column_imp(date, failed_at)
column_imp(boolean, internet)
column_imp(boolean, unique)
column_imp(string, job_id)

validation_do(
        validate_presence_of(handler)
        validate_presence_of(queue)
        validate_presence_of(attempts)
        validate_presence_of(job_id)
        validate_presence_of(priority)
)


@synthesize descriptor = _descriptor;
@synthesize params;
- (id)init {
    if (self = [super init]) {
        self.handler = NSStringFromClass([self class]);
        self.locked = @(NO);
        self.run_at = [NSDate date];
        self.attempts = @(0);
        self.priority = @(1);
        self.internet = @(NO);
        self.unique =  @(NO);
        _descriptor = [[NLJobDescriptor alloc] initWithJob:self];
    }

    return self;
}

- (NSMutableArray *)params {
    if (!_params) {
        _params = [NSMutableArray arrayWithCapacity:1];
        if (self.parameters) {
            NSArray *array = [self.parameters objectFromJSONString];
            [_params addObjectsFromArray:array];
        }
    }

    return _params;
}

+ (id)jobWithClass:(Class <NLDelayableJobAbility>)jobClass {
    return [self jobWithHandler:NSStringFromClass(jobClass) arguments:nil];;
}

+(id)job:(id) jobOrClass withArguments:(id) firstObject,... {
    NLDelayableJob *job = nil;
    va_list argumentList;
    id eachObject;
    NSAssert([jobOrClass conformsToProtocol:@protocol(NLJob)], @"jobOrClass parameter does not subclass or implement a protocol <NLJob>");
    if(class_isMetaClass(object_getClass(jobOrClass))) {
        Class jobClass =  jobOrClass;
        if(![jobClass conformsToProtocol:@protocol(NLDelayableJobAbility)])
            job = (NLDelayableJob *) [jobClass record];
        else
            job = [NLDelayableJob jobWithClass:jobClass];
    } else job = jobOrClass;

    if (job && firstObject) {
        [job.params addObject:firstObject];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, id))) {
            [job.params addObject:eachObject];
        } // As many times as we can get an argument of type "id"

        va_end(argumentList);
    }

    return job;
}



+ (NLDelayableJob *)jobWithHandler:(NSString *)className arguments:(id)firstObject, ... {
    Class jobClazz = NSClassFromString(className);
    NLDelayableJob *job = nil;
    va_list argumentList;
    id eachObject;

    NSAssert(className != nil, @"A job cannot be created with a null class name.");
    NSAssert(jobClazz != nil, @"Cannot find class %@ to create job", className);

    if ([jobClazz isSubclassOfClass:[NLDelayableJob class]]) {
        job = (NLDelayableJob*)[jobClazz record];
    } else if ([jobClazz conformsToProtocol:@protocol(NLDelayableJobAbility)]) {
        job = [self record];     // will use static protocol method
        job.handler = className;
    } else {
        NSAssert(NO, @"Job class must be either a subclass or NLDelayableJob or implement protocol <NLDelayableJobAbility>");
    }

    if (job && firstObject) {
        [job.params addObject:firstObject];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, id))) {
            [job.params addObject:eachObject];
        } // As many times as we can get an argument of type "id"

        va_end(argumentList);
    }

    return job;
}


+ (NLDelayableJob *)jobWithArguments:(id)firstObject, ... {

    NLDelayableJob *job = [[self alloc] init];
    va_list argumentList;
    id eachObject;
    if (firstObject) {
        [job.params addObject:firstObject];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, id))) {
            [job.params addObject:eachObject];
        }
        va_end(argumentList);
    }

    return job;
}

- (NLDelayableJob *)setArguments:(id)firstObject, ... {
    id eachObject;
    va_list argumentList;
    if (firstObject) {
        [self.params addObject:firstObject];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, id))) {
            [self.params addObject:eachObject];
        } // As many times as we can get an argument of type "id"
        va_end(argumentList);
    }
    return self;
}


- (BOOL)run {
    NLDelayableJob *jobSubclass = [self __ifJobSubclass]; //returns self
    Class <NLDelayableJobAbility> jobsAbilityClass = !jobSubclass ? [self __ifAbilityJob] : nil;
    BOOL success = NO;
    BOOL isAbility = NO;

    if (jobSubclass) {
        success = [self perform];
    } else if ([jobsAbilityClass respondsToSelector:@selector(performJob:withArguments:)]) {
        isAbility = YES;
        success = [jobsAbilityClass performJob:self.descriptor withArguments:self.params];
    } else {
        self.descriptor.code = kJobDescriptorCodeLoadFailure;
        self.descriptor.error = [NSString stringWithFormat:@"Unable to load job handler %@", self.handler];
        return NO;
    }

    if (!success) {
        self.failed_at = [NSDate date];
        NSInteger add_seconds = ([self.attempts intValue] + 5) * 4;
        NSDate *nextRunTime = [NSDate dateWithTimeIntervalSinceNow:(int) add_seconds];
        self.run_at = nextRunTime;

        if (isAbility &&
                [jobsAbilityClass respondsToSelector:@selector(scheduleJob:withArguments:)]) {
            nextRunTime = [jobsAbilityClass scheduleJob:self.descriptor withArguments:self.params];
            if (nextRunTime)
                self.run_at = nextRunTime;
        }

        self.attempts = @([self.attempts intValue] + 1);
        self.descriptor.code = kJobDescriptorCodeRunFailure;
    }

    return success;
}


#pragma mark - Job Helpers

- (NLDelayableJob *) __ifJobSubclass { // determines if job is a subclass of NLDelayableJob which handles itself for processing
     if (self.handler &&
             [self.handler isEqualToString:NSStringFromClass([self class])]) {
        return self;
    }
    return nil;
}

- (Class <NLDelayableJobAbility>) __ifAbilityJob { //determines if Job is handled by NLDelayableJobAbility class
    Class jobClass = NSClassFromString(self.handler);
    Class <NLDelayableJobAbility> jobsAbilityClass = [jobClass conformsToProtocol:@protocol(NLDelayableJobAbility)] ? jobClass : nil;
    if ([self __ifJobSubclass]) {
        return nil;
    } else if (jobsAbilityClass && [jobClass respondsToSelector:@selector(performJob:withArguments:)]) {
        return jobsAbilityClass;
    }
    return nil;
}

#pragma mark -

- (BOOL)shouldRestartJob { // No Need to call super if a subclass
    Class <NLDelayableJobAbility> jobsAbilityClass = [self __ifAbilityJob];

    if([jobsAbilityClass respondsToSelector:@selector(shouldRestartJob:withArguments:)]) {
        return [jobsAbilityClass shouldRestartJob:self.descriptor withArguments:self.params];
    }

    return NO;
}

- (void)onBeforeDeleteEvent {  // No Need to call super if a subclass
    Class <NLDelayableJobAbility> jobsAbilityClass = [self __ifAbilityJob];
    if(jobsAbilityClass &&
            [jobsAbilityClass respondsToSelector:@selector(shouldRestartJob:withArguments:)]) {
         [jobsAbilityClass beforeDeleteJob:self.descriptor withArguments:self.params];
    }
}

- (BOOL)perform {
    self.descriptor.error = @"Unimplemented perform method";
    self.descriptor.code = kJobDescriptorCodeRunFailure;
    return NO;
}

#pragma mark - Equality & Sorting

- (BOOL)isEqual:(id)anObject {
    return anObject && [anObject isKindOfClass:[self class]] && [self.job_id isEqualToString:((NLDelayableJob *) anObject).job_id];
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + [self.queue hash];
    result = prime * result + [self.job_id hash];
    return result;
}

- (NSComparisonResult)priorityCompare:(NLDelayableJob *)job {
    if (job == nil) {
        return NSOrderedAscending;
    }

    return [job.priority compare:self.priority];
}


#pragma mark - cleanup

- (void)dealloc {
    self.params = nil;
}

@end


