//
//  ViewController.h
//  SimpleCoreMLBenchmark
//
//  Created by Koan-Sin Tan on 2020/12/2.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource, AVCaptureVideoDataOutputSampleBufferDelegate> {
   AVCaptureSession *session;
   AVCaptureDevice *inputDevice;
   AVCaptureDeviceInput *deviceInput;
   AVCaptureVideoPreviewLayer *previewLayer;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *modelTable;
@property (weak, nonatomic) IBOutlet UITextView *resultText;
@property (weak, nonatomic) IBOutlet UIPickerView *runtimePicker;
@property (weak, nonatomic) IBOutlet UIPickerView *threadPicker;

- (IBAction)run:(id)sender;

@end

