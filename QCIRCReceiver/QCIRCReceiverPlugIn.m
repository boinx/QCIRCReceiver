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

#define	kQCIRCPlugIn_Name				@"IRC Receiver"
#define	kQCIRCPlugIn_Description		@"Receives chat messages from an IRC server"
#define kQCIRCPlugIn_MessageSize		100

@interface QCIRCReceiverPlugIn ()

@property (atomic, strong) IRCConnection *connection;
@property (atomic, strong) NSMutableArray *messages;

@property (atomic, assign) NSUInteger oldPort;
@property (atomic, strong) NSString *oldServer;
@property (atomic, strong) NSString *oldNickname;
@property (atomic, strong) NSString *oldChannel;
@property (atomic, strong) NSString *oldPassword;

@end

@implementation QCIRCReceiverPlugIn

@dynamic inputServer, inputPort, inputNickname, inputPassword, inputChannel, inputReconnect;
@dynamic outputMessages, outputConnected, outputConnectionState, outputConnectionError;

+ (NSDictionary *)attributes
{
    return @{QCPlugInAttributeNameKey: kQCIRCPlugIn_Name,
			 QCPlugInAttributeDescriptionKey: kQCIRCPlugIn_Description};
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	if ([key isEqualToString:@"inputServer"])
	{
		return @{QCPortAttributeNameKey: @"Server",
				 QCPortAttributeDefaultValueKey: @""};
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
				 QCPortAttributeDefaultValueKey: @""};
	}
	else if ([key isEqualToString:@"inputReconnect"])
	{
		return @{QCPortAttributeNameKey: @"Reconnect",
				 QCPortAttributeDefaultValueKey: @(NO)};
	}
	else if ([key isEqualToString:@"outputMessages"])
	{
		return @{QCPortAttributeNameKey: @"Messages"};
	}
	else if ([key isEqualToString:@"outputConnected"])
	{
		return @{QCPortAttributeNameKey: @"Connected"};
	}
	else if ([key isEqualToString:@"outputConnectionState"])
	{
		return @{QCPortAttributeNameKey: @"Connection State"};
	}
	else if ([key isEqualToString:@"outputConnectionError"])
	{
		return @{QCPortAttributeNameKey: @"Connection Error"};
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
	[self connect];
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	//If the input values have changed, disconnect and reconnect
	if (self.oldPort != self.inputPort ||
		![self.oldServer isEqualToString:self.inputServer] ||
		![self.oldNickname isEqualToString:self.inputNickname] ||
		![self.oldChannel isEqualToString:self.inputChannel] ||
		![self.oldPassword isEqualToString:self.inputPassword] ||
		self.inputReconnect)
	{
		[self disconnect];
		[self connect];
	}

	self.outputConnected = self.connection && self.connection.connected;
	
	if (self.messages)
	{
		self.outputMessages = [NSArray arrayWithArray:self.messages];
	}
	else
	{
		self.outputMessages = @[];
	}
	
	if(self.connection)
	{
		self.outputConnectionState = self.connection.connectionState;
		self.outputConnectionError = self.connection.connectionError;
	}

	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context
{
	[self disconnect];
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
	[self disconnect];
}


#pragma mark - IRC handling

- (void)connect
{
	if (self.inputPort > 0 &&
		![self.inputServer isEqualToString:@""] &&
		![self.inputNickname isEqualToString:@""] &&
		![self.inputChannel isEqualToString:@""])
	{
		NSString *password = nil;
		
		if (![self.inputPassword isEqualToString:@""])
		{
			password = self.inputPassword;
		}
		
		self.messages = [NSMutableArray array];
		
		IRCConnection *connection = [[IRCConnection alloc] initWithServer:self.inputServer port:self.inputPort serverPassword:password];
		connection.nickname = self.inputNickname;
		
		connection.messageCallback = ^void(IRCMessage * _Nonnull message) {
			//Append message to array
			NSTimeInterval timestamp = [NSDate.date timeIntervalSince1970];
			NSString *channel = [message channelFromArguments];
			if (!channel)
			{
				channel = @"";
			}
			
			[self.messages addObject:@{@"nickname": message.senderNickname, @"message": message.message, @"timestamp": @(timestamp), @"channel": channel}];
			
			if (self.messages.count > kQCIRCPlugIn_MessageSize)
			{
				[self.messages removeObjectAtIndex:0];
			}
		};

		[connection joinChannel:self.inputChannel];

		self.connection = connection;
		self.oldPort = self.inputPort;
		self.oldServer = self.inputServer;
		self.oldNickname = self.inputNickname;
		self.oldChannel = self.inputChannel;
		self.oldPassword = self.inputPassword;
	}
}

- (void)disconnect
{
	self.connection = nil;
	self.outputConnected = NO;
	self.messages = [NSMutableArray array];
}

@end
