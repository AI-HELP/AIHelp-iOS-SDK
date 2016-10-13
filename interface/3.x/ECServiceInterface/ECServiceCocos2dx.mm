//
//  ECServiceCocos2dx.m
//  SanguoCOK
//
//  Created by zhangwei on 16/4/12.
//
//

#import "ECServiceCocos2dx.h"
#import <ElvaChatServiceSDK/MessageViewController.h>
#import <ElvaChatServiceSDK/GetServerIP.h>
#import <ElvaChatServiceSDK/ShowWebViewController.h>
#import <ElvaChatServiceSDK/ChatMessageViewController.h>
#import <ElvaChatServiceSDK/ShowFAQListController.h>
#import <ElvaChatServiceSDK/ShowFAQSectionController.h>
#import <ElvaChatServiceSDK/ELVADBManager.h>

static NSString* elvaParseCString(const char *cstring) {
    if (cstring == NULL) {
        return NULL;
    }
    NSString * nsstring = [[NSString alloc] initWithBytes:cstring
                                                   length:strlen(cstring)
                                                 encoding:NSUTF8StringEncoding];
    return [nsstring autorelease];
}

static void elvaAddObjectToNSDict(const std::string& key, const cocos2d::Value& value, NSMutableDictionary *dict)
{
    if(value.isNull() || key.empty()) {
        return;
    }
    NSString *keyStr = [NSString stringWithCString:key.c_str() encoding:NSUTF8StringEncoding];
    if (value.getType() == cocos2d::Value::Type::MAP) {
        NSMutableDictionary *dictElement = [[NSMutableDictionary alloc] init];
        cocos2d::ValueMap subDict = value.asValueMap();
        for (auto iter = subDict.begin(); iter != subDict.end(); ++iter) {
            elvaAddObjectToNSDict(iter->first, iter->second, dictElement);
        }

        [dict setObject:dictElement forKey:keyStr];
    } else if (value.getType() == cocos2d::Value::Type::FLOAT) {
        NSNumber *number = [NSNumber numberWithFloat:value.asFloat()];
        [dict setObject:number forKey:keyStr];
    } else if (value.getType() == cocos2d::Value::Type::DOUBLE) {
        NSNumber *number = [NSNumber numberWithDouble:value.asDouble()];
        [dict setObject:number forKey:keyStr];
    } else if (value.getType() == cocos2d::Value::Type::BOOLEAN) {
        NSNumber *element = [NSNumber numberWithBool:value.asBool()];
        [dict setObject:element forKey:keyStr];
    } else if (value.getType() == cocos2d::Value::Type::INTEGER) {
        NSNumber *element = [NSNumber numberWithInt:value.asInt()];
        [dict setObject:element forKey:keyStr];
    } else if (value.getType() == cocos2d::Value::Type::STRING) {
        NSString *strElement = [NSString stringWithCString:value.asString().c_str() encoding:NSUTF8StringEncoding];
        [dict setObject:strElement forKey:keyStr];
    } else if (value.getType() == cocos2d::Value::Type::VECTOR) {
        NSMutableArray *arrElement = [NSMutableArray array];
        cocos2d::ValueVector array = value.asValueVector();

        NSMutableString * NtagValue  = [[NSMutableString alloc]init];
        for(int i = 0; i <array.size();i++ ){
            std::string tag =  array[i].asString();
            NSString * test = elvaParseCString(tag.c_str());
            if(i >0){
                [NtagValue appendString: @","];
            }
            [NtagValue appendString: test];    
        }
        [dict setObject:NtagValue forKey:keyStr];
    }
}

