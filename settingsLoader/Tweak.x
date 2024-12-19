#import <objc/runtime.h>
#import <notify.h>
#import <dlfcn.h>
#import <substrate.h>
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import "prefs.h"
#import <objc/runtime.h>
#ifdef DEBUG
#import "Log.h"
#endif
// static NSInteger PSSpecifierSort(PSSpecifier *a1, PSSpecifier *a2, void *context) {
// 	NSString *string1 = [a1 name];
// 	NSString *string2 = [a2 name];
// 	return [string1 localizedCaseInsensitiveCompare:string2];
// }

@interface TVSettingsMainViewController: TSKViewController

 - (BOOL)loadTweakMenu; //a function we add, add this header to prevent build warnings

@end

%hook TVSettingsMainViewController

//add a new function to test whether or not the tweak menu should be shown

%new - (BOOL)loadTweakMenu {

//right now just see if theres ANY plists in this folder, make this smarter later
	NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:@"/Library/PreferenceLoader/Preferences" error:NULL];
		for(NSString *item in subpaths) {
			if(![[item pathExtension] isEqualToString:@"plist"]) continue;

			return YES; //we have even one plist in here	
		}
	return NO;
}

/* 
	loadSettingsGroups is the initial entry point of every group of settings items in TVSettingsApp, this is the root one

	All menu items in the TVSettings application are organized in TSKSettingGroups of TSKSettingItem. These items could
	be viewed as PSSpecifiers in a manner of speaking, its solely what we deal with when we create menu items.

	therefore the property - (NSArray *)settingsGroups could be thought of as how - (id)specifiers; is in iOS, theoretically
	we could override the property variable for - (NSArray *)settingsGroups instead of -(id)loadSettignsGroup, but this works so meh!
*/
- (id)loadSettingGroups {

#ifdef DEBUG
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *logFile = @"/var/mobile/Documents/TVSettings.log";
    if ([man fileExistsAtPath:logFile]){
        [man removeItemAtPath:logFile error:nil];
    }
#endif
    NSLog(@"[Tweak.xm] loadSettingsGroup");
	%log;
	if (![self loadTweakMenu]){
		NSLog(@"no tweaks to load, dont even load the menu!");
		return %orig;
	}
	NSArray* groups = %orig;//all the groups (although theres only 1, theres actually 2 in 15+, but the first is empty so lastObject will be backwards compat) - this is appears to be a reference to the settingsGroup property
    NSLog(@"[Tweak.xm] groups: %@", groups);
	TSKSettingGroup *group = [groups lastObject]; //get first (and only) group
    //right now just show tweak list item, maybe in future add an app item too OR (ideally) inject into the current Application list that already exists (if even necessary)
	TSKSettingItem *tweakMenuItem = [TSKSettingItem childPaneItemWithTitle:@"Tweaks" description:nil representedObject:nil keyPath:nil childControllerClass:TVSettingsTweakViewController.class];
	NSArray *settingsItems = [group settingItems]; //get the individual TSKSettingItems
	NSMutableArray *newItems = [settingsItems mutableCopy]; //make a mutable copy, although there may be a way to add one without doing this.. TODO
    if (newItems.count > 7){
	    [newItems insertObject:tweakMenuItem atIndex:7]; //right underneath "Applications"
	    //update the group to have our Tweaks item shoehorned in :)
	    [group setSettingItems:newItems];
    } else {
        NSLog(@"[preferenceloader Tweak.xm] zero settings items, wtf???");
    }
	return @[group];
}

%end
