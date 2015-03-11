/**
 * IoTShutdownStatus.m
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

#import "IoTShutdownStatus.h"
#import "IoTMainController.h"
#import "IoTTimingSelection.h"
#import "IoTMainMenu.h"

@interface IoTShutdownStatus () <IoTTimingSelectionDelegate>
{
    IoTTimingSelection *_timingSelection;
    __strong IoTShutdownStatus * shutdownStatusCtrl;
}

@property (nonatomic, strong) XPGWifiDevice *device;
@property (weak, nonatomic) IBOutlet UIButton *btnOnTiming;

@end

@implementation IoTShutdownStatus

- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        self.device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self onUpdateTiming];
    [self.mainCtrl addObserver:self forKeyPath:@"onTiming" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mainCtrl removeObserver:self forKeyPath:@"onTiming"];
    [_timingSelection hide:YES];
}

#pragma mark - action

- (IBAction)onPowerOn:(id)sender {
    [self hide:YES];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteOnOff value:@1];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteCountDownOnMin value:@0];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteUpdateData value:nil];
}

- (IBAction)onOnTiming:(id)sender {
    _timingSelection = [[IoTTimingSelection alloc] initWithTitle:@"倒计时开机" delegate:self currentValue:self.mainCtrl.onTiming==0?24:((self.mainCtrl.onTiming/60)-1)];
    [_timingSelection show:YES];
}

- (void)onUpdateTiming {
    NSString *title = @" 倒计时开机";
    if(self.mainCtrl.onTiming != 0)
        title = [NSString stringWithFormat:@" %@小时后开机", @(self.mainCtrl.onTiming<= 60?1:self.mainCtrl.onTiming/60)];
    
    [self.btnOnTiming setTitle:title forState:UIControlStateNormal];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self onUpdateTiming];
}

#pragma mark - delegate
- (void)IoTTimingSelectionDidConfirm:(IoTTimingSelection *)selection withValue:(NSInteger)value
{
    if(value == 24)
        self.mainCtrl.onTiming = 0;
    else
        self.mainCtrl.onTiming = (value+1)* 60 ;
    [self.mainCtrl writeDataPoint:IoTDeviceWriteCountDownOnMin value:@(self.mainCtrl.onTiming)];
    
    //更新界面上的数据
    [self onUpdateTiming];
}

- (void)show:(BOOL)animated
{
    shutdownStatusCtrl = self;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    [UIView commitAnimations];
    
    self.view.frame = [UIApplication sharedApplication].keyWindow.frame;
}

- (void)hide:(BOOL)animated
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [self.view removeFromSuperview];
    [UIView commitAnimations];
    
    shutdownStatusCtrl = nil;
}

@end
