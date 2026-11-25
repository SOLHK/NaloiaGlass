#import "NGSettingsViewController.h"
#import "NGCapsuleDockView.h"
#import "NGCoreLogic.h"
#import "NGDockCoordinator.h"
#import "NGEnvironment.h"
#import "NGPreferences.h"
#import "NGRuntimeBridge.h"
#import <stdlib.h>

typedef NS_ENUM(NSInteger, NGSettingsSection) {
    NGSettingsSectionMode = 0,
    NGSettingsSectionAppearance = 1,
    NGSettingsSectionAccent = 2,
    NGSettingsSectionTools = 3,
    NGSettingsSectionCount = 4
};

@interface NGSettingsViewController ()
@property (nonatomic, strong) NGCapsuleDockView *previewDockView;
@property (nonatomic, strong, nullable) UILabel *insetValueLabel;
@property (nonatomic, strong, nullable) UILabel *heightValueLabel;
@end

@implementation NGSettingsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Naloia Glass";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    if (self.navigationController.topViewController == self &&
        self.navigationController.childViewControllers.firstObject == self) {
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:@selector(closeModalSettings)];
    }

    self.tableView.tableHeaderView = [self buildLivePreviewHeaderView];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onPrefsUpdated:)
                                               name:NGPreferencesDidChangeNotification
                                             object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *header = self.tableView.tableHeaderView;
    if (header && fabs(CGRectGetWidth(header.frame) - CGRectGetWidth(self.tableView.bounds)) > 0.5) {
        CGRect f = header.frame;
        f.size.width = CGRectGetWidth(self.tableView.bounds);
        header.frame = f;
        self.tableView.tableHeaderView = header;
    }
}

- (UIView *)buildLivePreviewHeaderView {
    CGFloat width = MAX(320.0, CGRectGetWidth(self.view.bounds));
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 152.0)];
    container.backgroundColor = UIColor.clearColor;

    UIView *stage = [[UIView alloc] initWithFrame:CGRectMake(16.0, 12.0, width - 32.0, 132.0)];
    stage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    stage.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    stage.layer.cornerCurve = kCACornerCurveContinuous;
    stage.layer.cornerRadius = 22.0;
    stage.clipsToBounds = YES;
    [container addSubview:stage];

    // Subtle decorative color blobs behind the dock to showcase Liquid Glass refraction & translucency.
    UIView *blobLeft = [[UIView alloc] initWithFrame:CGRectMake(24.0, 46.0, 118.0, 68.0)];
    blobLeft.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.24];
    blobLeft.layer.cornerRadius = 34.0;
    [stage addSubview:blobLeft];

    UIView *blobRight = [[UIView alloc] initWithFrame:CGRectMake(width - 178.0, 42.0, 126.0, 72.0)];
    blobRight.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    blobRight.backgroundColor = [[UIColor systemTealColor] colorWithAlphaComponent:0.24];
    blobRight.layer.cornerRadius = 36.0;
    [stage addSubview:blobRight];

    UILabel *caption = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 12.0, width - 64.0, 18.0)];
    caption.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    caption.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    caption.textColor = UIColor.secondaryLabelColor;
    caption.text = @"实时胶囊交互预览（可直接点按切换标签）";
    [stage addSubview:caption];

    NGCapsuleDockView *preview = [[NGCapsuleDockView alloc] initWithFrame:CGRectMake(0.0, 56.0, CGRectGetWidth(stage.bounds), 64.0)];
    preview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [stage addSubview:preview];

    UIImageSymbolConfiguration *symCfg = [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightMedium];
    UITabBarItem *chatItem = [[UITabBarItem alloc] initWithTitle:@"微信"
                                                           image:[UIImage systemImageNamed:@"message.fill" withConfiguration:symCfg]
                                                             tag:0];
    chatItem.badgeValue = @"3";
    UITabBarItem *contactsItem = [[UITabBarItem alloc] initWithTitle:@"通讯录"
                                                               image:[UIImage systemImageNamed:@"person.2.fill" withConfiguration:symCfg]
                                                                 tag:1];
    UITabBarItem *discoverItem = [[UITabBarItem alloc] initWithTitle:@"发现"
                                                               image:[UIImage systemImageNamed:@"safari.fill" withConfiguration:symCfg]
                                                                 tag:2];
    UITabBarItem *meItem = [[UITabBarItem alloc] initWithTitle:@"我"
                                                         image:[UIImage systemImageNamed:@"person.fill" withConfiguration:symCfg]
                                                           tag:3];
    [preview configureForPreviewItems:@[chatItem, contactsItem, discoverItem, meItem] selectedIndex:0];
    self.previewDockView = preview;

    return container;
}