static NSMutableDictionary * elvaValueMapToNSDictionary(cocos2d::ValueMap& dict) {
    NSMutableDictionary *nsDict = [NSMutableDictionary dictionary];
    for (auto iter = dict.begin(); iter != dict.end(); ++iter)
    {
        elvaAddObjectToNSDict(iter->first, iter->second, nsDict);
    }
    return nsDict;
}
//custom data 转成json字符串
static NSString* elvaParseConfig(cocos2d::ValueMap& config) {
    // if (config == NULL) {
    //     return @"";
    // }
    cocos2d::ValueMap customerData = config["hs-custom-metadata"].asValueMap();
    // if(customerData == NULL){
    //     return @"";
    // }
    NSMutableDictionary *data = elvaValueMapToNSDictionary(customerData);
    NSMutableDictionary *map = [[NSMutableDictionary  alloc]initWithCapacity:0];
    [map setObject:data forKey:@"hs-custom-metadata"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:map
                                                       options:0
                                                         error:nil];
    //把json 转成 nsstring
    NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [jsonString autorelease];
}

#pragma mark - 初始化init
void ECServiceCocos2dx::init(string appSecret,string domain,string appId) {
    NSString* NSAppId = elvaParseCString(appId.c_str());
    NSString* NSAppSecret = elvaParseCString(appSecret.c_str());
    NSString* NSDomain = elvaParseCString(domain.c_str());

    [GetServerIP getServerMsgWithAppId:NSAppSecret
                                    Domain:NSDomain
                                    appId:NSAppId
                                    ];
}
#pragma mark - show 不带参数config
void ECServiceCocos2dx::showElva(string playerName,string playerUid,int serverId,string playerParseId,string playershowConversationFlag){
    
    NSString* NSuserName = elvaParseCString(playerName.c_str());

    NSString* NSuserId = elvaParseCString(playerUid.c_str());

    NSString* parseId = elvaParseCString(playerParseId.c_str());

    NSString* conversationFlag = elvaParseCString(playershowConversationFlag.c_str());
    
    [UIApplication sharedApplication].keyWindow.backgroundColor = [UIColor whiteColor];
    //初始化KCMainViewController
    MessageViewController *mainController=[MessageViewController getMessageData];
    
    //vipchat
    mainController.vipChat =conversationFlag;
    
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    //playerParseId
    faqUrl.playerParseId = parseId;
    
    //serverId
    faqUrl.serverId =serverId;
    
    [mainController initParamsWithUserName:NSuserName  UserId:NSuserId Title:@"ElvaChatService"];
    //设置自定义控制器的大小和window相同，位置为（0，0）
    mainController.view.frame=[UIApplication sharedApplication].keyWindow.bounds;
    //设置此控制器为window的根控制器
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:mainController animated:YES completion:^{
                nil;
            }];
    
}

#pragma mark - show 带参数config
void ECServiceCocos2dx::showElva(string playerName,string playerUid,int serverId,string playerParseId,string playershowConversationFlag,cocos2d::ValueMap& config) {
    
    NSString* NSuserName = elvaParseCString(playerName.c_str());
    
    NSString* NSuserId = elvaParseCString(playerUid.c_str());
    
    NSString* parseId = elvaParseCString(playerParseId.c_str());
    
    NSString *conversationFlag =elvaParseCString(playershowConversationFlag.c_str());
    
    
    NSString * jsonString = elvaParseConfig(config);
    
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    faqUrl.customerData = jsonString;
    
    //playerParseId
    faqUrl.playerParseId = parseId;
    
    //serverId
    faqUrl.serverId =serverId;
    
    [UIApplication sharedApplication].keyWindow.backgroundColor = [UIColor whiteColor];
    
    //初始化KCMainViewController
    MessageViewController *mainController=[MessageViewController getMessageData];
    //vipchat
    mainController.vipChat =conversationFlag;
    
    
    
    [mainController initParamsWithUserName:NSuserName UserId:NSuserId Title:@"ElvaChatService"];
    //设置自定义控制器的大小和window相同，位置为（0，0）
    mainController.view.frame=[UIApplication sharedApplication].keyWindow.bounds;
    //设置此控制器为window的根控制器
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:mainController animated:YES completion:^{
        nil;
    }];
}



