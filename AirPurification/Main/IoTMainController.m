/**
 * IoTMainController.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "IoTMainController.h"
#import "IoTShutdownStatus.h"
#import "IoTTimingSelection.h"
#import "IoTRecord.h"
#import "IoTAdvancedFeatures.h"
#import "IoTAlertView.h"
#import "IoTMainMenu.h"
#import "UICircularSlider.h"
#import "IoTAdvancedFeatures.h"
#import "BJManegerHttpData.h"
#import <CoreLocation/CoreLocation.h>

#define ALERT_TAG_SHUTDOWN          1

@interface IoTMainController ()<UIAlertViewDelegate,IoTAlertViewDelegate,IoTTimingSelectionDelegate,CLLocationManagerDelegate>
{
    //提示框
    IoTAlertView *_alertView;
    
    //数据点的临时变量
    BOOL bSwitch;
    BOOL bSwitch_Plasma;
    BOOL bLED_Air_Quality;
    BOOL bChild_Security_Lock;
    NSInteger iOnTiming;
    NSInteger iOffTiming;
    NSInteger iWindVelocity;
    NSInteger iAir_Sensitivity;
    NSInteger iFilter_Life;
    NSInteger iAir_Quality;
    
    //临时数据
    NSArray *modeImages, *modeTexts;
    
    //时间选择
    IoTTimingSelection *_timingSelection;
    
}

@property (weak, nonatomic  ) IBOutlet UIView                    *globalView;

//室内空气质量情况
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageStatus;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageStatusColor;

//模式
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnSleep;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnStandard;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnStrong;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnAuto;

@property (weak, nonatomic  ) IBOutlet UISlider                  *Slider;

//定时关机
@property (weak, nonatomic  ) IBOutlet UILabel                   *textShutdown;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnShutdown;

@property (weak, nonatomic  ) IBOutlet UIButton                  *btnSwitchPlasma;
@property (weak, nonatomic  ) IBOutlet UILabel                   *textSwitchPlasma;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageSwitchPlasma;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnChildSecurityLock;
@property (weak, nonatomic  ) IBOutlet UILabel                   *textChildSecurityLock;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageChildSecurityLock;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnLEDAirQuality;
@property (weak, nonatomic  ) IBOutlet UILabel                   *textLEDAirQuality;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageLEDAirQuality;

@property (weak, nonatomic  ) IBOutlet UILabel                   *airQualityLabel;
@property (weak, nonatomic  ) IBOutlet UILabel                   *pm25Label;
@property (weak, nonatomic  ) IBOutlet UILabel                   *pm10Label;

@property (nonatomic, strong) IoTShutdownStatus         * shutdownStatusCtrl;

//定位
@property (nonatomic, strong) CLLocationManager         *manager;
@property (nonatomic, strong) UILabel                   * locationLabel;

@property (nonatomic, strong) NSArray                   * alerts;
@property (nonatomic, strong) NSArray                   * faults;
@property (strong, nonatomic) SlideNavigationController *navCtrl;

@end

@implementation IoTMainController

- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        if(nil == device)
        {
            NSLog(@"warning: device can't be null.");
            return nil;
        }
        self.device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_start"] style:UIBarButtonItemStylePlain target:self action:@selector(onPower)];
    
    [self.Slider setThumbImage:[UIImage imageNamed:@"stripe_poin.png"] forState:(UIControlStateNormal)];
    [self.Slider setMinimumTrackImage:[UIImage imageNamed:@"stripe_min.png"] forState:(UIControlStateNormal)];
    [self.Slider setMaximumTrackImage:[UIImage imageNamed:@"stripe_min.png"] forState:(UIControlStateNormal)];
    self.Slider.userInteractionEnabled = NO;
    self.airSensitivity = 0;
    
    //开启自动定位
    //判断是否开启了位置服务
    if ([CLLocationManager locationServicesEnabled])
    {
        self.manager = [[CLLocationManager alloc]init];
        self.manager.delegate = self;
        //设置精度
        [self.manager setDesiredAccuracy:kCLLocationAccuracyBest];
        //设置更新距离
        [self.manager setDistanceFilter:20];
        //开始更新经纬度
        [self.manager startUpdatingLocation];
        
        //开始获取当前城市名称
        self.locationLabel = [[UILabel alloc]init];
        [self.view addSubview:self.locationLabel];
    }
}

- (void)initDevice{
    //加载页面时，清除旧的故障报警记录
    [[IoTRecord sharedInstance] clearAllRecord];
    [self onUpdateAlarm];
    
    bSwitch       = 0;
    iWindVelocity = -1;
    self.onTiming = 0;
    iOffTiming    = 0;
    iOnTiming     = 0;
    
    [self selectSwitchPlasma:bSwitch_Plasma sendToDevice:NO];
    [self selectChildSecurityLock:bChild_Security_Lock sendToDevice:NO];
    [self selectLEDAirQuality:bLED_Air_Quality sendToDevice:NO];
    [self selectWindVelocity:iWindVelocity sendToDevice:NO];
    
    self.view.userInteractionEnabled = bSwitch;
    
    //更新关机时间
    [self onUpdateShutdownText];
    
    self.device.delegate = self;
}

- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value{
    
    NSDictionary *data = nil;
    
    switch (dataPoint)
    {
        case IoTDeviceWriteUpdateData:
            data = @{DATA_CMD: @(IoTDeviceCommandRead)};
            break;
        case IoTDeviceWriteOnOff:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_SWITCH: value}};
            break;
        case IoTDeviceWriteCountDownOnMin:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_COUNTDOWN_ON_MIN: value}};
            break;
        case IoTDeviceWriteCountDownOffMin:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_COUNTDOWN_OFF_MIN: value}};
            break;
        case IoTDeviceWriteChildSecurityLock:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_CHILD_SECURITY_LOCK: value}};
            break;
        case IoTDeviceWriteLEDAirQuality:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_LED_AIR_QUALITY: value}};
            break;
        case IoTDeviceWriteSwitchPlasma:
            data = @{DATA_CMD:@(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_SWITCH_PLASMA: value}};
            break;
        case IoTDeviceWriteWindVelocity:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_WIND_VELOCITY: value}};
            break;
        case IoTDeviceWriteQuality:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_AIR_QUALITY: value}};
            break;
        case IoTDeviceWriteAirSensitivity:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_AIR_SENSITIVITY: value}};
            break;
        case IoTDeviceWriteFilterLife:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_FILTER_LIFE: value}};
            NSLog(@"dataPoint = %u",dataPoint);
            break;
            
        default:
            NSLog(@"Error: write invalid datapoint, skip.");
            return;
    }
    NSLog(@"Write data: %@", data);
    [self.device write:data];
}

- (id)readDataPoint:(IoTDeviceDataPoint)dataPoint data:(NSDictionary *)data
{
    if(![data isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read data, error data format.");
        return nil;
    }
    
    NSNumber *nCommand = [data valueForKey:DATA_CMD];
    if(![nCommand isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Error: could not read cmd, error cmd format.");
        return nil;
    }
    
    int nCmd = [nCommand intValue];
    if(nCmd != IoTDeviceCommandResponse && nCmd != IoTDeviceCommandNotify)
    {
        NSLog(@"Error: command is invalid, skip.");
        return nil;
    }
    
    NSDictionary *attributes = [data valueForKey:DATA_ENTITY];
    if(![attributes isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read attributes, error attributes format.");
        return nil;
    }
    
    switch (dataPoint)
    {
        case IoTDeviceWriteOnOff:
            return [attributes valueForKey:DATA_ATTR_SWITCH];
        case IoTDeviceWriteCountDownOnMin:
            return [attributes valueForKey:DATA_ATTR_COUNTDOWN_ON_MIN];
        case IoTDeviceWriteCountDownOffMin:
            return [attributes valueForKey:DATA_ATTR_COUNTDOWN_OFF_MIN];
        case IoTDeviceWriteSwitchPlasma:
            return [attributes valueForKey:DATA_ATTR_SWITCH_PLASMA];
        case IoTDeviceWriteChildSecurityLock:
            return [attributes valueForKey:DATA_ATTR_CHILD_SECURITY_LOCK];
        case IoTDeviceWriteLEDAirQuality:
            return [attributes valueForKey:DATA_ATTR_LED_AIR_QUALITY];
        case IoTDeviceWriteWindVelocity:
            return [attributes valueForKey:DATA_ATTR_WIND_VELOCITY];
        case IoTDeviceWriteQuality:
            return [attributes valueForKey:DATA_ATTR_AIR_QUALITY];
        case IoTDeviceWriteAirSensitivity:
            return [attributes valueForKey:DATA_ATTR_AIR_SENSITIVITY];
        case IoTDeviceWriteFilterLife:
            return [attributes valueForKey:DATA_ATTR_FILTER_LIFE];
            
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
            
    }
    return nil;
}

//数据入口
- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result{
    
    if(![device.did isEqualToString:self.device.did])
        return YES;
    
    [IoTAppDelegate.hud hide:YES];
    [self.shutdownStatusCtrl hide:YES];
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    if(nil != _data)
    {
        NSString *onOff             = [self readDataPoint:IoTDeviceWriteOnOff data:_data];
        NSString *switchPlasma      = [self readDataPoint:(IoTDeviceWriteSwitchPlasma) data:_data];
        NSString *LEDairQuality     = [self readDataPoint:(IoTDeviceWriteLEDAirQuality) data:_data];
        NSString *countDownOnMin    = [self readDataPoint:(IoTDeviceWriteCountDownOnMin) data:_data];
        NSString *countDownOffMin   = [self readDataPoint:(IoTDeviceWriteCountDownOffMin) data:_data];
        NSString *windVelocity      = [self readDataPoint:(IoTDeviceWriteWindVelocity) data:_data];
        NSString *childSecurityLock = [self readDataPoint:IoTDeviceWriteChildSecurityLock data:_data];
        NSString *airQuality        = [self readDataPoint:IoTDeviceWriteQuality data:_data];
        NSString *airSensitivity    = [self readDataPoint:IoTDeviceWriteAirSensitivity data:_data];
        NSString *filterLife        = [self readDataPoint:IoTDeviceWriteFilterLife data:_data];

        bSwitch                     = [self prepareForUpdateFloat:onOff value:bSwitch];
        iOnTiming                   = [self prepareForUpdateFloat:countDownOnMin value:iOnTiming];
        iOffTiming                  = [self prepareForUpdateFloat:countDownOffMin value:iOffTiming];
        bSwitch_Plasma              = [self prepareForUpdateFloat:switchPlasma value:bSwitch_Plasma];
        bLED_Air_Quality            = [self prepareForUpdateFloat:LEDairQuality value:bLED_Air_Quality];
        bChild_Security_Lock        = [self prepareForUpdateFloat:childSecurityLock value:bChild_Security_Lock];
        iWindVelocity               = [self prepareForUpdateFloat:windVelocity value:iWindVelocity];
        iAir_Quality                = [self prepareForUpdateFloat:airQuality value:iAir_Quality];
        iAir_Sensitivity            = [self prepareForUpdateFloat:airSensitivity value:iAir_Sensitivity];
        iFilter_Life                = [self prepareForUpdateFloat:filterLife value:iFilter_Life];

        self.airSensitivity         = iAir_Sensitivity;
        self.filterLife             = iFilter_Life;
        
        /**
         * 更新到 UI
         */
        [self selectSwitchPlasma:bSwitch_Plasma sendToDevice:NO];
        [self selectChildSecurityLock:bChild_Security_Lock sendToDevice:NO];
        [self selectLEDAirQuality:bLED_Air_Quality sendToDevice:NO];
        [self selectWindVelocity:iWindVelocity sendToDevice:NO];
        [self selectAirQuality:iAir_Quality];
        
        self.view.userInteractionEnabled = bSwitch;
        
        //更新关机时间
        [self onUpdateShutdownText];
        
        //没有开机，切换页面
        if(!bSwitch)
        {
            [self onPower];
            return YES;
        }
    }
    
    
    /**
     * 报警和错误
     */
    if([self.navigationController.viewControllers lastObject] != self)
        return YES;
    
    self.alerts = [data valueForKey:@"alerts"];
    self.faults = [data valueForKey:@"faults"];
    
    /**
     * 清理旧报警及故障
     */
    [[IoTRecord sharedInstance] clearAllRecord];
    
    if(self.alerts.count == 0 && self.faults.count == 0)
    {
        [self onUpdateAlarm];
        return YES;
    }
    
    /**
     * 添加当前故障
     */
    NSDate *date = [NSDate date];
    if(self.alerts.count > 0)
    {
        for(NSDictionary *dict in self.alerts)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    
    if(self.faults.count > 0)
    {
        for(NSDictionary *dict in self.faults)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    
    [self onUpdateAlarm];
    
    return YES;
}

- (CGFloat)prepareForUpdateFloat:(NSString *)str value:(CGFloat)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        CGFloat newValue = [str floatValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateInteger:(NSString *)str value:(NSInteger)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        NSInteger newValue = [str integerValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initDevice];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //设备已解除绑定，或者断开连接，退出
    if(![self.device isBind:[IoTProcessModel sharedModel].currentUid] || !self.device.isConnected)
    {
        [self onDisconnected];
        return;
    }
    
    //更新侧边菜单数据
    [((IoTMainMenu *)[SlideNavigationController sharedInstance].leftMenu).tableView reloadData];
    
    //在页面加载后，自动更新数据
    if(self.device.isOnline)
    {
        IoTAppDelegate.hud.labelText = @"正在更新数据...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
    
    self.view.userInteractionEnabled = bSwitch;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if([self.navigationController.viewControllers indexOfObject:self] > self.navigationController.viewControllers.count)
        self.device.delegate = nil;
    
    //防止 delegate 出错，退出之前先关掉弹出框
    [_alertView hide:YES];
    [_timingSelection hide:YES];
    [_shutdownStatusCtrl hide:YES];
}

#pragma mark - Properties
- (NSInteger)onTiming
{
    return iOnTiming;
}

- (void)setOnTiming:(NSInteger)onTiming
{
    iOnTiming  = onTiming;
}

- (void)setDevice:(XPGWifiDevice *)device
{
    _device.delegate = nil;
    _device = device;
    [self initDevice];
}

#pragma mark - XPGWifiDeviceDelegate
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if(![device.did isEqualToString:self.device.did])
        return;
    
    [self onDisconnected];
}

- (void)onPower {
    //不在线就不能点
    if(!self.device.isOnline)
        return;

    if(bSwitch)
    {
        //关机
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"是否确定关机？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag = ALERT_TAG_SHUTDOWN;
        [alertView show];
    }
    else
    {
        //开机
        self.shutdownStatusCtrl = [[IoTShutdownStatus alloc]init];
        self.shutdownStatusCtrl.mainCtrl = self;
        [self.shutdownStatusCtrl show:YES];
    }
}

#pragma mark - Actions
- (void)onDisconnected {
    //断线且页面在控制页面时才弹框
    UIViewController *currentController = self.navigationController.viewControllers.lastObject;
    
    if(!self.device.isConnected &&
       ([currentController isKindOfClass:[IoTMainController class]] ||
        [currentController isKindOfClass:[IoTShutdownStatus class]]))
    {
        [IoTAppDelegate.hud hide:YES];
        [_alertView hide:YES];
        [self.shutdownStatusCtrl hide:YES];
        [[[IoTAlertView alloc] initWithMessage:@"连接已断开" delegate:nil titleOK:@"确定"] show:YES];
        
    }
    
    //退出到列表
    for(int i=(int)(self.navigationController.viewControllers.count-1); i>0; i--)
    {
        UIViewController *controller = self.navigationController.viewControllers[i];
        if([controller isKindOfClass:[IoTDeviceList class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
        }
    }
}

//title按钮
- (void)onUpdateAlarm {
    //自定义标题
    CGRect rc = CGRectMake(0, 0, 200, 64);
    
    UILabel *label = [[UILabel alloc] initWithFrame:rc];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"空气净化器";
    label.font = [UIFont boldSystemFontOfSize:label.font.pointSize];
    
    UIButton *view = [UIButton buttonWithType:UIButtonTypeCustom];
    [view addTarget:self action:@selector(onAlarmList) forControlEvents:UIControlEventTouchUpInside];
    view.frame = rc;
    [view addSubview:label];
    
    //故障条目数，原则上不大于65535
    NSInteger count = [IoTRecord sharedInstance].recordedCount;
    if(count > 65535)
        count = 65535;
    //故障条数目的气泡写法
    if(count > 0)
    {
        double n = log10(count);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(145, 23, 22+n*8, 18)];
        imageView.image = [[UIImage imageNamed:@"fault_tips.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        [view addSubview:imageView];
        
        UILabel *labelBadge = [[UILabel alloc] initWithFrame:imageView.bounds];
        labelBadge.textColor = [UIColor colorWithRed:0.1484375 green:0.49609375 blue:0.90234375 alpha:1.00];
        labelBadge.textAlignment = NSTextAlignmentCenter;
        labelBadge.text = [NSString stringWithFormat:@"%@", @(count)];
        [imageView addSubview:labelBadge];
        
        //弹出报警提示
        [_alertView hide:YES];
        _alertView = [[IoTAlertView alloc] initWithMessage:@"设备故障" delegate:self titleOK:@"暂不处理" titleCancel:@"拨打客服"];
        [_alertView show:YES];
    }
    
    self.navigationItem.titleView = view;
}

//跳入警报详细页面
- (void)onAlarmList {
    if(self.alerts.count == 0 && self.faults.count == 0)
    {
        NSLog(@"没有报警");
    }else{
    IoTAdvancedFeatures *faultList = [[IoTAdvancedFeatures alloc] init];
        [self.navigationController pushViewController:faultList animated:YES];
    }
}

//============风速===========
- (IBAction)onStrong:(id)sender
{
    if(iWindVelocity != 0)
        [self selectWindVelocity:0 sendToDevice:YES];
    [self getFanTextColor:YES];
}
- (IBAction)onSleep:(id)sender
{
    if(iWindVelocity != 2)
        [self selectWindVelocity:2 sendToDevice:YES];
    
}
- (IBAction)onStandard:(id)sender
{
    if(iWindVelocity != 1)
        [self selectWindVelocity:1 sendToDevice:YES];
    [self getFanTextColor:YES];
}

- (IBAction)onAuto:(id)sender
{
    if(iWindVelocity != 3)
        [self selectWindVelocity:3 sendToDevice:YES];
    [self getFanTextColor:YES];
}

#pragma mark - Group Selection
- (UIColor *)getFanTextColor:(BOOL)bSelected
{
    if(bSelected)
        return [UIColor blueColor];
    return [UIColor grayColor];
}

//设置风速
- (void)selectWindVelocity:(NSInteger)index sendToDevice:(BOOL)send
{
    if(nil == self.btnSleep)
        return;
    
    NSArray *btnItems = @[self.btnStrong, self.btnStandard, self.btnSleep, self.btnAuto];
    
    //风速：睡眠，标准，强力，自动，就只能选择其中的一种
    if(index >= -1 && index <= 3)
    {
        iWindVelocity = index;
        for(int i=0; i<(btnItems.count); i++)
        {
            BOOL bSelected = (index == i);
            ((UIButton *)btnItems[i]).selected = bSelected;
        }
        
        //发送数据
        if(send && index != -1)
            [self writeDataPoint:IoTDeviceWriteWindVelocity value:@(iWindVelocity)];
    }
}

- (void)selectAirQuality:(NSInteger)index
{
    //空气质量状况：优，良，中，差其中一种
    NSArray *imageString = @[@"good_word",@"liang_word",@"middle_word",@"bad_word"];
    NSArray *imageString2 = @[@"good_bg",@"liang_bg",@"middle_bg",@"bad_bg"];
    self.imageStatus.image = [UIImage imageNamed:imageString[index]];
    self.imageStatusColor.image = [UIImage imageNamed:[imageString2 objectAtIndex:index]];
    
    if (index == 0)
    {
        self.Slider.value = 3;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor =  [UIColor colorWithRed:0.1484375 green:0.49609375 blue:0.90234375 alpha:1.00];//导航颜色
    }
    else if (index == 1)
    {
        self.Slider.value = 2;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor = [UIColor colorWithRed:0.29 green:0.79 blue:0.44 alpha:1];
    }
    else if (index == 2)
    {
        self.Slider.value = 1;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor = [UIColor colorWithRed:0.67 green:0.69 blue:0.10 alpha:1];
    }
    else if (index == 3)
    {
        self.Slider.value = 0;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor = [UIColor colorWithRed:0.85 green:0.58 blue:0.18 alpha:1];
    }
}

//点击向上箭头按钮，设置动画使view上移65
- (IBAction)sender:(id)sender
{
    CGRect frame = self.globalView.frame;
    if(frame.origin.y == 0)
        frame.origin.y = -65;
    else
        frame.origin.y = 0;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:YES];
    self.globalView.frame = frame;
    [UIView commitAnimations];
}

- (IBAction)btnSwitchPlasma:(UIButton *)sender
{
    [self selectSwitchPlasma:!bSwitch_Plasma sendToDevice:YES];
}

- (IBAction)btnChildSecurityLock:(UIButton *)sender
{
    [self selectChildSecurityLock:!bChild_Security_Lock sendToDevice:YES];
}

- (IBAction)btnLEDAirQuality:(UIButton *)sender
{
    [self selectLEDAirQuality:!bLED_Air_Quality sendToDevice:YES];
}

//设置等离子开关
- (void)selectSwitchPlasma:(BOOL)bSelected sendToDevice:(BOOL)send
{
    bSwitch_Plasma = bSelected;
    
    //发送数据
    if(send)
        [self writeDataPoint:IoTDeviceWriteSwitchPlasma value:@(bSelected)];
    
    self.btnSwitchPlasma.selected = bSelected;
    self.textSwitchPlasma.textColor = [self getFanTextColor:bSelected];
    self.imageSwitchPlasma.image = self.btnSwitchPlasma.selected == YES ? [UIImage imageNamed:@"anion_select.png"] : [UIImage imageNamed:@"anion_not_select.png"];
}

//设置童锁
- (void)selectChildSecurityLock:(BOOL)bSelected sendToDevice:(BOOL)send
{
    bChild_Security_Lock = bSelected;
    
    //发送数据
    if(send)
        [self writeDataPoint:IoTDeviceWriteChildSecurityLock value:@(bSelected)];
    
    self.btnChildSecurityLock.selected = bSelected;
    self.textChildSecurityLock.textColor = [self getFanTextColor:bSelected];
    self.imageChildSecurityLock.image = self.btnChildSecurityLock.selected == YES ? [UIImage imageNamed:@"lock_select.png"] : [UIImage imageNamed:@"lock_not_select.png"];
}

//设置LED空气质量指示灯
- (void)selectLEDAirQuality:(BOOL)bSelected sendToDevice:(BOOL)send
{
    bLED_Air_Quality = bSelected;
    
    //发送数据
    if(send)
        [self writeDataPoint:IoTDeviceWriteLEDAirQuality value:@(bSelected)];
    
    self.btnLEDAirQuality.selected = bSelected;
    self.textLEDAirQuality.textColor = [self getFanTextColor:bSelected];
    self.imageLEDAirQuality.image = self.btnLEDAirQuality.selected == YES ? [UIImage imageNamed:@"quality_select.png"] : [UIImage imageNamed:@"quality_not_select.png"];
}

//定时关机
- (IBAction)onTimeShut:(id)sender
{
    [_timingSelection hide:YES];
    _timingSelection = [[IoTTimingSelection alloc] initWithTitle:@"倒计时关机" delegate:self currentValue:iOffTiming==0?24:(iOffTiming/60 -1)];
    [_timingSelection show:YES];
}

- (void)onUpdateShutdownText
{
    self.textShutdown.text = iOffTiming == 0 ? @"倒计时关机" : [NSString stringWithFormat:@"%@小时后关", @(iOffTiming <= 60?1:iOffTiming/60)];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1 && buttonIndex == 0)
    {
        IoTAppDelegate.hud.labelText = @"正在关机...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteOnOff value:@0];
        [self writeDataPoint:IoTDeviceWriteCountDownOffMin value:@0];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
}

- (void)IoTTimingSelectionDidConfirm:(IoTTimingSelection *)selection withValue:(NSInteger)value
{
    if(value == 24)
        iOffTiming = 0;
    else
        iOffTiming = (value+1) * 60 ;
    [self writeDataPoint:IoTDeviceWriteCountDownOffMin value:@(iOffTiming)];
    [self onUpdateShutdownText];
}

- (void)IoTAlertViewDidDismissButton:(IoTAlertView *)alertView withButton:(BOOL)isConfirm
{
    //拨打客服
    if(!isConfirm)
        [IoTAppDelegate callServices];
}

//获取当前经纬度
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    NSLog(@"***GPS***>>>%f-----%f",newLocation.coordinate.latitude,newLocation.coordinate.longitude);
    
    //通过经纬度获取城市名
    [BJManegerHttpData requestCityByCLLoacation:newLocation complation:^(id obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.locationLabel.text = (NSString *)obj;
            [self loadingEnvirenInfo];//加载室外空气数据
        });
    }];
}

