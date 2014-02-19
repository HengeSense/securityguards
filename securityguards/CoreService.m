//
//  CoreService.m
//  SmartHome
//
//  Created by Zhao yang on 8/29/13.
//  Copyright (c) 2013 hentre. All rights reserved.
//

#import "Shared.h"
#import "CoreService.h"
#import "UnitManager.h"
#import "NetworkModeChangedEvent.h"
#import "XXEventSubscriptionPublisher.h"
#import "DeviceCommandEvent.h"
#import "CurrentUnitChangedEvent.h"
#import "XXEventNameFilter.h"

/*  Command Handler  */
#import "DeviceCommandGetUnitsHandler.h"
#import "DeviceCommandGetAccountHandler.h"
#import "DeviceCommandGetNotificationsHandler.h"
#import "DeviceCommandUpdateDevicesHandler.h"
#import "DeviceCommandUpdateUnitNameHandler.h"
#import "DeviceCommandGetSensorsHandler.h"
#import "AlertView.h"

#define NETWORK_CHECK_INTERVAL 5
#define UNIT_REFRESH_INTERVAL  10
#define HEART_BEAT_TIMEOUT     1.f

static dispatch_queue_t networkModeCheckTaskQueue() {
    static dispatch_queue_t serialQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create("com.hentre.familyguards.coreservice.network", DISPATCH_QUEUE_SERIAL);
    });
    return serialQueue;
}

@implementation CoreService {
    NSTimer *tcpSocketConnectionCheckTimer;
    NSTimer *refreshTaskTimer;
    
    /* This array defined which commands can executed in internal net mode */
    NSArray *mayUsingInternalNetModeCommands;
    
    /* This array defined which commands execute using restful executor in any net modes */
    NSArray *usingRestfulForAnyNetModeCommands;
    
    CLLocationManager *locationManager;
    
    /*
     * no            0
     * wifi net      1
     * wifi no net   2
     * 3g            3
     */
    NSUInteger flag;
    Reachability *reachability;
    
    NSObject *netModeLockObject;
}

@synthesize tcpService;
@synthesize restfulService;

@synthesize state = _state_;
@synthesize netMode = _netMode_;
@synthesize needRefreshUnit = _needRefreshUnit_;

- (NSThread *)coreServiceThread {
    static NSThread *_coreServiceThread_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _coreServiceThread_ = [[NSThread alloc] initWithTarget:self selector:@selector(coreServiceThreadEntryPoint) object:nil];
        [_coreServiceThread_ start];
    });
    return _coreServiceThread_;
}

- (void)coreServiceThreadEntryPoint {
    [[NSThread currentThread] setName:@"CoreServiceThread"];

    // Start a network checker timer
    // Every 5 seconds to check the tcp is or not connectted
    // If it was closed, then should open it again.
    tcpSocketConnectionCheckTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:NETWORK_CHECK_INTERVAL target:self selector:@selector(checkTcp) userInfo:nil repeats:YES];
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), (__bridge CFRunLoopTimerRef)tcpSocketConnectionCheckTimer, kCFRunLoopDefaultMode);
    
    // Start a task refresh timer
    refreshTaskTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:UNIT_REFRESH_INTERVAL target:self selector:@selector(doTimerTask) userInfo:nil repeats:YES];
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), (__bridge CFRunLoopTimerRef)refreshTaskTimer, kCFRunLoopDefaultMode);
    
    CFRunLoopRun();
    
#ifdef DEBUG
    NSLog(@"Core Service RunLoop Stopped. [You will never see this message]");
#endif
}

#pragma mark -
#pragma mark Initializations

+ (instancetype)defaultService {
    static CoreService *service = nil;
    static dispatch_once_t serviceOnceToken;
    dispatch_once(&serviceOnceToken, ^{
        service = [[[self class] alloc] init];
    });
    return service;
}

- (id)init {
    self = [super init];
    if(self) {
        [self initDefaults];
    }
    return self;
}

