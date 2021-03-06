//
//  NLDelayedJob.h
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NLDelayableJob.h"
#import "NLDelayedJobManager.h"

typedef NS_ENUM(NSInteger, NLDelayedJobPriority) {
    NLDelayedJobPriorityNormal=1,
    NLDelayedJobPriorityMedium=5,
    NLDelayedJobPriorityHigh=10
};

@interface NLDelayedJobConfiguration : NSObject
@property(nonatomic, assign) NSInteger max_attempts;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, retain) NSString *host;
@property(nonatomic, retain) NSString *queue;
@property(nonatomic, assign) BOOL hasInternet;
@end


typedef void (^NLDelayedJobBlock)(NLJobDescriptor* descriptor , NSArray * arguments);
typedef void (^NLDelayedJobConfigurationBlock)(NLDelayedJobConfiguration *config);

@interface NLDelayedJob : NSObject {}
@property(nonatomic, assign) NSInteger max_attempts;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, retain) NSString *host;
@property(nonatomic, readonly) NSString *queue;
#pragma mark - Initialization

+ (instancetype)queueWithName:(NSString *)name interval:(NSTimeInterval)interval attemps:(NSInteger)attempts;

- (id)initWithQueue:(NSString *)name interval:(NSTimeInterval)interval attemps:(NSInteger)attempts;

+ (NLDelayedJob *)configure:(NLDelayedJobConfigurationBlock)config;

#pragma mark - Singleton Helpers

+ (NLDelayedJob *)defaultQueue;

+ (NLDelayedJobManager *)sharedManager;

#pragma mark - Instance Methods

- (NLDelayedJob *)start; //starts timers and job processing

- (void)pause; // Prevents now jobs from being processed

- (void)resume; // Allows new jobs to be pull from queue and executed

- (void)stop; // shuts down timers

- (NSInteger)run;

- (NLDelayableJob *)scheduleInternetJob:(id) jobOrClass priority:(NSInteger)priority;

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority internet:(BOOL)requireInternet;

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority;
@end