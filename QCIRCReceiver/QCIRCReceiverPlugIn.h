//
//  QCIRCReceiverPlugIn.h
//  QCIRCReceiver
//
//  Created by Peter Kraml on 17.04.16.
//  Copyright © 2016 MacPietsApps.net. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface QCIRCReceiverPlugIn : QCPlugIn

//Inputs
@property NSUInteger inputPort;
@property (copy) NSString *inputServer;
@property (copy) NSString *inputNickname;
@property (copy) NSString *inputPassword;
@property (copy) NSString *inputChannel;

//Outputs
@property (copy) NSArray *outputMessages;
@property BOOL outputConnected;

@end