/* default property set */
- (void)initDefaults {
    netModeLockObject = [[NSObject alloc] init];
    
    _state_ = ServiceStateClosed;
    _netMode_ = NetModeNone;
    
    _needRefreshUnit_ = YES;
    
    mayUsingInternalNetModeCommands = [NSArray arrayWithObjects:COMMAND_KEY_CONTROL, COMMAND_GET_CAMERA_SERVER, nil];
    usingRestfulForAnyNetModeCommands = [NSArray arrayWithObjects:COMMAND_GET_SENSORS, nil];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    /* Network monitor */
    reachability = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    [self startMonitorNetworks];
}

#pragma mark -
#pragma mark Execute device command

/*
 *
 * Execute device command
 *.
 * NO Network Environment  ---> RETURN
 * 3G                      ---> TCP CONNECTION
 * WIFI  WITH UNIT         ---> RESTFUL SERVICE
 * WIFI  WITH NO UNIT      ---> TCP CONNECTION
 *
 */
- (void)executeDeviceCommand:(DeviceCommand *)command {
    if(command == nil) return;
    if([self coreServiceThread] == [NSThread currentThread]) {
        [self executeDeviceCommandInternal:command];
    } else {
        @synchronized(self) {
            [self performSelector:@selector(executeDeviceCommandInternal:) onThread:[self coreServiceThread] withObject:command waitUntilDone:NO];
        }
    }
}

- (void)executeDeviceCommandInternal:(DeviceCommand *)command {
    
    if(_state_ != ServiceStateOpenned) {
#ifdef DEBUG
        NSLog(@"[Core Service] Service is not ready, [%@] can't be executed.", command.commandName);
#endif
        return;
    }
    
    /* Find the best command executor for device command */
    id<CommandExecutor> executor = [self determineCommandExcutor:command];
    if(executor != nil) {
#ifdef DEBUG
        if(![COMMAND_SEND_HEART_BEAT isEqualToString:command.commandName]) {
            NSLog(@"[Core Service] Execute [%@] From [%@]", command.commandName, [executor executorName]);
        }
#endif
        [executor executeCommand:command];
    } else {
#ifdef DEBUG
        NSLog(@"[Core Service] Executor not found, [%@] can't be executed.", command.commandName);
#endif
    }
}

- (void)queueCommand:(DeviceCommand *)command {
#ifdef DEBUG
    NSLog(@"[Core Service] Queue command [%@].", command.commandName);
#endif
    [self.tcpService queueCommand:command];
}

- (id<CommandExecutor>)determineCommandExcutor:(DeviceCommand *)command {
    /*
     * If the device command has explicit specify the network mode
     * that of course we know which executor should to be used
     */
    if(CommandNetworkModeInternal == command.commandNetworkMode
       || CommandNetworkModeExternalViaRestful == command.commandNetworkMode) {
        return self.restfulService;
    } else if(CommandNetworkModeExternalViaTcpSocket == command.commandNetworkMode) {
        return self.tcpService;
    }
    
    /*
     * At first , check the command wether has been defined in 
     * Internal network commands list
     */
    if([self commandCanDeliveryInInternalNetMode:command]) {
        // and also the current net mode is NetModeInternal
        if((self.netMode & NetModeInternal) == NetModeInternal) {
            command.commandNetworkMode = CommandNetworkModeInternal;
            return self.restfulService;
        }
    }
    
    // Not in internal commands list or current net mode isn't Internal
    // And command is restful command what ever
    if([self isRestfulCommandInAnyNetModes:command]) {
        command.commandNetworkMode = CommandNetworkModeExternalViaRestful;
        return self.restfulService;
    }
    
    if((self.netMode & NetModeExtranet) == NetModeExtranet) {
        command.commandNetworkMode = CommandNetworkModeExternalViaTcpSocket;
        return self.tcpService;
    }
    
    return nil;
}

