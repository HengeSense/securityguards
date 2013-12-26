//
//  Device.m
//  SmartHome
//
//  Created by Zhao yang on 8/22/13.
//  Copyright (c) 2013 hentre. All rights reserved.
//

#import "Device.h"

@implementation Device

@synthesize zone;

@synthesize category;
@synthesize ep;
@synthesize identifier;
@synthesize ip;
@synthesize irType;
@synthesize state;
@synthesize status;
@synthesize port;
@synthesize pwd;
@synthesize resolution;
@synthesize type;
@synthesize name;
@synthesize nwkAddr;
@synthesize user;
@synthesize isWarsignal;

@synthesize isRemote;
@synthesize isSccurtain;
@synthesize isCurtain;
@synthesize isInlight;
@synthesize isLightOrInlight;
@synthesize isAircondition;
@synthesize isCurtainOrSccurtain;
@synthesize isLight;
@synthesize isSocket;
@synthesize isSTB;
@synthesize isTV;
@synthesize isCamera;
@synthesize isBackgroundMusic;
@synthesize isDVD;

@synthesize isOnline;
@synthesize isAvailableDevice;

- (id)initWithJson:(NSDictionary *)json {
    self = [super init];
    if(self) {
        if(json != nil) {
            self.category = [json stringForKey:@"category"];
            self.ep = [json integerForKey:@"ep"];
            self.identifier = [json stringForKey:@"code"];
            self.ip = [json stringForKey:@"ip"];
            self.irType = [json integerForKey:@"irType"];
            self.status = [json integerForKey:@"status"];
            self.state = [json integerForKey:@"state"];
            self.port = [json integerForKey:@"port"];
            self.pwd = [json stringForKey:@"pwd"];
            self.resolution = [json integerForKey:@"resolution"];
            self.type = [json integerForKey:@"type"];
            self.name = [json stringForKey:@"name"];
            self.nwkAddr = [json stringForKey:@"nwkAddr"];
            self.user = [json stringForKey:@"user"];
        }
    }
    return self;
}

- (NSDictionary *)toJson {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    [json setMayBlankString:self.category forKey:@"category"];
    [json setInteger:self.ep forKey:@"ep"];
    [json setMayBlankString:self.identifier forKey:@"code"];
    [json setMayBlankString:self.ip forKey:@"ip"];
    [json setInteger:self.irType forKey:@"irType"];
    [json setInteger:self.status forKey:@"status"];
    [json setInteger:self.state forKey:@"state"];
    [json setInteger:self.port forKey:@"port"];
    [json setMayBlankString:self.pwd forKey:@"pwd"];
    [json setInteger:self.resolution forKey:@"resolution"];
    [json setInteger:self.type forKey:@"type"];
    [json setMayBlankString:self.name forKey:@"name"];
    [json setMayBlankString:self.nwkAddr forKey:@"nwkAddr"];
    [json setMayBlankString:self.user forKey:@"user"];
    return json;
}

- (NSString *)commandStringForStatus:(NSInteger)st {
    return [NSString stringWithFormat:@"%@-%@-%d", self.category, self.identifier, st];
}

- (NSString *)commandStringForCamera:(NSString *)direction {
    return [NSString stringWithFormat:@"%@-%@-%@", self.category, self.identifier, direction];
}

- (NSString *)commandStringForRemote:(NSInteger)st {
    return [NSString stringWithFormat:@"%@-%@-%d", self.category, self.nwkAddr, st];
}

#pragma mark -
#pragma mark device type or state

- (BOOL)isOnline {
    return self.state == 1;
}

- (BOOL)isAvailableDevice {
    return self.isLightOrInlight || self.isSocket || self.isCurtainOrSccurtain || self.isTV || self.isAircondition
    || self.isSTB || self.isCamera || self.isWarsignal || self.isBackgroundMusic;
}

- (BOOL)isLight {
    return [@"light" isEqualToString:self.category];
}

- (BOOL)isInlight {
    return [@"lnlight" isEqualToString:self.category];
}

- (BOOL)isLightOrInlight {
    return [self isLight] || [self isInlight];
}

- (BOOL)isSocket {
    return [@"socket" isEqualToString:self.category];
}

- (BOOL)isCurtain {
    return [@"curtain" isEqualToString:self.category];
}

- (BOOL)isSccurtain {
    return [@"sccurtain" isEqualToString:self.category];
}

- (BOOL)isCurtainOrSccurtain {
    return [self isCurtain] || [self isSccurtain];
}

- (BOOL)isRemote {
    return [@"remote" isEqualToString:self.category];
}

- (BOOL)isTV {
    return [self isRemote] && self.irType == 1;
}

- (BOOL)isDVD {
    return [self isRemote] && self.irType == 2;
}

- (BOOL)isSTB {
    return [self isRemote] && self.irType == 3;
}

- (BOOL)isAircondition {
    return [self isRemote] && self.irType == 4;
}

- (BOOL)isBackgroundMusic {
    return [self isRemote] && self.irType == 6;
}

- (BOOL)isCamera {
    return [@"camera" isEqualToString:self.category];
}

- (BOOL)isWarsignal {
    return [@"warsignal" isEqualToString:self.category];
}

@end
