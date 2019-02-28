//
//  PaidControlCenterViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 10/18/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

#if PAID
import UIKit

extension Notification.Name {
    static let themeChanged = Notification.Name("LumenThemeChanged")
}

var lumenTheme: LumenThemeName {
    
    if (UIColor.theme.name == "dark") {
        return .Dark
    }
    
    return .Light
}

var lumenDashboardMode: LumenThemeMode = UserPreferences.instance.isProtectionOn ? .Normal : .Disabled

class PaidControlCenterViewController: ControlCenterViewController {
    
    var upgradeView: UpgradeView?
    var upgradeButton: ButtonWithUnderlinedText?
	let privacyControl = LumenPrivacyStateControl()
    let tabs = UISegmentedControl(items: [NSLocalizedString("Today", tableName: "Lumen", comment:"[Lumen->Dashboard] Today tab"),
                                          NSLocalizedString("Last 7 days", tableName: "Lumen", comment:"[Lumen->Dashboard] Last 7 days tab")])

    let dashboard = CCCollectionViewController()
	let cellDataSource = CCDataSource()
    
    var currentPeriod: Period = .Today
    private let overlay = UIView()
    
    override func setupComponents() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VPNStatusDidChange(notification:)),
                                               name: .NEVPNStatusDidChange,
                                               object: nil)
        
        dashboard.dataSource = cellDataSource
        
        self.addChildViewController(dashboard)
		self.view.addSubview(privacyControl)
        self.view.addSubview(tabs)
        self.view.addSubview(dashboard.view)
		
		self.privacyControl.setState(isOn: UserPreferences.instance.isProtectionOn)
		self.privacyControl.addTarget(self, action: #selector(privacyStatuChanged(control:)), for: .valueChanged)

		tabs.selectedSegmentIndex = 0
        tabs.addTarget(self, action: #selector(tabChanged), for: .valueChanged)

		self.addUpgradeViewIfRequired()
        setStyle()
        setConstraints()

		CCWidgetManager.shared.update(period: currentPeriod)
		cellDataSource.tapHandler = { [weak self] (widget) in
			var vc: UIViewController?
			switch widget {
			case .savedTime:
				let timeVC = SavedTimeWidgetInfoViewController()
				timeVC.dataSource = SavedTimeDataSource()
				vc = timeVC
			case .savedData:
				let dataVC = WidgetGeneralInfoViewController()
				dataVC.dataSource = SavedDataDataSource()
				vc = dataVC
			case .blockedPhishingSites:
				let phishingVC = AntiPhishingWidgetInfoViewController()
				phishingVC.dataSource = AntiPhishingDataSource()
				vc = phishingVC
			case .blockedTrackers:
				let trackersVC = WidgetListInfoViewController()
				trackersVC.dataSource = BlockedTrackersDataSource()
				vc = trackersVC
			case .blockedAds:
				let adsVC = WidgetListInfoViewController()
				adsVC.dataSource = BlockedAdsDataSource()
				vc = adsVC
			}
			if let vc = vc {
				self?.present(vc, animated: true, completion: nil)
			}
		}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseSuccessNotification(_:)),
                                               name: .ProductPurchaseSuccessNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func handlePurchaseSuccessNotification(_ notification: Notification) {
        if !UserPreferences.instance.isProtectionOn {
            self.privacyControl.setState(isOn: true)
        }
        self.enableView()
    }

    private func setConstraints() {
        if let upgradeView = self.upgradeView {
            upgradeView.snp.makeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview().inset(20)
                make.height.equalTo(UpgradeViewUX.height)
            }
        }
		privacyControl.snp.makeConstraints { (make) in
			make.top.left.right.equalToSuperview()
			make.height.equalTo(40)
		}

        tabs.snp.makeConstraints { (make) in
            make.top.equalTo(privacyControl.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.leading.equalToSuperview().offset(10)
        }
        
        if let upgradeButton = upgradeButton {
            upgradeButton.snp.makeConstraints { (make) in
                make.top.equalTo(tabs.snp.bottom)
                make.centerX.equalToSuperview()
            }
        }
        dashboard.view.snp.makeConstraints { (make) in
            if let upgradeButton = upgradeButton {
                make.top.equalTo(upgradeButton.snp.bottom).offset(10)
            } else {
                make.top.equalTo(tabs.snp.bottom).offset(10)
            }
            make.trailing.leading.bottom.equalToSuperview()
        }
    }

    func setStyle() {
        self.view.backgroundColor = Lumen.Dashboard.backgroundColor(lumenTheme, lumenDashboardMode).withAlphaComponent(Lumen.Dashboard.backgroundColorAlpha(lumenTheme))
		updateUIState(isEnabled: UserPreferences.instance.isProtectionOn)
    }

    @objc func tabChanged(_ segmentedControl: UISegmentedControl) {
        if segmentedControl.selectedSegmentIndex == 0 {
            currentPeriod = .Today
        }
        else if segmentedControl.selectedSegmentIndex == 1 {
            currentPeriod = .Last7Days
        }
        
        CCWidgetManager.shared.update(period: currentPeriod)
		dashboard.update()
    }
    
    @objc func VPNStatusDidChange(notification: Notification) {
        //keep button up to date.
//        updateVPNButton()
    }

	@objc func privacyStatuChanged(control: UISwitch) {
		UserPreferences.instance.isProtectionOn = control.isOn
//		lumenDashboardMode = control.isOn ? .Normal : .Disabled
		updateUIState(isEnabled: control.isOn)
	}

	private func updateUIState(isEnabled: Bool) {
		lumenDashboardMode = isEnabled ? .Normal : .Disabled
		if isEnabled {
			tabs.tintColor = Lumen.Dashboard.segmentedControlColor(lumenTheme, lumenDashboardMode)
			tabs.isUserInteractionEnabled = true
		} else {
			tabs.tintColor = UIColor.lumenDisabled
			tabs.isUserInteractionEnabled = false
		}
		self.upgradeView?.updateViewState(isEnabled: isEnabled)
		self.upgradeButton?.updateViewState(isEnabled: isEnabled)
		dashboard.update()
	}
}