- (BOOL)commandCanDeliveryInInternalNetMode:(DeviceCommand *)command {
    if(mayUsingInternalNetModeCommands == nil) return NO;
    /* 
     * This is a special command
     * Get all units only execute from tcp (both master device code and unit server url is blank)
     * Get one unit can execute in rest or tcp
     */
    if([COMMAND_GET_UNITS isEqualToString:command.commandName]) {
        if([XXStringUtils isBlank:command.masterDeviceCode]) {
            DeviceCommandGetUnit *cmd = (DeviceCommandGetUnit *)command;
            return ![XXStringUtils isBlank:cmd.unitServerUrl];
        } else {
            return YES;
        }
    }
    
    for(int i=0; i<mayUsingInternalNetModeCommands.count; i++) {
        NSString *cmdName = [mayUsingInternalNetModeCommands objectAtIndex:i];
        if([cmdName isEqualToString:command.commandName]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isRestfulCommandInAnyNetModes:(DeviceCommand *)command {
    if(usingRestfulForAnyNetModeCommands == nil) return NO;
    
    for(int i=0; i<usingRestfulForAnyNetModeCommands.count; i++) {
        NSString *cmdName = [usingRestfulForAnyNetModeCommands objectAtIndex:i];
        if([cmdName isEqualToString:command.commandName]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark -
#pragma mark Handle device command

- (void)handleDeviceCommand:(DeviceCommand *)command {
    if(command == nil) return;
    
#ifdef DEBUG
    NSString *networkModeString = [XXStringUtils emptyString];
    if(command.commandNetworkMode == CommandNetworkModeExternalViaRestful
        || command.commandNetworkMode == CommandNetworkModeExternalViaTcpSocket) {
        networkModeString = @"External";
    } else if(command.commandNetworkMode == CommandNetworkModeInternal) {
        networkModeString = @"Internal";
    }
    NSLog(@"[Core Service] Received [%@] From [%@]", command.commandName, networkModeString);
#endif
    
    // Security key is invalid or expired
    if(command.resultID == -3000 || command.resultID == -2000 || command.resultID == -1000) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[Shared shared].app logout];
            return;
        });
    }
    
    // If the resutID of command is equal -100
    // that the command should be ignore,
    // our client will never process this command.
    if(command.resultID == -100) return;
    
    // If the service is not served
    if(_state_ != ServiceStateOpenned) {
#ifdef DEBUG
        NSLog(@"[Core Service] Service is't opened, can't handle [%@].", command.commandName);
#endif
        return;
    }
    
    DeviceCommandHandler *handler = nil;
    
    if([COMMAND_GET_UNITS isEqualToString:command.commandName]) {
        handler = [[DeviceCommandGetUnitsHandler alloc] init];
    } else if([COMMAND_GET_SENSORS isEqualToString:command.commandName]) {
        handler = [[DeviceCommandGetSensorsHandler alloc] init];
    } else if([COMMAND_PUSH_DEVICE_STATUS isEqualToString:command.commandName]) {
        handler = [[DeviceCommandUpdateDevicesHandler alloc] init];
    } else if([COMMAND_GET_ACCOUNT isEqualToString:command.commandName]) {
        handler = [[DeviceCommandGetAccountHandler alloc] init];
    } else if([COMMAND_PUSH_NOTIFICATIONS isEqualToString:command.commandName] || [COMMAND_GET_NOTIFICATIONS isEqualToString:command.commandName]) {
        handler = [[DeviceCommandGetNotificationsHandler alloc] init];
    } else if([COMMAND_CHANGE_UNIT_NAME isEqualToString:command.commandName]) {
        handler = [[DeviceCommandUpdateUnitNameHandler alloc] init];
    }
    
    if(handler != nil) {
        [handler handle:command];
    }
}

#pragma mark -
#pragma mark Event Subscriber

- (void)xxEventPublisherNotifyWithEvent:(XXEvent *)event {
    if([event isKindOfClass:[DeviceCommandEvent class]]) {
        DeviceCommandEvent *commandReceivedEvent = (DeviceCommandEvent *)event;
        [self handleDeviceCommand:commandReceivedEvent.command];
    } else if([event isKindOfClass:[CurrentUnitChangedEvent class]]) {
        CurrentUnitChangedEvent *unitChangedEvent = (CurrentUnitChangedEvent *)event;
#ifdef DEBUG
        NSString *triggerSource = [XXStringUtils emptyString];
        if(unitChangedEvent.triggeredSource == TriggeredByGetUnitsCommand) {
            triggerSource = @"Device Command";
        } else if(unitChangedEvent.triggeredSource == TriggeredByManual) {
            triggerSource = @"User Manual";
        } else if(unitChangedEvent.triggeredSource == TriggeredByReadDisk) {
            triggerSource = @"Read Disk";
        }
        NSLog(@"[Core Service] Current Unit Changed to [%@] triggerd by [%@]", unitChangedEvent.unitIdentifier, triggerSource);
#endif
        if(![XXStringUtils isBlank:unitChangedEvent.unitIdentifier]) {
            [self fireTaskTimer];
           
            DeviceCommand *getSensorsCommand = [CommandFactory commandForType:CommandTypeGetSensors];
            getSensorsCommand.masterDeviceCode = unitChangedEvent.unitIdentifier;
            [self executeDeviceCommand:getSensorsCommand];
        }
    }
}

- (NSString *)xxEventSubscriberIdentifier {
    return @"deviceCommandDeliveryServiceSubscriber";
}

#pragma mark -
#pragma mark Open or Stop Core Service

- (void)startService {
    if([NSThread currentThread] == [self coreServiceThread]) {
        [self startServiceInternal];
    } else {
        [self performSelector:@selector(startServiceInternal) onThread:[self coreServiceThread] withObject:nil waitUntilDone:YES];
    }
}

- (void)startServiceInternal {
    if(_state_ != ServiceStateOpenned && _state_ != ServiceStateOpenning) {
#ifdef DEBUG
        NSLog(@"[Core Service] Service starting on [%@].", [NSThread currentThread].name);
#endif
        // openning service ...
        _state_ = ServiceStateOpenning;
        
        // subscribe events
        XXEventSubscription *subscription = [[XXEventSubscription alloc] initWithSubscriber:self eventFilter:[[XXEventNameFilter alloc] initWithSupportedEventNames:[NSArray arrayWithObjects:EventDeviceCommand, EventCurrentUnitChanged, nil]]];
        [[XXEventSubscriptionPublisher defaultPublisher] subscribeFor:subscription];
        
        // load all units from disk
        [[UnitManager defaultManager] loadUnitsFromDisk];
        
        // service was openned ...
        _state_ = ServiceStateOpenned;
        
#ifdef DEBUG
        NSLog(@"[Core Service] Service started on [%@]", [NSThread currentThread].name);
#endif
    }
}

- (void)stopService {
    /*
     * stop service should be executed in main thread, we think that is better
     */
    if([NSThread currentThread].isMainThread) {
        [self stopServiceInternal];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self stopServiceInternal];
        });
    }
}

