#import <objc/runtime.h>
#import <notify.h>
#import <dlfcn.h>
#import <substrate.h>
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import "TVSettingsTweakViewController.h"
#import <objc/runtime.h>

// static NSInteger PSSpecifierSort(PSSpecifier *a1, PSSpecifier *a2, void *context) {
// 	NSString *string1 = [a1 name];
// 	NSString *string2 = [a2 name];
// 	return [string1 localizedCaseInsensitiveCompare:string2];
// }

%hook NSBundle
+ (NSBundle *)bundleWithPath:(NSString *)path {
	NSString *newPath = nil;
	NSRange sysRange = [path rangeOfString:@"/System/Library/PreferenceBundles" options:0];
	if(sysRange.location != NSNotFound) {
		newPath = [path stringByReplacingCharactersInRange:sysRange withString:@"/Library/PreferenceBundles"];
	}
	if(newPath && [[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
		// /Library/PreferenceBundles will override /System/Library/PreferenceBundles.
		path = newPath;
	}
	return %orig;
}
%end

@interface TVSettingsMainViewController: TSKViewController

 - (BOOL)loadTweakMenu;

@end

%hook TVSettingsMainViewController

//loadSettingsGroups is the initial entry point of every group of settings items in TVSettingsApp, this is the root one

%new - (BOOL)loadTweakMenu {

//right now just see if theres ANY plists in this folder, make this smarter later
	NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:@"/Library/PreferenceLoader/Preferences" error:NULL];
		for(NSString *item in subpaths) {
			if(![[item pathExtension] isEqualToString:@"plist"]) continue;

			return YES; //we have even one plist in here	
		}
	return NO;
}

- (id)loadSettingGroups {
	
	%log;
	if (![self loadTweakMenu]){
		NSLog(@"no tweaks to load, dont even load the menu!");
		return %orig;
	}
	NSArray* groups = %orig;//all the groups (theres only 1)
	TSKSettingGroup *group = groups[0]; //get group 1	
	//right now just show tweak list item, maybe in future add an app item too OR (ideally) inject into the current Application list that already exists (if even necessary)
	TSKSettingItem *tweakMenuItem = [TSKSettingItem childPaneItemWithTitle:@"Tweaks" description:nil representedObject:nil keyPath:nil childControllerClass:TVSettingsTweakViewController.class];
	NSArray *settingsItems = [group settingItems];
	NSMutableArray *newItems = [settingsItems mutableCopy];
	[newItems insertObject:tweakMenuItem atIndex:7]; //right underneath /Apps
	//update the group to have our Tweaks item shoehorned in :)
	[group setSettingItems:newItems];
	return @[group];
}

%end