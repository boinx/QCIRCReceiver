//
//  IRCMessage.h
//  IRCReceiver
//
//  Created by Peter Kraml on 17.04.16.
//  Copyright © 2016 MacPietsApps.net. All rights reserved.
//

#import <Foundation/Foundation.h>

///Command Constants
extern NSString * _Nonnull const IRCMessageCommandPASS;
extern NSString * _Nonnull const IRCMessageCommandNICK;
extern NSString * _Nonnull const IRCMessageCommandPING;
extern NSString * _Nonnull const IRCMessageCommandPONG;
extern NSString * _Nonnull const IRCMessageCommandJOIN;
extern NSString * _Nonnull const IRCMessageCommandPRIVMSG;


@interface IRCMessage : NSObject

///Convenience method to generate a password message
+ (instancetype _Nonnull)passMessage:(NSString * _Nonnull)password;

///Convenience method to generate a nickname message
+ (instancetype _Nonnull)nickMessage:(NSString * _Nonnull)nick;

///Convenience method to generate a pong reply to a ping request
+ (instancetype _Nonnull)pongMessage:(IRCMessage * _Nonnull)pingMessage;

//Convenience method to generate a join message to join a channel
+ (instancetype _Nonnull)joinMessage:(NSString * _Nonnull)channel;


/*!
 * @brief Use initWithData to parse incomming messages. The properties will be filled out automatically
 *
 * @param data	The incomming data from the server
 */
- (instancetype _Nonnull)initWithData:(NSData * _Nonnull)data;

///Prefix of the message (only if the message starts with a colon)
@property (nonatomic, strong) NSString * _Nullable prefix;

///Parsed nickname of the sender (only valid if sender is not a server and message contains a prefix)
@property (nonatomic, strong) NSString * _Nullable senderNickname;


///Command of the message (e. g. PRIVMSG)
@property (nonatomic, strong) NSString * _Nullable command;

///All the arguments of the message (split by whitespace)
@property (nonatomic, strong) NSArray * _Nullable arguments;

///Message content of the message (e. g. the users message to a Channel)
@property (nonatomic, strong) NSString * _Nullable message;


/*!
 * @brief Returns a channel if contained in the arguments (e. g. #test), nil otherwise)
 */
- (NSString * _Nullable)channelFromArguments;


/*!
 * @brief Data representation of the Message, used for sending the message to a server
 */
- (NSData * _Nullable)dataRepresentation;

@end
