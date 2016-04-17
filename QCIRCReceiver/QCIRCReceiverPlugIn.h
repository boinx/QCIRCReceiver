//
//  QCIRCReceiverPlugIn.h
//  QCIRCReceiver
//
//  Created by Peter Kraml on 17.04.16.
//  Copyright © 2016 MacPietsApps.net. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface QCIRCReceiverPlugIn : QCPlugIn

@property (copy) NSString *inputServer;
@property NSUInteger inputPort;
@property (copy) NSString *inputNickname;
@property (copy) NSString *inputPassword;
@property (copy) NSString *inputChannel;

@property (copy) NSString *outputMessageText;
@property (copy) NSString *outputNickname;
@property BOOL outputNewMessage;
@property BOOL outputConnected;

@end
