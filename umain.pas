{*******************************************************************************
  Unit:        UMain
  Project:     Relative Humidity Calculator
  Description: Main form unit for a small psychrometric utility. Given the
               dry-bulb temperature, wet-bulb temperature and elevation
               above sea level, it computes the relative humidity (%) and
               the dew point (°C) and updates the labels live as the user
               edits any input.

  Compiler:    Free Pascal (mode objfpc)
  Framework:   Lazarus LCL

  DISCLAIMER:  Documentation generated using Antropic's Clause Opus 4.7

  Units of measurement
  --------------------
    Temperatures      : degrees Celsius (°C)
    Elevation         : metres above sea level (m)
    Pressures         : kilopascals (kPa)
    Relative humidity : percent (%)

  Physical model
  --------------
    The unit uses the classic wet-bulb / dry-bulb psychrometric formulation:

      1. Air pressure is approximated from elevation; at sea level the
         standard value of 101.325 kPa is used.
      2. A conversion factor A is computed from the wet-bulb temperature.
      3. Saturation vapor pressures at both Twb and Tdb are computed using
         the Magnus-style approximation
             ES(T) = exp((16.78*T - 116.9) / (T + 237.3))
      4. The actual vapor pressure Ed is derived from the wet-bulb
         depression (Tdb - Twb), the conversion factor A and the air
         pressure.
      5. Relative humidity is Ed / ES(Tdb) expressed as a percentage.
      6. Dew point is the inverse of the Magnus formula applied to Ed.

  Caveats
  -------
    * The approximation is intended for ordinary ambient conditions
      (roughly 0 °C to 60 °C, low altitude). Outside that range the
      reported values are still indicative but progressively less
      accurate.
    * The wet-bulb temperature must be less than or equal to the
      dry-bulb temperature. The form does not enforce this; entering
      Twb > Tdb will produce a relative humidity above 100 %.
    * If the computed vapor pressure Ed is non-positive, the dew point
      is returned as the sentinel value 999 because Ln(Ed) is undefined.
*******************************************************************************}

unit UMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Spin, StdCtrls,
  ExtCtrls, Buttons, Math,
  UAboutBox;

type
  { TTwoValues
    -----------
    Simple record used to return the two computed quantities from a
    single call to RelHumidity.

      RH       : relative humidity in percent (0..100, may exceed 100
                 if Twb > Tdb)
      DewPoint : dew-point temperature in degrees Celsius, or the
                 sentinel value 999 when Ed <= 0 and the dew point is
                 mathematically undefined. }
  TTwoValues = record
    RH: float;
    DewPoint: float;
  end;

type
  { TfrmMain
    ---------
    Main (and only) form of the application. Contains three numeric
    inputs and two output labels. Every input change recomputes both
    outputs through RelHumidity. }
  TfrmMain = class(TForm)
    Bevel1: TBevel;                  // Visual separator on the form

    // ---- Inputs ----
    fspDBTemperature: TFloatSpinEdit; // Dry-bulb temperature (°C)
    fspWBTemperature: TFloatSpinEdit; // Wet-bulb temperature (°C)
    fspElevation: TFloatSpinEdit;     // Elevation above sea level (m)

    // ---- Static labels (titles, units, etc.) ----
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;

    // ---- Output labels (updated by the event handlers) ----
    lblHumidity: TLabel; // Relative humidity, formatted as fixed-point
    lblDewPoint: TLabel; // Dew point in °C, formatted as fixed-point
    spbAbout: TSpeedButton;

    StaticText1: TStaticText; // Footer / credit text

    // ---- Event handlers (one per input control) ----
    procedure FormCreate(Sender: TObject);
    procedure fspDBTemperatureChange(Sender: TObject);
    procedure fspElevationChange(Sender: TObject);
    procedure fspWBTemperatureChange(Sender: TObject);
    procedure spbAboutClick(Sender: TObject);

  private
    { RelHumidity
      ------------
      Core calculation. Given the three inputs, returns relative
      humidity and dew point in a TTwoValues record. See the unit
      header for the symbol table and the physical model. }
    function RelHumidity(Elv, Twb, Tdb: float): TTwoValues;

  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ ============================================================================
  Core psychrometric calculation
  ============================================================================

  Symbol table
  ------------
    ESwb : saturation vapor pressure at Twb (kPa)
    ESdb : saturation vapor pressure at Tdb (kPa)
    Ed   : actual vapor pressure / partial pressure of water (kPa)
    Elv  : elevation above sea level (m)
    P    : air pressure (kPa), approximated from Elv
    Twb  : wet-bulb temperature (°C)
    Tdb  : dry-bulb temperature (°C)
    A    : psychrometric conversion factor (1/°C)
}
function TfrmMain.RelHumidity(Elv, Twb, Tdb: float): TTwoValues;
var
  pressure: float;
  A: float;
  ESwb, ESdb, Ed: float;
