//
//  SpeechRecognizer.m
//  Snagr
//
//  Created by Eyuel Tessema on 3/7/15.
//  Copyright (c) 2015 Alexander Hsu. All rights reserved.
//

#import "SpeechRecognizer.h"

#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OELogging.h>
#import <OpenEars/OEAcousticModel.h>
#import <Slt/Slt.h>

@interface SpeechRecognizer ()

@property (nonatomic, strong) Slt *slt;

// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) OEPocketsphinxController *pocketsphinxController;
@property (nonatomic, strong) OEFliteController *fliteController;

// Some UI, not specifically related to OpenEars.
@property (nonatomic, assign) BOOL usingStartingLanguageModel;
@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;

// Things which help us show off the dynamic language features.
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedDictionary;

// Our NSTimer that will help us read and display the input and output levels without locking the UI
@property (nonatomic, strong) 	NSTimer *uiUpdateTimer;

@end


@implementation SpeechRecognizer

+ (void)hello
{
    NSLog(@"hello");
}



#define kLevelUpdatesPerSecond 2 // We'll have the ui update 18 times a second to show some fluidity without hitting the CPU too hard.

#pragma mark -
#pragma mark Setup

- (void)setup {
    self.fliteController = [[OEFliteController alloc] init];
    self.openEarsEventsObserver = [[OEEventsObserver alloc] init];
    self.openEarsEventsObserver.delegate = self;
    self.slt = [[Slt alloc] init];
    
    self.restartAttemptsDueToPermissionRequests = 0;
    self.startupFailedDueToLackOfPermissions = FALSE;
    
    // [OELogging startOpenEarsLogging]; // Uncomment me for OELogging, which is verbose logging about internal OpenEars operations such as audio settings. If you have issues, show this logging in the forums.
    //[OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE; // Uncomment this for much more verbose speech recognition engine output. If you have issues, show this logging in the forums.
    
    [self.openEarsEventsObserver setDelegate: self]; // Make this class the delegate of OpenEarsObserver so we can get all of the messages about what OpenEars is doing.
    
    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this before setting any OEPocketsphinxController characteristics
    
    // This is the language model we're going to start up with. The only reason I'm making it a class property is that I reuse it a bunch of times in this example, 
    // but you can pass the string contents directly to OEPocketsphinxController:startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF:
    
    NSArray *firstLanguageArray = @[@"BACKWARD",
                                    @"CHANGE",
                                    @"FORWARD",
                                    @"GO",
                                    @"LEFT",
                                    @"MODEL",
                                    @"RIGHT",
                                    @"TURN"];
    
    OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init]; 
    
    // languageModelGenerator.verboseLanguageModelGenerator = TRUE; // Uncomment me for verbose language model generator debug output.

    NSError *error = [languageModelGenerator generateLanguageModelFromArray:firstLanguageArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
    
    if(error) {
        NSLog(@"Dynamic language generator reported error %@", [error description]);	
    } else {
        self.pathToFirstDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
        self.pathToFirstDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
    }
    
    self.usingStartingLanguageModel = TRUE; // This is not an OpenEars thing, this is just so I can switch back and forth between the two models in this sample app.
    
    // Here is an example of dynamically creating an in-app grammar.
    
    // We want it to be able to response to the speech "CHANGE MODEL" and a few other things.  Items we want to have recognized as a whole phrase (like "CHANGE MODEL") 
    // we put into the array as one string (e.g. "CHANGE MODEL" instead of "CHANGE" and "MODEL"). This increases the probability that they will be recognized as a phrase. This works even better starting with version 1.0 of OpenEars.
    
    NSArray *secondLanguageArray = @[@"SUNDAY",
                                     @"MONDAY",
                                     @"TUESDAY",
                                     @"WEDNESDAY",
                                     @"THURSDAY",
                                     @"FRIDAY",
                                     @"SATURDAY",
                                     @"QUIDNUNC",
                                     @"CHANGE MODEL"];
    
    // The last entry, quidnunc, is an example of a word which will not be found in the lookup dictionary and will be passed to the fallback method. The fallback method is slower,
    // so, for instance, creating a new language model from dictionary words will be pretty fast, but a model that has a lot of unusual names in it or invented/rare/recent-slang
    // words will be slower to generate. You can use this information to give your users good UI feedback about what the expectations for wait times should be.
    
    // I don't think it's beneficial to lazily instantiate OELanguageModelGenerator because you only need to give it a single message and then release it.
    // If you need to create a very large model or any size of model that has many unusual words that have to make use of the fallback generation method,
    // you will want to run this on a background thread so you can give the user some UI feedback that the task is in progress.
        
    // generateLanguageModelFromArray:withFilesNamed returns an NSError which will either have a value of noErr if everything went fine or a specific error if it didn't.
    error = [languageModelGenerator generateLanguageModelFromArray:secondLanguageArray withFilesNamed:@"SecondOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
    //    NSError *error = [languageModelGenerator generateLanguageModelFromTextFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"OpenEarsCorpus.txt"] withFilesNamed:@"SecondOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Try this out to see how generating a language model from a corpus works.
    
    
    if(error) {
        NSLog(@"Dynamic language generator reported error %@", [error description]);	
    }	else {
        
        self.pathToSecondDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"SecondOpenEarsDynamicLanguageModel"]; // We'll set our new .languagemodel file to be the one to get switched to when the words "CHANGE MODEL" are recognized.
        self.pathToSecondDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"SecondOpenEarsDynamicLanguageModel"];; // We'll set our new dictionary to be the one to get switched to when the words "CHANGE MODEL" are recognized.
        
        // Next, an informative message.
        
        NSLog(@"\n\nWelcome to the OpenEars sample project. This project understands the words:\nBACKWARD,\nCHANGE,\nFORWARD,\nGO,\nLEFT,\nMODEL,\nRIGHT,\nTURN,\nand if you say \"CHANGE MODEL\" it will switch to its dynamically-generated model which understands the words:\nCHANGE,\nMODEL,\nMONDAY,\nTUESDAY,\nWEDNESDAY,\nTHURSDAY,\nFRIDAY,\nSATURDAY,\nSUNDAY,\nQUIDNUNC");
        
        // This is how to start the continuous listening loop of an available instance of OEPocketsphinxController. We won't do this if the language generation failed since it will be listening for a command to change over to the generated language.
        
        [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this once before setting properties of the OEPocketsphinxController instance.

        //   [OEPocketsphinxController sharedInstance].pathToTestFile = [[NSBundle mainBundle] pathForResource:@"change_model_short" ofType:@"wav"];  // This is how you could use a test WAV (mono/16-bit/16k) rather than live recognition
        
        if(![OEPocketsphinxController sharedInstance].isListening) {
            [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
        }
        
        NSLog(@"Is listening: %@", ([OEPocketsphinxController sharedInstance].isListening ? @"YES" : @"NO"));
        
        [self startDisplayingLevels];
    }
}

#pragma mark -
#pragma mark OEEventsObserver delegate methods

// What follows are all of the delegate methods you can optionally use once you've instantiated an OEEventsObserver and set its delegate to self. 
// I've provided some pretty granular information about the exact phase of the Pocketsphinx listening loop, the Audio Session, and Flite, but I'd expect 
// that the ones that will really be needed by most projects are the following:
//
//- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID;
//- (void) audioSessionInterruptionDidBegin;
//- (void) audioSessionInterruptionDidEnd;
//- (void) audioRouteDidChangeToRoute:(NSString *)newRoute;
//- (void) pocketsphinxDidStartListening;
//- (void) pocketsphinxDidStopListening;
//
// It isn't necessary to have a OEPocketsphinxController or a OEFliteController instantiated in order to use these methods.  If there isn't anything instantiated that will
// send messages to an OEEventsObserver, all that will happen is that these methods will never fire.  You also do not have to create a OEEventsObserver in
// the same class or view controller in which you are doing things with a OEPocketsphinxController or OEFliteController; you can receive updates from those objects in
// any class in which you instantiate an OEEventsObserver and set its delegate to self.


// This is an optional delegate method of OEEventsObserver which delivers the text of speech that Pocketsphinx heard and analyzed, along with its accuracy score and utterance ID.
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
    NSLog(@"Local callback: The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID); // Log it.
    if([hypothesis isEqualToString:@"CHANGE MODEL"]) { // If the user says "CHANGE MODEL", we will switch to the alternate model (which happens to be the dynamically generated model).
        
        // Here is an example of language model switching in OpenEars. Deciding on what logical basis to switch models is your responsibility.
        // For instance, when you call a customer service line and get a response tree that takes you through different options depending on what you say to it,
        // the models are being switched as you progress through it so that only relevant choices can be understood. The construction of that logical branching and 
        // how to react to it is your job, OpenEars just lets you send the signal to switch the language model when you've decided it's the right time to do so.
        
        if(self.usingStartingLanguageModel) { // If we're on the starting model, switch to the dynamically generated one.
            
            // You can only change language models with ARPA grammars in OpenEars (the ones that end in .languagemodel or .DMP). 
            // Trying to switch between JSGF models (the ones that end in .gram) will return no result.
            [[OEPocketsphinxController sharedInstance] changeLanguageModelToFile:self.pathToSecondDynamicallyGeneratedLanguageModel withDictionary:self.pathToSecondDynamicallyGeneratedDictionary]; 
            self.usingStartingLanguageModel = FALSE;
        } else { // If we're on the dynamically generated model, switch to the start model (this is just an example of a trigger and method for switching models).
            [[OEPocketsphinxController sharedInstance] changeLanguageModelToFile:self.pathToFirstDynamicallyGeneratedLanguageModel withDictionary:self.pathToFirstDynamicallyGeneratedDictionary];
            self.usingStartingLanguageModel = TRUE;
        }
    }
    
//    self.heardTextView.text = [NSString stringWithFormat:@"Heard: \"%@\"", hypothesis]; // Show it in the status box.
    
    // This is how to use an available instance of OEFliteController. We're going to repeat back the command that we heard with the voice we've chosen.
    [self.fliteController say:[NSString stringWithFormat:@"You said %@",hypothesis] withVoice:self.slt];
}

#ifdef kGetNbest   
- (void) pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray { // Pocketsphinx has an n-best hypothesis dictionary.
    NSLog(@"Local callback:  hypothesisArray is %@",hypothesisArray);   
}
#endif
// An optional delegate method of OEEventsObserver which informs that there was an interruption to the audio session (e.g. an incoming phone call).
- (void) audioSessionInterruptionDidBegin {
    NSLog(@"Local callback:  AudioSession interruption began."); // Log it.
//    self.statusTextView.text = @"Status: AudioSession interruption began."; // Show it in the status box.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) {
        error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening (if it is listening) since it will need to restart its loop after an interruption.
        if(error) NSLog(@"Error while stopping listening in audioSessionInterruptionDidBegin: %@", error);
    }
}

