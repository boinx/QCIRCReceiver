//
//  IRCMessage.m
//  IRCReceiver
//
//  Created by Peter Kraml on 17.04.16.
//  Copyright © 2016 MacPietsApps.net. All rights reserved.
//

#import "IRCMessage.h"

//Command constants
NSString * const IRCMessageCommandPASS = @"PASS";
NSString * const IRCMessageCommandNICK = @"NICK";
NSString * const IRCMessageCommandPING = @"PING";
NSString * const IRCMessageCommandPONG = @"PONG";
NSString * const IRCMessageCommandJOIN = @"JOIN";
NSString * const IRCMessageCommandPRIVMSG = @"PRIVMSG";

@implementation IRCMessage

+ (instancetype)passMessage:(NSString *)password
{
	IRCMessage *message = [IRCMessage new];
	message.command = IRCMessageCommandPASS;
	message.arguments = @[password];
	
	return message;
}

+ (instancetype)nickMessage:(NSString *)nick
{
	IRCMessage *message = [IRCMessage new];
	message.command = IRCMessageCommandNICK;
	message.arguments = @[nick];
	
	return message;
}

+ (instancetype)pongMessage:(IRCMessage *)pingMessage
{
	IRCMessage *message = [IRCMessage new];
	message.command = IRCMessageCommandPONG;
	message.message = pingMessage.message;
	
	return message;
}

+ (instancetype)joinMessage:(NSString *)channel
{
	IRCMessage *message = [IRCMessage new];
	message.command = IRCMessageCommandJOIN;
	message.arguments = @[channel];
	
	return message;
}

- (instancetype)initWithData:(NSData *)data
{
	self = [super init];
	if (self)
	{
		NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		NSArray *parts = [message componentsSeparatedByString:@" "];
		NSInteger currentIndex = 0;
		
		//Prefix (and Nickname)
		if ([message hasPrefix:@":"])
		{
			//If the message starts with a colon we have a prefix from the server
			NSString *prefix = parts[currentIndex];
			self.prefix = prefix;
			currentIndex++;
			
			NSArray *prefixParts = [prefix componentsSeparatedByString:@"!"];
			if (prefixParts.count > 1)
			{
				self.senderNickname = [prefixParts.firstObject substringFromIndex:1];
			}
		}
		
		//Command
		if (currentIndex < parts.count)
		{
			self.command = parts[currentIndex];
			currentIndex++;
		}
		
		//Arguments + Message
		if (currentIndex < parts.count)
		{
			NSMutableArray *arguments = [NSMutableArray array];
			
			while (currentIndex < parts.count)
			{
				NSString *part = parts[currentIndex];
				
				if ([part hasPrefix:@":"])
				{
					//Everything beyond this point is the message
					NSArray *messageParts = [parts subarrayWithRange:NSMakeRange(currentIndex, parts.count - currentIndex)];
					NSString *message = [messageParts componentsJoinedByString:@" "];
					
					message = [message substringFromIndex:1];
					self.message = [message stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
					break;
				}
				else
				{
					[arguments addObject:part];
					currentIndex++;
				}
			}
			
			self.arguments = [NSArray arrayWithArray:arguments];
		}
	}
	
	return self;
}

- (NSString *)channelFromArguments
{
	for (NSString *argument in self.arguments)
	{
		if ([argument hasPrefix:@"#"])
		{
			return argument;
		}
	}
	
	return nil;
}

- (NSData *)dataRepresentation
{
	NSMutableString *message = [NSMutableString string];
	
	if (self.prefix)
	{
		[message appendFormat:@":%@ ", self.prefix];
	}
	
	if (self.command)
	{
		[message appendFormat:@"%@ ", self.command];
	}
	
	for (NSString *argument in self.arguments)
	{
		[message appendFormat:@"%@ ", argument];
	}
	
	if (self.message)
	{
		[message appendFormat:@":%@", message];
	}
	
	[message appendString:@"\r\n"];
	
	return [message dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)description
{
	NSData *data = [self dataRepresentation];
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
