//
//  ViewController.m
//  SimpleCoreMLBenchmark
//
//  Created by Koan-Sin Tan on 2020/12/2.
//

#import "ViewController.h"

#import "DeepLabV3_ADE20K.h"
#import "MobileNet_EdgeTPU.h"
#import "MobileNetV2_SSD.h"
#import "MobileBERT_384.h"

@interface ViewController () {
    bool enableGPU;
    bool enableCoreML;
    int numberOfThreads;
    NSArray *_cpuGPUData;
    NSArray *_numberOfThreadsData;
    NSArray *_modelNames;

    NSString *modelName;
    MLModelConfiguration *mc;
    MLModel *model;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _runtimePicker.tag = 0;
    _threadPicker.tag = 1;
    
    enableGPU = false;
    enableCoreML = false;
    numberOfThreads = 1;
    
    _cpuGPUData = @[@"CPU", @"GPU", @"CoreML"];
    _numberOfThreadsData = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"];
    _modelNames = @[@"MobileNet EdgeTPU", @"SSD MobileNet V2",
                    @"DeepLabV3 ADE20K", @"MobileBERT"];
    modelName = @"MobileNet EdgeTPU";
    
    mc = [[MLModelConfiguration alloc] init];
    mc.computeUnits = MLComputeUnitsCPUOnly;
    model = (MLModel *) [[MobileBERT_384 alloc] initWithConfiguration:mc error:nil];
    
    [self setupCamera];
}


- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([pickerView tag] == 0)
        return 3;
    else
        return [_numberOfThreadsData count];
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([pickerView tag] == 0)
        return _cpuGPUData[row];
    else
        return _numberOfThreadsData[row];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    // NSLog(@"tag, row, c: %ld, %ld, %ld ", [pickerView tag], (long)row, (long)component);
    if ([pickerView tag] == 0) {
        switch (row) {
        case 0:
            enableGPU = false;
            enableCoreML = false;
            mc.computeUnits = MLComputeUnitsCPUOnly;
            break;
        case 1:
            enableGPU = true;
            enableCoreML = false;
            mc.computeUnits = MLComputeUnitsCPUAndGPU;
            break;
        case 2:
            enableGPU = false;
            enableCoreML = true;
            mc.computeUnits = MLComputeUnitsAll;
            break;
        }
    } else {
        numberOfThreads = (int) row + 1;
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyIdentifier"];
    }
    
    // Set up the cell
    id item = _modelNames[[indexPath row]];
    
    cell.textLabel.text = [item description];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_modelNames count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%ld, %@", (long)indexPath.row, _modelNames[indexPath.row]); // you can see selected row number in your console;
    modelName = _modelNames[indexPath.row];
    
    if (modelName == _modelNames[0]) {
        model = (MLModel *)[[MobileNet_EdgeTPU alloc] initWithConfiguration:mc error: nil];
    } else if (modelName == _modelNames[1]) {
        model = (MLModel *)[[MobileNetV2_SSD alloc] initWithConfiguration:mc error: nil];
    } else if (modelName == _modelNames[2]) {
        model = (MLModel *)[[DeepLabV3_ADE20K alloc] initWithConfiguration:mc error: nil];
    } else if (modelName == _modelNames[3]) {
        model = (MLModel *)[[MobileBERT_384 alloc] initWithConfiguration:mc error: nil];
    } else {
        NSLog(@"How come %@", modelName);
    }
}

- (IBAction)run:(id)sender {
    NSObject<MLFeatureProvider> *input;
    CVPixelBufferRef b;
    
    NSLog(@"model name = %@", modelName);
    if (modelName == _modelNames[0]) {
        CVPixelBufferCreate(NULL, 224, 224, kCVPixelFormatType_32ARGB, NULL, &b);
        input = [[MobileNet_EdgeTPUInput alloc] initWithImages: b];
    } else if (modelName == _modelNames[1]) {
        CVPixelBufferCreate(NULL, 300, 300, kCVPixelFormatType_32ARGB, NULL, &b);
        input = [[MobileNetV2_SSDInput alloc] initWithImage: b iouThreshold: 0.00001 confidenceThreshold:0.000001];
    } else if (modelName == _modelNames[2]) {
        CVPixelBufferCreate(NULL, 512, 512, kCVPixelFormatType_32ARGB, NULL, &b);
        input = [[DeepLabV3_ADE20KInput alloc] initWithImageTensor: b];
    } else if (modelName == _modelNames[3]) {
        NSArray *ids_shape = [NSArray arrayWithObjects: [NSNumber numberWithInt:1], [NSNumber numberWithInt:384], nil];
        MLMultiArray *ids = [[MLMultiArray alloc] initWithShape: ids_shape dataType: MLMultiArrayDataTypeFloat error:nil];
        MLMultiArray *masks = [[MLMultiArray alloc] initWithShape: ids_shape dataType: MLMultiArrayDataTypeFloat error:nil];
        MLMultiArray *segment_ids = [[MLMultiArray alloc] initWithShape: ids_shape dataType: MLMultiArrayDataTypeFloat error:nil];
        input  = [[MobileBERT_384Input alloc] initWithInput_ids:ids input_mask:masks segment_ids:segment_ids];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval start, stop;
        
        for (int i=0; i < 5; i++) {
            [self->model predictionFromFeatures:input error:nil];
        }
        
        int runs = 50;
        start = [[NSDate date] timeIntervalSince1970];
        for (int i=0; i < runs; i++) {
            [self->model predictionFromFeatures: input error: NULL];
        }
        stop = [[NSDate date] timeIntervalSince1970];
        self->_resultText.text = [NSString stringWithFormat: @"%f ms", ((stop - start) * 1000 / runs)];
    });
    
    // [model predictionFromImages:b error:NULL];
    
}

- (void) setupCamera {
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];

    inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];

    if ([session canAddInput:deviceInput]) {
        [session addInput:deviceInput];
    }

    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.view.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];

    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];

    NSDictionary *rgbOutputSettings = [NSDictionary
                                       dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA]
                                       forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [videoDataOutput setVideoSettings:rgbOutputSettings];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];

    if ([session canAddOutput:videoDataOutput])
        [session addOutput:videoDataOutput];
    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];

    [session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
}
@end
