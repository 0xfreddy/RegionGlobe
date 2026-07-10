import Foundation

public struct RegionGlobeRegion: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let displayTitle: String
    public let countryNames: Set<String>
    public let focus: RegionGlobeCoordinate

    public init(
        id: String,
        title: String,
        displayTitle: String? = nil,
        countryNames: Set<String>,
        focus: RegionGlobeCoordinate
    ) {
        self.id = id
        self.title = title
        self.displayTitle = displayTitle ?? title
        self.countryNames = countryNames
        self.focus = focus
    }
}

public extension Array where Element == RegionGlobeRegion {
    static let defaultWorldRegions: [RegionGlobeRegion] = [
        .init(
            id: "us",
            title: "United States",
            countryNames: ["USA"],
            focus: .init(latitude: 38.6, longitude: -130.0)
        ),
        .init(
            id: "middle_east",
            title: "Middle East",
            countryNames: [
                "Saudi Arabia", "United Arab Emirates", "Israel", "Iran", "Iraq", "Jordan",
                "Lebanon", "Qatar", "Kuwait", "Oman", "Yemen", "Syria", "West Bank",
                "Georgia", "Armenia", "Azerbaijan"
            ],
            focus: .init(latitude: 29.3, longitude: 47.5)
        ),
        .init(
            id: "europe",
            title: "Europe",
            countryNames: [
                "Albania", "Austria", "Belarus", "Belgium", "Bosnia and Herzegovina", "Bulgaria",
                "Croatia", "Cyprus", "Czech Republic", "Denmark", "England", "Estonia", "Finland",
                "France", "Germany", "Greece", "Hungary", "Iceland", "Ireland", "Italy", "Kosovo",
                "Latvia", "Lithuania", "Luxembourg", "Macedonia", "Moldova", "Montenegro",
                "Netherlands", "Northern Cyprus", "Norway", "Poland", "Portugal", "Republic of Serbia",
                "Romania", "Slovakia", "Slovenia", "Spain", "Sweden", "Switzerland", "Turkey",
                "Ukraine", "United Kingdom", "Georgia", "Armenia", "Azerbaijan"
            ],
            focus: .init(latitude: 50.2, longitude: 10.4)
        ),
        .init(
            id: "asia",
            title: "Asia",
            countryNames: [
                "Afghanistan", "Bangladesh", "Bhutan", "Brunei", "Cambodia", "China", "India",
                "Indonesia", "Japan", "Kazakhstan", "Kyrgyzstan", "Laos", "Malaysia", "Mongolia",
                "Myanmar", "Nepal", "North Korea", "Pakistan", "Philippines", "Singapore",
                "South Korea", "Sri Lanka", "Taiwan", "Tajikistan", "Thailand", "Turkmenistan",
                "Uzbekistan", "Vietnam", "East Timor"
            ],
            focus: .init(latitude: 34.0, longitude: 103.0)
        ),
        .init(
            id: "africa",
            title: "Africa",
            countryNames: [
                "Algeria", "Angola", "Benin", "Botswana", "Burkina Faso", "Burundi", "Cameroon",
                "Central African Republic", "Chad", "Democratic Republic of the Congo", "Djibouti",
                "Egypt", "Equatorial Guinea", "Eritrea", "Ethiopia", "Gabon", "Gambia", "Ghana",
                "Guinea", "Guinea Bissau", "Ivory Coast", "Kenya", "Lesotho", "Liberia", "Libya",
                "Madagascar", "Malawi", "Mali", "Mauritania", "Morocco", "Mozambique", "Namibia",
                "Niger", "Nigeria", "Republic of the Congo", "Rwanda", "Senegal", "Sierra Leone",
                "Somalia", "Somaliland", "South Africa", "South Sudan", "Sudan", "Swaziland",
                "Togo", "Tunisia", "Uganda", "United Republic of Tanzania", "Western Sahara",
                "Zambia", "Zimbabwe"
            ],
            focus: .init(latitude: 1.5, longitude: 20.0)
        ),
        .init(
            id: "latam",
            title: "LATAM",
            displayTitle: "Latam",
            countryNames: [
                "Argentina", "Belize", "Bolivia", "Brazil", "Chile", "Colombia", "Costa Rica",
                "Cuba", "Dominican Republic", "Ecuador", "El Salvador", "Falkland Islands",
                "Guatemala", "Guyana", "Haiti", "Honduras", "Jamaica", "Mexico", "Nicaragua",
                "Panama", "Paraguay", "Peru", "Puerto Rico", "Suriname", "The Bahamas",
                "Trinidad and Tobago", "Uruguay", "Venezuela"
            ],
            focus: .init(latitude: -14.2, longitude: -58.9)
        ),
        .init(
            id: "russia",
            title: "Russia",
            countryNames: ["Russia"],
            focus: .init(latitude: 61.5, longitude: 96.0)
        )
    ]
}