// An optional delegate method of OEEventsObserver which informs that the interruption to the audio session ended.
- (void) audioSessionInterruptionDidEnd {
    NSLog(@"Local callback:  AudioSession interruption ended."); // Log it.
//    self.statusTextView.text = @"Status: AudioSession interruption ended."; // Show it in the status box.
    // We're restarting the previously-stopped listening loop.
    if(![OEPocketsphinxController sharedInstance].isListening){
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't currently listening.    
    }
}

// An optional delegate method of OEEventsObserver which informs that the audio input became unavailable.
- (void) audioInputDidBecomeUnavailable {
    NSLog(@"Local callback:  The audio input has become unavailable"); // Log it.
//    self.statusTextView.text = @"Status: The audio input has become unavailable"; // Show it in the status box.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening){
        error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening since there is no available input (but only if we are listening).
        if(error) NSLog(@"Error while stopping listening in audioInputDidBecomeUnavailable: %@", error);
    }
}

// An optional delegate method of OEEventsObserver which informs that the unavailable audio input became available again.
- (void) audioInputDidBecomeAvailable {
    NSLog(@"Local callback: The audio input is available"); // Log it.
//    self.statusTextView.text = @"Status: The audio input is available"; // Show it in the status box.
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition, but only if we aren't already listening.
    }
}
// An optional delegate method of OEEventsObserver which informs that there was a change to the audio route (e.g. headphones were plugged in or unplugged).
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
    NSLog(@"Local callback: Audio route change. The new audio route is %@", newRoute); // Log it.
