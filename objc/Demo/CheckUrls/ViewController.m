//
//  ViewController.m
//  CheckUrls
//
//  Created by Daniel Khamsing on 10/12/15.
//  Copyright © 2015 Daniel Khamsing. All rights reserved.
//

#import "ViewController.h"
#import "checkliveurls.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *console;
@property (weak, nonatomic) IBOutlet UILabel *passLabel;
@property (weak, nonatomic) IBOutlet UITextView *consoleFail;
@property (weak, nonatomic) IBOutlet UILabel *foundLabel;

@property (nonatomic) BOOL showSuccess;
@property (nonatomic) BOOL addControlFailure;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.console.text = @"";
    self.consoleFail.text = @"";
    
    self.showSuccess = YES;
    self.addControlFailure = NO;
    
    NSArray *readmes = @[
                         //                         @"https://raw.githubusercontent.com/sindresorhus/awesome/master/readme.md",
                         //                         @"https://raw.githubusercontent.com/matteocrippa/awesome-swift/master/README.md",
                         //                         @"https://raw.githubusercontent.com/vsouza/awesome-ios/master/README.md",
                         @"https://raw.githubusercontent.com/dkhamsing/open-source-ios-apps/master/README.md",
                         ];
    
    NSLog(@"processing %@", readmes);
    
    [CheckLiveURLs getUrlsFromPages:readmes completion:^(NSArray *stringUrls) {
        NSMutableArray *links = stringUrls.mutableCopy;
        
        if (self.addControlFailure) {
            [links addObject:@"control failure :)"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.foundLabel.text = @(links.count).stringValue;
        });
        
        [self checkLinks:links];
    }];
}

#pragma mark Private

- (void)checkLinks:(NSArray *)links {
    __block NSInteger counter = 0;
    
    [links enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CheckLiveURLs getHttpResponseStatusCodeForStringUrl:obj completion:^(NSInteger statusCode, BOOL success, NSError *error) {
                counter++;
                
                if (counter==links.count) {
                    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Yay" message:@"all done" preferredStyle:UIAlertControllerStyleAlert];
                    [controller addAction: [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil] ];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:controller animated:YES completion:nil];
                    });
                }
                
                if (statusCode!=200 || error) {
                    NSLog(@"🔴🔴🔴 error code %@ for %@: %@", obj,
                          @(statusCode),
                          error);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.consoleFail.text = [self.consoleFail.text stringByAppendingFormat:@"🔴 %@ %@ \n",
                                                 @(statusCode),
                                                 obj];
                    });
                }
                else {
                    if (self.showSuccess) {
                        NSLog(@"✅ %@", obj);
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.console.text = [self.console.text stringByAppendingFormat:@"✅ %@ \n", obj];
                        
                        self.passLabel.text = ({
                            NSString *passString = self.passLabel.text;
                            NSInteger number = passString.integerValue;
                            number++;
                            
                            @(number).stringValue;
                        });
                    });
                } //end if
            }]; //get http respoonse
        });//dispatch
    }];//enumerate
}

@end
