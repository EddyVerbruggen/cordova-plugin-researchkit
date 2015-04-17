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
  NSMutableDictionary *args = [command.arguments objectAtIndex:0];
  NSMutableDictionary *instructionSteps = [args objectForKey:@"instructionSteps"];
//  NSArray *consentSteps = [args objectForKey:@"consentSteps"]; // TODO not sure about the name
  NSMutableDictionary *questionSteps = [args objectForKey:@"questionSteps"];

  [self.commandDelegate runInBackground:^{

    NSMutableArray *steps = [[NSMutableArray alloc] initWithCapacity:instructionSteps.count + questionSteps.count];

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
    NSArray *questionResults = res.results;
    NSMutableArray *questionResultEntries = [[NSMutableArray alloc] initWithCapacity:questionResults.count];
    for (ORKQuestionResult *qres in questionResults) {
      NSString *unit;
      NSNumber *value;
      // NOTE: this will likely change to a different result entry per response class
      if (qres.class == [ORKNumericQuestionResult class]) { //  ==  if (qres.questionType == ORKQuestionTypeInteger) {
        unit = ((ORKNumericQuestionResult*)qres).unit;
        value = ((ORKNumericQuestionResult*)qres).numericAnswer;
      } else if (qres.class == [ORKBooleanQuestionResult class]) {
        value = ((ORKBooleanQuestionResult*)qres).booleanAnswer;
      }

      NSMutableDictionary *questionResultEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
//                                                  qres.identifier, @"id",
//                                                  qres.description, @"description",
//                                                  [df stringFromDate:qres.startDate], @"startDate",
//                                                  [df stringFromDate:qres.endDate], @"endDate",
                                                  value, @"value",
                                                  unit, @"unit",
                                                  nil
                                                  ];
      [questionResultEntries addObject:questionResultEntry];
    }
    //    }
    NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                  res.identifier, @"id",
                                  [df stringFromDate:res.startDate], @"startDate",
                                  [df stringFromDate:res.endDate], @"endDate",
                                  questionResultEntries, @"answers",
                                  nil
                                  ];
    
    [finalResults addObject:entry];
  }
  
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
}

@end