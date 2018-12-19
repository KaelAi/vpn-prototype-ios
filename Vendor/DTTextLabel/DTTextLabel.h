//
//  DTTextLabel.h
//  PFIMCLient
//
//

#import <UIKit/UIKit.h>

/**
 解析带有标签的字符串。
 目前支持的标签：
 1. <inapplink>这些文本下面会有下划线</inapplink>
 2. <font color=#FF0000>这些文本会被加上颜色</font>
 */

@interface DTTextLabelFont : NSObject
@property (nonatomic,assign)NSRange fontTextRange; //显示字符串中需要加颜色标记的位置
@property (nonatomic,retain)UIColor* fontTextColor; //显示字符串中加颜色标注使用的颜色
@end

@interface DTTextLabelLink: NSObject
@property (nonatomic,assign)NSRange linkRange;    //显示字符串中需要加下划线的位置
@property (nonatomic,retain)UIColor* linkColor;   //下划线颜色
@end

@interface DTTextDecoder : NSObject
@property (nonatomic,retain)NSString* strOriginal; //传入的带有特殊标签的原始文本
@property (nonatomic,retain)NSString* strDisplay; //去掉特殊标签后显示到界面上的纯文本

@property (nonatomic,retain)NSMutableArray* arrayLink;
@property (nonatomic,retain)NSMutableArray* arrayFont;

-(instancetype)initWithText:(NSString*)text;
@end


// --------------------------------------------------------------------- //

/**
 使用这个Label来显示带标签的字符串，会自动去加下划线，给部分文字增加颜色
 */
@interface DTTextLabel : UILabel
//扩展变量，某些情况下可用来存储DTRichTextLabel相关的上下文数据
@property (nonatomic,retain) id userData;


/*
 auto add link to range from <inapplink> to </inapplink>
 */
- (void)setDTText:(NSString*)text linkURL:(NSURL*)url;

- (void)setDTText:(NSString*)text linkURL:(NSURL*)url attrDict:(NSMutableDictionary *)arrtDict;

@end
