#import <UIKit/UIKit.h>

@interface SBIcon : NSObject
- (NSString *)applicationBundleID;
- (NSString *)leafIdentifier;
@end

static NSString *const kDir = @"/var/mobile/Library/ChipsGlass";

static UIImage *CustomImage(SBIcon *icon, UIImage *orig) {
    if (!orig) return nil;

    NSString *bid = nil;
    if ([icon respondsToSelector:@selector(applicationBundleID)]) {
        bid = [icon applicationBundleID];
    }
    if (!bid.length && [icon respondsToSelector:@selector(leafIdentifier)]) {
        bid = [icon leafIdentifier];
    }
    if (!bid.length) return nil;

    NSString *file = [bid stringByAppendingString:@".png"];
    UIImage *src = [UIImage imageWithContentsOfFile:[kDir stringByAppendingPathComponent:file]];
    if (!src) return nil;

    CGSize size = orig.size;
    CGRect r = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, orig.scale);
    [[UIBezierPath bezierPathWithRoundedRect:r cornerRadius:size.width * 0.2237] addClip];
    [src drawInRect:r];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out;
}

%hook SBIcon
- (UIImage *)generateIconImage:(int)format {
    UIImage *orig = %orig;
    UIImage *c = CustomImage(self, orig);
    return c ?: orig;
}
- (UIImage *)getIconImage:(int)format {
    UIImage *orig = %orig;
    UIImage *c = CustomImage(self, orig);
    return c ?: orig;
}
%end
