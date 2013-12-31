//
//  RegisterStep2ViewController.m
//  securityguards
//
//  Created by Zhao yang on 12/26/13.
//  Copyright (c) 2013 hentre. All rights reserved.
//

#import "RegisterStep2ViewController.h"
#import "AccountService.h"
#import "XXTextField.h"
#import "NSDictionary+Extension.h"
#import "DeviceCommand.h"
#import "LoginViewController.h"
#import "Shared.h"

#define TOPBAR_HEIGHT   self.topbarView.frame.size.height

@interface RegisterStep2ViewController ()

@end

@implementation RegisterStep2ViewController{
    UITextField *txtPhoneNumber;
    UITextField *txtVerificationCode;
    UIButton *btnRegister;
    UIButton *btnResendVerificationCode;
    NSTimer *countDownTimer;
}
@synthesize phoneNumber;
@synthesize countDown;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)initUI{
    [super initUI];
    [self registerTapGestureToResignKeyboard];
    self.view.backgroundColor = [UIColor whiteColor];
    self.topbarView.title = NSLocalizedString(@"register.account", @"");
    
    UILabel *lblPhoneNumber = [[UILabel alloc] initWithFrame:CGRectMake(5, TOPBAR_HEIGHT+20, 80, 44)];
    lblPhoneNumber.text = [NSString stringWithFormat:@"%@ :", NSLocalizedString(@"phone.number", @"")];
    lblPhoneNumber.font = [UIFont systemFontOfSize:16.0f];
    [self.view addSubview:lblPhoneNumber];

    UILabel *lblVerificationCode = [[UILabel alloc] initWithFrame:CGRectMake(5, lblPhoneNumber.frame.origin.y+lblPhoneNumber.frame.size.height+5, 80, 44)];
    lblVerificationCode.text = [NSString stringWithFormat:@"%@ :", NSLocalizedString(@"verification.code", @"")];
    lblVerificationCode.font = [UIFont systemFontOfSize:16.0f];
    [self.view addSubview:lblVerificationCode];

    if (txtPhoneNumber == nil) {
        txtPhoneNumber = [[UITextField alloc] initWithFrame:CGRectMake(85, 20+TOPBAR_HEIGHT, 200, 44)];
        txtPhoneNumber.text = phoneNumber;
        [self.view addSubview:txtPhoneNumber];
    }
    
    if (txtVerificationCode == nil) {
        txtVerificationCode = [[UITextField alloc] initWithFrame:CGRectMake(85, lblVerificationCode.frame.origin.y, 200, 44)];
        txtVerificationCode.placeholder = NSLocalizedString(@"please.input.verification.code", @"");
        txtVerificationCode.clearButtonMode = UITextFieldViewModeWhileEditing;
        txtVerificationCode.autocorrectionType = UITextAutocapitalizationTypeNone;
        [self.view addSubview:txtVerificationCode];
    }
    
    UIView *seperatorView = [[UIView alloc] initWithFrame:CGRectMake(0, lblVerificationCode.frame.size.height+lblVerificationCode.frame.origin.y+5, self.view.bounds.size.width, 1)];
    seperatorView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:seperatorView];

    UILabel *lblTip = [[UILabel alloc] initWithFrame:CGRectMake(0, seperatorView.frame.size.height+seperatorView.frame.origin.y+10,200,100)];
    lblTip.numberOfLines = 2;
    lblTip.center = CGPointMake(self.view.center.x, lblTip.center.y);
    lblTip.lineBreakMode = NSLineBreakByWordWrapping;
    lblTip.textColor = [UIColor lightGrayColor];
    lblTip.font = [UIFont systemFontOfSize:11.f];
    lblTip.text = NSLocalizedString(@"register.tip2", @"");
    [self.view addSubview:lblTip];
    
    if (btnRegister == nil) {
        btnRegister = [[UIButton alloc] initWithFrame:CGRectMake(0, lblTip.frame.origin.y+lblTip.frame.size.height+10, 400/2, 53/2)];
        btnRegister.center = CGPointMake(self.view.center.x, btnRegister.center.y);
        [btnRegister setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btnRegister setTitle:NSLocalizedString(@"finish.register.and.login", @"") forState:UIControlStateNormal];
        [btnRegister addTarget:self action:@selector(btnRegisterPressed:) forControlEvents:UIControlEventTouchUpInside];
        btnRegister.enabled = NO;
        [btnRegister setImage:[UIImage imageNamed:@"btn_blue"] forState:UIControlStateNormal];
        [btnRegister setImage:[UIImage imageNamed:@"btn_gray"] forState:UIControlStateDisabled];
        [btnRegister setImage:[UIImage imageNamed:@"btn_blue_highlighted"] forState:UIControlStateHighlighted];
        [self.view addSubview:btnRegister];
    }
    
    if (btnResendVerificationCode == nil) {
        btnResendVerificationCode = [[UIButton alloc] initWithFrame:CGRectMake(0, btnRegister.frame.origin.y+btnRegister.frame.size.height+10, 400/2, 53/2)];
        btnResendVerificationCode.center = CGPointMake(self.view.center.x, btnResendVerificationCode.center.y);
        if (countDownTimer == nil) {
            countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(countDownForResend) userInfo:nil repeats:YES];
        }
        [btnResendVerificationCode setTitle:[NSString stringWithFormat:@"%@(%i)",NSLocalizedString(@"resend.verification.code", @""),countDown] forState:UIControlStateDisabled];
        [btnResendVerificationCode setTitle:[NSString stringWithFormat:@"%@",NSLocalizedString(@"resend.verification.code", @"")] forState:UIControlStateNormal];
        [btnResendVerificationCode setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btnRegister addTarget:self action:@selector(btnResendVerificationCode:) forControlEvents:UIControlEventTouchUpInside];
        [btnResendVerificationCode setImage:[UIImage imageNamed:@"btn_blue.png"] forState:UIControlStateNormal];
        [btnResendVerificationCode setImage:[UIImage imageNamed:@"btn_gray.png"] forState:UIControlStateDisabled];
        [btnResendVerificationCode setImage:[UIImage imageNamed:@"btn_blue_highlighted.png"] forState:UIControlStateHighlighted];
        btnResendVerificationCode.enabled = NO;
        [self.view addSubview:btnResendVerificationCode];
    }
    
}

