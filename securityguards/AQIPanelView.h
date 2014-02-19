//
//  AQIPanelView.h
//  securityguards
//
//  Created by Zhao yang on 2/19/14.
//  Copyright (c) 2014 hentre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorDisplayView.h"

#define AQI_PANEL_VIEW_HEIGHT 60

@interface AQIPanelView : UIView

- (instancetype)initWithPoint:(CGPoint)point;

- (void)setCity:(NSString *)city aqiNumber:(int)aqiNumber tips:(NSString *)tips;

@end