//    self.statusTextView.text = [NSString stringWithFormat:@"Status: Audio route change. The new audio route is %@",newRoute]; // Show it in the status box.
    
    NSError *error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling the Pocketsphinx loop to shut down and then start listening again on the new route
    
    if(error)NSLog(@"Local callback: error while stopping listening in audioRouteDidChangeToRoute: %@",error);

    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
    }
}

// An optional delegate method of OEEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void) pocketsphinxRecognitionLoopDidStart {
    
    NSLog(@"Local callback: Pocketsphinx started."); // Log it.
//    self.statusTextView.text = @"Status: Pocketsphinx started."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
- (void) pocketsphinxDidStartListening {
    
    NSLog(@"Local callback: Pocketsphinx is now listening."); // Log it.
//    self.statusTextView.text = @"Status: Pocketsphinx is now listening."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected speech."); // Log it.
//    self.statusTextView.text = @"Status: Pocketsphinx has detected speech."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance. 
// This was added because developers requested being able to time the recognition speed without the speech time. The processing time is the time between 
// this method being called and the hypothesis being returned.
- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected a second of silence, concluding an utterance."); // Log it.
//    self.statusTextView.text = @"Status: Pocketsphinx has detected finished speech."; // Show it in the status box.
}


// An optional delegate method of OEEventsObserver which informs that Pocketsphinx has exited its recognition loop, most 
// likely in response to the OEPocketsphinxController being told to stop listening via the stopListening method.
- (void) pocketsphinxDidStopListening {
    NSLog(@"Local callback: Pocketsphinx has stopped listening."); // Log it.
//    self.statusTextView.text = @"Status: Pocketsphinx has stopped listening."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
// Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
// in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to suspend recognition via the suspendRecognition method.
- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Local callback: Pocketsphinx has suspended recognition."); // Log it.
//    self.statusTextView.text = @"Status: Pocketsphinx has suspended recognition."; // Show it in the status box.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
// having been suspended it is now resuming.  This can happen as a result of Flite speech completing
// on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to resume recognition via the resumeRecognition method.
- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Local callback: Pocketsphinx has resumed recognition."); // Log it.
//    self.statusTextView.text = @"Status: Pocketsphinx has resumed recognition."; // Show it in the status box.
}