#pragma mark-
#pragma mark btn actions
- (void)btnRegisterPressed:(id) sender{
    [self submitVerificationCode];
}

- (void)btnResendVerificationCode:(id) sender{
    [self resendVerificationCode];
}

#pragma mark-
#pragma mark countdown
- (void)countDownForResend{
    if (countDown>0) {
        countDown--;
        [btnResendVerificationCode setTitle:[NSString stringWithFormat:@"%@(%iS)",NSLocalizedString(@"resend.verification.code", @""),countDown] forState:UIControlStateDisabled];
    }else{
        btnResendVerificationCode.enabled = YES;
        [countDownTimer invalidate];
        countDownTimer = nil;
    }
    
}

#pragma mark-
#pragma mark services
- (void)resendVerificationCode {
    [[AlertView currentAlertView] setMessage:NSLocalizedString(@"please_wait", @"") forType:AlertViewTypeWaitting];
    [[AlertView currentAlertView] alertAutoDisappear:NO lockView:self.view];
    [[[AccountService alloc] init] sendVerificationCodeFor:self.phoneNumber success:@selector(verificationCodeSendSuccess:) failed:@selector(verificationCodeSendError:) target:self callback:nil];
}

- (void)verificationCodeSendSuccess:(RestResponse *)resp {
    if(resp.statusCode == 200) {
        NSDictionary *json = [JsonUtils createDictionaryFromJson:resp.body];
        if(json != nil) {
            NSString *_id_ = [json notNSNullObjectForKey:@"id"];
            if(_id_ != nil) {
                if([@"1" isEqualToString:_id_]) {
                    [[AlertView currentAlertView] setMessage:NSLocalizedString(@"send_success", @"") forType:AlertViewTypeSuccess];
                    [[AlertView currentAlertView] delayDismissAlertView];
                    self.countDown = 60;
                    [btnResendVerificationCode setTitle:[NSString stringWithFormat:@"%@(%iS)",NSLocalizedString(@"resend.verification.code", @""),countDown] forState:UIControlStateDisabled];
                    [self countDownForResend];
                    return;
                }
            }
        }
    }
    [self verificationCodeSendError:resp];
}

