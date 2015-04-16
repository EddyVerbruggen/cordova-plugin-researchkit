#import "ResearchKit.h"

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// TODO useful implementation as this is merely a PoC
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

@implementation ResearchKit

- (void) isAvailable:(CDVInvokedUrlCommand*)command; {
  // all ok, for now
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

// see http://researchkit.github.io/docs/docs/Survey/CreatingSurveys.html
- (void) survey:(CDVInvokedUrlCommand*)command {

  // remember the command, because we need it in the delegate
  _command = command;
  
  [self.commandDelegate runInBackground:^{

    ORKInstructionStep *instructionStep = [[ORKInstructionStep alloc] initWithIdentifier:@"intro"];
    instructionStep.title = @"ResearchKit + Cordova = Awesome";
    instructionStep.text = @"This is the text, dude :)";

    ORKNumericAnswerFormat *format = [ORKNumericAnswerFormat integerAnswerFormatWithUnit:@"years"];
    format.minimum = @(18);
    format.maximum = @(90);
    ORKQuestionStep *questionStep = [ORKQuestionStep questionStepWithIdentifier:@"step1"
                                                                          title:@"How old are you?"
                                                                         answer:format];

    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:@"task" steps:@[instructionStep, questionStep]];
  
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    [self.viewController presentViewController:taskViewController animated:YES completion:nil];

  }];
}

// ORKTaskViewControllerDelegate
- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(NSError *)error {

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
      if (qres.class == [ORKNumericQuestionResult class]) { //  ==  if (qres.questionType == ORKQuestionTypeInteger) {
        unit = ((ORKNumericQuestionResult*)qres).unit;
        value = ((ORKNumericQuestionResult*)qres).numericAnswer;
      }

      NSMutableDictionary *questionResultEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
//                                                  qres.identifier, @"id",
//                                                  qres.description, @"description",
//                                                  [df stringFromDate:qres.startDate], @"startDate",
//                                                  [df stringFromDate:qres.endDate], @"endDate",
                                                  unit, @"unit",
                                                  value, @"value",
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
  
  
  
  // Then, dismiss the task view controller.
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
  
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalResults];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
}

@end