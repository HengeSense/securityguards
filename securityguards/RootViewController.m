//
//  RootViewController.m
//  securityguards
//
//  Created by Zhao yang on 12/26/13.
//  Copyright (c) 2013 hentre. All rights reserved.
//

#import "RootViewController.h"
#import "NewsViewController.h"
#import "UserManagementViewController.h"
#import "CopyrightViewController.h"
#import "UnitSelectionDrawerView.h"
#import "NotificationsViewController.h"
#import "UserLogoutEvent.h"

@interface RootViewController ()

@end

@implementation RootViewController {
    PortalViewController *portalViewController;
}

@synthesize displayViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    // init left view
    NSArray *navItems = [NSArray arrayWithObjects:
        [[LeftNavItem alloc] initWithIdentifier:@"portalItem" andDisplayName:NSLocalizedString(@"portal_drawer_title", @"") andImageName:@"icon_portal"],
        [[LeftNavItem alloc] initWithIdentifier:@"newsItem" andDisplayName:NSLocalizedString(@"news_drawer_title", @"") andImageName:@"icon_news"],
        [[LeftNavItem alloc] initWithIdentifier:@"notificationsItem" andDisplayName:NSLocalizedString(@"notifications_drawer_title", @"") andImageName:@"icon_notifications"],
        [[LeftNavItem alloc] initWithIdentifier:@"accountManagerItem" andDisplayName:NSLocalizedString(@"user_mgr_drawer_title", @"") andImageName:@"icon_account"],
        [[LeftNavItem alloc] initWithIdentifier:@"copyrightItem" andDisplayName:NSLocalizedString(@"copyright_drawer_title", @"") andImageName:@"icon_copyright"],
        [[LeftNavItem alloc] initWithIdentifier:@"logoutItem" andDisplayName:NSLocalizedString(@"logout_drawer_title", @"") andImageName:@"icon_logout"], nil];
    LeftNavView *navView = [[LeftNavView alloc] initWithFrame:[UIScreen mainScreen].bounds andNavItems:navItems];
    navView.delegate = self;
    self.leftView = navView;
    
    // init center view
    if(navItems.count > 0) {
        [self leftNavViewItemChanged:[navItems objectAtIndex:0]];
    }
    
    // init right view
    
    UnitSelectionDrawerView *unitSelectionView = [[UnitSelectionDrawerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    unitSelectionView.weakRootViewController = self;
    self.rightView = unitSelectionView;
    
    self.leftViewVisibleWidth = 160;
    self.showDrawerMaxTrasitionX = 50;
    self.rightViewVisibleWidth = 160;
    self.rightViewCenterX = 200;
    
    // setup
    [self initialDrawerViewController];
    
    [self subscribeEvents];
}

#pragma mark -
#pragma mark Left Nav View Delegate

- (void)leftNavViewItemChanged:(LeftNavItem *)item {
    // if the item is nil, we think it not changed
    if(item == nil) {
        [self showCenterView:YES];
        return;
    }
    
    UIViewController *centerViewController = nil;
    
    if([@"portalItem" isEqualToString:item.identifier]) {
        if(portalViewController == nil) {
            portalViewController = [[PortalViewController alloc] init];
        }
        centerViewController = portalViewController;
    } else if([@"newsItem" isEqualToString:item.identifier]) {
        centerViewController = [[NewsViewController alloc] init];
    } else if([@"notificationsItem" isEqualToString:item.identifier]) {
        centerViewController = [[NotificationsViewController alloc] init];
    } else if([@"accountManagerItem" isEqualToString:item.identifier]) {
        centerViewController = [[UserManagementViewController alloc] init];
    } else if([@"copyrightItem" isEqualToString:item.identifier]) {
        centerViewController = [[CopyrightViewController alloc] init];
    }
    
    if(centerViewController == nil) return;
    
    [self addChildViewController:centerViewController];
    if(self.displayViewController != nil) {
        [self.displayViewController willMoveToParentViewController:nil];
    }
    self.centerView = centerViewController.view;
    [centerViewController didMoveToParentViewController:self];
    if(self.displayViewController != nil) {
        [self.displayViewController removeFromParentViewController];
    }
    self.displayViewController = centerViewController;
    [self showCenterView:YES];
    
    self.rightViewEnable = [@"portalItem" isEqualToString:item.identifier];
}

- (void)subscribeEvents {
    XXEventSubscription *subscription = [[XXEventSubscription alloc] initWithSubscriber:self eventFilter:[[XXEventNameFilter alloc] initWithSupportedEventName:EventUserLogout]];
    subscription.notifyMustInMainThread = YES;
    [[XXEventSubscriptionPublisher defaultPublisher] subscribeFor:subscription];
}

#pragma mark -
#pragma mark Event Subscriber

- (void)xxEventPublisherNotifyWithEvent:(XXEvent *)event {
    if([event isKindOfClass:[UserLogoutEvent class]]) {
        [self userHasLogout];
    }
}

- (NSString *)xxEventSubscriberIdentifier {
    return @"rootViewControllerSubscriber";
}

- (void)userHasLogout {
    if(self.leftView != nil) {
        LeftNavView *leftNavView = (LeftNavView *)self.leftView;
        [leftNavView reset];
    }
    
    if(self.displayViewController != nil) {
        if(self.displayViewController != portalViewController) {
            LeftNavItem *portalItem = [[LeftNavItem alloc] init];
            portalItem.identifier = @"portalItem";
            [self leftNavViewItemChanged:portalItem];
            return;
        }
    }
    
    [self showCenterView:NO];
}

- (PortalViewController *)portalViewController {
    return portalViewController;
}

@end
