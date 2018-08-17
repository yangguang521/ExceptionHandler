//
//  ExceptionHandler.m
//  CrashExceptionHandler
//
//  Created by xgqq on 2018/8/14.
//  Copyright © 2018年 hfzz. All rights reserved.
//

#import "ExceptionHandler.h"
#include <signal.h>
#include <execinfo.h>
#import <UIKit/UIKit.h>
@interface ExceptionHandler()


@end

@implementation ExceptionHandler
//之前的SignalHandler
typedef void (*SignalHandler)(int signo, siginfo_t *info, void *context);
static SignalHandler previousSignalHandler = NULL;
//之前的ExceptionHandler
static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler;


+ (ExceptionHandler *)sharedInstance {
    static ExceptionHandler *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ExceptionHandler alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        //还不够全面
        //不管是对于 Signal 捕获还是 NSException 捕获都会存在 handler 覆盖的问题，正确的做法应该是先判断是否有前者已经注册了 handler，如果有则应该把这个 handler 保存下来，在自己处理完自己的 handler 之后，再把这个 handler 抛出去，供前面的注册者处理。
        [self initSignalHandler];
        [self initExceptionHandler];
    }
    return self;
}

//当前的ExceptionHandler
void handleExceptions(NSException *exception) {
    //获取堆栈，收集堆栈
    NSLog(@"exception = %@",exception);
    NSLog(@"callStackSymbols = %@",[exception callStackSymbols]);
    
    //处理前者注册的 handler
    if (previousUncaughtExceptionHandler) {
        previousUncaughtExceptionHandler(exception);
    }
}

//当前的SignalHandler
void signalHandler(int signal, siginfo_t* info, void* context) {
    //获取堆栈，收集堆栈
    //可能会打印太多内容
    NSLog(@"signal = %d", signal);
    
    // 处理前者注册的 handler
    if (previousSignalHandler) {
        previousSignalHandler(signal, info, context);
    }
}

//设置Crash捕获SignalHandler
- (void)initSignalHandler {
    struct sigaction old_action;
    sigaction(SIGABRT, NULL, &old_action);
    if (old_action.sa_flags & SA_SIGINFO) {
        previousSignalHandler = old_action.sa_sigaction;
    }
    
    struct sigaction newSignalAction;
    memset(&newSignalAction, 0,sizeof(newSignalAction));
    newSignalAction.sa_sigaction = signalHandler;
    newSignalAction.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&newSignalAction.sa_mask);
    sigaction(SIGABRT, &newSignalAction, NULL);
    sigaction(SIGILL, &newSignalAction, NULL);
    sigaction(SIGSEGV, &newSignalAction, NULL);
    sigaction(SIGFPE, &newSignalAction, NULL);
    sigaction(SIGBUS, &newSignalAction, NULL);
    sigaction(SIGPIPE, &newSignalAction, NULL);
}

//设置Crash捕获ExceptionHandler
- (void)initExceptionHandler {
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    //异常时调用的函数
    NSSetUncaughtExceptionHandler(&handleExceptions);
}



@end