extension PaidControlCenterViewController : UpgradeLumenDelegate {
    @objc func showUpgradeViewController() {
        let upgradLumenViewController = UpgradLumenViewController()
        self.present(upgradLumenViewController, animated: true, completion: nil)
    }
	
    fileprivate func addUpgradeViewIfRequired() {
        let currentSubscription = SubscriptionController.shared.getCurrentSubscription()
        switch currentSubscription {
        case .trial(_):
            let trialRemainingDays = currentSubscription.trialRemainingDays() ?? -1
            if trialRemainingDays > 7 {
                let title = String(format: NSLocalizedString("%d more days left in trial", tableName: "Lumen", comment: "Trial days left title"), trialRemainingDays)
                let action = NSLocalizedString("UPGRADE", tableName: "Lumen", comment: "Upgrade action")
                upgradeButton = ButtonWithUnderlinedText(startText: (title, UIColor.theme.lumenSubscription.upgradeLabel),
                                                         underlinedText: (action, UIColor.lumenBrightBlue),
                                                         position: .next,
                                                         view: "dashboard")
                upgradeButton?.addTarget(self, action: #selector(showUpgradeViewController), for: .touchUpInside)
                self.view.addSubview(upgradeButton!)
            } else if trialRemainingDays >= 0 {
                 self.addUpgradeView()
            } else {
                // TODO: invalid state
            }
            
        case .limited:
            self.addUpgradeView()
            self.disableView()
        default:
            print("Premium User")
        }
    }
    
    fileprivate func addUpgradeView() {
        self.upgradeView = UpgradeView(view: "dashboard")
        self.upgradeView?.delegate = self
        view.addSubview(upgradeView!)
    }
    
    fileprivate func disableView() {
        tabs.tintColor = UIColor.lumenDisabled
        tabs.isUserInteractionEnabled = false

        overlay.backgroundColor = UIColor.black
        overlay.alpha = 0.5
        self.view.addSubview(overlay)
        overlay.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            if let upgradeView = self.upgradeView {
                make.top.equalTo(upgradeView.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
        }
    }

    fileprivate func enableView() {
        tabs.isUserInteractionEnabled = true
        overlay.removeFromSuperview()
        
        upgradeView?.removeFromSuperview()
        upgradeView = nil
        upgradeButton?.removeFromSuperview()
        upgradeButton = nil
        self.setStyle()
        self.setConstraints()
    }
}
#endif
