//
//  DTTextLabel.m
//  PFIMCLient
//
//

#import "DTTextLabel.h"
#import "types.h"

@implementation DTTextLabelFont

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.fontTextColor = [UIColor colorWithRed:1.0 green:168/255.0 blue:168/255.0 alpha:1.0];
    }
    
    return self;
}

-(void)dealloc
{
    self.fontTextColor = nil;
    [super dealloc];
}
@end

@implementation DTTextLabelLink

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.linkColor = [UIColor defaultStrongBlueColor];
    }
    
    return self;
}

-(void)dealloc
{
    self.linkColor = nil;
    [super dealloc];
}
@end

@implementation DTTextDecoder

-(instancetype)initWithText:(NSString*)text
{
    self = [super init];
    if(self){
        self.strOriginal = text;
        self.strDisplay = text;//默认显示全部
        self.arrayLink = [NSMutableArray array];
        self.arrayFont = [NSMutableArray array];
        //解析字符串
        [self decodeRichText];
    }
    
    return self;
}

-(void)dealloc
{
    self.strOriginal = nil;
    self.strDisplay = nil;
    self.arrayFont = nil;
    self.arrayLink = nil;
    [super dealloc];
}

#pragma mark - Decode Text
- (void)decodeRichText
{
    NSString* display = self.strDisplay;
    
    while (display.length > 0) {
        NSUInteger lenOld = display.length;
        
        NSRange rangeFontStart = [display rangeOfString:@"<font [^<]*?>" options:NSRegularExpressionSearch];
        NSRange rangeLinkStart = [display rangeOfString:@"<inapplink>" options:NSRegularExpressionSearch];
        rangeLinkStart.length = 0;//test
        if (rangeFontStart.length > 0 && rangeLinkStart.length > 0) {
            if (rangeLinkStart.location < rangeFontStart.location) {
                display = [self decodeLinkEnd:display];
            }
            else{
                display = [self decodeFontEnd:display];
            }
        }
        else if (rangeFontStart.length > 0){
            display = [self decodeFontEnd:display];
        }
        else if (rangeLinkStart.length > 0){
            display = [self decodeLinkEnd:display];
        }
        else{
            break;
        }
        
        if (lenOld == display.length) {
            break;//防止死循环
        }
    }
}

- (NSString*)decodeLinkEnd:(NSString*)display
{
    return display;
//    NSString* display = self.strDisplay;
//    NSRange rangeLinkStart = [display rangeOfString:@"<inapplink>"];
//    NSRange rangeLinkEnd = [display rangeOfString:@"</inapplink>"];
//    if (rangeLinkStart.length > 0 && rangeLinkEnd.length > 0 && rangeLinkEnd.location > rangeLinkStart.location) {
//        display = [display stringByReplacingOccurrencesOfString:@"<inapplink>" withString:@""];
//        display = [display stringByReplacingOccurrencesOfString:@"</inapplink>" withString:@""];
//        
//        NSRange range;
//        range.location = rangeLinkStart.location;
//        range.length = rangeLinkEnd.location - rangeLinkStart.location - rangeLinkStart.length;
//        
//        //获取加下划线range
//        self.linkRange = range;
//        //更新显示字符串
//        self.strDisplay = display;
//    }
}

- (NSString*)decodeFontEnd:(NSString*)display
{
    NSRange rangeFontStart = [display rangeOfString:@"<font [^<]*?>" options:NSRegularExpressionSearch];
    NSRange rangeFontEnd = [display rangeOfString:@"</font>"];
    if (rangeFontStart.length > 0 && rangeFontEnd.length > 0 && rangeFontEnd.location > rangeFontStart.location) {
        
        DTTextLabelFont* aFontItem = [[[DTTextLabelFont alloc] init] autorelease];
        [self.arrayFont addObject:aFontItem];
        
        //颜色 <font color=#FF0000>
        NSString* strFontValue = [display substringWithRange:rangeFontStart];
        NSRange rangeFontValue = [strFontValue rangeOfString:@"color="];
        if (rangeFontValue.length > 0) {
            NSRange rangeColor;
            rangeColor.location = rangeFontValue.length + rangeFontValue.location;
            rangeColor.length = strFontValue.length - rangeColor.location - 1;
            
            NSString* strColor = [strFontValue substringWithRange:rangeColor];
            UIColor* color = [self colorWithHexString:strColor];
            if (color) {
                aFontItem.fontTextColor = color;
            }
        }
        
        //更新显示字符串
        display = [display stringByReplacingCharactersInRange:rangeFontStart withString:@""];
        NSRange rangeFontEndNew = [display rangeOfString:@"</font>"];
        display = [display stringByReplacingCharactersInRange:rangeFontEndNew withString:@""];
        self.strDisplay = display;
        
        //获取range
        NSRange range;
        range.location = rangeFontStart.location;
        range.length = rangeFontEnd.location - rangeFontStart.location - rangeFontStart.length;
        aFontItem.fontTextRange = range;
    }
    
    return display;
}

- (UIColor *) colorWithHexString: (NSString *)color
{
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return nil;
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return nil;
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}
@end

#pragma mark -

@interface DTTextLabel ()
@property (nonatomic,assign)NSRange actionLinkRange;
@end

@implementation DTTextLabel
@synthesize userData;
@synthesize actionLinkRange;

-(void)dealloc
{
    self.userData = nil;
    [super dealloc];
}

- (void)setDTText:(NSString*)text linkURL:(NSURL*)url
{
    DTTextDecoder* decoder = [[[DTTextDecoder alloc] initWithText:text] autorelease];
    
    NSMutableAttributedString *strAttribute = [[[NSMutableAttributedString alloc] initWithString:decoder.strDisplay] autorelease];
    if (ios6) {
        //下划线
//        if (decoder.linkRange.length != 0) {
//            [strAttribute addAttribute:NSForegroundColorAttributeName value:decoder.linkColor range:decoder.linkRange];
//            [strAttribute addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:decoder.linkRange];
//        }
        
        //部分文字颜色，设置的是同一个字段，会覆盖掉“下划线”设置的颜色
        for (DTTextLabelFont* aFontItem in decoder.arrayFont) {
            if (aFontItem.fontTextRange.length != 0) {
                [strAttribute addAttribute:NSForegroundColorAttributeName value:aFontItem.fontTextColor range:aFontItem.fontTextRange];
            }
        }
    }
    
    [self setAttributedText:strAttribute];
}

- (void)setDTText:(NSString*)text linkURL:(NSURL*)url attrDict:(NSMutableDictionary *)arrtDict {
    DTTextDecoder* decoder = [[[DTTextDecoder alloc] initWithText:text] autorelease];
    
    NSMutableAttributedString *strAttribute = [[[NSMutableAttributedString alloc] initWithString:decoder.strDisplay attributes:arrtDict] autorelease];
    if (ios6) {
        //下划线
        //        if (decoder.linkRange.length != 0) {
        //            [strAttribute addAttribute:NSForegroundColorAttributeName value:decoder.linkColor range:decoder.linkRange];
        //            [strAttribute addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:decoder.linkRange];
        //        }
        
        //部分文字颜色，设置的是同一个字段，会覆盖掉“下划线”设置的颜色
        for (DTTextLabelFont* aFontItem in decoder.arrayFont) {
            if (aFontItem.fontTextRange.length != 0) {
                [strAttribute addAttribute:NSForegroundColorAttributeName value:aFontItem.fontTextColor range:aFontItem.fontTextRange];
            }
        }
    }
    
    [self setAttributedText:strAttribute];
}
@end

