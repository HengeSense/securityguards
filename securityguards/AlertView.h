//
//  AlertView.h
//  SmartHome
//
//  Created by Zhao yang on 8/16/13.
//  Copyright (c) 2013 hentre. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AlertViewState) {
    AlertViewStateReady,
    AlertViewStateWillAppear,
    AlertViewStateDidAppear,
    AlertViewStateWillDisappear
};

typedef NS_ENUM(NSUInteger, AlertViewType) {
    AlertViewTypeNone,
    AlertViewTypeWaitting,
    AlertViewTypeSuccess,
    AlertViewTypeFailed
};

@interface AlertView : UIView

@property (assign, nonatomic, readonly) AlertViewType alertViewType;
@property (assign, nonatomic) AlertViewState alertViewState;

+ (instancetype)currentAlertView;

- (void)setMessage:(NSString *)message forType:(AlertViewType)type;
- (void)alertForLock:(BOOL)isLock autoDismiss:(BOOL)autoDismiss;
- (void)alertForLock:(BOOL)isLock timeout:(NSTimeInterval)timeout timeoutMessage:(NSString *)message;
- (void)delayDismissAlertView;
- (void)dismissAlertView;

@end
