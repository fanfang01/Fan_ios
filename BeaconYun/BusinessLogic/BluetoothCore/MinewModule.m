//
//  MinewModule.m
//  MinewModuleDemo
//
//  Created by SACRELEE on 11/16/16.
//  Copyright © 2016 SACRELEE. All rights reserved.
//

#import "MinewModule.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MinewCommonTool.h"

//#define sWriteUUIDs @[@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E", @"FFF2"]
//#define sNotifyUUIDs @[@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E", @"FFF1"]
//#define sServiceUUIDs @[@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E", @"FFF0"]

#define WriteCharacterUUID @[@"FF01"]
//#define ReadCharacterUUID @[@"FFF4"]
#define NotifyCharacterUUID @[@"FF02"]
#define SERVICEUUID @[@"0xFFF0"]

#define Characters @[@"FFF1",@"FFF4"]

@interface MinewModule()<CBPeripheralDelegate>

@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;

@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;


//@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;

@end

@implementation MinewModule

@synthesize rssi = _rssi;
@synthesize name = _name;
@synthesize connected = _connected;
@synthesize inRange = _inRange;
@synthesize battery = _battery;

- (void)writeData:(NSData *)data hex:(BOOL)hex
{
    NSLog(@"_writeCharacteristic.UUID.UUIDString==%@  character==%@",_writeCharacteristic.UUID.UUIDString,_writeCharacteristic);

    if (_writeCharacteristic) {
        [_peripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithResponse];

    }
}

- (instancetype)initWithPeripheral:(CBPeripheral *)per infoDict:(NSDictionary *)info
{
    self = [super init];
    if (self) {
        _peripheral = per;
        _updateTime = [NSDate date];
        _UUID = per.identifier.UUIDString;
        _name = per.name;
        _customName = info[@"customName"];
        [per readRSSI];
    }
    return self;
}



#pragma mark ************************************Bluetooth
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    _name = peripheral.name;
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    _rssi = [RSSI integerValue];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    
    for ( CBService *s in peripheral.services)
    {
        if ([SERVICEUUID indexOfObject:s.UUID.UUIDString])
        {
            [peripheral discoverCharacteristics:nil forService:s];

        }
        else
            [self executeConnectionHandler:NO];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"++++%@", characteristic);
        if (error.description) {
        NSLog(@"读取设备的错误信息==%@",error.description);
    }
    
    if ([_notifyCharacteristic.UUID.UUIDString isEqualToString:characteristic.UUID.UUIDString]) {
        if (_notifyHandler) {
            _notifyHandler(characteristic.value);
        }
    }
    

    if ([_writeCharacteristic.UUID.UUIDString isEqualToString:characteristic.UUID.UUIDString])
    {
        if (_receiveHandler)
            _receiveHandler(error?NO:YES,characteristic.value);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateNotificationStateForCharacteristic Error:%@  收到的数据:%@", error,characteristic.value);
    if (error.description) {
        NSLog(@"读取设备的错误信息==%@",error.description);
    }
    
    [peripheral readValueForCharacteristic:characteristic];
    
    if (_notifyHandler)
    {
        _notifyHandler(characteristic.value);
    }
        
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"扫描到的服务==%@",service.UUID.UUIDString);
    for (CBCharacteristic *c in service.characteristics)
    {
        NSLog(@"扫描到的character的特性==%@",c.UUID.UUIDString);
        if ([WriteCharacterUUID indexOfObject:[c.UUID.UUIDString uppercaseString]] != NSNotFound)
        {
            _writeCharacteristic = c;
            NSLog(@"已扫描到写服务");
        }
        if ([NotifyCharacterUUID indexOfObject:[c.UUID.UUIDString uppercaseString]] != NSNotFound) {
            _notifyCharacteristic = c;
           [peripheral setNotifyValue:YES forCharacteristic:c];

        }
        [peripheral readValueForCharacteristic:c];

    }
    
    
    if (!_connectionHandler)
        return ;
    
    if (_writeCharacteristic)
        [self executeConnectionHandler:YES];
    else
        [self executeConnectionHandler:NO];
}

//如果有写入回应的情况
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didWriteValueForCharacteristic Error:%@", error);
    
    
    NSLog(@"peripheral == %@",peripheral);
    if ( [_writeCharacteristic.UUID.UUIDString isEqualToString:characteristic.UUID.UUIDString] )
    {
        [peripheral readValueForCharacteristic:characteristic];
        
//        NSLog(@"写入回应收到的数据:%@",characteristic.value);

//        _writeHandler(error? NO: YES,characteristic.value);
    }
}

- (void)executeConnectionHandler:(BOOL)connected
{
    if (_connectionHandler)
    {
        NSDictionary *dict = connected? [self deviceInfo]: @{@"state": @"0"};
        _connectionHandler(dict, self);
    }
}

#pragma mark ***********************************Setter
- (void)setPeripheral:(CBPeripheral *)peripheral
{
    _peripheral = peripheral;
    _UUID = peripheral.identifier.UUIDString;
    _peripheral.delegate = self;
}

- (void)didConnect
{
    _connected = YES;
    _connecting = NO;
    [_peripheral discoverServices:nil];
}


- (void)didDisconnect
{
    _connecting = NO;
    _connected = NO;
    
    [self executeConnectionHandler:NO];
}


- (void)didConnectFailed
{
    _connecting = NO;
    _connected = NO;
    [self executeConnectionHandler:NO];
}

- (NSDictionary *)deviceInfo
{
    NSMutableDictionary *infoOut = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [infoOut setValue:@"1" forKey:@"state"];
    
    
    if (_name)
        [infoOut setValue:_name forKey:@"name"];
    
    [infoOut setValue:@(_rssi) forKey:@"rssi"];
    [infoOut setValue:@(_battery) forKey:@"battery"];
    
    if (_UUID)
       [infoOut setValue:_UUID forKey:@"identifer"];
    
    return [NSDictionary dictionaryWithDictionary:infoOut];
}


@end
