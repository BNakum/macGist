//
//  Menu.swift
//  macGist
//
//  Created by Fernando Bunn on 23/05/17.
//  Copyright © 2017 Fernando Bunn. All rights reserved.
//

import Foundation
import AppKit

public enum Images {
    case standardIcon
    case checkmarkIcon
    case failureIcon
    
    var image: NSImage {
        var image: NSImage
        
        switch self {
        case .standardIcon:
            image = NSImage(named: "icon")!
        case .checkmarkIcon:
            image = NSImage(named: "check_white_icon")!
        case .failureIcon:
            image = NSImage(named: "x-icon")!
        }
        image.isTemplate = true
        return image
    }
}

class Menu {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let notificationHelper = NotificationHelper()
    var windowController: NSWindowController?
    
    func setupMenu() {
        item.image = Images.standardIcon.image
        let menu = NSMenu()
        
        let githubAPI = GitHubAPI()
        
        if githubAPI.isAuthenticated {
            let authenticatedItem = NSMenuItem(title: "Post Gist", action: #selector(Menu.createAuthenticatedGist), keyEquivalent: "")
            authenticatedItem.target = self
            menu.addItem(authenticatedItem)
        }
        
        let settingsMenuItem = NSMenuItem(title: "Settings", action: #selector(Menu.openSettings), keyEquivalent: "")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)
        
        if githubAPI.isAuthenticated {
            let gistsMenuItem = NSMenuItem(title: "Gists", action: #selector(Menu.opeGists), keyEquivalent: "")
            gistsMenuItem.target = self
            menu.addItem(gistsMenuItem)
        }
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(Menu.quit), keyEquivalent: "")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        item.menu = menu
    }
    
    private func displaySuccessIcon() {
        displayTemporary(icon: Images.checkmarkIcon.image)
    }
    
    private func displayFailureIcon() {
        displayTemporary(icon: Images.failureIcon.image)
    }
    
    private func displayTemporary(icon: NSImage) {
        DispatchQueue.main.async {
            self.item.image = icon
        }
        
        let deadlineTime = DispatchTime.now() + .seconds(2)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.item.image = Images.standardIcon.image
        }
    }
    
    private func postGist(authenticated: Bool) {
        guard let copiedItem = PasteboardHelper().getPasteboardString() else { return }

        GitHubAPI().post(gist: copiedItem, fileExtension: PasteboardHelper().getFileExtension(), authenticated: authenticated) { (error, string) in
            if let value = string {
                PasteboardHelper().save(string: value)
                self.displaySuccessIcon()
                self.notificationHelper.sendNotification(withIdentifier: value)
            } else {
                self.displayFailureIcon()
            }
        }
    }
    
    //MARK: - Button Methods
    
    @objc private func opeGists() {
        NSApp.activate(ignoringOtherApps: true)
        let gists = GistSplitViewController()
        let window = NSWindow(contentViewController: gists)
        windowController = NSWindowController(window: window)
        windowController?.showWindow(self)
        windowController?.window?.makeKey()
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        let settings = SettingsViewController()
        settings.delegate = self
        let window = NSWindow(contentViewController: settings)
        windowController = NSWindowController(window: window)
        windowController?.showWindow(self)
        windowController?.window?.makeKey()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc fileprivate func createAuthenticatedGist() {
        postGist(authenticated: true)
    }
    
    @objc fileprivate func createAnonymousGist() {
        postGist(authenticated: false)
    }
}

extension Menu: SettingsViewControllerDelegate {
    func didUpdateAuthStatus(controller: SettingsViewController) {
        setupMenu()
    }
}
