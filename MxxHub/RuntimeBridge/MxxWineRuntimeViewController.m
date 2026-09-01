#import "MxxWineRuntimeViewController.h"
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <unistd.h>

#import "WGMetalView.h"
#import "WGCompositor.h"
#include "wg_engine.h"
#include "wg_log.h"
#include "wg_selftest.h"
#include "wg_win32_windows.h"

@interface MxxWineRuntimeViewController ()
@property (nonatomic, copy, readwrite) NSString *executablePath;
@property (nonatomic, strong) WGMetalView *metalView;
@property (nonatomic, strong) WGCompositor *compositor;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) NSThread *engineThread;
@end

@implementation MxxWineRuntimeViewController {
    WGEngine *_engine;
    volatile BOOL _engineThreadRunning;
}

- (instancetype)initWithExecutablePath:(NSString *)executablePath {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _executablePath = [executablePath copy];
        _engine = NULL;
        _engineThreadRunning = NO;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self setupMetal];
    [self setupOverlay];
    [self setupTapHandler];
    [self startDisplayLink];
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    [self setStatus:@"Preparing Windows runtime…"];
    [self startEngine];
}

- (void)dealloc {
    [self shutdownEngine];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.presentingViewController == nil || self.navigationController == nil) {
        [self shutdownEngine];
    }
}

- (void)setupMetal {
    self.metalView = [[WGMetalView alloc] initWithFrame:self.view.bounds];
    self.metalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.metalView];

    id<MTLDevice> device = self.metalView.metalLayer.device;
    if (device) {
        self.commandQueue = [device newCommandQueue];
        self.compositor = [[WGCompositor alloc] initWithDevice:device];
    }
}

- (void)setupOverlay {
    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.layer.cornerRadius = 14.0;
    panel.clipsToBounds = YES;
    [self.view addSubview:panel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.textColor = UIColor.whiteColor;
    self.statusLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.statusLabel.numberOfLines = 3;
    [panel.contentView addSubview:self.statusLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setTitle:@"Done" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [panel.contentView addSubview:self.closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [panel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-12],
        [panel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:panel.contentView.leadingAnchor constant:12],
        [self.statusLabel.topAnchor constraintEqualToAnchor:panel.contentView.topAnchor constant:10],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:panel.contentView.bottomAnchor constant:-10],
        [self.closeButton.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.statusLabel.trailingAnchor constant:8],
        [self.closeButton.trailingAnchor constraintEqualToAnchor:panel.contentView.trailingAnchor constant:-12],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:panel.contentView.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:58]
    ]];
}

- (void)setupTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.cancelsTouchesInView = NO;
    [self.metalView addGestureRecognizer:tap];
}

- (void)startDisplayLink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderFrame:)];
    self.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 120, 60);
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)startEngine {
    wg_log_init();
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        bool selfTestOK = wg_selftest_run();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setStatus:(selfTestOK ? @"x86/x64 self-test passed — creating engine…" : @"Self-test incomplete — trying engine fallback…")];
        });

        self->_engine = wg_engine_create();
        if (!self->_engine || !wg_engine_init(self->_engine)) {
            dispatch_async(dispatch_get_main_queue(), ^{ [self setStatus:@"Runtime initialization failed"]; });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{ [self setStatus:@"Loading Windows PE…"]; });
        bool loaded = wg_engine_load_pe(self->_engine, self.executablePath.UTF8String);
        if (!loaded) {
            dispatch_async(dispatch_get_main_queue(), ^{ [self setStatus:@"PE load failed — check runtime log"]; });
            return;
        }

        bool started = wg_engine_run(self->_engine);
        if (!started) {
            dispatch_async(dispatch_get_main_queue(), ^{ [self setStatus:@"Execution could not start"]; });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{ [self setStatus:@"x86/x64 engine running"]; });
        [self startEngineThread];
    });
}

- (void)startEngineThread {
    _engineThreadRunning = YES;
    self.engineThread = [[NSThread alloc] initWithTarget:self selector:@selector(engineLoop) object:nil];
    self.engineThread.stackSize = 4 * 1024 * 1024;
    self.engineThread.qualityOfService = NSQualityOfServiceUserInteractive;
    self.engineThread.name = @"MxxHub-WindowsRuntime";
    [self.engineThread start];
}

- (void)engineLoop {
    @autoreleasepool {
        while (_engineThreadRunning && _engine) {
            WGEngineState state = wg_engine_get_state(_engine);
            if (state == WG_ENGINE_RUNNING) {
                wg_engine_tick(_engine);
            } else if (state == WG_ENGINE_PAUSED) {
                wg_engine_tick(_engine);
                usleep(8000);
            } else {
                NSString *message = state == WG_ENGINE_STOPPED ? @"Windows program exited" : @"Windows runtime stopped / unsupported API";
                dispatch_async(dispatch_get_main_queue(), ^{ [self setStatus:message]; });
                break;
            }
        }
    }
}

- (void)renderFrame:(CADisplayLink *)link {
    (void)link;
    if (!self.commandQueue || !self.compositor) return;
    id<CAMetalDrawable> drawable = [self.metalView.metalLayer nextDrawable];
    if (!drawable) return;

    if (wg_wm_visible_count() > 0) {
        [self.compositor renderWindowsToDrawable:drawable
                                     commandQueue:self.commandQueue
                                       screenSize:self.metalView.metalLayer.drawableSize];
    } else {
        MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
        pass.colorAttachments[0].texture = drawable.texture;
        pass.colorAttachments[0].loadAction = MTLLoadActionClear;
        pass.colorAttachments[0].storeAction = MTLStoreActionStore;
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0.025, 0.03, 0.035, 1.0);
        id<MTLCommandBuffer> buffer = [self.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
        [encoder endEncoding];
        [buffer presentDrawable:drawable];
        [buffer commit];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (!_engine || !wg_engine_dialog_active(_engine)) return;
    CGPoint point = [gesture locationInView:self.metalView];
    CGSize drawable = self.metalView.metalLayer.drawableSize;
    CGSize bounds = self.metalView.bounds.size;
    if (bounds.width <= 0 || bounds.height <= 0) return;

    float px = point.x * (drawable.width / bounds.width);
    float py = point.y * (drawable.height / bounds.height);
    float scale = fminf(drawable.width / 800.0f, drawable.height / 600.0f);
    if (scale <= 0) return;
    float offsetX = (drawable.width - 800.0f * scale) * 0.5f;
    float offsetY = (drawable.height - 600.0f * scale) * 0.5f;
    int vx = (int)((px - offsetX) / scale);
    int vy = (int)((py - offsetY) / scale);
    uint32_t control = wg_engine_hit_test(_engine, vx, vy);
    if (control) wg_engine_dialog_command(_engine, control);
}

- (void)setStatus:(NSString *)text {
    self.statusLabel.text = [NSString stringWithFormat:@"MxxHub Windows Runtime\n%@\n%@", text, self.executablePath.lastPathComponent];
}

- (void)closeTapped {
    [self shutdownEngine];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)shutdownEngine {
    _engineThreadRunning = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
    if (_engine) {
        wg_engine_stop(_engine);
        [NSThread sleepForTimeInterval:0.02];
        wg_engine_destroy(_engine);
        _engine = NULL;
    }
    UIApplication.sharedApplication.idleTimerDisabled = NO;
}

@end
