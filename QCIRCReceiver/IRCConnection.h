//
//  IRCConnection.h
//  IRCReceiver
//
//  Created by Peter Kraml on 17.04.16.
//  Copyright © 2016 MacPietsApps.net. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, IRCConnectionState) {
	IRCConnectionStateDisconnected = 0,
	IRCConnectionStateConnecting = 1,
	IRCConnectionStateConnected = 2,
	IRCConnectionStateReceivingData = 3,
	IRCConnectionStateConnectionError = 99,
	
};

@class IRCMessage;

@interface IRCConnection : NSObject

/*!
 * @brief An IRCConnectionMessageCallback will be called whenever a message is received.
 *
 * @param message	parsed IRCMessage, usefull info is channel, nickname and message contents
 */
typedef void (^IRCConnectionMessageCallback)(IRCMessage * _Nonnull message);

/*!
 * @brief Initialises a connection to a server and starts the communication process
 *
 * @param server	the server hostname or IP address to connect to
 * @param port		which port to connect to (usually this is 6667 for non-SSL IRC)
 * @param password	specify the password you want to use for the connection, can be nil
 */
- (instancetype _Nonnull)initWithServer:(NSString * _Nonnull)server port:(NSInteger)port serverPassword:(NSString * _Nullable)password;

/*!
 * @brief Join a Channel on the IRC server
 * @discussion you can call this method immediately after initialization as command to the server will be queued up until the server is ready.
 *
 * @param channel	The channel to join
 */
- (void)joinChannel:(NSString * _Nonnull)channel;


/*!
 * @brief The nick name to use on the server
 * @discussion This method should get called immediately after initializing the connection and before joining a channel
 */
@property (nonatomic, strong, readwrite) NSString * _Nonnull nickname;

/*!
 * @brief The connection state, will be true if there is an active connection with the server
 */
@property (nonatomic, assign, readonly) BOOL connected;


/*!
 * @brief The messageCallback will be called with new incomming messages, see above typedef for more information
 */
@property (nonatomic, copy) IRCConnectionMessageCallback _Nullable messageCallback;

/*!
 * @brief Stores the current connection state
 */
@property (nonatomic, assign, readonly) IRCConnectionState connectionState;

/*!
 * @brief Stores the last connection error
 */
@property (atomic, strong, readonly) NSString * _Nullable connectionError;

@end
