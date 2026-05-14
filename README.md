# Relative Humidity Calculator

**DISCLAIMER: Documentation, including this readme, generated using Antropic's Claude Opus 4.7**

A tiny desktop utility that computes **relative humidity** and **dew point** from dry-bulb temperature, wet-bulb temperature, and elevation above sea level. Built with **Free Pascal** and **Lazarus (LCL)**.

The values update live as you type.

## Features

- Three inputs: dry-bulb temperature (°C), wet-bulb temperature (°C), elevation (m).
- Two outputs: relative humidity (%) and dew point (°C), shown to one decimal place.
- Live recalculation on every input change.

## Screenshots

![Alt Text](`docs/screenshot-main.png`)

## Usage

1. Enter the **dry-bulb temperature** (Tdb) — the ordinary air temperature measured by a thermometer.
2. Enter the **wet-bulb temperature** (Twb) — the temperature measured by a thermometer with a water-wetted wick under airflow. Twb must be less than or equal to Tdb.
3. Enter the **elevation** above sea level in metres. Leave at `0` for a standard sea-level atmosphere of 101.325 kPa.
4. Read off the **relative humidity** and **dew point** from the labels.

### Worked example

| Input              | Value     |
| ------------------ | --------- |
| Dry-bulb (Tdb)     | 25.0 °C   |
| Wet-bulb (Twb)     | 20.0 °C   |
| Elevation          | 0 m       |

Typical output: relative humidity ≈ 64 %, dew point ≈ 17.6 °C.

## How it works

The unit uses the classic psychrometric formulation built on a Magnus-style saturation-vapor-pressure approximation.

### Symbols

| Symbol | Meaning                                              | Units |
| ------ | ---------------------------------------------------- | ----- |
| Tdb    | Dry-bulb temperature                                 | °C    |
| Twb    | Wet-bulb temperature                                 | °C    |
| Elv    | Elevation above sea level                            | m     |
| P      | Air pressure (derived from Elv)                      | kPa   |
| ESdb   | Saturation vapor pressure at Tdb                     | kPa   |
| ESwb   | Saturation vapor pressure at Twb                     | kPa   |
| Ed     | Actual vapor pressure (partial pressure of water)    | kPa   |
| A      | Psychrometric conversion factor                      | 1/°C  |

### Steps

1. **Air pressure from elevation.** At sea level, P = 101.325 kPa. For Elv ≠ 0:

   ```
   P = 101.325 ^ (-0.0001184 · Elv)
   ```

2. **Psychrometric factor.**

   ```
   A = 0.00066 · (1 + 0.00115 · Twb)
   ```

3. **Saturation vapor pressure** (Magnus-style) at both wet-bulb and dry-bulb temperatures:

   ```
   ES(T) = exp((16.78·T - 116.9) / (T + 237.3))
   ```

4. **Actual vapor pressure** from the wet-bulb depression:

   ```
   Ed = ESwb - A · P · (Tdb - Twb)
   ```

5. **Relative humidity:**

   ```
   RH = 100 · Ed / ESdb
   ```

6. **Dew point** by inverting the Magnus formula:

   ```
   DewPoint = (116.9 + 237.3 · ln(Ed)) / (16.78 - ln(Ed))
   ```

   If `Ed <= 0` (mathematically undefined) the calculator returns the sentinel value `999` for the dew point.

## Caveats

- The approximation is intended for ordinary ambient conditions (roughly 0 °C to 60 °C, modest altitudes). Outside that range the numbers remain indicative but progressively less accurate.
- The form does **not** enforce `Twb ≤ Tdb`. Entering Twb above Tdb produces a relative humidity greater than 100 % — useful as a quick sanity check, but not physically meaningful.
- All units are SI / Celsius.

## License

This project is released under the MIT License. See [`LICENSE`](LICENSE) for details.