- (void)stopServiceInternal {
    if(_state_ != ServiceStateClosed && _state_ != ServiceStateClosing) {
        _state_ = ServiceStateClosing;
#ifdef DEBUG
        NSLog(@"[Core Service] Service stopping on [%@].",
              [NSThread currentThread].isMainThread ? @"Main Thread" : [NSThread currentThread].name);
#endif
        
        [[XXEventSubscriptionPublisher defaultPublisher] unSubscribeForSubscriber:self];
        
        // Disconnect tcp connection
        [self.tcpService disconnect];
        
        // Synchronize memory units to disk
        [[UnitManager defaultManager] syncUnitsToDisk];
      
        _state_ = ServiceStateClosed;
        
        [locationManager stopUpdatingLocation];
#ifdef DEBUG
        NSLog(@"[Core Service] Service stopped on [%@].",
              [NSThread currentThread].isMainThread ? @"Main Thread" : [NSThread currentThread].name);
#endif
    }
}

#pragma mark -
#pragma mark TCP Connection checker

- (void)checkTcp {
    if(self.state != ServiceStateOpenned) {
#ifdef DEBUG
        NSLog(@"[Core Service] Check tcp can't be executed, because core service is not openned.");
#endif
        return;
    }
    [self startTcpIfNeed];
}

