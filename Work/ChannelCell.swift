import UIKit

final class ChannelCell: UITableViewCell {
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var badgeBackground: UIView!
    @IBOutlet private var badgeLabel: UILabel!
    @IBOutlet private var verticalMargins: [NSLayoutConstraint]!

    let tapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)

    var channel: Channel? {
        didSet {
            if let name = channel?.name {
                nameLabel.text = "# \(name)"
            }
        }
    }

//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//        super.setHighlighted(highlighted, animated: animated)
//
//        #if targetEnvironment(macCatalyst)
//        if highlighted {
//            nameLabel.textColor = .systemBackground
//        } else {
//            nameLabel.textColor = .label
//        }
//        #endif
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        #if targetEnvironment(macCatalyst)
//        if selected {
//            nameLabel.textColor = .systemBackground
//        } else {
//            nameLabel.textColor = .label
//        }
//        #endif
//    }

    override func awakeFromNib() {
        super.awakeFromNib()

        #if targetEnvironment(macCatalyst)
        badgeBackground.layer.cornerRadius = 10
        badgeBackground.backgroundColor = UIColor.darkGray
        badgeLabel.textColor = UIColor.white
        badgeLabel.text = "\(Int.random(in: 10...200))"
        #else
        badgeBackground.isHidden = true
        badgeLabel.isHidden = true
        #endif

        #if targetEnvironment(macCatalyst)
        addGestureRecognizer(tapGestureRecognizer)

        verticalMargins.forEach {
            $0.constant = 4
        }
        #endif
    }
}
