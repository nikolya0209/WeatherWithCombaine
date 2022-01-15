//
//  ViewController.swift
//  openWeatherWithCombaine
//
//  Created by MacBookPro on 11.11.2021.
//

import UIKit
import Combine

enum WeatherError: Error {
    case invalidResponse
}

class ViewController: UIViewController {
    
    
    private let celsiusCharacters = "°С"
    private let openWeatherBaseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let openWeatherAPIKey = "2fde583d9bff183c3d658143a82b5cfb"

    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    private var cancelLabel: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicatorView.isHidden = true
    }

    @IBAction func searchTap(_ sender: Any) {
        view.endEditing(true)
        
        guard let cityName = cityTextField.text else { return }
        getTemperature(for: cityName)
    }
    
    
    private func getTemperature(for cityName: String) {
        guard let weatherURL = URL(string: "\(openWeatherBaseURL)?q=\(cityName)&appid=\(openWeatherAPIKey)&units=metric") else { return }
        activityIndicatorView.startAnimating()
        searchButton.isEnabled = false
        
        cancelLabel = URLSession.shared.dataTaskPublisher(for: weatherURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw WeatherError.invalidResponse
                }
                return data
            }
            .decode(type: WeatherData.self, decoder: JSONDecoder())
            .catch({ error in
                return Just(WeatherData.placeHolder)
            })
            .map({ $0.main?.temp ?? 0.0 })
            .map({ "\($0) \(self.celsiusCharacters)"})
            .subscribe(on: DispatchQueue(label: "Combine.Weather"))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                self.activityIndicatorView.stopAnimating()
                self.searchButton.isEnabled = true
            }, receiveValue: { temp in
                self.temperatureLabel.text = "Temperature is: \(temp)"
            })
    }
    
}