begin
  // 1. Approximate the air pressure (kPa) from elevation.
  //    At sea level the standard atmosphere is 101.325 kPa; an
  //    elevation correction is applied when Elv <> 0.
  pressure := 101.325;
  if Elv <> 0 then
    pressure := Power(101.325, -0.0001184 * Elv);

  // 2. Psychrometric conversion factor A, dependent on Twb.
  A := 0.00066 * (1.0 + 0.00115 * Twb);

  // 3. Saturation vapor pressure at the wet-bulb temperature (kPa),
  //    via the Magnus-style approximation.
  ESwb := Exp((16.78 * Twb - 116.9) / (Twb + 237.3));

  // 4. Actual vapor pressure Ed (kPa) derived from the wet-bulb
  //    depression (Tdb - Twb).
  Ed := ESwb - A * pressure * (Tdb - Twb);

  // 5. Saturation vapor pressure at the dry-bulb temperature (kPa).
  ESdb := Exp((16.78 * Tdb - 116.9) / (Tdb + 237.3));

  // Relative humidity = ratio of actual to saturation vapor pressure,
  // expressed as a percentage.
  Result.RH := 100 * Ed / ESdb;

  // Dew point: inverse of the Magnus formula applied to Ed.
  // Ln(Ed) requires Ed > 0; otherwise return a sentinel value (999).
  if (Ed >= 0) then
    Result.DewPoint := (116.9 + 237.3 * Ln(Ed)) / (16.78 - Ln(Ed))
  else
    Result.DewPoint := 999;
end;

{ ============================================================================
  Event handlers

  All three input controls share identical handlers: each one simply
  rebuilds both outputs from the *current* values of all three inputs.
  The duplication is intentional and keeps the form definition compact;
  a single shared handler would work just as well.
  ============================================================================ }

{ fspDBTemperatureChange
  -----------------------
  Triggered when the dry-bulb temperature input changes. Recomputes
  the outputs and refreshes the two result labels. }
procedure TfrmMain.fspDBTemperatureChange(Sender: TObject);
var
  val: TTwoValues;
begin
  val := RelHumidity(fspElevation.Value, fspWBTemperature.Value, fspDBTemperature.Value);
  lblHumidity.Caption := FloatToStrF(val.RH, ffFixed, 3, 1);
  lblDewPoint.Caption := FloatToStrF(val.DewPoint, ffFixed, 3, 1);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Window title shows app name + current version + release date
  frmMain.Caption := APPLICATION_NAME + ' v. ' + VERSION_HISTORY[0].Version +
                     ' (' + VERSION_HISTORY[0].Date + ')';
end;

{ fspElevationChange
  -------------------
  Triggered when the elevation input changes. Recomputes the outputs
  and refreshes the two result labels. }
procedure TfrmMain.fspElevationChange(Sender: TObject);
var
  val: TTwoValues;
begin
  val := RelHumidity(fspElevation.Value, fspWBTemperature.Value, fspDBTemperature.Value);
  lblHumidity.Caption := FloatToStrF(val.RH, ffFixed, 3, 1);
  lblDewPoint.Caption := FloatToStrF(val.DewPoint, ffFixed, 3, 1);
end;

{ fspWBTemperatureChange
  -----------------------
  Triggered when the wet-bulb temperature input changes. Recomputes
  the outputs and refreshes the two result labels. }
procedure TfrmMain.fspWBTemperatureChange(Sender: TObject);
var
  val: TTwoValues;
begin
  val := RelHumidity(fspElevation.Value, fspWBTemperature.Value, fspDBTemperature.Value);
  lblHumidity.Caption := FloatToStrF(val.RH, ffFixed, 3, 1);
  lblDewPoint.Caption := FloatToStrF(val.DewPoint, ffFixed, 3, 1);
end;

procedure TfrmMain.spbAboutClick(Sender: TObject);
begin
  ShowAboutBox;
end;

end.
