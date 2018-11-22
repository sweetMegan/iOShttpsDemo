//
//  AppDelegate.h
//  iOSHttpsDemo
//
//  Created by zhqMAC on 2018/11/22.
//  Copyright © 2018 zhqMAC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

