//
//  ViewController.m
//  YYQRCode
//
//  Created by ayong on 2017/8/13.
//  Copyright © 2017年 ayong. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define kUIscreenH [UIScreen mainScreen].bounds.size.height
#define kUIscreenW  [UIScreen mainScreen].bounds.size.width
#define kUIscreenB  [UIScreen mainScreen].bounds

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, assign) NSInteger num;
@property (nonatomic, assign) BOOL upOrdown;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) AVCaptureDevice * device;
@property (nonatomic, strong) AVCaptureDeviceInput * input;
@property (nonatomic, strong) AVCaptureMetadataOutput * output;
@property (nonatomic, strong) AVCaptureSession * session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * preview;
@property (nonatomic, strong) UIImageView * line;
@property (nonatomic, strong) NSTimer *time;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kUIscreenW/2 - 110, kUIscreenH/2 - 110, 220, 220)];
    imageView.image = [UIImage imageNamed:@"pick_bg"];
    [self.view addSubview:imageView];
    
    self.upOrdown = NO;
    self.num =0;
    self.line = [[UIImageView alloc] initWithFrame:CGRectMake(kUIscreenW/2 - 110, kUIscreenH/2 - 110, 220, 2)];
    self.line.image = [UIImage imageNamed:@"line.png"];
    [self.view addSubview:self.line];
    
    self.shapeLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, imageView.frame);
    CGPathAddRect(path, nil, self.view.bounds);
    
    [self.shapeLayer setFillRule:kCAFillRuleEvenOdd];
    [self.shapeLayer setPath:path];
    [self.shapeLayer setFillColor:[UIColor lightGrayColor].CGColor];
    [self.shapeLayer setOpacity:0.6];
    [self.shapeLayer setNeedsDisplay];
    [self.view.layer addSublayer:self.shapeLayer];

    self.time = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(lineAnimation) userInfo:nil repeats:YES];
}


-(void)viewWillAppear:(BOOL)animated{
    [self performSelector:@selector(setupCamera) withObject:nil afterDelay:0.3];
    
}

-(void)lineAnimation{
    
    self.num ++;
    self.line.frame = CGRectMake(kUIscreenW/2 - 110, kUIscreenH/2 - 100 + 2*self.num, 220, 2);
    if (self.num * 2 > 220) {
        self.num = 0;
        self.line.frame = CGRectMake(kUIscreenW/2 - 110, kUIscreenH/2 - 100 + 2*self.num, 220, 2);
    }
}

- (void)setupCamera
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device==nil) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"设备没有摄像头" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    // Device
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output
    self.output = [[AVCaptureMetadataOutput alloc]init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.output setRectOfInterest:kUIscreenB];
    //设置扫描区域
//    CGFloat top = TOP/SCREEN_HEIGHT;
//    CGFloat left = LEFT/SCREEN_WIDTH;
//    CGFloat width = 220/SCREEN_WIDTH;
//    CGFloat height = 220/SCREEN_HEIGHT;
//    ///top 与 left 互换  width 与 height 互换
//    [_output setRectOfInterest:CGRectMake(top,left, height, width)];
    
    
    // Session
    self.session = [[AVCaptureSession alloc]init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.session canAddInput:self.input])
    {
        [self.session addInput:self.input];
    }
    
    if ([self.session canAddOutput:self.output])
    {
        [self.session addOutput:self.output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    [self.output setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeQRCode, nil]];
    
    // Preview
    self.preview =[AVCaptureVideoPreviewLayer layerWithSession:_session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame =self.view.layer.bounds;
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    // Start
    [self.session startRunning];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;
    
    if ([metadataObjects count] >0)
    {
        //停止扫描
        [_session stopRunning];
        [self.time setFireDate:[NSDate distantFuture]];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
        NSLog(@"扫描结果：%@",stringValue);
        
        NSArray *arry = metadataObject.corners;
        for (id temp in arry) {
            NSLog(@"%@",temp);
        }
        
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果" message:stringValue preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_session != nil && self.time != nil) {
                [_session startRunning];
                [self.time setFireDate:[NSDate date]];
            }
            
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        
    } else {
        NSLog(@"无扫描信息");
        return;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
