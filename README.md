# Variable Weather

A feature-rich weather widget for KDE Plasma 6, powered by [Open-Meteo](https://open-meteo.com/) and optionally [Pirate Weather](https://pirateweather.net/).

## Features

- **Current conditions** — temperature, feels-like, humidity, wind speed & direction, pressure, cloud cover, gusts, and precipitation rate
- **Hourly forecast** — scrollable 6-hour preview with icons, temperatures, and precipitation probability
- **5-day forecast** — daily high/low with temperature range bars that reflect the global temperature spread using a color gradient
- **Precipitation nowcast** — bar chart showing upcoming precipitation probability and intensity
  - Open-Meteo provides 15-minute resolution
  - Pirate Weather (optional) provides 1-minute resolution for the first hour, merged seamlessly with Open-Meteo data
- **Weather alerts** — banner-style alerts with severity coloring from Pirate Weather (requires API key)
- **Saved locations** — save multiple locations and switch between them from the widget header dropdown
- **Cross-location alerts** — monitor weather alerts at all saved locations; alerts from other locations appear in a condensed section, and the panel icon badge reflects alerts at any saved location
- **Network resilience** — cached data displayed when a refresh fails, with a stale-data indicator
- **Compact panel view** — weather icon with temperature and alert badge

## Requirements

- KDE Plasma 6.0+
- An internet connection

### Optional

- A [Pirate Weather](https://pirateweather.net/) API key for 1-minute precipitation nowcast and weather alerts

## Installation

### From .plasmoid file

1. Download the latest `variable-weather.plasmoid` from the [Releases](https://github.com/JoshuaKimsey/variable-weather/releases) page
2. Install with:
   ```bash
   kpackagetool6 -t Plasma/Applet -i variable-weather.plasmoid
   ```
3. Right-click your panel or desktop and add "Variable Weather"

### From source

```bash
git clone https://github.com/JoshuaKimsey/variable-weather.git
cd variable-weather
./install.sh
```

To upgrade an existing installation, just run `./install.sh` again.

You may need to restart Plasma after installing:

```bash
plasmashell --replace &
```

## Configuration

Right-click the widget and select **Configure...** to access settings:

- **Location** — search for a city or enter coordinates manually
- **Saved Locations** — save the current location for quick switching; activate or remove saved locations from the list
- **Pirate Weather API Key** — optional; enables 1-minute precipitation nowcast and weather alerts
- **Units** — auto (system locale), metric, or imperial
- **Refresh interval** — 5 to 60 minutes
- **Pressure unit** — millibar or hPa/inHg based on unit setting
- **Weather alerts** — toggle alert display (requires Pirate Weather key)

## Data Sources

- [Open-Meteo](https://open-meteo.com/) — weather data and 15-minute precipitation nowcast (CC BY 4.0)
- [Pirate Weather](https://pirateweather.net/) — 1-minute precipitation nowcast and weather alerts (optional)

## License

[BSD 3-Clause](LICENSE)
