//
//  SpeechRecognizer.h
//  Snagr
//
//  Created by Eyuel Tessema on 3/7/15.
//  Copyright (c) 2015 Alexander Hsu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenEars/OEEventsObserver.h>

@interface SpeechRecognizer : NSObject <OEEventsObserverDelegate>

- (void)setup;

@end
