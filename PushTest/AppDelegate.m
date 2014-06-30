//
//  AppDelegate.m
//  PushTest
//
//  Created by Drew TREYBIG on 6/11/14.
//  Copyright (c) 2014 Davis Treybig. All rights reserved.
//

#import "AppDelegate.h"
#import "Parse/Parse.h"
#import <AWSSNS/AWSSNS.h>
#import <AWSSNS/AmazonSNSClient.h>
#import <WindowsAzureMessaging/WindowsAzureMessaging.h>
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"

@implementation AppDelegate
double myLatitude;
double myLongitude;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //UA setup (Registration keys in AirshipConfig.plist)
    UAConfig *config = [UAConfig defaultConfig];
    [config setAutomaticSetupEnabled:true];
    [UAirship takeOff:config];
    
    //Parse Setup
    [Parse setApplicationId:@"parseKey"
                  clientKey:@"parseClientID"];
    
    // Register for push notifications with phone
    [application registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
    
    return YES;
}

- (void) parseSetup:(NSData *) newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    
    //Example code to add key/value tags to Parse
    [currentInstallation addUniqueObject:@"iOS" forKey:@"channels"];
    [currentInstallation setObject: @YES forKey:@"citi"];
    
    //Example code to add a geo-location tag
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            myLatitude=geoPoint.latitude;
            myLongitude=geoPoint.longitude;
            currentInstallation[@"location"] = [PFGeoPoint geoPointWithLatitude:myLatitude longitude:myLongitude];
            [currentInstallation saveInBackground];
            
        }
        else{
            NSLog(@"Parse Geo-Location Error");
        }
    }];
 
    //Save tags we have added
    [currentInstallation saveInBackground];
}
- (void) azureSetup:(NSData *) newDeviceToken{
    SBNotificationHub* hub = [[SBNotificationHub alloc] initWithConnectionString:
                              @"SampleEndpoint" notificationHubPath:@"hubpath"];
    //Sample azure tags
    NSMutableSet *azureTagSet = [[NSMutableSet alloc] initWithObjects:@"iOS", @"Davis", @"Test", nil];
    [hub registerNativeWithDeviceToken:newDeviceToken tags:azureTagSet completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Error registering for notifications: %@", error);
        }
    }];
}
- (void) amazonSetup: (NSData *) newDeviceToken {
    AmazonCredentials *credentials = [[AmazonCredentials alloc] initWithAccessKey:@"AccessKey"  withSecretKey:@"SecretKey"];
    
    //Amazon needs to be registered in a dispatch queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        @try
        {
            //Amazon only accepts a String device token.
            const char* data = [newDeviceToken bytes];
            NSMutableString* tokenString = [NSMutableString string];
            for (int i = 0; i < [newDeviceToken length]; i++) {
                [tokenString appendFormat:@"%02.2hhX", data[i]];
            };

            //Registration for Amazon SNS
            AmazonSNSClient *snsClient = [[AmazonSNSClient alloc] initWithAccessKey:@"AccessKey" withSecretKey:@"SecretKey"];
            snsClient.endpoint = @"Endpoint";
            SNSCreatePlatformEndpointRequest *request = [[SNSCreatePlatformEndpointRequest alloc] init];
            [request setPlatformApplicationArn:@"AmazonARN"];
            [request setToken:tokenString];
            NSLog(@"%@", tokenString);
            [snsClient createPlatformEndpoint:request];
        }
        @catch (AmazonServiceException *serviceException) {
            NSLog(@"%@", serviceException);
        }
    });
}

//Callback after the app registers for push notifications
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [self parseSetup:newDeviceToken];
    [self azureSetup:newDeviceToken];
    [self amazonSetup:newDeviceToken];
    [[UAPush shared] registerDeviceToken:newDeviceToken];
}

//push recieved
- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [PFPush handlePush: userInfo];
    
    //Sample code showing how to utilize extra payload information.
    NSDictionary *aps = (NSDictionary *)[userInfo objectForKey:@"aps"];
    if ([aps objectForKey:@"alert"]){
        if(![[aps objectForKey: @"alert"] isEqualToString:@""]){
            //Normal push notification since message is not null
            NSLog(@"Regular Push recieved: %@", [aps objectForKey:@"alert"]);
        
            //Sample code to load a webpage if web payload information included
            if([userInfo objectForKey:@"web"]){
                NSString *urlString = [userInfo objectForKey:@"web"];
                
                //Create a URL object.
                NSURL *url = [NSURL URLWithString:urlString];
                
                //URL Requst Object
                NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
                
                //Load the request in the UIWebView.
                UIWebView *web = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
                [self.window.rootViewController.view addSubview:web];
                [web loadRequest:requestObj];
                //Remove webview after 5 seconds
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                     [web removeFromSuperview];
                });
            }
        }
        else{
            //Message is null. Background notification received. Here we could play with fetching data based on payload info
            NSLog(@"Background notification recieved");
        }
    }
    
    if ([userInfo objectForKey:@"extra"])
    {
        NSLog(@"Extra: %@", [userInfo objectForKey:@"extra"]);
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

//If push is recieved in app
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //Shows push if receieved while in app
    [PFPush handlePush:userInfo];
}

@end
