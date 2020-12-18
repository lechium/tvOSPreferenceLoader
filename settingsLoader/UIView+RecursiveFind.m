#import "UIView+RecursiveFind.h"

@implementation NSArray (reverse)

- (NSArray *)reverseArray {
    return [[self reverseObjectEnumerator] allObjects];
}

@end

@implementation UIView (RecursiveFind)

- (NSArray *)siblingsInclusive:(BOOL)include {
    UIView *superview = [self superview];
    if (!superview) return nil;
    __block NSMutableArray *sibs = [[superview subviews] mutableCopy];
    [[superview subviews] enumerateObjectsUsingBlock:^(UIView  *_Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![subview isMemberOfClass:[self class]]){
            [sibs removeObject:subview];
            NSLog(@"removing object: %@", subview);
        }
    }];
    if (!include){
        [sibs removeObject:self];
    }
    return [sibs reverseArray];
}

- (BOOL)darkMode {
    
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark){
        return TRUE;
    }
    return FALSE;
}

- (UIImage *)snapshotViewWithSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, self.opaque, 0);
    //DLog(@"size: %@", NSStringFromCGSize(size));
    
    CGRect newBounds = self.bounds;
    newBounds.size.width = size.width;
    newBounds.size.height = size.height;
    newBounds.size = size;
    //DLog(@"newBounds: %@", NSStringFromCGRect(newBounds));
    [self drawViewHierarchyInRect:newBounds afterScreenUpdates:true];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (UIImage *) snapshotView
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:true];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}


- (UIView *)findFirstSubviewWithClass:(Class)theClass {
    if ([self isKindOfClass:theClass]) {
            return self;
        }
    for (UIView *v in self.subviews) {
        UIView *theView = [v findFirstSubviewWithClass:theClass];
        if (theView != nil){
            return theView;
        }
    }
    return nil;
}

- (void)printAutolayoutTrace
{
    // NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
    //NSLog(@"%@", recursiveDesc);
#if DEBUG
//    NSString *trace = [self _recursiveAutolayoutTraceAtLevel:0];
  //  NSLog(@"%@", trace);
#endif
}


- (void)printRecursiveDescription
{
//#if DEBUG
    NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
   NSLog(@"%@", recursiveDesc);
//#else
  //  NSLog(@"BUILT FOR RELEASE, NO SOUP FOR YOU");
//#endif
}

- (void)removeAllSubviews
{
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
}


@end
