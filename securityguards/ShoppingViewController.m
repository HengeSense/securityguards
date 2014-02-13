//
//  ShoppingViewController.m
//  securityguards
//
//  Created by Zhao yang on 2/11/14.
//  Copyright (c) 2014 hentre. All rights reserved.
//

#import "ShoppingViewController.h"
#import "OrderConfirmViewController.h"
#import "ShoppingStateView.h"
#import "MerchandiseCell.h"
#import "MerchandiseDetailSelectView.h"
#import "ShoppingService.h"

@interface ShoppingViewController ()

@end

@implementation ShoppingViewController {
    UITableView *tblMerchandises;
    NSMutableArray *merchandises;
    
    UIView *bottomBar;
    UIButton *btnSubmit;
}

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initUI {
    [super initUI];
    self.topbarView.title = NSLocalizedString(@"shopping_online", @"");
    ShoppingStateView *shoppingStateView = [[ShoppingStateView alloc] initWithPoint:CGPointMake(0, self.topbarView.bounds.size.height) shoppingState:ShoppingStateSelecting];
    [self.view addSubview:shoppingStateView];
    
    bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44)];
    bottomBar.backgroundColor = [UIColor appDarkDarkGray];
    
    btnSubmit = [[UIButton alloc] initWithFrame:CGRectMake(180, 0, 140, 44)];
    [btnSubmit addTarget:self action:@selector(btnSubmitPressed:) forControlEvents:UIControlEventTouchUpInside];
    [btnSubmit setTitle:NSLocalizedString(@"next_step", @"") forState:UIControlStateNormal];
    btnSubmit.backgroundColor = [UIColor appBlue];
    [bottomBar addSubview:btnSubmit];
    
    [self.view addSubview:bottomBar];
    
    tblMerchandises = [[UITableView alloc] initWithFrame:CGRectMake(0, shoppingStateView.frame.origin.y + shoppingStateView.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height - self.topbarView.bounds.size.height - shoppingStateView.bounds.size.height - bottomBar.bounds.size.height) style:UITableViewStylePlain];
    tblMerchandises.separatorStyle = UITableViewCellSeparatorStyleNone;
    tblMerchandises.delegate = self;
    tblMerchandises.dataSource = self;
    [self.view addSubview:tblMerchandises];
}

- (void)getProductsSuccess:(RestResponse *)resp {
    [JsonUtils printJsonData:resp.body];
    if(resp.statusCode == 200) {
        NSDictionary *_json_ = [JsonUtils createDictionaryFromJson:resp.body];
        int result = [_json_ intForKey:@"i"];
        if(result == 1) {
            NSArray *_m_ = [_json_ arrayForKey:@"m"];
            if(merchandises == nil) {
                merchandises = [NSMutableArray array];
            } else {
                [merchandises removeAllObjects];
            }
            if(_m_ != nil) {
                for(int i=0; i<_m_.count; i++) {
                    [merchandises addObject:[[Merchandise alloc] initWithJson:[_m_ objectAtIndex:i]]];
                }
            }
            [tblMerchandises reloadData];
            return;
        }
    }
    [self getProductsFailed:resp];
}

- (void)getProductsFailed:(RestResponse *)resp {
    
}

- (void)viewDidAppear:(BOOL)animated {
    ShoppingService *service = [[ShoppingService alloc] init];
    [service getProductsSuccess:@selector(getProductsSuccess:) failed:@selector(getProductsFailed:) target:self callback:nil];
}

#pragma mark -
#pragma mark UI Events

- (void)btnSubmitPressed:(id)sender {
    OrderConfirmViewController *orderConfirmViewController = [[OrderConfirmViewController alloc] init];
    [self.navigationController pushViewController:orderConfirmViewController animated:YES];
}

#pragma mark -
#pragma mark Table View

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MerchandiseCellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return merchandises == nil ? 0 : merchandises.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    MerchandiseCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil) {
        cell = [[MerchandiseCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.merchandise = [merchandises objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MerchandiseDetailSelectView *selectView = [[MerchandiseDetailSelectView alloc] initWithMerchandise:nil];
    [selectView showInView:self.view];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end