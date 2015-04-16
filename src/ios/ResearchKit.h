#import <Cordova/CDVPlugin.h>
#import <ResearchKit/ResearchKit.h>

@interface ResearchKit : CDVPlugin<ORKTaskViewControllerDelegate>

@property (retain) CDVInvokedUrlCommand * command;

- (void) isAvailable:(CDVInvokedUrlCommand*)command;

- (void) survey:(CDVInvokedUrlCommand*)command;

@end