//
//  HowToPlayViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/8/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit

class HowToPlayViewController: UIViewController {
    
    @IBOutlet weak var firstText: UILabel!
    @IBOutlet weak var secondText: UILabel!
    @IBOutlet weak var thirdText: UILabel!
    @IBOutlet weak var fourthText: UILabel!
    @IBOutlet weak var fifthText: UILabel!
    @IBOutlet weak var continueButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        continueButton.layer.cornerRadius = 20.0
        firstText.alpha = 0
        secondText.alpha = 0
        thirdText.alpha = 0
        fourthText.alpha = 0
        fifthText.alpha = 0
        continueButton.alpha = 0

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fadeInstructions()
    }
    
    func fadeInstructions() {
        UIView.animate(withDuration: 0.7, delay: 0.7, options: .curveEaseOut, animations: {
            self.firstText.alpha = 1.0
          }, completion: { finished in
            UIView.animate(withDuration: 0.7, delay: 0.5, options: .curveEaseOut, animations: {
              self.secondText.alpha = 1.0
            }, completion: { finished in
                UIView.animate(withDuration: 0.7, delay: 0.5, options: .curveEaseOut, animations: {
                  self.thirdText.alpha = 1.0
                }, completion: { finished in
                    UIView.animate(withDuration: 0.7, delay: 0.5, options: .curveEaseOut, animations: {
                  self.fourthText.alpha = 1.0
                }, completion: { finished in
                    UIView.animate(withDuration: 0.7, delay: 0.5, options: .curveEaseOut, animations: {
                  self.fifthText.alpha = 1.0
                }, completion: { finished in
                    UIView.animate(withDuration: 0.7, delay: 0.5, options: .curveEaseOut, animations: {
                      self.continueButton.alpha = 1.0
                    }, completion: { finished in
                    })
                })
                })
                })
            })
          })
    }
    
    @IBAction func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