- (void) startDisplayingLevels { // Start displaying the levels using a timer
    [self stopDisplayingLevels]; // We never want more than one timer valid so we'll stop any running timers first.
    self.uiUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/kLevelUpdatesPerSecond target:self selector:@selector(updateLevelsUI) userInfo:nil repeats:YES];
}

- (void) stopDisplayingLevels { // Stop displaying the levels by stopping the timer if it's running.
    if(self.uiUpdateTimer && [self.uiUpdateTimer isValid]) { // If there is a running timer, we'll stop it here.
        [self.uiUpdateTimer invalidate];
        self.uiUpdateTimer = nil;
    }
}

- (void) updateLevelsUI { // And here is how we obtain the levels.  This method includes the actual OpenEars methods and uses their results to update the UI of this view controller.
    
    NSString *foo1 = [NSString stringWithFormat:@"Pocketsphinx Input level:%f",[[OEPocketsphinxController sharedInstance] pocketsphinxInputLevel]];  //pocketsphinxInputLevel is an OpenEars method of the class OEPocketsphinxController.
    
    NSString *foo2 = @"";
    if(self.fliteController.speechInProgress) {
        foo2 = [NSString stringWithFormat:@"Flite Output level: %f",[self.fliteController fliteOutputLevel]]; // fliteOutputLevel is an OpenEars method of the class OEFliteController.
    }
    
    NSLog(@"%@", foo1);
    NSLog(@"%@", foo2);
}
@end
