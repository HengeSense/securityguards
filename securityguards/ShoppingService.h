//
//  ShoppingService.h
//  securityguards
//
//  Created by Zhao yang on 2/13/14.
//  Copyright (c) 2014 hentre. All rights reserved.
//

#import "ServiceBase.h"

@interface ShoppingService : ServiceBase

- (void)getProductsSuccess:(SEL)s failed:(SEL)f target:(id)t callback:(id)cb;

@end