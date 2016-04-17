//
//  QCIRCReceiverPlugIn.m
//  QCIRCReceiver
//
//  Created by Peter Kraml on 17.04.16.
//  Copyright © 2016 MacPietsApps.net. All rights reserved.
//


#import "QCIRCReceiverPlugIn.h"

#import "IRCConnection.h"
#import "IRCMessage.h"

#define	kQCPlugIn_Name				@"IRC Receiver"
#define	kQCPlugIn_Description		@"Pushes new messages from an IRC Channel out"

@interface QCIRCReceiverPlugIn ()

@property (nonatomic, strong) IRCConnection *connection;
@property (nonatomic, strong) NSDictionary *nextMessage;

@property (nonatomic, assign) NSUInteger oldPort;
@property (nonatomic, strong) NSString *oldServer;
@property (nonatomic, strong) NSString *oldNickname;
@property (nonatomic, strong) NSString *oldChannel;
@property (nonatomic, strong) NSString *oldPassword;

@end

@implementation QCIRCReceiverPlugIn

@dynamic inputServer, inputPort, inputNickname, inputPassword, inputChannel;
@dynamic outputNewMessage, outputMessageText, outputNickname, outputConnected;

+ (NSDictionary *)attributes
{
    return @{QCPlugInAttributeNameKey:kQCPlugIn_Name, QCPlugInAttributeDescriptionKey:kQCPlugIn_Description};
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	if ([key isEqualToString:@"inputServer"])
	{
		return @{QCPortAttributeNameKey: @"Server",
				 QCPortAttributeDefaultValueKey: @"irc.chat.twitch.tv"};
	}
	else if ([key isEqualToString:@"inputPort"])
	{
		return @{QCPortAttributeNameKey: @"Port",
				 QCPortAttributeDefaultValueKey: @(6667)};
	}
	else if ([key isEqualToString:@"inputNickname"])
	{
		return @{QCPortAttributeNameKey: @"Nickname",
				 QCPortAttributeDefaultValueKey: @""};
	}
	else if ([key isEqualToString:@"inputPassword"])
	{
		return @{QCPortAttributeNameKey: @"Server Password",
				 QCPortAttributeDefaultValueKey: @""};
	}
	else if ([key isEqualToString:@"inputChannel"])
	{
		return @{QCPortAttributeNameKey: @"IRC Channel",
				 QCPortAttributeDefaultValueKey: @"#macpiets"};
	}
	else if ([key isEqualToString:@"outputNewMessage"])
	{
		return @{QCPortAttributeNameKey: @"New Message Signal"};
	}
	else if ([key isEqualToString:@"outputMessageText"])
	{
		return @{QCPortAttributeNameKey: @"Message Text"};
	}
	else if ([key isEqualToString:@"outputNickname"])
	{
		return @{QCPortAttributeNameKey: @"IRC Nickname"};
	}
	else if ([key isEqualToString:@"outputConnected"])
	{
		return @{QCPortAttributeNameKey: @"Connected"};
	}
	
	return nil;
}

+ (QCPlugInExecutionMode)executionMode
{
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode
{
	return kQCPlugInTimeModeIdle;
}

@end

@implementation QCIRCReceiverPlugIn (Execution)

- (BOOL)startExecution:(id <QCPlugInContext>)context
{
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	if (self.oldPort != self.inputPort || ![self.oldServer isEqualToString:self.inputServer] || ![self.oldNickname isEqualToString:self.inputNickname] || ![self.oldChannel isEqualToString:self.inputChannel] || ![self.oldPassword isEqualToString:self.inputPassword] || !self.connection.connected)
	{
		self.connection = nil;
	}
	
	if (!self.connection && self.inputPort > 0 && ![self.inputServer isEqualToString:@""] && ![self.inputNickname isEqualToString:@""] && ![self.inputChannel isEqualToString:@""])
	{
		NSString *password = nil;
		
		if (![self.inputPassword isEqualToString:@""])
		{
			password = self.inputPassword;
		}
		
		IRCConnection *connection = [[IRCConnection alloc] initWithServer:self.inputServer port:self.inputPort serverPassword:password];
		connection.nickname = self.inputNickname;
		[connection joinChannel:self.inputChannel];
		connection.messageCallback = ^void(IRCMessage * _Nonnull message) {
			self.nextMessage = @{@"nick": message.senderNickname, @"message": message.message};
		};
		self.connection = connection;
		
		self.oldPort = self.inputPort;
		self.oldServer = self.inputServer;
		self.oldNickname = self.inputNickname;
		self.oldChannel = self.inputChannel;
		self.oldPassword = self.inputPassword;
	}
	
	self.outputNewMessage = NO;
	self.outputConnected = self.connection && self.connection.connected;
	
	if (self.nextMessage)
	{
		self.outputNewMessage = YES;
		self.outputMessageText = self.nextMessage[@"message"];
		self.outputNickname = self.nextMessage[@"nick"];
		
		self.nextMessage = nil;
	}
	
	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context
{
	self.connection = nil;
	self.outputConnected = NO;
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
	self.connection = nil;
	self.outputConnected = NO;
}

@end
