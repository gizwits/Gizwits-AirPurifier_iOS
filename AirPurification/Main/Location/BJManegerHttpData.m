/**
 * BJManegerHttpData.m
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

#import "BJManegerHttpData.h"

@implementation BJManegerHttpData

+ (void)requestWeatherInfo:(NSString*)location complation:(CallBack)complation{
    NSString* path = [NSString stringWithFormat:@"http://api.map.baidu.com/telematics/v3/weather?location=%@&output=json&ak=fS84XeYNhFoTp8qXLLdcMBdn",location];
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//有中文时记得转码
    NSURL* url = [NSURL URLWithString:path];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        NSString *dicStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"￥室外空气：--%@--￥",dicStr);
        
        UIImage *weatherImage = [self parserDicForWeather:dic];
        complation(weatherImage);
        
    }];
    [dataTask resume];
}

+ (UIImage *)parserDicForWeather:(NSDictionary *)dic{
    NSArray* results = [dic objectForKey:@"results"];
    NSDictionary* subDic = results[0];
    NSArray* weatherData = [subDic objectForKey:@"weather_data"];
    NSDictionary* weatherDic = weatherData[0];
    NSString* todayWeather = [weatherDic objectForKey:@"weather"];
    
    //判断天气 返回对应天气的图片
    UIImage *weatherImage;
    
    //晴`|多云`|阴`|阵雨`|雷阵雨`|雷阵雨伴有冰雹`|雨夹雪`|小雨`|中雨`|大雨|`暴雨`|大暴雨`|特大暴雨`|阵雪`|小雪`|中雪`|大雪`|暴雪`|雾`|冻雨`|沙尘暴|小雨转中雨`|中雨转大雨`|大雨转暴雨`|暴雨转大暴雨`|大暴雨转特大暴雨`|小雪转中雪`|中雪转大雪`|大雪转暴雪`|浮尘|扬沙|强沙尘暴|霾
    if ([todayWeather isEqualToString:@"晴"] || todayWeather == NULL) {
        weatherImage = [UIImage imageNamed:@"weather_sunny.png"];
    }else if ([todayWeather isEqualToString:@"多云"]){
        weatherImage = [UIImage imageNamed:@"weather_cloudy.png"];
    }else if ([todayWeather isEqualToString:@"阴"]){
        weatherImage = [UIImage imageNamed:@"weather_partly.png"];
    }else if ([todayWeather rangeOfString:@"雨"].location != NSNotFound){
        weatherImage = [UIImage imageNamed:@"weather_rain.png"];
        if (![todayWeather isEqualToString:@"小雨"]) {
            weatherImage = [UIImage imageNamed:@"weather_heavy_rain.png"];
        }
        if (![todayWeather isEqualToString:@"阵雨"]) {
            weatherImage = [UIImage imageNamed:@"weather_shower.png"];
        }
        if (![todayWeather isEqualToString:@"冰雨"]) {
            weatherImage = [UIImage imageNamed:@"weather_sleet.png"];
        }
        if ([todayWeather isEqualToString:@"雷阵雨"]) {
            weatherImage = [UIImage imageNamed:@"weather_thundershowers.png"];
        }
        if ([todayWeather isEqualToString:@"雷阵雨伴有冰雹"]) {
            weatherImage = [UIImage imageNamed:@"weather_sleet_rain.png"];
        }
        if ([todayWeather isEqualToString:@"雨夹雪"]) {
            weatherImage = [UIImage imageNamed:@"weather_rain_snow.png"];
        }
    }else if ([todayWeather rangeOfString:@"雪"].location != NSNotFound){
        weatherImage = [UIImage imageNamed:@"weather_snow.png"];
        if (![todayWeather isEqualToString:@"小雪"]) {
            weatherImage = [UIImage imageNamed:@"weather_heavy_snow.png"];
        }
        if ([todayWeather isEqualToString:@"雨夹雪"]) {
            weatherImage = [UIImage imageNamed:@"weather_rain_snow.png"];
        }
    }else if ([todayWeather isEqualToString:@"雾"]){
        weatherImage = [UIImage imageNamed:@"weather_fog.png"];
    }else{
        weatherImage = [UIImage imageNamed:@"weather_dust.png"];
    }
    
    return weatherImage;
}

- (void)parserDic:(NSDictionary*)dic{
    NSArray* results = [dic objectForKey:@"results"];
    NSDictionary* subDic = results[0];
    NSArray* weatherData = [subDic objectForKey:@"weather_data"];
    NSDictionary* weatherDic = weatherData[0];
    NSString* todayWeather = [weatherDic objectForKey:@"weather"];
    
    if([todayWeather rangeOfString:@"大雨"].location != NSNotFound)
    {
        NSLog(@"大雨");
    }
    else if([todayWeather rangeOfString:@"雨"].location != NSNotFound)
    {
        NSLog(@"雨");
    }
    else if([todayWeather rangeOfString:@"阴"].location != NSNotFound)
    {
        NSLog(@"阴");
    }
    else if([todayWeather rangeOfString:@"晴"].location != NSNotFound)
    {
        NSLog(@"晴");
    }
    else if([todayWeather rangeOfString:@"多云"].location != NSNotFound)
    {
        NSLog(@"多云");
    }
    
    NSLog(@"--%@--",todayWeather);
}

+ (void)requestAirQualifyInfo:(NSString*)location complation:(CallBack)complation{
    NSString* urlString = [NSString stringWithFormat:@"http://data.gizwits.com/1/pm25?area=%@",location];
    NSURL* url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"c79c8ef6002111e48a9b00163e0e2e0d" forHTTPHeaderField:@"X-XPG-Application-Id"];
    [request addValue:@"c79cd5c8002111e48a9b00163e0e2e0d" forHTTPHeaderField:@"X-XPG-REST-API-Key"];
    
    NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"error = %@",[error localizedDescription]);
            return ;
        }
        NSError* parserError;
        NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&parserError];

#if DEBUG
        if (parserError) {
            NSLog(@"parserError = %@",[parserError localizedDescription]);
            NSLog(@"parserError_all = %@",parserError);
        }
#endif
        
        //解析
        NSDictionary *resultDic = [dic valueForKey:@"result"];
        NSLog(@"resultDic = %@",resultDic);
        complation(resultDic);
        
    }];
    [dataTask resume];
}

static NSString *baiDuAK = @"fS84XeYNhFoTp8qXLLdcMBdn";

+(void)requestCityByCLLoacation:(CLLocation *)newLocation complation:(CallBack)complation{
    
    NSString* urlString = [NSString stringWithFormat:@"http://api.map.baidu.com/geocoder/v2/?ak=%@&callback=renderReverse&location=%f,%f&output=json&pois=1", baiDuAK, newLocation.coordinate.latitude, newLocation.coordinate.longitude];
    NSURL* url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

#if DEBUG
        if (error) {
            NSLog(@"error = %@",[error localizedDescription]);
            return ;
        }
#endif
        
        NSString *dicString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString * dicStr = [dicString substringToIndex:([dicString length] -1)];
        NSArray *dicArr = [dicStr componentsSeparatedByString:@"renderReverse&&renderReverse("];
        
        dicStr = dicArr[1];
        data = [dicStr dataUsingEncoding:NSUTF8StringEncoding] ;
        
        NSError* parserError;
        NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&parserError];
        if (parserError)
        {
            NSLog(@"parserError_all = %@",parserError);
        }
        
        NSLog(@" dicStr for city ==== %@",dicStr);
        
        complation([BJManegerHttpData paserCityDic:dic]);
        
    }];
    [dataTask resume];
}

//解析得到的城市
+ (NSString *)paserCityDic:(NSDictionary *)dic{
    NSDictionary *resultDic = [dic valueForKey:@"result"];
    NSDictionary *addressDic = [resultDic valueForKey:@"addressComponent"];
    NSString *cityStr = [addressDic valueForKey:@"city"];
    return [cityStr componentsSeparatedByString:@"市"][0];
}

+(void)requestAirqualityInCurrentMonth:(NSDate *)date withMachineID:(NSString *)did complation:(CallBack)complation{

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateStr = [formatter stringFromDate:date];
    
    if (did == nil) {
        did = @"SBSkzNmncbSqzNT5s2QguZ";
        dateStr = @"2014-09-10";
    }
    
    NSDictionary *dateDic = [[NSDictionary alloc] initWithObjectsAndKeys: dateStr, @"$regex",nil];
    NSDictionary *pagramDic = [[NSDictionary alloc] initWithObjectsAndKeys: dateDic,@"date",did,@"did", nil];
    
    NSData *pagramData = [NSJSONSerialization dataWithJSONObject:pagramDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *pagram = [[NSString alloc] initWithData:pagramData encoding:NSUTF8StringEncoding];
    
    NSString *path = [NSString stringWithFormat:@"http://data.iotsdk.com/1/classes/air_quality?&where=%@&limit=24&skip=0",pagram];
    NSURL *usl = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"++++++++++++++++++++++++++++++%@",pagram);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:usl];
    
    [request addValue:@"c79c8ef6002111e48a9b00163e0e2e0d" forHTTPHeaderField:@"X-XPG-Application-Id"];
    [request addValue:@"c79cd5c8002111e48a9b00163e0e2e0d" forHTTPHeaderField:@"X-XPG-REST-API-Key"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            NSLog(@"error = %@",[error localizedDescription]);
            return ;
        }
        
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"******监测数据统计******\n%@",dataStr);
        
        NSError* parserError;
        NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&parserError];
        if (parserError) {
            NSLog(@"parserError = %@",[parserError localizedDescription]);
            NSLog(@"parserError_all = %@",parserError);
        }
        NSLog(@"******监测数据统计******\n%@",dic);
        //数据解析
        NSArray *airQulitys = [dic valueForKeyPath:@"results"];
        complation(airQulitys);
        
    }];
    [task resume];
}

@end