- (void)closeModalSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onPrefsUpdated:(NSNotification *)note {
    (void)note;
    [self.previewDockView refreshAppearanceAndSelectionAnimated:YES];
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)colorPresets {
    return @[
        @{@"name": @"微信绿（默认）", @"hex": @"#07C160"},
        @{@"name": @"清澈蓝", @"hex": @"#007AFF"},
        @{@"name": @"琉璃青", @"hex": @"#00A699"},
        @{@"name": @"靛青紫", @"hex": @"#5856D6"},
        @{@"name": @"琥珀橙", @"hex": @"#FF9500"}
    ];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return NGSettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    switch ((NGSettingsSection)section) {
        case NGSettingsSectionMode:       return 3;
        case NGSettingsSectionAppearance: return 6;
        case NGSettingsSectionAccent:     return (NSInteger)self.colorPresets.count + 1;
        case NGSettingsSectionTools:      return 4;
        case NGSettingsSectionCount:      return 0;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    switch ((NGSettingsSection)section) {
        case NGSettingsSectionMode:       return @"液态玻璃模式";
        case NGSettingsSectionAppearance: return @"视觉与几何参数";
        case NGSettingsSectionAccent:     return @"选中滑块与图标强调色";
        case NGSettingsSectionTools:      return @"诊断与配置备份";
        case NGSettingsSectionCount:      return nil;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section == NGSettingsSectionMode) {
        if (![NGEnvironment isIOS26OrNewer]) {
            return @"当前系统低于 iOS 26.0，液态玻璃引擎已自动保持安全静默。";
        }
        return @"「系统真原生模式」解锁 iOS 26 Solarium 原生折射底栏（切换此模式需重启微信生效）；「自绘悬浮胶囊模式」支持免重启实时调节边距、分离圆钮与配色。长按底栏 0.8 秒也可随时呼出本面板。";
    }
    return nil;
}

- (UITableViewCell *)switchCellWithTitle:(NSString *)title
                                      on:(BOOL)on
                                  action:(SEL)action {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = title;
    UISwitch *sw = [[UISwitch alloc] init];
    [sw setOn:on animated:NO];
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}

- (UITableViewCell *)sliderCellWithTitle:(NSString *)title
                                   value:(CGFloat)value
                                     min:(float)minVal
                                     max:(float)maxVal
                                  action:(SEL)action
                              labelStore:(UILabel * __strong *)labelStore {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 10.0, 180.0, 20.0)];
    titleLbl.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    titleLbl.text = title;
    [cell.contentView addSubview:titleLbl];

    UILabel *valLbl = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 10.0, 120.0, 20.0)];
    valLbl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    valLbl.font = [UIFont monospacedDigitSystemFontOfSize:14.0 weight:UIFontWeightMedium];
    valLbl.textColor = UIColor.secondaryLabelColor;
    valLbl.textAlignment = NSTextAlignmentRight;
    valLbl.text = [NSString stringWithFormat:@"%.0f pt", value];
    [cell.contentView addSubview:valLbl];
    if (labelStore) *labelStore = valLbl;

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20.0, 36.0, MAX(220.0, CGRectGetWidth(cell.contentView.bounds) - 40.0), 30.0)];
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    slider.minimumValue = minVal;
    slider.maximumValue = maxVal;
    [slider setValue:(float)value animated:NO];
    [slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:slider];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (indexPath.section == NGSettingsSectionAppearance && (indexPath.row == 4 || indexPath.row == 5)) {
        return 74.0;
    }
    return 48.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NGPreferences *prefs = NGPreferences.shared;

    if (indexPath.section == NGSettingsSectionMode) {
        if (indexPath.row == 0) {
            return [self switchCellWithTitle:@"启用 Naloia Glass" on:prefs.enabled action:@selector(onMasterEnabledChanged:)];
        }
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        if (indexPath.row == 1) {
            cell.textLabel.text = @"iOS 26 系统真原生模式（Solarium）";
            cell.detailTextLabel.text = @"系统级光学折射透镜 + 微信底栏局部去遮罩";
            cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
            cell.accessoryType = (prefs.dockMode == NGDockModeSystemNative)
                ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else {
            cell.textLabel.text = @"自绘悬浮胶囊模式（Capsule Dock）";
            cell.detailTextLabel.text = @"UIGlassEffect 悬浮胶囊 + 分离圆钮 + 红点同步";
            cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
            cell.accessoryType = (prefs.dockMode == NGDockModeFloatingCapsule)
                ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }

    if (indexPath.section == NGSettingsSectionAppearance) {
        switch (indexPath.row) {
            case 0:
                return [self switchCellWithTitle:@"清透高透玻璃（Clear 变体）"
                                              on:prefs.clearGlass
                                          action:@selector(onClearGlassChanged:)];
            case 1:
                return [self switchCellWithTitle:@"隐藏底部栏文字标签"
                                              on:prefs.hideTabTitles
                                          action:@selector(onHideTitlesChanged:)];
            case 2:
                return [self switchCellWithTitle:@"右侧独立分离圆钮（「我」）"
                                              on:prefs.detachedRightButton
                                          action:@selector(onDetachedOrbChanged:)];
            case 3:
                return [self switchCellWithTitle:@"底栏点击轻触感反馈"
                                              on:prefs.hapticEnabled
                                          action:@selector(onHapticChanged:)];
            case 4: {
                UILabel *lbl = nil;
                UITableViewCell *c = [self sliderCellWithTitle:@"胶囊左右边距"
                                                         value:prefs.horizontalInset
                                                           min:8.0f
                                                           max:28.0f
                                                        action:@selector(onInsetSliderChanged:)
                                                    labelStore:&lbl];
                self.insetValueLabel = lbl;
                return c;
            }
            case 5: {
                UILabel *lbl = nil;
                UITableViewCell *c = [self sliderCellWithTitle:@"胶囊高度"
                                                         value:prefs.dockHeight
                                                           min:44.0f
                                                           max:58.0f
                                                        action:@selector(onHeightSliderChanged:)
                                                    labelStore:&lbl];
                self.heightValueLabel = lbl;
                return c;
            }
        }
    }

    if (indexPath.section == NGSettingsSectionAccent) {
        NSArray<NSDictionary<NSString *, NSString *> *> *presets = self.colorPresets;
        NSString *currentHex = prefs.accentHex;
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        if (indexPath.row < (NSInteger)presets.count) {
            NSDictionary<NSString *, NSString *> *item = presets[(NSUInteger)indexPath.row];
            NSString *hex = item[@"hex"];
            cell.textLabel.text = item[@"name"];
            cell.detailTextLabel.text = hex;
            cell.accessoryType = [currentHex isEqualToString:hex]
                ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else {
            cell.textLabel.text = @"自定义十六进制颜色…";
            cell.detailTextLabel.text = currentHex;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    }

    UITableViewCell *toolCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    switch (indexPath.row) {
        case 0:
            toolCell.textLabel.text = @"查看并复制环境与底栏诊断信息";
            toolCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 1:
            toolCell.textLabel.text = @"导出当前 JSON 配置到剪贴板";
            toolCell.textLabel.textColor = UIColor.systemBlueColor;
            break;
        case 2:
            toolCell.textLabel.text = @"从剪贴板导入 JSON 配置";
            toolCell.textLabel.textColor = UIColor.systemBlueColor;
            break;
        case 3:
            toolCell.textLabel.text = @"恢复默认设置";
            toolCell.textLabel.textColor = UIColor.systemRedColor;
            break;
    }
    return toolCell;
}

#pragma mark - Actions & Delegate

- (void)promptRestartIfSolariumChangedFrom:(BOOL)before to:(BOOL)after {
    if (before == after || ![NGEnvironment isIOS26OrNewer]) return;
    NSString *msg = after
        ? @"已写入 iOS 26 原生 Solarium 解锁偏好键，需要重新启动微信以让系统加载真原生液态玻璃底栏。"
        : @"已清理 iOS 26 原生 Solarium 偏好键，重启微信后系统将完全卸下原生液态玻璃层。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"需要重启微信生效"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"立即退出微信（手动重开）"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        (void)action;
        [NSUserDefaults.standardUserDefaults synchronize];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"稍后重启"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onMasterEnabledChanged:(UISwitch *)sender {
    NGPreferences *prefs = NGPreferences.shared;
    BOOL before = (prefs.enabled && prefs.dockMode == NGDockModeSystemNative);
    prefs.enabled = sender.isOn;
    BOOL after = (prefs.enabled && prefs.dockMode == NGDockModeSystemNative);
    [self.tableView reloadData];
    [self promptRestartIfSolariumChangedFrom:before to:after];
}

- (void)onClearGlassChanged:(UISwitch *)sender {
    NGPreferences.shared.clearGlass = sender.isOn;
}

- (void)onHideTitlesChanged:(UISwitch *)sender {
    NGPreferences.shared.hideTabTitles = sender.isOn;
}

- (void)onDetachedOrbChanged:(UISwitch *)sender {
    NGPreferences.shared.detachedRightButton = sender.isOn;
}

- (void)onHapticChanged:(UISwitch *)sender {
    NGPreferences.shared.hapticEnabled = sender.isOn;
}

- (void)onInsetSliderChanged:(UISlider *)sender {
    CGFloat val = round((double)sender.value);
    self.insetValueLabel.text = [NSString stringWithFormat:@"%.0f pt", val];
    NGPreferences.shared.horizontalInset = val;
}

- (void)onHeightSliderChanged:(UISlider *)sender {
    CGFloat val = round((double)sender.value);
    self.heightValueLabel.text = [NSString stringWithFormat:@"%.0f pt", val];
    NGPreferences.shared.dockHeight = val;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NGPreferences *prefs = NGPreferences.shared;

    if (indexPath.section == NGSettingsSectionMode && (indexPath.row == 1 || indexPath.row == 2)) {
        BOOL before = (prefs.enabled && prefs.dockMode == NGDockModeSystemNative);
        prefs.dockMode = (indexPath.row == 1) ? NGDockModeSystemNative : NGDockModeFloatingCapsule;
        BOOL after = (prefs.enabled && prefs.dockMode == NGDockModeSystemNative);
        [tableView reloadData];
        [self promptRestartIfSolariumChangedFrom:before to:after];
        return;
    }

    if (indexPath.section == NGSettingsSectionAccent) {
        NSArray<NSDictionary<NSString *, NSString *> *> *presets = self.colorPresets;
        if (indexPath.row < (NSInteger)presets.count) {
            prefs.accentHex = presets[(NSUInteger)indexPath.row][@"hex"];
            [tableView reloadData];
        } else {
            [self presentCustomHexInputAlert];
        }
        return;
    }

    if (indexPath.section == NGSettingsSectionTools) {
        if (indexPath.row == 0) {
            NSString *diag = [NGDockCoordinator.shared hierarchyDiagnosticReport];
            UIPasteboard.generalPasteboard.string = diag;
            [self showSimpleAlertTitle:@"诊断信息已复制到剪贴板" message:diag];
        } else if (indexPath.row == 1) {
            NSString *json = [prefs exportJSONString];
            if (json) {
                UIPasteboard.generalPasteboard.string = json;
                [self showSimpleAlertTitle:@"导出成功" message:@"JSON 配置已复制到系统剪贴板。"];
            }
        } else if (indexPath.row == 2) {
            NSString *clip = UIPasteboard.generalPasteboard.string ?: @"";
            NSError *err = nil;
            if ([prefs importJSONString:clip error:&err]) {
                [tableView reloadData];
                [self showSimpleAlertTitle:@"导入成功" message:@"剪贴板中的配置已应用。"];
            } else {
                [self showSimpleAlertTitle:@"导入失败" message:err.localizedDescription ?: @"请先复制有效的 JSON 配置文本。"];
            }
        } else if (indexPath.row == 3) {
            BOOL before = (prefs.enabled && prefs.dockMode == NGDockModeSystemNative);
            [prefs resetToDefaults];
            BOOL after = (prefs.enabled && prefs.dockMode == NGDockModeSystemNative);
            [tableView reloadData];
            [self promptRestartIfSolariumChangedFrom:before to:after];
        }
    }
}

- (void)presentCustomHexInputAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义强调色"
                                                                   message:@"请输入 6 位十六进制色值（如 #07C160）"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"#07C160";
        textField.text = NGPreferences.shared.accentHex;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"应用" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        (void)action;
        NSString *input = alert.textFields.firstObject.text ?: @"";
        unsigned int r = 0, g = 0, b = 0;
        if (!NGParseHexColorRGBC(input.UTF8String, &r, &g, &b)) {
            [self showSimpleAlertTitle:@"色值格式无效" message:@"请输入形如 #07C160 的 6 位十六进制颜色。"];
            return;
        }
        NGPreferences.shared.accentHex = input;
        [self.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showSimpleAlertTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
