//
// Created by James Whitfield on 4/10/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLDelayedJob.h"

@interface NLDelayedJob()
- (NSInteger) processJobsUpToMaximum:(NSInteger) maximum;
@end