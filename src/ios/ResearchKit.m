#import "ResearchKit.h"

@implementation ResearchKit

- (void) isAvailable:(CDVInvokedUrlCommand*)command; {
  // all ok, for now
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

// see http://researchkit.github.io/docs/docs/Survey/CreatingSurveys.html
- (void) survey:(CDVInvokedUrlCommand*)command {
  
  // remember the command, because we need it in the delegate
  _command = command;
  
  // let's see what's passed in
  // TODO rewrite this so it loops over all passed-in items so the JS order prevails
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  NSMutableDictionary *consentSteps     = [args objectForKey:@"consentSteps"];
  NSMutableDictionary *instructionSteps = [args objectForKey:@"instructionSteps"];
  NSMutableDictionary *questionSteps    = [args objectForKey:@"questionSteps"];
  
  [self.commandDelegate runInBackground:^{
    
    // todo update count
    NSMutableArray *steps = [[NSMutableArray alloc] initWithCapacity:instructionSteps.count + questionSteps.count + consentSteps.count];
    
    // consent steps
    NSMutableArray *consentSections = [[NSMutableArray alloc] initWithCapacity:consentSteps.count];
    ORKConsentDocument *document = [ORKConsentDocument new];
    document.title = @"Demo koncent"; // TODO, shown in the review step
    document.signaturePageTitle = @"Sig.."; // TODO

    for (NSDictionary *consentStep in consentSteps) {
      //NSString *id = [consentStep objectForKey:@"id"]; // TODO do we need this?
      NSString *title = [consentStep objectForKey:@"title"];
      NSString *summary = [consentStep objectForKey:@"summary"];
      NSString *content = [consentStep objectForKey:@"content"];
      NSString *htmlContent = [consentStep objectForKey:@"htmlContent"];
      ORKConsentSection *section = [self getORKConsentSection:consentStep];
      section.title = title;
      section.summary = summary;
      section.content = content;
      section.htmlContent = htmlContent;
      [consentSections addObject:section];
    }
    document.sections = consentSections;
    ORKVisualConsentStep *visualConsentStep = [[ORKVisualConsentStep alloc] initWithIdentifier:@"visualconsent" document:document];
    [steps addObject:visualConsentStep];

    
    // TODO from API
    ORKConsentSharingStep *sharingStep = [[ORKConsentSharingStep alloc] initWithIdentifier:@"sharing1"
                                                              investigatorShortDescription:@"MyInstitution"
                                                               investigatorLongDescription:@"MyInstitution and its partners"
                                                             localizedLearnMoreHTMLContent:@"Lorem ipsum..."];
    [steps addObject:sharingStep];
    
    // TODO from API
    ORKConsentReviewStep *reviewStep = [[ORKConsentReviewStep alloc] initWithIdentifier:@"review1"
                                           signature:document.signatures[0]
                                          inDocument:document];
    reviewStep.text = @"Lorem ipsum 1..";
    reviewStep.reasonForConsent = @"Lorem ipsum 2..."; // shown when 'Agree' is pressed
    reviewStep.title = @"tijtel";
    [steps addObject:reviewStep];

    
    // instruction steps
    for (NSDictionary *instructionStep in instructionSteps) {
      NSString *id = [instructionStep objectForKey:@"id"];
      NSString *title = [instructionStep objectForKey:@"title"];
      NSString *text = [instructionStep objectForKey:@"text"];
      ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:id];
      step.title = title;
      step.text = text;
      // TODO nice additions
      // step.image = [UIImage ..]
      // step.detailText = @"details here";
      [steps addObject:step];
    }
    
    // question steps
    for (NSDictionary *questionStep in questionSteps) {
      NSString *id = [questionStep objectForKey:@"id"];
      NSString *title = [questionStep objectForKey:@"title"];
      ORKAnswerFormat *format = [self getORKAnswerFormat:questionStep];
      ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:id title:title answer:format];
      [steps addObject:step];
    }
    
    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:@"task" steps:steps];
    
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    [self.viewController presentViewController:taskViewController animated:YES completion:nil];
    
  }];
}