- (void)verificationCodeSendError:(RestResponse *)resp {
    if(resp.statusCode == 1001) {
        [[AlertView currentAlertView] setMessage:NSLocalizedString(@"request_timeout", @"") forType:AlertViewTypeSuccess];
    } else {
        [[AlertView currentAlertView] setMessage:NSLocalizedString(@"unknow_error", @"") forType:AlertViewTypeSuccess];
    }
    [[AlertView currentAlertView] delayDismissAlertView];
}

- (void)submitVerificationCode {
    if([XXStringUtils isBlank:txtVerificationCode.text] || txtVerificationCode.text.length != 6) {
        [[AlertView currentAlertView] setMessage:NSLocalizedString(@"verification_code_error", @"") forType:AlertViewTypeFailed];
        [[AlertView currentAlertView] alertAutoDisappear:YES lockView:self.view];
        return;
    }
    [[AlertView currentAlertView] setMessage:NSLocalizedString(@"please_wait", @"") forType:AlertViewTypeWaitting];
    [[AlertView currentAlertView] alertAutoDisappear:NO lockView:self.view];
    [[[AccountService alloc] init] registerWithPhoneNumber:self.phoneNumber checkCode:txtVerificationCode.text success:@selector(registerSuccessfully:) failed:@selector(registerFailed:) target:self callback:nil];
}

- (void)registerSuccessfully:(RestResponse *)resp {
    if(resp.statusCode == 200) {
        NSDictionary *json = [JsonUtils createDictionaryFromJson:resp.body];
        if(json != nil) {
            DeviceCommand *command = [[DeviceCommand alloc] initWithDictionary:json];
            if(command != nil && ![XXStringUtils isBlank:command.result]) {
                if([@"1" isEqualToString:command.result]) {
                    if(![XXStringUtils isBlank:command.security] && ![XXStringUtils isBlank:command.tcpAddress]) {
                        [[AlertView currentAlertView] dismissAlertView];
                        GlobalSettings *settings = [GlobalSettings defaultSettings];
                        settings.secretKey = command.security;
                        settings.account = self.phoneNumber;
                        settings.tcpAddress = command.tcpAddress;
                        settings.deviceCode = command.deviceCode;
                        settings.restAddress = command.restAddress;
                        [settings saveSettings];
                        
                        ((LoginViewController *)[Shared shared].app.window.rootViewController).hasLogin = YES;
                        [self.navigationController popToRootViewControllerAnimated:NO];
//                        [self.navigationController pushViewController:[[UnitsBindingViewController alloc] init] animated:YES];
                        [[CoreService defaultService] startService];
                        return;
                    }
                } else if([@"-1" isEqualToString:command.result]) {
                    [[AlertView currentAlertView] setMessage:NSLocalizedString(@"none_verification_code", @"") forType:AlertViewTypeFailed];
                    [[AlertView currentAlertView] delayDismissAlertView];
                    return;
                } else if([@"-2" isEqualToString:command.result]) {
                    [[AlertView currentAlertView] setMessage:NSLocalizedString(@"verification_code_expire", @"") forType:AlertViewTypeFailed];
                    [[AlertView currentAlertView] delayDismissAlertView];
                    return;
                } else if([@"-3" isEqualToString:command.result]) {
                    [[AlertView currentAlertView] setMessage:NSLocalizedString(@"verification_code_error", @"") forType:AlertViewTypeFailed];
                    [[AlertView currentAlertView] delayDismissAlertView];
                    return;
                }
            }
        }
    }
    [self registerFailed:resp];
}

- (void)registerFailed:(RestResponse *)resp {
    if(abs(resp.statusCode) == 1001) {
        [[AlertView currentAlertView] setMessage:NSLocalizedString(@"request_timeout", @"") forType:AlertViewTypeFailed];
    } else {
        [[AlertView currentAlertView] setMessage:NSLocalizedString(@"unknow_error", @"") forType:AlertViewTypeFailed];
    }
    [[AlertView currentAlertView] delayDismissAlertView];
}






- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
