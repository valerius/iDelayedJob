//
//  DelayedJob.h
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLDelayedJob.h"
#import "NLDelayableJob.h"
#import "NLDelayedJobManager.h"
#import "NLDelayableJobAbility.h"


#define DelayedJob NLDelayedJob
#define DelayableJobAbility NLDelayableJobAbility
#define DelayableJob NLDelayableJob

#define DelayedJob_schedule(jobOrClass,queue_name,queue_priority,...) [[NLDelayedJob sharedManager] scheduleJob: \
    [NLDelayableJob job:jobOrClass withArguments: __VA_ARGS__ , nil ] \
    queue:queue_name priority:queue_priority internet:NO]

#define DelayedJob_configure(config_block) \
    [NLDelayedJob configure: config_block]

#define DelayedJob_create(jobOrClass, ...)  [NLDelayableJob job:jobOrClass withArguments: __VA_ARGS__ , nil ]