- (void)startTcpIfNeed {
    if(!self.tcpService.isConnecttingOrConnectted) {
        [self.tcpService connect];
    }
}

- (void)doTimerTask {
    if(self.state != ServiceStateOpenned) {
#ifdef DEBUG
        NSLog(@"[Core Service] Timer task can't be executed, because core service is not openned.");
#endif
        return;
    }
    
#ifdef DEBUG
    NSLog(@"[Core Service] Timer task On Thread [%@].", [NSThread currentThread].name);
#endif
    
    // Send heart beat command
    [self executeDeviceCommand:[CommandFactory commandForType:CommandTypeSendHeartBeat]];
    
    Unit *unit = [UnitManager defaultManager].currentUnit;
    if(unit != nil) {
        // This is a sync method, not checkInternalOrNotInternalNetwork (async method)
        // Here you must check net work sync, then continue execute command
        [self checkIsReachableInternalUnit];
        
        if(self.needRefreshUnit) {
            // if current network mode is internal , need refresh by rest api
            // otherwise update it's by server's push notification on tcp socket
            if((self.netMode & NetModeInternal) == NetModeInternal) {
                // Update current unit
                DeviceCommand *command = [CommandFactory commandForType:CommandTypeGetUnits];
                command.commandNetworkMode = CommandNetworkModeInternal;
                command.masterDeviceCode = unit.identifier;
                command.hashCode = unit.hashCode;
                [self executeDeviceCommand:command];
            }
        }
    }
}

