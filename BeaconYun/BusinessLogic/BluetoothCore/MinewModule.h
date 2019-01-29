//
//  MinewModule.h
//  MinewModuleDemo
//
//  Created by SACRELEE on 11/16/16.
//  Copyright © 2016 SACRELEE. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ConnectionState) {
    StateConnected,
    StateDisconnected,
};

@class MinewModule;

//发送给设备的数据结构
struct SendDataNodel {
    uint8_t Command_id;
    uint8_t key;
    uint8_t mode;
    uint8_t Wind_Speed;
    uint8_t Hand_Flag;
    uint8_t Dispaly_Flag;
    uint16_t Timing;
    Byte reserve[12];
};

struct DeviceBaseInfo {
    uint32_t deviceId;
    uint32_t firewareVer;
    uint8_t PairFlag;
};

typedef void(^Connection)(NSDictionary *dataDict, MinewModule *module);
typedef void(^Receive)(BOOL result, NSData *data);
typedef void(^Send)(BOOL result,NSData *data);//写入回应的回调
typedef void(^Notify)(NSData *data);

@class CBPeripheral;

//struct SendDataNodel dataModel = {0,0,0,0,0,0,0,0};


@interface MinewModule : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) NSString *UUID;

@property (nonatomic, strong) NSString *macString;
@property (nonatomic, strong) NSString *device_id;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, assign) BOOL pair_flag;

//设备状态
//@property (nonatomic, assign) WorkMode workMode;
//@property (nonatomic, assign) WorkMode workMode;

@property (nonatomic, assign) BOOL connecting;

@property (nonatomic, assign) BOOL activeDisconnect;

@property (nonatomic, strong) NSDate *updateTime;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *customName;

@property (nonatomic, assign) NSInteger rssi;

@property (nonatomic, assign) NSInteger battery;

@property (nonatomic, assign) BOOL inRange;

@property (nonatomic, assign) BOOL connected;

@property (nonatomic, copy) Connection connectionHandler;

@property (nonatomic, copy) Receive receiveHandler;

//获取设备推送过来的数据
@property (nonatomic, copy) Notify notifyHandler;

@property (nonatomic, copy) Send writeHandler;

- (instancetype)initWithPeripheral:(CBPeripheral *)per infoDict:(NSDictionary *)info;

// write data to module
- (void)writeData:(NSData *)data hex:(BOOL)hex;


- (void)didConnect;
- (void)didDisconnect;
- (void)didConnectFailed;

@end
