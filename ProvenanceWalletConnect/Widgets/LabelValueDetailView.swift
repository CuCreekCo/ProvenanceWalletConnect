//
// Created by JD on 2/9/22.
//

import Foundation
import UIKit

class LabelValueDetailView: UIView {

    var separator: UIView!
    var label: UILabel!
    var value: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func labelText(_ text: String) {
        label.text = text
    }
    func valueText(_ text: String) {
        value.text = text
    }

    private func commonInit() {
        backgroundColor = .clear

        label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        addSubview(label)

        value = UILabel(frame: .zero)
        value.font = .systemFont(ofSize: 14.0, weight: .semibold)
        value.translatesAutoresizingMaskIntoConstraints = false
        value.text = "Value"
        addSubview(value)

        frame = bounds
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    private func constraintsInit() {
        let labelPadding = 10.0
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelPadding),
            label.topAnchor.constraint(equalTo: topAnchor, constant: labelPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: labelPadding),

            value.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelPadding),
            value.topAnchor.constraint(equalTo: label.bottomAnchor, constant: labelPadding),
            value.trailingAnchor.constraint(equalTo: trailingAnchor, constant: labelPadding)
        ])
    }
}