#pragma mark - faq参数为faqID
void ECServiceCocos2dx::showSingleFAQ(string faqId) {
    cocos2d::ValueMap config;
    showSingleFAQ(faqId,config);
}

#pragma mark - faq参数为faqID 带config
void ECServiceCocos2dx::showSingleFAQ(string faqId,cocos2d::ValueMap& config) {
    
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    if(!config["showConversationFlag"].isNull()){
        faqUrl.showVipChat=@"1";
    }else{
        faqUrl.showVipChat=nil;
    }
    //把json 转成 nsstring
    if(config.size()>0){
        NSString * jsonString = elvaParseConfig(config);
        faqUrl.customerData = jsonString;
    }
    ShowWebViewController *showWebView = [[ShowWebViewController alloc]init];
    NSString *faqid = elvaParseCString(faqId.c_str());
    
    NSString * appId = faqUrl.appId;
    showWebView.isShowManue = true;//首次打开显示菜单
    //判断是否存在userID，没有就不显示自助服务
    if(faqUrl.userId == nil || [faqUrl.userId isEqualToString:@""]){
        showWebView.isShowUserSelfBtn = true;
    }else{
        showWebView.isShowUserSelfBtn = false;
    }
    [showWebView showSelfInterface:faqid];//展示自助服务
    
    ELVADBManager *db = [ELVADBManager getSharedInstance];
    NSString *faqContent =  [db getFaqByPublishId:faqid];
    if(faqContent){//默认查询本地数据库，如果查询不到就从服务器查询
        showWebView.isShowFaqList = true;
        showWebView.contentStr = faqContent;
    }else{
        NSString *showfaqs = faqUrl.showUrl;
        //获取本地语言
        NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
        NSArray  *languages = [defs objectForKey:@"AppleLanguages"];
        NSString *preferredLang = [languages objectAtIndex:0];
        NSString * type = @"3";
        NSString* url =[NSString stringWithFormat:@"%@?type=%@&appid=%@&l=%@&faqid=%@",showfaqs,type,appId,preferredLang,faqid];
        showWebView.url = [NSURL URLWithString:url];
    }
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:showWebView animated:YES completion:^{
        nil;
    }];
    
}

#pragma mark - showFAQSection
void ECServiceCocos2dx::showFAQSection(string sectionPublishId){
    cocos2d::ValueMap config;
    showFAQSection(sectionPublishId, config);
}

#pragma mark - showFAQSection(带config)
void ECServiceCocos2dx::showFAQSection(string sectionPublishId,cocos2d::ValueMap& config){
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    if(!config["showConversationFlag"].isNull()){
        faqUrl.showVipChat=@"1";
    }else{
        faqUrl.showVipChat=nil;
    }
    //把json 转成 nsstring
    if(config.size()>0){
        NSString * jsonString = elvaParseConfig(config);
        faqUrl.customerData = jsonString;
    }
    
    NSString *sectionId = elvaParseCString(sectionPublishId.c_str());
    
    
    
    ELVADBManager *db = [ELVADBManager getSharedInstance];
    NSMutableArray *faqsArray = [db getFaqsBySectionId:sectionId];
    if(nil != faqsArray)
    {
        ShowFAQSectionController *showWebView = [[ShowFAQSectionController alloc]init];
        showWebView.isShowManue = true;//首次打开显示菜单
        //判断是否存在userID，没有就不显示自助服务
        if(faqUrl.userId == nil || [faqUrl.userId isEqualToString:@""]){
            showWebView.isShowUserSelfBtn = true;
        }else{
            showWebView.isShowUserSelfBtn = false;
        }
        showWebView.sectionId = sectionId;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:showWebView animated:YES completion:^{
            nil;
        }];
        
    }else{
        ShowWebViewController *webView = [[ShowWebViewController alloc]init];
         NSString *showfaqs = faqUrl.showUrl;
        webView.isShowManue = true;//首次打开显示菜单
        //判断是否存在userID，没有就不显示自助服务
        if(faqUrl.userId == nil || [faqUrl.userId isEqualToString:@""]){
            webView.isShowUserSelfBtn = true;
        }else{
            webView.isShowUserSelfBtn = false;
        }
        //获取本地语言
        NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
        NSArray  *languages = [defs objectForKey:@"AppleLanguages"];
        NSString *preferredLang = [languages objectAtIndex:0];
        NSString *appid = faqUrl.appId;
        NSString *type = @"2";
        NSString* url =[NSString stringWithFormat:@"%@?type=%@&appid=%@&l=%@&sectionid=%@",showfaqs,type,appid,preferredLang,sectionId];
        
        webView.url = [NSURL URLWithString:url];
        webView.loadingBarTintColor = [UIColor blueColor];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:webView animated:YES completion:^{
            nil;
        }];
    }

}


