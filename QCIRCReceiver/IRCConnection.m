//
//  IRCConnection.m
//  IRCReceiver
//
//  Created by Peter Kraml on 17.04.16.
//  Copyright © 2016 MacPietsApps.net. All rights reserved.
//

#import "IRCConnection.h"

#import "IRCAsyncSocket.h"
#import "IRCMessage.h"

@interface IRCConnection () <IRCAsyncSocketDelegate>

@property (nonatomic, strong) IRCAsyncSocket *socket;
@property (nonatomic, strong) NSMutableArray *messageQueue;

@property (nonatomic, assign) IRCConnectionState connectionState;
@property (atomic, strong) NSString * _Nullable connectionError;

@end

@implementation IRCConnection

- (instancetype _Nonnull)initWithServer:(NSString * _Nonnull)server port:(NSInteger)port serverPassword:(NSString * _Nullable)password
{
	self = [super init];
	if (self)
	{
		self.messageQueue = [NSMutableArray array];
		
		self.connectionState = IRCConnectionStateDisconnected;

		IRCAsyncSocket *socket = [[IRCAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
		
		NSError *error = nil;
		[socket connectToHost:server onPort:port error:&error];
		if (error)
		{
			self.connectionState = IRCConnectionStateConnectionError;
			self.connectionError = error.localizedDescription;
			
			NSLog(@"Error while connecting to server: %@", error);
		}
		else
		{
			self.connectionState = IRCConnectionStateConnecting;

			self.socket = socket;
		
			if (password)
			{
				IRCMessage *passMessage = [IRCMessage passMessage:password];
				[self _addMessageToQueue:passMessage];
			}
		}
	}
	
	return self;
}

- (void)dealloc
{
	if (self.socket)
	{
		self.socket.delegate = nil;
		[self.socket disconnect];
		self.socket = nil;
	}
}

- (void)joinChannel:(NSString * _Nonnull)channel
{
	IRCMessage *joinMessage = [IRCMessage joinMessage:channel];
	[self _addMessageToQueue:joinMessage];
}

- (void)setNickname:(NSString *)nickname
{
	IRCMessage *nickMessage = [IRCMessage nickMessage:nickname];
	[self _addMessageToQueue:nickMessage];
}

- (BOOL)connected
{
	return self.socket && self.socket.isConnected;
}


#pragma mark - IRCAsyncSocketDelegate

- (void)socket:(IRCAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	self.connectionState = IRCConnectionStateConnected;

	[self _workMessageQueue];
	[sock readDataToData:IRCAsyncSocket.CRLFData withTimeout:-1 tag:0];
}

- (void)socket:(IRCAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	self.connectionState = IRCConnectionStateReceivingData;

	//Parse message
	IRCMessage *message = [[IRCMessage alloc] initWithData:data];
	
	if ([message.command isEqualToString:IRCMessageCommandPING])
	{
		IRCMessage *pongMessage = [IRCMessage pongMessage:message];
		[self _addMessageToQueue:pongMessage];
	}
	else if ([message.command isEqualToString:IRCMessageCommandPRIVMSG])
	{
		if (self.messageCallback)
		{
			self.messageCallback(message);
		}
	}
	
	[sock readDataToData:IRCAsyncSocket.CRLFData withTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(IRCAsyncSocket *)sock withError:(NSError *)err
{
	if(err)
	{
		self.connectionState = IRCConnectionStateConnectionError;
		self.connectionError = err.localizedDescription;
	}
	else
	{
		self.connectionState = IRCConnectionStateDisconnected;
	}
	
	self.socket = nil;
	[self.messageQueue removeAllObjects];
}


#pragma mark - Private Methods
- (void)_addMessageToQueue:(IRCMessage *)message
{
	[self.messageQueue addObject:message];
	
	[self _workMessageQueue];
}

- (void)_workMessageQueue
{
	if (!self.connected)
	{
		return;
	}
	
	IRCAsyncSocket *socket = self.socket;
	for (IRCMessage *message in self.messageQueue)
	{
		[socket writeData:message.dataRepresentation withTimeout:-1 tag:0];
	}
}


@end
