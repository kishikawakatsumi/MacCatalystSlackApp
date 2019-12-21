import UIKit
import Combine

private let dateFormatter = RelativeDateTimeFormatter()

final class TextMessageCell: UITableViewCell {
    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var timestampLabel: UILabel!
    @IBOutlet private var contentTextView: UITextView!
    @IBOutlet private var attachedImageView: UIImageView!

    @IBOutlet private var horizontalMargins: [NSLayoutConstraint]!
    @IBOutlet private var verticalMargins: [NSLayoutConstraint]!

    var cancellable: AnyCancellable?

    var message: TextMessage? {
        didSet {
            avatarImageView.image = nil
            nameLabel.text = message?.user

            if let timestamp = message?.eventTs, let interval = TimeInterval(timestamp) {
                timestampLabel.text = dateFormatter.string(for: Date(timeIntervalSince1970: interval))
            }
            if let message = message {
                let attributedText = NSMutableAttributedString()
                message.blocks.forEach { (block) in
                    block.elements.forEach { (element) in
                        element.elements.forEach { (element) in
                            let defaultFont = UIFont.preferredFont(forTextStyle: .body)

                            if let text = element.text, element.type == "text" {
                                guard let style = element.style else {
                                    attributedText.append(NSAttributedString(string: text, attributes: [.font: defaultFont]))
                                    return
                                }
                                var attriutes = [NSAttributedString.Key: Any]()
                                var symbolicTraits = UIFontDescriptor.SymbolicTraits()
                                if let bold = style.bold, bold {
                                    symbolicTraits = symbolicTraits.union(.traitBold)
                                }
                                if let italic = style.italic, italic {
                                    symbolicTraits = symbolicTraits.union(.traitItalic)
                                }
                                if let strike = style.strike, strike {
                                    attriutes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                                }
                                if let code = style.code, code {
                                    symbolicTraits = symbolicTraits.union(.traitMonoSpace)
                                    attriutes[.foregroundColor] = UIColor.systemRed
                                    attriutes[.backgroundColor] = UIColor.systemGray
                                }
                                if let font = contentTextView.font, let descriptor = font.fontDescriptor.withSymbolicTraits(symbolicTraits) {
                                    attriutes[.font] = UIFont(descriptor: descriptor, size: font.pointSize)
                                    attributedText.append(NSAttributedString(string: text, attributes: attriutes))
                                }
                            }
                            if let url = element.url, element.type == "link" {
                                let attriutes: [NSAttributedString.Key: Any] = [.link: url, .font: defaultFont]
                                attributedText.append(NSAttributedString(string: url, attributes: attriutes))
                            }
                        }
                    }
                }
                contentTextView.attributedText = attributedText

                if let file = message.files?.first, let url = URL(string: file.thumb1024) {
                    attachedImageView.isHidden = false
                    ImagePipeline.shared.load(url, into: attachedImageView)
                } else {
                    attachedImageView.isHidden = true
                }
            }
        }
    }

    func updateUserProfile(_ userProfile: UserProfile) {
        if let image192 = URL(string: userProfile.image192) {
            ImagePipeline.shared.load(image192, into: avatarImageView)
        }
        nameLabel.text = userProfile.displayName.isEmpty ? userProfile.realName : userProfile.displayName
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.layer.cornerRadius = 6

        contentTextView.textContainerInset = .zero
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.layoutManager.usesFontLeading = false

        contentTextView.linkTextAttributes = [.foregroundColor: UIColor.systemBlue, .underlineStyle: NSUnderlineStyle.single.rawValue]

        attachedImageView.layer.borderWidth = 1
        attachedImageView.layer.borderColor = UIColor.separator.cgColor
        attachedImageView.layer.cornerRadius = 6

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        attachedImageView.addGestureRecognizer(tapGestureRecognizer)

        #if targetEnvironment(macCatalyst)
        horizontalMargins.forEach {
            $0.constant = 24
        }
        verticalMargins.forEach {
            $0.constant = 24
        }

        let hoverGestureRecognizer = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        addGestureRecognizer(hoverGestureRecognizer)
        #endif
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellable?.cancel()
    }

    #if targetEnvironment(macCatalyst)
    @objc
    private func handleHover(_ sender: UIHoverGestureRecognizer) {
        switch sender.state {
        case .possible:
            break
        case .began:
            backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
        case .changed:
            break
        case .ended, .cancelled, .failed:
            backgroundColor = .systemBackground
        @unknown default:
            backgroundColor = .systemBackground
        }
    }

    @objc
    private func handleImageTap(_ sender: UITapGestureRecognizer) {
        let activity = NSUserActivity(activityType: "panel")
        if let file = message?.files?.first {
            activity.userInfo?["image"] = file.thumb1024
        }
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil)
    }
    #endif
}