#pragma mark - faqList无参数
void ECServiceCocos2dx::showFAQs() {
    cocos2d::ValueMap config;
    showFAQs(config);
   }

#pragma mark - showFAQList 带参数config
void ECServiceCocos2dx::showFAQs(cocos2d::ValueMap& config) {
    
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    if(!config["showConversationFlag"].isNull()){
        faqUrl.showVipChat=@"1";
        config["showConversationFlag"];
    }else{
        faqUrl.showVipChat=nil;
    }
    //把json 转成 nsstring
    if(config.size()>0){
        NSString * jsonString = elvaParseConfig(config);
        faqUrl.customerData = jsonString;
    }
    
    ELVADBManager *db = [ELVADBManager getSharedInstance];
    NSMutableArray * sectionsArray = [db getAllSections];
    if(nil != sectionsArray)
    {
        ShowFAQListController *show = [[ShowFAQListController alloc]init];
        show.isShowManue = true;//首次打开显示菜单
        //判断是否存在userID，没有就不显示自助服务
        if(faqUrl.userId == nil || [faqUrl.userId isEqualToString:@""]){
            show.isShowUserSelfBtn = true;
        }else{
            show.isShowUserSelfBtn = false;
        }
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:show animated:YES completion:^{
            nil;
        }];
    }else{
        
        NSString *showfaqs = faqUrl.showfaqlist;
        NSString *appId = faqUrl.appId;
        
        //获取本地语言
        NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
        NSArray* languages = [defs objectForKey:@"AppleLanguages"];
        NSString* preferredLang = [languages objectAtIndex:0];
        
        ShowWebViewController *showWebView = [[ShowWebViewController alloc]init];
        NSString * type = @"1";
        NSString* url =[NSString stringWithFormat:@"%@?type=%@&appid=%@&l=%@",showfaqs,type,appId,preferredLang];
        //    NSString* url =[NSString stringWithFormat:@"%@?AppID=%@&l=%@",showfaqs,appId,preferredLang];
        
        NSURLCache *urlCache = [NSURLCache sharedURLCache];
        /* 设置缓存的大小为1M*/
        [urlCache setMemoryCapacity:1*1024*1024];
        //创建一个nsurl
        NSURL *cacheUrls = [NSURL URLWithString:url];
        //        showWebView.url = [NSURL URLWithString:url];
        showWebView.url =cacheUrls;
        
        //创建一个请求
        NSMutableURLRequest *request =
        [NSMutableURLRequest
         requestWithURL: showWebView.url
         cachePolicy:NSURLRequestReloadRevalidatingCacheData
         timeoutInterval:60.0f];
        //从请求中获取缓存输出
        NSCachedURLResponse *response =
        [urlCache cachedResponseForRequest:request];
        //判断是否有缓存
        if (response != nil){
            // NSLog(@"如果有缓存输出，从缓存中获取数据");
            [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
        }
        showWebView.isShowManue = true;//首次打开显示菜单
        //判断是否存在userID，没有就不显示自助服务
        if(faqUrl.userId == nil || [faqUrl.userId isEqualToString:@""]){
            showWebView.isShowUserSelfBtn = true;
        }else{
            showWebView.isShowUserSelfBtn = false;
        }
        
        showWebView.loadingBarTintColor = [UIColor blueColor];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:showWebView animated:YES completion:^{
            nil;
        }];

    }
    
    
    
    
}

