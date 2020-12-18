#import <TVSettingKit/TVSettingKit.h>

@interface PLCustomListViewController: TSKViewController

@property (nonatomic, strong) NSDictionary *rootPlist;
@property (nonatomic, strong) NSString *ourDomain;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) UIImage *ourIcon;

- (void)relaunchBackboardd;
- (void)showMissingActionAlert;
@end
