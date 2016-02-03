/**
 * IoTMainController.h
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

#import <UIKit/UIKit.h>

typedef enum
{
    // writable
    IoTDeviceWriteUpdateData = 0,           //更新数据
    IoTDeviceWriteOnOff,                    //开关
    IoTDeviceWriteSwitchPlasma,             //等离子开关
    IoTDeviceWriteChildSecurityLock,        //儿童锁
    IoTDeviceWriteLEDAirQuality,            //空气指令指示灯
    IoTDeviceWriteCountDownOnMin,           //倒计时开机
    IoTDeviceWriteCountDownOffMin,          //倒计时关机
    IoTDeviceWriteWindVelocity,             //风速
    IoTDeviceWriteQuality,                  //空气质量
    IoTDeviceWriteAirSensitivity,           //灵敏度
    IoTDeviceWriteFilterLife,               //滤网寿命

    // alert
    IoTDeviceAlertDust,                     //空气质量_粉尘
    IoTDeviceAlertPeculiar,                 //空气质量_异味
    IoTDeviceAlertFilterLife,               //滤芯寿命报警
    IoTDeviceAlertAirQuality,               //空气质量警报

    // fault
    IoTDeviceFaultMotor,                    //电机故障
    IoTDeviceFaultAir,                      //空气传感器故障
    IoTDeviceFaultDust,                     //灰尘传感器故障
    
}IoTDeviceDataPoint;

typedef enum
{
    IoTDeviceCommandWrite    = 1,//写
    IoTDeviceCommandRead     = 2,//读
    IoTDeviceCommandResponse = 3,//读响应
    IoTDeviceCommandNotify   = 4,//通知
}IoTDeviceCommand;

#define DATA_CMD                        @"cmd"                  //命令
#define DATA_ENTITY                     @"entity0"              //实体
#define DATA_ATTR_SWITCH                @"Switch"               //属性：开关
#define DATA_ATTR_SWITCH_PLASMA         @"Switch_Plasma"        //属性：等离子开关
#define DATA_ATTR_LED_AIR_QUALITY       @"LED_Air_Quality"      //属性：空气质量指示灯
#define DATA_ATTR_CHILD_SECURITY_LOCK   @"Child_Security_Lock"  //属性：儿童安全锁
#define DATA_ATTR_WIND_VELOCITY         @"Wind_Velocity"        //属性：风速
#define DATA_ATTR_AIR_SENSITIVITY       @"Air_Sensitivity"      //属性：空气检测灵敏度
#define DATA_ATTR_FILTER_LIFE           @"Filter_Life"          //属性：滤网寿命
#define DATA_ATTR_WEEK_REPEAT           @"Week_Repeat"          //属性：按周重复
#define DATA_ATTR_COUNTDOWN_ON_MIN      @"CountDown_On_min"     //属性：倒计时开机
#define DATA_ATTR_COUNTDOWN_OFF_MIN     @"CountDown_Off_min"    //属性：倒计时关机
#define DATA_ATTR_TIMING_ON             @"Timing_On"            //属性：定时开机
#define DATA_ATTR_TIMING_OFF            @"Timing_Off"           //属性：定时关机
#define DATA_ATTR_AIR_QUALITY           @"Air_Quality"          //属性：空气质量
#define DATA_ATTR_DUST_AIR_QUALITY      @"Dust_Air_Quality"     //属性：空气质量_粉尘
#define DATA_ATTR_PECULIAR_AIR_QUALITY  @"Peculiar_Air_Quality" //属性：空气质量_异味
#define DATA_ATTR_ALERT_FILTER_LIFE     @"Alert_Filter_Life"    //属性：滤芯寿命报警
#define DATA_ATTR_ALERT_AIR_QUALITY     @"Alert_Air_Quality"    //属性：空气质量警报
#define DATA_ATTR_FAULT_MOTOR           @"Fault_Motor"          //属性：电机故障
#define DATA_ATTR_FAULT_AIR_SENSORS     @"Fault_Air_Sensors"    //属性：空气传感器故障
#define DATA_ATTR_FAULT_DUST_SENSOR     @"Fault_Dust_Sensor"    //属性：灰尘传感器故障


@interface IoTMainController : UIViewController<XPGWifiDeviceDelegate>

//用于切换设备
@property (nonatomic, strong) XPGWifiDevice *device;

//数据信息
@property (nonatomic, assign) NSInteger onTiming;       //开机定时
@property (nonatomic, assign) NSInteger airSensitivity; //空气灵敏度
@property (nonatomic, assign) NSInteger filterLife;     //滤网寿命

//写入数据接口
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value;

- (id)initWithDevice:(XPGWifiDevice *)device;

//获取当前实例
+ (IoTMainController *)currentController;

@end