- (ORKConsentSection*) getORKConsentSection:(NSDictionary*) consentStep {
  NSString *sectionType = [consentStep objectForKey:@"sectionType"];
  
  if ([sectionType isEqualToString: @"ORKConsentSectionTypeDataGathering"] || [sectionType isEqualToString: @"dataGathering"]) {
    return [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeDataGathering];

  } else if ([sectionType isEqualToString: @"ORKConsentSectionTypeOverview"] || [sectionType isEqualToString: @"overview"]) {
    return [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeOverview];

  } else {
    return nil;
  }
}

- (ORKAnswerFormat*) getORKAnswerFormat:(NSDictionary*) questionStep {
  NSString *answerFormat = [questionStep objectForKey:@"answerFormat"];
  
  if ([answerFormat isEqualToString: @"ORKBooleanAnswerFormat"] || [answerFormat isEqualToString: @"boolean"]) {
    return [ORKBooleanAnswerFormat booleanAnswerFormat];
    
  } else if ([answerFormat isEqualToString: @"ORKNumericAnswerFormat"] || [answerFormat isEqualToString: @"numeric"]) {
    NSString *unit = [questionStep objectForKey:@"unit"];
    NSNumber *minimum = [questionStep objectForKey:@"minimum"];
    NSNumber *maximum = [questionStep objectForKey:@"maximum"];
    ORKNumericAnswerFormat *format = [ORKNumericAnswerFormat integerAnswerFormatWithUnit:unit]; // e.g. "years"
    format.minimum = minimum;
    format.maximum = maximum;
    return format;
    
  } else {
    return nil;
  }
}

// ORKTaskViewControllerDelegate
- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(NSError *)error {
  
  if (reason != ORKTaskViewControllerFinishReasonCompleted) {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR]; // TODO a nice reason
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
    return;
  }
  
  ORKTaskResult *taskResult = [taskViewController result];
  // You could do something with the result here.
  
  NSArray *results = taskResult.results;
  // create a return object per identifier with the answer(s)
  
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  
  NSMutableArray *finalResults = [[NSMutableArray alloc] initWithCapacity:results.count];
  for (ORKStepResult *res in results) {
    NSArray *orkResults = res.results;
    NSMutableArray *questionResultEntries = [[NSMutableArray alloc] initWithCapacity:orkResults.count];
    if (orkResults.count > 0) { // visual consent screens / instructions don't required answers
      for (ORKResult *orkResult in orkResults) {
        NSMutableDictionary *questionResultEntry;
        // TODO: rewrite so this results in a different result entry per response class
        if (orkResult.class == [ORKNumericQuestionResult class]) { //  ==  if (qres.questionType == ORKQuestionTypeInteger) {
          questionResultEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 orkResult.identifier, @"id",
                                 [orkResult.class description], @"type",
                                 ((ORKNumericQuestionResult*)orkResult).numericAnswer, @"value",
                                 ((ORKNumericQuestionResult*)orkResult).unit, @"unit",
                                 nil];
        } else if (orkResult.class == [ORKBooleanQuestionResult class]) {
          questionResultEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 orkResult.identifier, @"id",
                                 [orkResult.class description], @"type",
                                 ((ORKBooleanQuestionResult*)orkResult).booleanAnswer, @"value",
                                 nil];
        } else if (orkResult.class == [ORKConsentSignatureResult class]) {
          questionResultEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 orkResult.identifier, @"id",
                                 [orkResult.class description], @"type",
                                 ((ORKConsentSignatureResult*)orkResult).signature, @"signature",
                                 nil];
        } else if (orkResult.class == [ORKChoiceQuestionResult class]) {
          NSArray *values = ((ORKChoiceQuestionResult*)orkResult).choiceAnswers;
          questionResultEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 orkResult.identifier, @"id",
                                 [orkResult.class description], @"type",
                                 values, @"values",
                                 nil];
        }
        [questionResultEntries addObject:questionResultEntry];
      }

      NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    res.identifier, @"id",
                                    [df stringFromDate:res.startDate], @"startDate",
                                    [df stringFromDate:res.endDate], @"endDate",
                                    questionResultEntries, @"answers",
                                    nil];
    
      [finalResults addObject:entry];
    }
  }
  
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
}

@end