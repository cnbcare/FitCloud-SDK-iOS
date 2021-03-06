//
//  FCConfigManager.m
//  FitCloudDemo
//
//  Created by 远征 马 on 2017/5/27.
//  Copyright © 2017年 马远征. All rights reserved.
//

#import "FCConfigManager.h"
#import "FitCloud+Category.h"
#import "FCWatchConfigDB.h"
#import <YYModel.h>
#import "FitCloudKit.h"


@interface FCConfigManager ()

@end

@implementation FCConfigManager
+ (instancetype)manager
{
    static FCConfigManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    __weak __typeof(self) ws = self;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ws alloc]init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self loadWatchSettingFromDB];
    }
    return self;
}

#pragma mark - 从数据库加载手表配置

- (void)loadWatchSettingFromDB
{
    NSString *uuidString = [[FitCloud shared]bondDeviceUUID];
    _watchSetting = [FCWatchConfigDB getWatchConfigFromDBWithUUID:uuidString];
    NSLog(@"---_watchSetting--%@",_watchSetting.yy_modelDescription);
    
//    [FitCloudAPI getNewFirmwareFromServer:@"0000000000200000004D00220033000011013117000000000000010012345678" result:^(id responseObject, NSError *error) {
//        NSLog(@"---responseObject---%@",responseObject);
//    }];
}


- (void)updateConfigWithWatchSettingData:(NSData*)data
{
    if (!data || data.length < 53) {
        return;
    }
    _watchSetting = [FCWatchSettingsObject objectWithData:data];
    // 更新数据库
    NSString *uuidString = [[FitCloud shared]bondDeviceUUID];
    BOOL ret = [FCWatchConfigDB storeWatchConfig:_watchSetting forUUID:uuidString];
    if (ret) {
        NSLog(@"--存储手表配置---");
    }
    
    self.sensorFlagUpdate = YES;
}


- (void)updateConfigWithVersionData:(NSData*)data
{
    if (!data || data.length < 32) {
        return;
    }
    _watchSetting.versionData = data;
    // 更新数据库
    NSString *uuidString = [[FitCloud shared]bondDeviceUUID];
    BOOL ret = [FCWatchConfigDB storeWatchConfig:_watchSetting forUUID:uuidString];
    if (ret) {
        NSLog(@"--存储手表配置---");
    }
    
    self.sensorFlagUpdate = YES;
}

- (NSArray*)getPageDisplayItems
{
    NSMutableArray *tmpArray = [NSMutableArray array];
    // 从数据库加载手表配置
    NSData *watchConfigData = nil;
    FCPageDisplayFlagObject *pageDisplayFlag = [FCWatchConfigUtils getPageDisplayFlagFromWatchConfig:watchConfigData];
    if (pageDisplayFlag.dateTime)
    {
        [tmpArray addObject:@"时间和日期"];
    }
    if (pageDisplayFlag.stepCount)
    {
        [tmpArray addObject:@"步数"];
    }
    if (pageDisplayFlag.distance)
    {
        [tmpArray addObject:@"距离"];
    }
    if (pageDisplayFlag.calorie)
    {
        [tmpArray addObject:@"卡路里"];
    }
    if (pageDisplayFlag.sleep)
    {
        [tmpArray addObject:@"睡眠"];
    }
    if (pageDisplayFlag.heartRate)
    {
        [tmpArray addObject:@"心率"];
    }
    if (pageDisplayFlag.bloodOxygen)
    {
        [tmpArray addObject:@"血氧"];
    }
    if (pageDisplayFlag.bloodPressure)
    {
        [tmpArray addObject:@"血压"];
    }
    if (pageDisplayFlag.weatherForecast)
    {
        [tmpArray addObject:@"天气预报"];
    }
    if (pageDisplayFlag.findPhone)
    {
        [tmpArray addObject:@"查找手机"];
    }
    [tmpArray addObject:@"ID"];
    
    // 将tmpArray 数据展示到屏幕显示设置列表中
    
    // e.g. [@"时间和日期",@"步数",@"距离",@"卡路里",@"睡眠"];
    FCScreenDisplayConfigObject *screenDisplayConfig = [FCWatchConfigUtils getScreenDisplayConfigFromWatchConfig:watchConfigData];
    // 判断对应的cell是哪一项
    NSString *item = nil; // 这里获取对应的item
    if ([item isEqualToString:@"时间和日期"]) {
//        screenDisplayConfig.dateTime = !screenDisplayConfig.dateTime;
        screenDisplayConfig.dateTime = YES;
    }
    else if ([item isEqualToString:@"步数"])
    {
        screenDisplayConfig.stepCount = !screenDisplayConfig.stepCount;
    }

    NSData *screenDisplayData = [screenDisplayConfig writeData];
    // 发送数据到蓝牙
    
    
    return [NSArray arrayWithArray:tmpArray];
    
    
    
    
}

- (NSDictionary*)defaultBloodPressure
{
    if (_watchSetting) {
        return [_watchSetting defaultBloodPressure];
    }
    return @{@"systolicBP":@(125),@"diastolicBP":@(80)};
}

- (BOOL)isDrinkRemimdEnabled
{
    if (_watchSetting) {
        return [_watchSetting drinkRemindEnabled];
    }
    return NO;
}

- (FCSedentaryReminderObject*)sedentaryReminderObject
{
    if (_watchSetting) {
        FCSedentaryReminderObject *obj = [_watchSetting sedentaryReminderObject];
        return obj;
    }
    return [FCSedentaryReminderObject objectWithData:nil];
}

- (FCHealthMonitoringObject*)healthMonitoringObject
{
    if (_watchSetting) {
        FCHealthMonitoringObject *obj = [_watchSetting healthMonitoringObject];
        return obj;
    }
    return [FCHealthMonitoringObject objectWithData:nil];
}

- (FCNotificationObject*)notificationObject
{
    if (_watchSetting) {
        FCNotificationObject *noteObj = [_watchSetting messageNotificationObject];
        return noteObj;
    }
    return [FCNotificationObject objectWithData:nil];
}

- (FCSensorFlagObject*)sensorFlagObject
{
    FCVersionDataObject *versionDataObj = [_watchSetting versionObject];
    if (versionDataObj)
    {
        FCSensorFlagObject *sensorFlagObj = [versionDataObj sensorTagObject];
        return sensorFlagObj;
    }
    return [FCSensorFlagObject objectWithData:nil];
}

- (FCPageDisplayFlagObject*)pageDisplayFlagObject
{
    if (_watchSetting)
    {
        FCVersionDataObject *versionDataObj = [_watchSetting versionObject];
        if (versionDataObj)
        {
            return [versionDataObj pageDisplayFlagObject];
        }
    }
    return [FCPageDisplayFlagObject objectWithData:nil];
}

- (FCScreenDisplayConfigObject*)screenDisplayConfigObject
{
    if (_watchSetting)
    {
        FCScreenDisplayConfigObject *sdObj = [_watchSetting watchScreenDisplayObject];
        return sdObj;
    }
    return [FCScreenDisplayConfigObject objectWithData:nil];
}


- (FCFeaturesObject*)featuresObject
{
    if (_watchSetting) {
        return [_watchSetting featuresObject];
    }
    return [FCFeaturesObject objectWithData:nil];
}
@end