#pragma mark - 设置游戏名称
void ECServiceCocos2dx::setName(string game_name){
     GetServerIP* faqUrl = [GetServerIP getFaqService];
     NSString* gameName  = elvaParseCString(game_name.c_str());
     [faqUrl setGameName:gameName];

}

#pragma mark - 设置deviceToken
void ECServiceCocos2dx::registerDeviceToken(string deviceToken) {

    GetServerIP* faqUrl = [GetServerIP getFaqService];
     NSString* token = elvaParseCString(deviceToken.c_str());
    faqUrl.isToken = true;
    faqUrl.deviceToken =token;
    
}
#pragma mark - 设置UserId
void ECServiceCocos2dx::setUserId(string playerUid)
{
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    NSString* userId = elvaParseCString(playerUid.c_str());
    faqUrl.userId = userId;
    
}
#pragma mark - 设置ServerId
void ECServiceCocos2dx::setServerId(int serverId)
{
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    faqUrl.serverId = serverId;

}

#pragma mark - 设置userName
void ECServiceCocos2dx::setUserName(string playerName)
{
    GetServerIP* faqUrl = [GetServerIP getFaqService];
     NSString* userName = elvaParseCString(playerName.c_str());
    faqUrl.userName = userName;
    
}
#pragma mark - 设置showConversation
void ECServiceCocos2dx::showConversation(string playerUid,int serverId){
    
    [UIApplication sharedApplication].keyWindow.backgroundColor = [UIColor whiteColor];
    //初始化KCMainViewController
    ChatMessageViewController *messageView = [[ChatMessageViewController alloc] init];
    
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    //serverId
    faqUrl.serverId =serverId;
    messageView.type = @"1";
    NSString* NSuserId = elvaParseCString(playerUid.c_str());
    NSString *userName = faqUrl.userName;
    if(userName != nil){
        [messageView initParamsWithUserName:userName UserId:NSuserId Title:@"ElvaChatService"];
    }else{
        [messageView initParamsWithUserName:@"anonymous" UserId:NSuserId Title:@"ElvaChatService"];
    }
    //设置自定义控制器的大小和window相同，位置为（0，0）
    messageView.view.frame=[UIApplication sharedApplication].keyWindow.bounds;
    //设置此控制器为window的根控制器
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:messageView animated:YES completion:^{
        nil;
    }];
    

}
#pragma mark - 设置showConversation带config
void ECServiceCocos2dx::showConversation(string playerUid,int serverId,cocos2d::ValueMap& config){
    NSString * jsonString = elvaParseConfig(config);
    GetServerIP* faqUrl = [GetServerIP getFaqService];
    faqUrl.customerData = jsonString;
    //serverId
    faqUrl.serverId =serverId;
    
    [UIApplication sharedApplication].keyWindow.backgroundColor = [UIColor whiteColor];
    //初始化KCMainViewController
    ChatMessageViewController *messageView = [[ChatMessageViewController alloc] init];
    messageView.type = @"1";
    NSString* NSuserId = elvaParseCString(playerUid.c_str());
    NSString *userName = faqUrl.userName;
    if(userName != nil){
        [messageView initParamsWithUserName:userName UserId:NSuserId Title:@"ElvaChatService"];
    }else{
        [messageView initParamsWithUserName:@"anonymous" UserId:NSuserId Title:@"ElvaChatService"];
    }
    
    //设置自定义控制器的大小和window相同，位置为（0，0）
    messageView.view.frame=[UIApplication sharedApplication].keyWindow.bounds;
    //设置此控制器为window的根控制器
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:messageView animated:YES completion:^{
        nil;
    }];

}
