//
//  ViewController.m
//  iOSHttpsDemo
//
//  Created by zhqMAC on 2018/11/22.
//  Copyright © 2018 zhqMAC. All rights reserved.
//


#import "ViewController.h"

@interface ViewController ()<NSURLSessionTaskDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self httpsRequest];
}
-(void)httpsRequest{
    // 1.创建一个网络路径
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/test",@"https://localhost:8081"]];
    // 2.创建一个网络请求，分别设置请求方法、请求参数
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    NSDictionary *params = @{
                             @"name":@"name",
                             };
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil]];
    // 3.获得会话对象,设置代理,证书验证在代理中实现
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    // 4.根据会话对象，创建一个Task任务
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"从服务器获取到数据");
        NSLog(@"%@",response);
        NSLog(@"%@",error);
        
    }];
    //5.最后一步，执行任务，(resume也是继续执行)。
    [sessionDataTask resume];
}
#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable ))completionHandler{
    __autoreleasing NSURLCredential *credential =nil;
    
    SecTrustRef servertrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef certi= SecTrustGetCertificateAtIndex(servertrust, 0);
    NSData *certidata = CFBridgingRelease(CFBridgingRetain(CFBridgingRelease(SecCertificateCopyData(certi))));
    //指定服务端证书
    NSString *path = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"der"];
    NSData *localCertiData = [NSData dataWithContentsOfFile:path];
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([certidata isEqualToData:localCertiData]) {
            NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:servertrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            NSLog(@"服务端证书认证通过");
        }else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            NSLog(@"服务端认证失败");
        }
    }else {
        
        // client authentication
        
        SecIdentityRef identity = NULL;
        
        SecTrustRef trust = NULL;
        //指定客户端证书
        NSString *p12 = [[NSBundle mainBundle] pathForResource:@"client"ofType:@"p12"];
        
        NSFileManager *fileManager =[NSFileManager defaultManager];
        
        if(![fileManager fileExistsAtPath:p12])
            
        {
            
            NSLog(@"client.p12:not exist");
            
        }
        
        else
            
        {
            
            NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
            
            if ([[self class]extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data])
                
            {
                
                SecCertificateRef certificate = NULL;
                
                SecIdentityCopyCertificate(identity, &certificate);
                
                const void*certs[] = {certificate};
                
                CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
                credential =[NSURLCredential credentialWithIdentity:identity certificates:(__bridge  NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
                
                //                disposition = NSURLSessionAuthChallengeUseCredential;
                
            }
            
        }
        
    }
    //    *_credential = credential;
    
}
+ (BOOL)extractIdentity:(SecIdentityRef*)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
    
    OSStatus securityError = errSecSuccess;
    
    //生成p12是，输入的密码
    NSDictionary*optionsDictionary = [NSDictionary dictionaryWithObject:@"123"
                                      
                                                                 forKey:(__bridge id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    
    securityError = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);
    
    if(securityError == 0) {
        
        CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
        
        const void*tempIdentity =NULL;
        
        tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
        
        *outIdentity = (SecIdentityRef)tempIdentity;
        
        const void*tempTrust =NULL;
        
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
        
        *outTrust = (SecTrustRef)tempTrust;
        
    } else {
        
        NSLog(@"Failedwith error code %d",(int)securityError);
        
        return NO;
        
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
