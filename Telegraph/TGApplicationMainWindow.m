#import "TGApplicationMainWindow.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "UIViewController+Proxy.h"

#import "../submodules/LegacyComponents/SSignalKitCompat/SSignalKit.h"

#include <stdarg.h>

void TGRotationLog(NSString *format, ...)
{
    NSArray *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    if (documents.count == 0)
        return;
    NSString *path = [[documents objectAtIndex:0] stringByAppendingPathComponent:@"tgram-rotation.log"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
    if ([[attributes objectForKey:NSFileSize] unsignedLongLongValue] > 512 * 1024)
        return;
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    NSString *line = [NSString stringWithFormat:@"%.3f %@\n", [[NSProcessInfo processInfo] systemUptime], message];
    if (![fileManager fileExistsAtPath:path])
        [fileManager createFileAtPath:path contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle seekToEndOfFile];
    [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
    NSLog(@"[TGramRotation] %@", message);
}

@interface TGApplicationMainWindow () {
    NSMutableArray *_presentedControllers;
}

@end

@implementation TGApplicationMainWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        _presentedControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    TGRotationLog(@"[window] setBounds=%@ frame=%@ transform=%@ screen=%@ statusBar=%d", NSStringFromCGRect(bounds), NSStringFromCGRect(self.frame), NSStringFromCGAffineTransform(self.transform), NSStringFromCGRect([UIScreen mainScreen].bounds), (int)[UIApplication sharedApplication].statusBarOrientation);
}

- (void)presentOverlayController:(TGViewController * )controller {
    __weak TGApplicationMainWindow *weakSelf = self;
    __weak TGViewController *weakController = controller;
    [controller setProxyDismissBlock:^(__unused bool animated) {
        __strong TGApplicationMainWindow *strongSelf = weakSelf;
        __strong TGViewController *strongController = weakController;
        if (strongSelf != nil && strongController != nil) {
            NSUInteger index = [strongSelf->_presentedControllers indexOfObject:strongController];
            if (index != NSNotFound) {
                if ([strongController isViewLoaded]) {
                    [strongController viewWillDisappear:false];
                    [strongController.view removeFromSuperview];
                    [strongController viewDidDisappear:false];
                    [strongSelf->_presentedControllers removeObjectAtIndex:index];
                }
            }
        }
    }];
    [_presentedControllers addObject:controller];
    [self addSubview:controller.view];
    controller.view.frame = self.bounds;
    [controller viewWillAppear:false];
    [controller viewDidAppear:false];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    for (TGViewController *controller in _presentedControllers) {
        controller.view.frame = self.bounds;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (TGViewController *controller in _presentedControllers.reverseObjectEnumerator) {
        UIView *result = [controller.view hitTest:point withEvent:event];
        if (result != nil) {
            return result;
        }
    }
    return [super hitTest:point withEvent:event];
}

@end
