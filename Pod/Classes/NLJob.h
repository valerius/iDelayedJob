//
//  NLJob.h
//
//  Created by James Whitfield on 06/14/12.
//  Copyright (c) 2012 NEiLAB, INC. All rights reserved.
//


#import "VinylRecord.h"

@class  NLJob;

#define kJobDescriptorCodeOk  0
#define kJobDescriptorCodeRunFailure  1
#define kJobDescriptorCodeLoadFailure  2

@interface NLJobDescriptor : NSObject  {
    NSString *_error;
    NSInteger _code;
    NLJob *_job;
}

@property (nonatomic, assign) NSInteger code;
@property (nonatomic,retain) NSString *error;

- (id) initWithJob: (NLJob *) job;
@end

@interface NLJob : VinylRecord           {
    NSMutableArray *_params;
    NLJobDescriptor *_descriptor;
}

column_dec(string, handler)
column_dec(string, queue)
column_dec(string, parameters)
column_dec(integer, priority)
column_dec(integer, attempts)
column_dec(string, last_error)
column_dec(date, run_at)
column_dec(date, locked_at)
column_dec(boolean, locked)
column_dec(date, failed_at)
column_dec(boolean, internet)
column_dec(boolean,unique)
column_dec(integer, job_id)


@property(nonatomic,retain) NSMutableArray *params;
@property(readonly,retain) NLJobDescriptor *descriptor;

+ (NLJob *) jobWithArguments: (id) firstObject, ...;
+ (NLJob *) jobWithHandler: (NSString *) className arguments: (id) firstObject, ...;
+ (NLJob *) jobWithHandler: (NSString *) className;
- (NLJob *) setArguments: (id) firstObject, ...;

- (BOOL) shouldRestartJob;
- (void) onBeforeDeleteEvent; //onBeforeDeleteEvent
- (BOOL) perform;
- (BOOL) run;
@end

@protocol NLJobsAbility <NSObject>
@required
+ (BOOL) performJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@optional

@end