- (void)loadingEnvirenInfo{
    [BJManegerHttpData requestAirQualifyInfo:self.locationLabel.text complation:^(id obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *resultDic = (NSDictionary *)obj;
            
            //pm2.5
            double pm25 = [[resultDic valueForKey:@"pm2_5"] doubleValue];
            NSLog(@"pm2.5 --- %f",pm25);
            
            //空气质量
            double aqi = [[resultDic valueForKey:@"aqi"] doubleValue];
            NSString *airQualify;
            
            //0-50=优, 50-100=良, 100-150=轻度污染, 150-200=中度污染,200-300=重度污染, 300以上=严重污染
            if (aqi >= 0 && aqi <=50)
                airQualify = @"优";
            else if (aqi > 50 && aqi <= 100)
                airQualify = @"良好";
            else if (aqi > 100 && aqi <= 150)
                airQualify = @"轻度污染";
            else if (aqi > 150 && aqi <= 200)
                airQualify = @"中度污染";
            else if (aqi > 200 && aqi <= 300)
                airQualify = @"重度污染";
            else if (aqi > 300)
                airQualify = @"严重污染";
            else
                airQualify = @"-";
            
            NSLog(@"airQua --- %@",airQualify);
            NSLog(@"PM2.5/PM10: --- %@",resultDic);
            
            //pm10
            double pm10 = [[resultDic valueForKey:@"pm10"] doubleValue];
            
            self.airQualityLabel.text = airQualify;
            self.pm25Label.text = [NSString stringWithFormat:@"%.0f",pm25];
            self.pm10Label.text = [NSString stringWithFormat:@"%.0f",pm10];
        });
    }];
}

+ (IoTMainController *)currentController
{
    SlideNavigationController *navCtrl = [SlideNavigationController sharedInstance];
    for(int i=(int)(navCtrl.viewControllers.count-1); i>0; i--)
    {
        if([navCtrl.viewControllers[i] isKindOfClass:[IoTMainController class]])
            return navCtrl.viewControllers[i];
    }
    return nil;
}

@end
