//
//  ViewController.m
//  Example
//
//  Created by joshua li on 15/9/12.
//
//

#import "ViewController.h"

#import "CaptureViewController.h"

@interface ViewController ()
@property(strong, nonatomic) CaptureViewController *vc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    let bundle = NSBundle(forClass: CaptureViewController.self)
//    let captureViewCon = CaptureViewController(nibName: "CaptureViewController", bundle: bundle)
    NSBundle *bundel = [NSBundle bundleForClass:[CaptureViewController class]];
    _vc = [[CaptureViewController alloc] initWithNibName:@"CaptureViewController" bundle:bundel];
    

    
}

- (IBAction)onTap:(id)sender {
    _vc.view.frame = CGRectMake(0, -100, 320, 568);
    [self.view addSubview:_vc.view];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _vc.view.frame = CGRectMake(0, -100, 320, 568);
    [self.view addSubview:_vc.view];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