- (void)fireTaskTimer {
    if(refreshTaskTimer != nil) {
        if([NSThread currentThread] == [self coreServiceThread]) {
            [self fireTaskTimerInternal];
        } else {
            [self performSelector:@selector(fireTaskTimerInternal) onThread:[self coreServiceThread] withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)fireTaskTimerInternal {
    [refreshTaskTimer fire];
}

#pragma mark -
#pragma mark Network monitor

- (void)startMonitorNetworks {
	// Here we set up a NSNotification observer. The Reachability that caused the notification
	// is passed in the object parameter
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    [reachability startNotifier];
}

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reach = notification.object;
    if(reach == nil) return;
    
    if(reach.isReachable) {
        if(reach.isReachableViaWiFi) {
            // WIFI &&   Network
            flag = 1;
        } else if(reach.isReachableViaWWAN) {
            // 3G   &&   Network
            flag = 3;
        } else {
            // ignore else
        }
    } else {
        if([Reachability reachabilityForLocalWiFi].currentReachabilityStatus != NotReachable) {
            // WIFI && No Network
            flag = 2;
        } else {
            // No (WIFI && 3G && 2G && Network)
            flag = 0;
        }
    }
    
    if(flag == 1 || flag == 2) {
        [self checkInternalOrNotInternalNetwork];
    } else {
        if(flag == 0) {
            self.netMode = NetModeNone;
        } else {
            if(self.tcpService.isConnectted) {
                [self addNetMode:NetModeExtranet];
            } else {
                [self removeNetMode:NetModeExtranet];
            }
        }
    }
}

- (void)checkInternalOrNotInternalNetwork {
    dispatch_async(networkModeCheckTaskQueue(), ^{
        [self checkIsReachableInternalUnit];
    });
}

- (void)checkIsReachableInternalUnit {
    if([UnitManager defaultManager].currentUnit == nil) return;
    if([Reachability reachabilityForLocalWiFi].currentReachabilityStatus == NotReachable) {
        // no wifi
        self.netMode = self.tcpService.isConnectted ? NetModeExtranet : NetModeNone;
        return;
    }
    
    // has wifi, check is reachbilityForInternal for current unit ?
    
    NSString *url = [NSString stringWithFormat:@"http://%@:%d/heartbeat",
                     [UnitManager defaultManager].currentUnit.localIP, [UnitManager defaultManager].currentUnit.localPort];
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:HEART_BEAT_TIMEOUT];
    NSURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(error == nil) {
        if(response) {
            NSHTTPURLResponse *rp = (NSHTTPURLResponse *)response;
            if(rp.statusCode == 200 && data != nil) {
                NSString *unitIdentifier = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                Unit *currentUnit = [UnitManager defaultManager].currentUnit;
                if(currentUnit != nil) {
                    if([currentUnit.identifier isEqualToString:unitIdentifier]) {
                        // reachbility for internal
                        [self addNetMode:NetModeInternal];
                        return;
                    }
                }
            }
        }
    }
    
    // not reachbility for internal
    // delete NetModeInternal from _netMode_
    [self removeNetMode:NetModeInternal];
}

- (void)addNetMode:(NetMode)netMode {
    @synchronized(netModeLockObject) {
        if((_netMode_ & netMode) == NetModeNone) {
            // new netMode which will added doesn't exists
            _netMode_ |= netMode;
            [self notifyNetModeChanged];
        }
    }
}

- (void)removeNetMode:(NetMode)netMode {
    @synchronized(netModeLockObject) {
        if((_netMode_ & netMode) == netMode) {
            // new netMode which will removed has exists
            _netMode_ = ~(~_netMode_ | netMode);
            [self notifyNetModeChanged];
        }
    }
}

- (void)setNetMode:(NetMode)netMode {
    @synchronized(netModeLockObject) {
        if(_netMode_ != netMode) {
            _netMode_ = netMode;
            [self notifyNetModeChanged];
        }
    }
}

- (NetMode)netMode {
    @synchronized(netModeLockObject) {
        return _netMode_;
    }
}

- (void)notifyNetModeChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
        NSString *netModeString = [XXStringUtils emptyString];
        NetMode nm = self.netMode;
        if(nm == NetModeNone) {
            netModeString = @"No net";
        } else if(nm == NetModeExtranet) {
            netModeString = @"Extranet";
        } else if(nm == NetModeInternal) {
            netModeString = @"Internal";
        } else if(nm == NetModeAll) {
            netModeString = @"Both (Internal & Extranet)";
        }
        NSLog(@"[Core Service] Net Mode Was Changed To [%@].", netModeString);
#endif
        [[XXEventSubscriptionPublisher defaultPublisher] publishWithEvent:
            [[NetworkModeChangedEvent alloc] initWithNetMode:self.netMode]];
    });
}

- (void)notifyTcpConnectionOpened {
    [self addNetMode:NetModeExtranet];
    
    [self executeDeviceCommand:[CommandFactory commandForType:CommandTypeGetUnits]];
    [self executeDeviceCommand:[CommandFactory commandForType:CommandTypeGetNotifications]];
}

- (void)notifyTcpConnectionClosed {
    [self removeNetMode:NetModeExtranet];
}

#pragma mark -
#pragma mark Core Location Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if(locations == nil || locations.count == 0) return;
    CLLocation *location = [locations lastObject];
    
    
    
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"[CORE SERVICE] Get location failed.");
#endif
}

#pragma mark -
#pragma mark Getter and Setters

- (TCPCommandService *)tcpService {
    static dispatch_once_t tcpOnceToken;
    dispatch_once(&tcpOnceToken, ^{
        tcpService = [[TCPCommandService alloc] init];
    });
    return tcpService;
}

- (RestfulCommandService *)restfulService {
    static dispatch_once_t restOnceToken;
    dispatch_once(&restOnceToken, ^{
        restfulService = [[RestfulCommandService alloc] init];
    });
    return restfulService;
}

@end