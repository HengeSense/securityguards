//
//  AccountManageCell.m
//  securityguards
//
//  Created by hadoop user account on 9/01/2014.
//  Copyright (c) 2014 hentre. All rights reserved.
//

#import "AccountManageCell.h"
#import "UIColor+HexColor.h"
#import "UIDevice+SystemVersion.h"
#import "UIColor+MoreColor.h"

@implementation AccountManageCell {
    UIImageView *imgUserRole;
    UILabel *lblUserInfo;
    UIImageView *imgAccessory;
    UILabel *lblUserStatus;
}

@synthesize data;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(10, 5, CELL_WIDTH, CELL_HEIGHT-5)];
    backgroundView.backgroundColor = [UIColor appWhite];
    [self.backgroundView addSubview:backgroundView];
    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(10, 5, CELL_WIDTH, CELL_HEIGHT-5)];
    selectedBackgroundView.backgroundColor = [UIColor appDarkGray];
    [self.selectedBackgroundView addSubview:selectedBackgroundView];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(10, 5, CELL_WIDTH, CELL_HEIGHT-5)];
    view.backgroundColor = [UIColor clearColor];
    view.tag = CUSTOM_VIEW_TAG;
    [self addSubview:view];
    
    view.backgroundColor = [UIColor colorWithHexString:@"fafafa"];

    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    if (imgUserRole == nil) {
        imgUserRole = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44/2, 34/2)];
        imgUserRole.center = CGPointMake(30, view.center.y-5);
        imgUserRole.backgroundColor = [UIColor clearColor];
        [view addSubview:imgUserRole];
    }
    
    if (lblUserInfo == nil) {
        lblUserInfo = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 160, CELL_HEIGHT-5)];
        lblUserInfo.center = CGPointMake(lblUserInfo.center.x, view.center.y-5);
        lblUserInfo.textColor = [UIColor darkGrayColor];
        lblUserInfo.backgroundColor = [UIColor clearColor];
        lblUserInfo.font = [UIFont systemFontOfSize:13.f];
        if(![UIDevice systemVersionIsMoreThanOrEuqal7]) {
            lblUserInfo.textColor = [UIColor lightGrayColor];
        }
        [view addSubview:lblUserInfo];
    }
    
    if (imgAccessory == nil) {
        imgAccessory = [[UIImageView alloc] initWithFrame:CGRectMake(CELL_WIDTH-55.5, 0, 71/2, 28/2)];
        imgAccessory.center = CGPointMake(imgAccessory.center.x, view.center.y-5);
        
        [view addSubview:imgAccessory];
        if (lblUserStatus == nil) {
            lblUserStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 71/2, 28/2)];
            lblUserStatus.textColor = [UIColor whiteColor];
            lblUserStatus.font = [UIFont systemFontOfSize:10.f];
            lblUserStatus.textAlignment = NSTextAlignmentCenter;
            [imgAccessory addSubview:lblUserStatus];
        }
    }
}

- (void)loadData:(AccountManageCellData *) cellData {
    data = cellData;
    User *user = data.user;
    if(user != nil) {
        lblUserInfo.text = [NSString stringWithFormat:@"%@(%@)" ,user.name,user.mobile];
        imgAccessory.image = [UIImage imageNamed:(user.userState == UserStateOnline?@"icon_online_accessory.png":@"icon_offline_accessory.png")];
        lblUserStatus.text = user.userState == UserStateOnline? NSLocalizedString(@"user_online", @""):NSLocalizedString(@"user_offline", @"");
        if(user.isCurrentUser) {
            imgUserRole.image = [UIImage imageNamed:user.isOwner ? @"icon_me_owner.png" : @"icon_me.png"];
        } else {
            imgUserRole.image = [UIImage imageNamed:user.isOwner ? @"icon_owner.png" : @"transparent.png"];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
