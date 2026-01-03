# Weather Feature Setup

## Overview
The money tree now displays a weather-based background that changes based on the user's current weather conditions.

## Required Setup

### 1. Add Location Permission to Info.plist

You need to add location permission keys to your app's Info.plist. In Xcode:

1. Open your project
2. Select the **soteria** target (not SoteriaMonitor)
3. Go to the **Info** tab
4. Add the following keys:

**Key:** `NSLocationWhenInUseUsageDescription`
**Type:** String
**Value:** `Soteria uses your location to display weather-based backgrounds on your money tree.`

**Key:** `NSLocationAlwaysAndWhenInUseUsageDescription` (optional, if you want background location)
**Type:** String
**Value:** `Soteria uses your location to display weather-based backgrounds.`

Alternatively, if you have a separate Info.plist file, add these entries:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Soteria uses your location to display weather-based backgrounds on your money tree.</string>
```

### 2. How It Works

- The `WeatherService` requests location permission when the money tree view appears
- It fetches weather data from wttr.in API (free, no API key required)
- Weather conditions are mapped to visual themes:
  - **Sunny**: Warm yellow/golden gradient
  - **Partly Cloudy**: Light gray-blue gradient
  - **Cloudy**: Gray-blue gradient
  - **Rainy**: Blue-gray gradient
  - **Snowy**: Light blue-white gradient
  - **Stormy**: Dark gray gradient
  - **Foggy**: Light gray gradient

- The background gradient is subtle (30% opacity) so it doesn't overwhelm the tree
- If location permission is denied or weather is unavailable, a default subtle background is shown

### 3. Testing

1. Build and run the app
2. Navigate to the Home screen with the money tree
3. You should see a location permission prompt (first time only)
4. Grant permission
5. The background should update to match your current weather

### 4. Privacy

- Location is only used for weather data
- Location accuracy is set to `kCLLocationAccuracyKilometer` (low accuracy, saves battery)
- Location is only requested when the money tree view appears
- Weather data is fetched once per view appearance

