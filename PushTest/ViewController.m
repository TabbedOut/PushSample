//
//  ViewController.m
//  PushTest
//
//  Created by Davis Treybig on 6/11/14.
//  Copyright (c) 2014 Davis Treybig. All rights reserved.
//

#import "ViewController.h"
#import "Parse/Parse.h"
#import <AWSSNS/AWSSNS.h>
#import <AWSSNS/AmazonSNSClient.h>

//This view controller has some sample code to send pushes from in-app via Parse and Amazon SNS. Azure and Urban Airship
//Dont offer this functionality
@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)parseTestPush:(id)sender {
    //Sample code to send parse push from in app. Sends a push to all iOS devices with the specified alert which will increment badge values
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"This is a Parse test push", @"alert",
                          @"Increment", @"badge",
                          nil];
    PFPush *push = [[PFPush alloc] init];
    [push setChannel: @"iOS"];
    [push setData:data];
    [push sendPushInBackground];
    
}

- (IBAction) amazonTestPush:(id)sender {
    //Sample code to send Amazon Push in app. Sends a push to all devices with message "Amazon Test". 
    AmazonSNSClient *snsClient = [[AmazonSNSClient alloc] initWithAccessKey:@"AccessKey" withSecretKey:@"SecretKey"];
    snsClient.endpoint = @"Endpoint";
    
    //get a list of endpoints on the platform
    SNSListEndpointsByPlatformApplicationRequest *platformEndpointList = [[SNSListEndpointsByPlatformApplicationRequest alloc] init];
    platformEndpointList.platformApplicationArn = @"PlatformARN";
    SNSListEndpointsByPlatformApplicationResponse *platformEndpointResponse = [snsClient listEndpointsByPlatformApplication:platformEndpointList];
    NSMutableArray *endpointArray = [platformEndpointResponse endpoints];
    //send notification to every device in list
    for(int i=0; i<endpointArray.count; i++){
        SNSPublishRequest *request = [[SNSPublishRequest alloc] init];
        request.message = @"Amazon test";
        SNSEndpoint *endpoint = [endpointArray objectAtIndex:i];
        request.targetArn = [endpoint endpointArn];
         @try{
             [snsClient publish:request];
         }
         @catch (AmazonServiceException *serviceException){
             NSLog(@"%@", serviceException);
         }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
