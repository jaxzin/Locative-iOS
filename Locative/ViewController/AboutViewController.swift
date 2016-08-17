import Eureka
import VTAcknowledgementsViewController
import SafariServices

private extension String {
    static let shortVersionString = "CFBundleShortVersionString"
    static let shortVersion = "CFBundleVersion"
}

class AboutViewController: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let social = Social(viewController: self)
    
        form
            
        +++ Section(NSLocalizedString("HTTP Webhooks", comment: "HTTP Webhooks section in info"))
            <<< ButtonRow {
                $0.title = NSLocalizedString("View pending and failed", comment: "View pending and failed webhooks")
                $0.onCellSelection { [weak self] cell, row in
                    self?.navigationController?
                        .pushViewController(WebhookViewController(), animated: true)
                }
            }
            
        +++ Section(NSLocalizedString("Get in touch", comment: "Get in touch"))
            <<< ButtonRow {
                $0.title = "Facebook"
                $0.onCellSelection { cell, row in
                    social.openFacebook()
                }
        }
            <<< ButtonRow {
                $0.title = "Twitter"
                $0.onCellSelection { cell, row in
                    social.openTwitter()
                }
        }
        
        +++ Section(NSLocalizedString("Support", comment: "Support header"))
            <<< ButtonRow {
                $0.title = NSLocalizedString("Support request", comment: "Support request button")
                $0.onCellSelection { cell, row in
                    UIApplication.sharedApplication().openURL(NSURL(string: "https://my.locative.io/support")!)
                }
        }
            
        +++ Section(NSLocalizedString("Acknowledgements", comment: "Acknowledgements header"))
            <<< ButtonRow {
                $0.title = NSLocalizedString("Licenses", comment: "Licenses button")
                $0.onCellSelection { [weak self] cell, row in
                    if let controller = VTAcknowledgementsViewController(fileNamed: "Acknowledgements") {
                        controller.title = NSLocalizedString("Licenses", comment: "Licenses header")
                        controller.footerText = "Made with ❤️ and Open Source Software"
                        self?.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            }
            <<< ButtonRow() {
                $0.title = NSLocalizedString("Legal", comment: "Legal button")
                $0.onCellSelection { cell, row in
                    UIApplication.sharedApplication().openURL(NSURL(string: "https://my.locative.io/legal")!)
                }
            }

        +++ Section(footer: versionString())
    }
}

private extension AboutViewController {
    func versionString() -> String {
        guard let infoDict = NSBundle.mainBundle().infoDictionary else {
            return "Unknown Version"
        }
        return "Version".stringByAppendingFormat(
            " %@ (%@)",
            infoDict[.shortVersionString] as! String,
            infoDict[.shortVersion] as! String
        )
    }
}
