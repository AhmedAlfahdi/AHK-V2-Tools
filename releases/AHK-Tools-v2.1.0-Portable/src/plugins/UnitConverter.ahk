#Requires AutoHotkey v2.0-*

; Unit Converter Plugin for AHK Tools
; Supports comprehensive SI (metric) and Imperial unit conversions
class UnitConverterPlugin extends Plugin {
    ; Plugin metadata
    static Name := "Unit Converter"
    static Description := "Convert between SI (metric) and Imperial units for length, weight, temperature, volume, area, and more"
    static Version := "1.0.0"
    static Author := "AHK Tools"
    
    ; Plugin state
    Enabled := false
    
    ; GUI components
    ConverterGui := ""
    CategoryDropdown := ""
    FromUnitDropdown := ""
    ToUnitDropdown := ""
    InputValue := ""
    OutputValue := ""
    ResultText := ""
    
    ; Unit conversion data structure
    UnitCategories := Map()
    
    ; Constructor
    __New() {
        this.InitializeUnitData()
    }
    
    ; Initialize the plugin
    Initialize() {
        ; Register Alt+U hotkey directly - bypass main system to get text selection
        Hotkey "!u", this.HandleAltU.Bind(this)
        return true
    }
    
    ; Enable the plugin
    Enable() {
        try {
            Hotkey "!u", "On"
            this.Enabled := true
        } catch as e {
            MsgBox("Error enabling Unit Converter: " e.Message)
            return false
        }
        return true
    }
    
    ; Disable the plugin
    Disable() {
        try {
            Hotkey "!u", "Off"
            this.Enabled := false
            if (this.ConverterGui) {
                try {
                    this.ConverterGui.Destroy()
                } catch {
                    ; Ignore errors
                }
                this.ConverterGui := ""
            }
        } catch as e {
            MsgBox("Error disabling Unit Converter: " e.Message)
            return false
        }
        return true
    }
    
    ; Main execution method - shows the converter GUI
    Execute() {
        if (!this.Enabled) {
            return false
        }
        
        this.ShowConverter("", "", "")
        return true
    }
    
    ; Main Alt+U handler - similar to currency converter
    HandleAltU(*) {
        ; Try to get selected text first
        selectedText := ""
        savedClip := ClipboardAll()
        A_Clipboard := ""
        Send "^c"
        if ClipWait(0.3) {
            selectedText := Trim(A_Clipboard)
        }
        A_Clipboard := savedClip
        
        ; Parse selected text for value and unit
        parsedValue := ""
        parsedUnit := ""
        parsedCategory := ""
        
        if selectedText {
            ; Try to extract number and unit from selected text
            this.ParseSelectedText(selectedText, &parsedValue, &parsedUnit, &parsedCategory)
        }
        
        ; Show the converter GUI with parsed data
        this.ShowConverter(parsedValue, parsedUnit, parsedCategory)
    }
    
    ; Parse selected text to extract value, unit, and category
    ParseSelectedText(text, &value, &unit, &category) {
        ; Common unit patterns with their categories
        unitPatterns := Map(
            ; Length units
            "mm|millimeter|millimeters", Map("unit", "Millimeter (mm)", "category", "Length"),
            "cm|centimeter|centimeters", Map("unit", "Centimeter (cm)", "category", "Length"),
            "m|meter|meters|metre|metres", Map("unit", "Meter (m)", "category", "Length"),
            "km|kilometer|kilometers|kilometre|kilometres", Map("unit", "Kilometer (km)", "category", "Length"),
            "in|inch|inches", Map("unit", "Inch (in)", "category", "Length"),
            "ft|foot|feet", Map("unit", "Foot (ft)", "category", "Length"),
            "yd|yard|yards", Map("unit", "Yard (yd)", "category", "Length"),
            "mi|mile|miles", Map("unit", "Mile (mi)", "category", "Length"),
            
            ; Weight units
            "mg|milligram|milligrams", Map("unit", "Milligram (mg)", "category", "Weight"),
            "g|gram|grams", Map("unit", "Gram (g)", "category", "Weight"),
            "kg|kilogram|kilograms", Map("unit", "Kilogram (kg)", "category", "Weight"),
            "oz|ounce|ounces", Map("unit", "Ounce (oz)", "category", "Weight"),
            "lb|lbs|pound|pounds", Map("unit", "Pound (lb)", "category", "Weight"),
            "st|stone", Map("unit", "Stone (st)", "category", "Weight"),
            
            ; Volume units
            "ml|milliliter|milliliters|millilitre|millilitres", Map("unit", "Milliliter (ml)", "category", "Volume"),
            "l|liter|liters|litre|litres", Map("unit", "Liter (l)", "category", "Volume"),
            "gal|gallon|gallons", Map("unit", "Gallon (US)", "category", "Volume"),
            "qt|quart|quarts", Map("unit", "Quart (US)", "category", "Volume"),
            "pt|pint|pints", Map("unit", "Pint (US)", "category", "Volume"),
            "cup|cups", Map("unit", "Cup (US)", "category", "Volume"),
            "fl oz|fluid ounce|fluid ounces", Map("unit", "Fluid Ounce (fl oz)", "category", "Volume"),
            
            ; Temperature units  
            "°c|celsius|c", Map("unit", "Celsius (°C)", "category", "Temperature"),
            "°f|fahrenheit|f", Map("unit", "Fahrenheit (°F)", "category", "Temperature"),
            "k|kelvin", Map("unit", "Kelvin (K)", "category", "Temperature"),
            
            ; Area units
            "m²|m2|square meter|square meters|square metre|square metres", Map("unit", "Square Meter (m²)", "category", "Area"),
            "ft²|ft2|square foot|square feet", Map("unit", "Square Foot (ft²)", "category", "Area"),
            "in²|in2|square inch|square inches", Map("unit", "Square Inch (in²)", "category", "Area"),
            "acre|acres", Map("unit", "Acre", "category", "Area"),
            
            ; Speed units
            "mph|miles per hour", Map("unit", "Mile/Hour (mph)", "category", "Speed"),
            "km/h|kmh|kilometers per hour", Map("unit", "Kilometer/Hour (km/h)", "category", "Speed"),
            "m/s|mps|meters per second", Map("unit", "Meter/Second (m/s)", "category", "Speed"),
            "kn|knot|knots", Map("unit", "Knot (kn)", "category", "Speed"),
            
            ; Data Storage units
            "bit|bits", Map("unit", "Bit", "category", "Data Storage"),
            "byte|bytes|b", Map("unit", "Byte (B)", "category", "Data Storage"),
            "kb|kilobyte|kilobytes", Map("unit", "Kilobyte (KB)", "category", "Data Storage"),
            "mb|megabyte|megabytes", Map("unit", "Megabyte (MB)", "category", "Data Storage"),
            "gb|gigabyte|gigabytes", Map("unit", "Gigabyte (GB)", "category", "Data Storage"),
            "tb|terabyte|terabytes", Map("unit", "Terabyte (TB)", "category", "Data Storage"),
            "pb|petabyte|petabytes", Map("unit", "Petabyte (PB)", "category", "Data Storage"),
            "kib|kibibyte|kibibytes", Map("unit", "Kibibyte (KiB)", "category", "Data Storage"),
            "mib|mebibyte|mebibytes", Map("unit", "Mebibyte (MiB)", "category", "Data Storage"),
            "gib|gibibyte|gibibytes", Map("unit", "Gibibyte (GiB)", "category", "Data Storage"),
            "tib|tebibyte|tebibytes", Map("unit", "Tebibyte (TiB)", "category", "Data Storage"),
            "pib|pebibyte|pebibytes", Map("unit", "Pebibyte (PiB)", "category", "Data Storage"),
            
            ; Time units
            "ns|nanosecond|nanoseconds", Map("unit", "Nanosecond (ns)", "category", "Time"),
            "μs|microsecond|microseconds", Map("unit", "Microsecond (μs)", "category", "Time"),
            "ms|millisecond|milliseconds", Map("unit", "Millisecond (ms)", "category", "Time"),
            "s|sec|second|seconds", Map("unit", "Second (s)", "category", "Time"),
            "min|minute|minutes", Map("unit", "Minute (min)", "category", "Time"),
            "h|hr|hour|hours", Map("unit", "Hour (h)", "category", "Time"),
            "day|days", Map("unit", "Day", "category", "Time"),
            "week|weeks", Map("unit", "Week", "category", "Time"),
            "month|months", Map("unit", "Month (30 days)", "category", "Time"),
            "year|years", Map("unit", "Year (365 days)", "category", "Time"),
            
            ; Frequency units
            "hz|hertz", Map("unit", "Hertz (Hz)", "category", "Frequency"),
            "khz|kilohertz", Map("unit", "Kilohertz (kHz)", "category", "Frequency"),
            "mhz|megahertz", Map("unit", "Megahertz (MHz)", "category", "Frequency"),
            "ghz|gigahertz", Map("unit", "Gigahertz (GHz)", "category", "Frequency"),
            "thz|terahertz", Map("unit", "Terahertz (THz)", "category", "Frequency"),
            "rpm", Map("unit", "RPM (rev/min)", "category", "Frequency"),
            "bpm", Map("unit", "BPM (beats/min)", "category", "Frequency"),
            
            ; Force units
            "n|newton|newtons", Map("unit", "Newton (N)", "category", "Force"),
            "kn|kilonewton|kilonewtons", Map("unit", "Kilonewton (kN)", "category", "Force"),
            "dyn|dyne|dynes", Map("unit", "Dyne (dyn)", "category", "Force"),
            "lbf|pound-force|pounds-force", Map("unit", "Pound-force (lbf)", "category", "Force"),
            "kgf|kilogram-force", Map("unit", "Kilogram-force (kgf)", "category", "Force"),
            "gf|gram-force", Map("unit", "Gram-force (gf)", "category", "Force"),
            "ozf|ounce-force", Map("unit", "Ounce-force (ozf)", "category", "Force"),
            "pdl|poundal", Map("unit", "Poundal (pdl)", "category", "Force"),
            
            ; Torque units
            "nm|newton-meter|newton-meters", Map("unit", "Newton-meter (N⋅m)", "category", "Torque"),
            "ncm|newton-centimeter", Map("unit", "Newton-centimeter (N⋅cm)", "category", "Torque"),
            "lbft|lb-ft|pound-foot|foot-pound", Map("unit", "Pound-force foot (lbf⋅ft)", "category", "Torque"),
            "lbin|lb-in|pound-inch|inch-pound", Map("unit", "Pound-force inch (lbf⋅in)", "category", "Torque"),
            
            ; Electric Current units
            "a|amp|amps|ampere|amperes", Map("unit", "Ampere (A)", "category", "Electric Current"),
            "ma|milliamp|milliampere", Map("unit", "Milliampere (mA)", "category", "Electric Current"),
            "μa|microamp|microampere", Map("unit", "Microampere (μA)", "category", "Electric Current"),
            "na|nanoamp|nanoampere", Map("unit", "Nanoampere (nA)", "category", "Electric Current"),
            "ka|kiloamp|kiloampere", Map("unit", "Kiloampere (kA)", "category", "Electric Current"),
            
            ; Electric Voltage units
            "v|volt|volts", Map("unit", "Volt (V)", "category", "Electric Voltage"),
            "mv|millivolt|millivolts", Map("unit", "Millivolt (mV)", "category", "Electric Voltage"),
            "μv|microvolt|microvolts", Map("unit", "Microvolt (μV)", "category", "Electric Voltage"),
            "kv|kilovolt|kilovolts", Map("unit", "Kilovolt (kV)", "category", "Electric Voltage"),
            
            ; Electric Resistance units
            "ω|ohm|ohms", Map("unit", "Ohm (Ω)", "category", "Electric Resistance"),
            "mω|milliohm|milliohms", Map("unit", "Milliohm (mΩ)", "category", "Electric Resistance"),
            "kω|kiloohm|kiloohms", Map("unit", "Kiloohm (kΩ)", "category", "Electric Resistance"),
            "mω|megaohm|megaohms", Map("unit", "Megaohm (MΩ)", "category", "Electric Resistance"),
            
            ; Electric Capacitance units
            "f|farad|farads", Map("unit", "Farad (F)", "category", "Electric Capacitance"),
            "μf|microfarad|microfarads", Map("unit", "Microfarad (μF)", "category", "Electric Capacitance"),
            "nf|nanofarad|nanofarads", Map("unit", "Nanofarad (nF)", "category", "Electric Capacitance"),
            "pf|picofarad|picofarads", Map("unit", "Picofarad (pF)", "category", "Electric Capacitance"),
            
            ; Electric Inductance units
            "h|henry|henrys", Map("unit", "Henry (H)", "category", "Electric Inductance"),
            "mh|millihenry|millihenrys", Map("unit", "Millihenry (mH)", "category", "Electric Inductance"),
            "μh|microhenry|microhenrys", Map("unit", "Microhenry (μH)", "category", "Electric Inductance"),
            
            ; Magnetic Field units
            "t|tesla|teslas", Map("unit", "Tesla (T)", "category", "Magnetic Field"),
            "mt|millitesla", Map("unit", "Millitesla (mT)", "category", "Magnetic Field"),
            "μt|microtesla", Map("unit", "Microtesla (μT)", "category", "Magnetic Field"),
            "g|gauss", Map("unit", "Gauss (G)", "category", "Magnetic Field"),
            
            ; Angular units
            "rad|radian|radians", Map("unit", "Radian (rad)", "category", "Angle"),
            "°|deg|degree|degrees", Map("unit", "Degree (°)", "category", "Angle"),
            "grad|gradian|gradians", Map("unit", "Gradian (grad)", "category", "Angle"),
            "rev|revolution|revolutions", Map("unit", "Revolution (rev)", "category", "Angle"),
            "mrad|milliradian|milliradians", Map("unit", "Milliradian (mrad)", "category", "Angle"),
            
            ; Acceleration units
            "m/s²|m/s2|meter per second squared", Map("unit", "Meter/second² (m/s²)", "category", "Acceleration"),
            "ft/s²|ft/s2|foot per second squared", Map("unit", "Foot/second² (ft/s²)", "category", "Acceleration"),
            "gal", Map("unit", "Gal (cm/s²)", "category", "Acceleration"),
            
            ; Density units
            "kg/m³|kg/m3", Map("unit", "kg/m³", "category", "Density"),
            "g/cm³|g/cm3", Map("unit", "g/cm³", "category", "Density"),
            "lb/ft³|lb/ft3", Map("unit", "lb/ft³", "category", "Density"),
            
            ; Illuminance units
            "lx|lux", Map("unit", "Lux (lx)", "category", "Illuminance"),
            "fc|foot-candle|foot-candles", Map("unit", "Foot-candle (fc)", "category", "Illuminance"),
            
            ; Luminous Intensity units
            "cd|candela|candelas", Map("unit", "Candela (cd)", "category", "Luminous Intensity")
        )
        
        ; Try different patterns to extract value and unit
        ; Pattern 1: Number followed by unit (e.g., "100 kg", "5.5 ft", "25°C")
        for pattern, unitInfo in unitPatterns {
            regexPattern := "(\d+(?:\.\d+)?)\s*(" . pattern . ")(?:\s|$)"
            if RegExMatch(text, "i)" . regexPattern, &match) {
                value := match[1]
                unit := unitInfo["unit"]
                category := unitInfo["category"]
                return
            }
        }
        
        ; Pattern 2: Unit followed by number (e.g., "kg 100", "miles 5.5")
        for pattern, unitInfo in unitPatterns {
            regexPattern := "(" . pattern . ")\s*(\d+(?:\.\d+)?)"
            if RegExMatch(text, "i)" . regexPattern, &match) {
                value := match[2]
                unit := unitInfo["unit"]
                category := unitInfo["category"]
                return
            }
        }
        
        ; Pattern 3: Just a number (assume meters for length)
        if RegExMatch(text, "^\d+(?:\.\d+)?$") {
            value := text
            unit := "Meter (m)"
            category := "Length"
            return
        }
        
        ; No valid pattern found
        value := ""
        unit := ""
        category := ""
    }
    
    ; Show settings dialog
    ShowSettings() {
        if (!this.Enabled) {
            MsgBox("Unit Converter plugin is disabled.", "Plugin Disabled", "Icon!")
            return
        }
        
        ; For now, just show the main converter (settings can be added later)
        this.ShowConverter()
    }
    
    ; Initialize comprehensive unit conversion data
    InitializeUnitData() {
        ; Length conversions (base unit: meter)
        this.UnitCategories["Length"] := Map(
            "Millimeter (mm)", 0.001,
            "Centimeter (cm)", 0.01,
            "Meter (m)", 1.0,
            "Kilometer (km)", 1000.0,
            "Inch (in)", 0.0254,
            "Foot (ft)", 0.3048,
            "Yard (yd)", 0.9144,
            "Mile (mi)", 1609.344,
            "Nautical Mile (nmi)", 1852.0,
            "Micron (μm)", 0.000001,
            "Nanometer (nm)", 0.000000001
        )
        
        ; Weight/Mass conversions (base unit: kilogram)
        this.UnitCategories["Weight"] := Map(
            "Milligram (mg)", 0.000001,
            "Gram (g)", 0.001,
            "Kilogram (kg)", 1.0,
            "Metric Ton (t)", 1000.0,
            "Ounce (oz)", 0.0283495,
            "Pound (lb)", 0.453592,
            "Stone (st)", 6.35029,
            "US Ton", 907.185,
            "Imperial Ton", 1016.05,
            "Carat (ct)", 0.0002
        )
        
        ; Volume conversions (base unit: liter)
        this.UnitCategories["Volume"] := Map(
            "Milliliter (ml)", 0.001,
            "Liter (l)", 1.0,
            "Cubic Meter (m³)", 1000.0,
            "Cubic Centimeter (cm³)", 0.001,
            "Fluid Ounce (fl oz)", 0.0295735,
            "Cup (US)", 0.236588,
            "Pint (US)", 0.473176,
            "Quart (US)", 0.946353,
            "Gallon (US)", 3.78541,
            "Pint (Imperial)", 0.568261,
            "Gallon (Imperial)", 4.54609,
            "Tablespoon (tbsp)", 0.0147868,
            "Teaspoon (tsp)", 0.00492892
        )
        
        ; Area conversions (base unit: square meter)
        this.UnitCategories["Area"] := Map(
            "Square Millimeter (mm²)", 0.000001,
            "Square Centimeter (cm²)", 0.0001,
            "Square Meter (m²)", 1.0,
            "Square Kilometer (km²)", 1000000.0,
            "Hectare (ha)", 10000.0,
            "Square Inch (in²)", 0.00064516,
            "Square Foot (ft²)", 0.092903,
            "Square Yard (yd²)", 0.836127,
            "Acre", 4046.86,
            "Square Mile (mi²)", 2590000.0
        )
        
        ; Speed conversions (base unit: meter per second)
        this.UnitCategories["Speed"] := Map(
            "Meter/Second (m/s)", 1.0,
            "Kilometer/Hour (km/h)", 0.277778,
            "Mile/Hour (mph)", 0.44704,
            "Foot/Second (ft/s)", 0.3048,
            "Knot (kn)", 0.514444,
            "Mach (at sea level)", 343.0
        )
        
        ; Energy conversions (base unit: joule)
        this.UnitCategories["Energy"] := Map(
            "Joule (J)", 1.0,
            "Kilojoule (kJ)", 1000.0,
            "Calorie (cal)", 4.184,
            "Kilocalorie (kcal)", 4184.0,
            "BTU", 1055.06,
            "Watt-hour (Wh)", 3600.0,
            "Kilowatt-hour (kWh)", 3600000.0,
            "Foot-pound (ft⋅lb)", 1.35582
        )
        
        ; Power conversions (base unit: watt)
        this.UnitCategories["Power"] := Map(
            "Watt (W)", 1.0,
            "Kilowatt (kW)", 1000.0,
            "Megawatt (MW)", 1000000.0,
            "Horsepower (hp)", 745.7,
            "BTU/hour", 0.293071
        )
        
        ; Pressure conversions (base unit: pascal)
        this.UnitCategories["Pressure"] := Map(
            "Pascal (Pa)", 1.0,
            "Kilopascal (kPa)", 1000.0,
            "Megapascal (MPa)", 1000000.0,
            "Bar", 100000.0,
            "Atmosphere (atm)", 101325.0,
            "PSI (lb/in²)", 6894.76,
            "Torr (mmHg)", 133.322,
            "Inch of Mercury (inHg)", 3386.39
        )
        
        ; Data Storage conversions (base unit: byte)
        this.UnitCategories["Data Storage"] := Map(
            "Bit", 0.125,
            "Byte (B)", 1.0,
            "Kilobyte (KB)", 1000.0,
            "Megabyte (MB)", 1000000.0,
            "Gigabyte (GB)", 1000000000.0,
            "Terabyte (TB)", 1000000000000.0,
            "Petabyte (PB)", 1000000000000000.0,
            "Kibibyte (KiB)", 1024.0,
            "Mebibyte (MiB)", 1048576.0,
            "Gibibyte (GiB)", 1073741824.0,
            "Tebibyte (TiB)", 1099511627776.0,
            "Pebibyte (PiB)", 1125899906842624.0
        )
        
        ; Time conversions (base unit: second)
        this.UnitCategories["Time"] := Map(
            "Nanosecond (ns)", 0.000000001,
            "Microsecond (μs)", 0.000001,
            "Millisecond (ms)", 0.001,
            "Second (s)", 1.0,
            "Minute (min)", 60.0,
            "Hour (h)", 3600.0,
            "Day", 86400.0,
            "Week", 604800.0,
            "Month (30 days)", 2592000.0,
            "Year (365 days)", 31536000.0,
            "Decade", 315360000.0,
            "Century", 3153600000.0
        )
        
        ; Frequency conversions (base unit: Hertz)
        this.UnitCategories["Frequency"] := Map(
            "Hertz (Hz)", 1.0,
            "Kilohertz (kHz)", 1000.0,
            "Megahertz (MHz)", 1000000.0,
            "Gigahertz (GHz)", 1000000000.0,
            "Terahertz (THz)", 1000000000000.0,
            "RPM (rev/min)", 0.0166667,
            "BPM (beats/min)", 0.0166667
        )
        
        ; Temperature conversions (special handling required)
        this.UnitCategories["Temperature"] := Map(
            "Celsius (°C)", "C",
            "Fahrenheit (°F)", "F",
            "Kelvin (K)", "K",
            "Rankine (°R)", "R"
        )
        
        ; Force conversions (base unit: Newton)
        this.UnitCategories["Force"] := Map(
            "Newton (N)", 1.0,
            "Kilonewton (kN)", 1000.0,
            "Dyne (dyn)", 0.00001,
            "Pound-force (lbf)", 4.44822,
            "Kilogram-force (kgf)", 9.80665,
            "Gram-force (gf)", 0.00980665,
            "Ounce-force (ozf)", 0.278014,
            "Poundal (pdl)", 0.138255
        )
        
        ; Torque/Moment conversions (base unit: Newton-meter)
        this.UnitCategories["Torque"] := Map(
            "Newton-meter (N⋅m)", 1.0,
            "Newton-centimeter (N⋅cm)", 0.01,
            "Kilogram-force meter (kgf⋅m)", 9.80665,
            "Pound-force foot (lbf⋅ft)", 1.35582,
            "Pound-force inch (lbf⋅in)", 0.112985,
            "Ounce-force inch (ozf⋅in)", 0.00706155,
            "Dyne-centimeter (dyn⋅cm)", 0.0000001
        )
        
        ; Electric Current conversions (base unit: Ampere)
        this.UnitCategories["Electric Current"] := Map(
            "Ampere (A)", 1.0,
            "Milliampere (mA)", 0.001,
            "Microampere (μA)", 0.000001,
            "Nanoampere (nA)", 0.000000001,
            "Picoampere (pA)", 0.000000000001,
            "Kiloampere (kA)", 1000.0,
            "Abampere (abA)", 10.0,
            "Statampere (statA)", 3.33564e-10
        )
        
        ; Electric Voltage conversions (base unit: Volt)
        this.UnitCategories["Electric Voltage"] := Map(
            "Volt (V)", 1.0,
            "Millivolt (mV)", 0.001,
            "Microvolt (μV)", 0.000001,
            "Nanovolt (nV)", 0.000000001,
            "Kilovolt (kV)", 1000.0,
            "Megavolt (MV)", 1000000.0,
            "Abvolt (abV)", 0.00000001,
            "Statvolt (statV)", 299.792458
        )
        
        ; Electric Resistance conversions (base unit: Ohm)
        this.UnitCategories["Electric Resistance"] := Map(
            "Ohm (Ω)", 1.0,
            "Milliohm (mΩ)", 0.001,
            "Microohm (μΩ)", 0.000001,
            "Kiloohm (kΩ)", 1000.0,
            "Megaohm (MΩ)", 1000000.0,
            "Gigaohm (GΩ)", 1000000000.0,
            "Abohm (abΩ)", 0.000000001,
            "Statohm (statΩ)", 8.98755e11
        )
        
        ; Electric Capacitance conversions (base unit: Farad)
        this.UnitCategories["Electric Capacitance"] := Map(
            "Farad (F)", 1.0,
            "Millifarad (mF)", 0.001,
            "Microfarad (μF)", 0.000001,
            "Nanofarad (nF)", 0.000000001,
            "Picofarad (pF)", 0.000000000001,
            "Femtofarad (fF)", 0.000000000000001,
            "Abfarad (abF)", 1000000000.0,
            "Statfarad (statF)", 1.11265e-12
        )
        
        ; Electric Inductance conversions (base unit: Henry)
        this.UnitCategories["Electric Inductance"] := Map(
            "Henry (H)", 1.0,
            "Millihenry (mH)", 0.001,
            "Microhenry (μH)", 0.000001,
            "Nanohenry (nH)", 0.000000001,
            "Picohenry (pH)", 0.000000000001,
            "Kilohenry (kH)", 1000.0,
            "Abhenry (abH)", 0.000000001,
            "Stathenry (statH)", 8.98755e11
        )
        
        ; Magnetic Field conversions (base unit: Tesla)
        this.UnitCategories["Magnetic Field"] := Map(
            "Tesla (T)", 1.0,
            "Millitesla (mT)", 0.001,
            "Microtesla (μT)", 0.000001,
            "Nanotesla (nT)", 0.000000001,
            "Gauss (G)", 0.0001,
            "Milligauss (mG)", 0.0000001,
            "Weber/m² (Wb/m²)", 1.0,
            "Maxwell/cm² (Mx/cm²)", 0.0001
        )
        
        ; Angular conversions (base unit: radian)
        this.UnitCategories["Angle"] := Map(
            "Radian (rad)", 1.0,
            "Degree (°)", 0.0174533,
            "Gradian (grad)", 0.0157080,
            "Revolution (rev)", 6.28319,
            "Arcminute (')", 0.000290888,
            "Arcsecond ('')", 4.84814e-6,
            "Milliradian (mrad)", 0.001,
            "Turn", 6.28319
        )
        
        ; Angular Velocity conversions (base unit: radian per second)
        this.UnitCategories["Angular Velocity"] := Map(
            "Radian/second (rad/s)", 1.0,
            "Degree/second (°/s)", 0.0174533,
            "Revolution/minute (rpm)", 0.104720,
            "Revolution/second (rps)", 6.28319,
            "Revolution/hour (rph)", 0.00174533,
            "Degree/minute (°/min)", 0.000290888,
            "Degree/hour (°/h)", 4.84814e-6
        )
        
        ; Acceleration conversions (base unit: meter per second squared)
        this.UnitCategories["Acceleration"] := Map(
            "Meter/second² (m/s²)", 1.0,
            "Kilometer/hour² (km/h²)", 7.71605e-8,
            "Mile/hour² (mi/h²)", 1.24178e-7,
            "Foot/second² (ft/s²)", 0.3048,
            "Inch/second² (in/s²)", 0.0254,
            "Gal (cm/s²)", 0.01,
            "Standard gravity (g)", 9.80665,
            "Knot/second (kn/s)", 0.514444
        )
        
        ; Density conversions (base unit: kilogram per cubic meter)
        this.UnitCategories["Density"] := Map(
            "kg/m³", 1.0,
            "g/cm³", 1000.0,
            "g/mL", 1000.0,
            "kg/L", 1000.0,
            "lb/ft³", 16.0185,
            "lb/in³", 27679.9,
            "oz/in³", 1729.99,
            "slug/ft³", 515.379,
            "g/L", 1.0,
            "mg/mL", 1.0
        )
        
        ; Dynamic Viscosity conversions (base unit: Pascal-second)
        this.UnitCategories["Dynamic Viscosity"] := Map(
            "Pascal-second (Pa⋅s)", 1.0,
            "Poise (P)", 0.1,
            "Centipoise (cP)", 0.001,
            "Millipascal-second (mPa⋅s)", 0.001,
            "Micropascal-second (μPa⋅s)", 0.000001,
            "Pound-force second/ft² (lbf⋅s/ft²)", 47.8803,
            "Pound/foot-second (lb/ft⋅s)", 1.48816,
            "Reyn (lbf⋅s/in²)", 6895.0
        )
        
        ; Kinematic Viscosity conversions (base unit: square meter per second)
        this.UnitCategories["Kinematic Viscosity"] := Map(
            "m²/s", 1.0,
            "cm²/s (Stokes)", 0.0001,
            "mm²/s (Centistokes)", 0.000001,
            "ft²/s", 0.092903,
            "in²/s", 0.00064516,
            "ft²/h", 2.58064e-5,
            "cm²/min", 1.66667e-6
        )
        
        ; Luminous Intensity conversions (base unit: candela)
        this.UnitCategories["Luminous Intensity"] := Map(
            "Candela (cd)", 1.0,
            "Candle (international)", 1.02,
            "Carcel unit", 9.74,
            "Decimal candle", 1.0,
            "Hefner candle", 0.903,
            "Pentane candle", 1.0,
            "Violle", 20.17
        )
        
        ; Luminance conversions (base unit: candela per square meter)
        this.UnitCategories["Luminance"] := Map(
            "cd/m² (nit)", 1.0,
            "cd/cm²", 10000.0,
            "cd/ft²", 10.7639,
            "cd/in²", 1550.0,
            "Lambert (L)", 3183.1,
            "Foot-lambert (fL)", 3.42626,
            "Stilb (sb)", 10000.0,
            "Apostilb (asb)", 0.31831
        )
        
        ; Illuminance conversions (base unit: lux)
        this.UnitCategories["Illuminance"] := Map(
            "Lux (lx)", 1.0,
            "Kilolux (klx)", 1000.0,
            "Millilux (mlx)", 0.001,
            "Foot-candle (fc)", 10.7639,
            "Phot (ph)", 10000.0,
            "Nox", 0.001,
            "Meter-candle", 1.0,
            "Centimeter-candle", 10000.0
        )
    }
    
    ; Show the main converter GUI (simplified)
    ShowConverter(parsedValue := "", parsedUnit := "", parsedCategory := "") {
        
        ; Close existing GUI if open
        if (this.ConverterGui) {
            try {
                this.ConverterGui.Destroy()
            } catch {
                ; Ignore errors
            }
        }
        
        ; Create simplified converter window
        this.ConverterGui := Gui("+AlwaysOnTop", "Unit Converter")
        this.ConverterGui.SetFont("s10", "Segoe UI")
        this.ConverterGui.BackColor := 0xF5F5F5
        
        ; Category selection
        this.ConverterGui.Add("Text", "x10 y10", "Category:")
        this.CategoryDropdown := this.ConverterGui.Add("ComboBox", "x70 y7 w200", this.GetCategoryNames())
        this.CategoryDropdown.OnEvent("Change", (*) => this.OnCategoryChange())
        
        ; Value input
        this.ConverterGui.Add("Text", "x10 y40", "Value:")
        this.InputValue := this.ConverterGui.Add("Edit", "x50 y37 w100")
        this.InputValue.OnEvent("Change", (*) => this.OnInputChange())
        
        ; From unit
        this.ConverterGui.Add("Text", "x160 y40", "From:")
        this.FromUnitDropdown := this.ConverterGui.Add("ComboBox", "x200 y37 w180", [])
        this.FromUnitDropdown.OnEvent("Change", (*) => this.OnUnitChange())
        
        ; To unit
        this.ConverterGui.Add("Text", "x10 y70", "To:")
        this.ToUnitDropdown := this.ConverterGui.Add("ComboBox", "x40 y67 w180", [])
        this.ToUnitDropdown.OnEvent("Change", (*) => this.OnUnitChange())
        
        ; Result display
        this.ConverterGui.Add("Text", "x230 y70", "Result:")
        this.OutputValue := this.ConverterGui.Add("Edit", "x280 y67 w100 ReadOnly")
        this.OutputValue.SetFont("s10 Bold")
        
        ; Copy button
        copyBtn := this.ConverterGui.Add("Button", "x390 y67 w25 h23", "📋")
        copyBtn.OnEvent("Click", (*) => this.CopyResult())
        
        ; Result text
        this.ResultText := this.ConverterGui.Add("Edit", "x10 y100 w405 h40 ReadOnly")
        this.ResultText.SetFont("s9")
        
        ; Quick conversion buttons
        quickBtn1 := this.ConverterGui.Add("Button", "x10 y150 w75 h25", "°C ↔ °F")
        quickBtn1.OnEvent("Click", (*) => this.QuickTemperatureConversion())
        
        quickBtn2 := this.ConverterGui.Add("Button", "x95 y150 w75 h25", "km ↔ mi")
        quickBtn2.OnEvent("Click", (*) => this.QuickDistanceConversion())
        
        quickBtn3 := this.ConverterGui.Add("Button", "x180 y150 w75 h25", "kg ↔ lb")
        quickBtn3.OnEvent("Click", (*) => this.QuickWeightConversion())
        
        quickBtn4 := this.ConverterGui.Add("Button", "x265 y150 w65 h25", "L ↔ gal")
        quickBtn4.OnEvent("Click", (*) => this.QuickVolumeConversion())
        
        clearBtn := this.ConverterGui.Add("Button", "x340 y150 w65 h25", "Clear")
        clearBtn.OnEvent("Click", (*) => this.ClearFields())
        
        ; Close button
        closeBtn := this.ConverterGui.Add("Button", "x10 y185 w80 h30", "Close")
        closeBtn.OnEvent("Click", (*) => this.ConverterGui.Destroy())
        
        ; Swap button
        swapBtn := this.ConverterGui.Add("Button", "x100 y185 w80 h30", "Swap")
        swapBtn.OnEvent("Click", (*) => this.SwapUnits())
        
        ; Event handlers
        this.ConverterGui.OnEvent("Close", (*) => this.ConverterGui.Destroy())
        this.ConverterGui.OnEvent("Escape", (*) => this.ConverterGui.Destroy())
        
        ; Initialize with parsed category or first category
        if (parsedCategory && this.HasCategory(parsedCategory)) {
            ; Set to parsed category
            this.CategoryDropdown.Text := parsedCategory
            this.OnCategoryChange()
            
            ; Set the from unit if parsed
            if (parsedUnit && this.HasUnitInCategory(parsedCategory, parsedUnit)) {
                this.FromUnitDropdown.Text := parsedUnit
                
                ; Auto-select a good "to" unit for common conversions
                this.AutoSelectToUnit(parsedCategory, parsedUnit)
            }
        } else {
            ; Use first category as default
            this.CategoryDropdown.Choose(1)
            this.OnCategoryChange()
        }
        
        ; Show the GUI
        this.ConverterGui.Show("w425 h225")
        
        ; Pre-fill value AFTER GUI is set up
        if parsedValue {
            this.InputValue.Text := parsedValue
        }
        
        ; Focus the input field
        this.InputValue.Focus()
        
        ; Auto-convert if we have parsed data
        if (parsedValue && parsedUnit && parsedCategory) {
            ; Add status message
            this.ResultText.Text := "Auto-detected: " parsedValue " " parsedUnit " from selected text"
            ; Trigger conversion after a short delay
            SetTimer(() => this.PerformConversion(), -200)
        }
    }
    
    ; Get list of category names
    GetCategoryNames() {
        categories := []
        for category in this.UnitCategories {
            categories.Push(category)
        }
        return categories
    }
    
    ; Handle category selection change
    OnCategoryChange() {
        selectedCategory := this.CategoryDropdown.Text
        
        if (selectedCategory && this.UnitCategories.Has(selectedCategory)) {
            units := []
            for unit in this.UnitCategories[selectedCategory] {
                units.Push(unit)
            }
            
            ; Update both dropdowns
            this.FromUnitDropdown.Delete()
            this.ToUnitDropdown.Delete()
            
            for unit in units {
                this.FromUnitDropdown.Add([unit])
                this.ToUnitDropdown.Add([unit])
            }
            
            ; Select first units
            if (units.Length > 0) {
                this.FromUnitDropdown.Choose(1)
                if (units.Length > 1) {
                    this.ToUnitDropdown.Choose(2)
                } else {
                    this.ToUnitDropdown.Choose(1)
                }
            }
            
            ; Clear previous results
            this.ClearFields()
        }
    }
    
    ; Handle unit selection change
    OnUnitChange() {
        ; Auto-convert if input value exists
        if (this.InputValue.Text != "") {
            this.PerformConversion()
        }
    }
    
    ; Handle input value change
    OnInputChange() {
        ; Auto-convert as user types (with small delay)
        SetTimer(() => this.PerformConversion(), -300)
    }
    
    ; Perform the main conversion
    PerformConversion() {
        try {
            inputText := Trim(this.InputValue.Text)
            if (inputText = "") {
                this.OutputValue.Text := ""
                this.ResultText.Text := ""
                return
            }
            
            ; Parse input value
            inputValue := Number(inputText)
            if (!IsNumber(inputValue)) {
                this.OutputValue.Text := "Invalid input"
                this.ResultText.Text := "Please enter a valid number"
                return
            }
            
            selectedCategory := this.CategoryDropdown.Text
            fromUnit := this.FromUnitDropdown.Text
            toUnit := this.ToUnitDropdown.Text
            
            if (!selectedCategory || !fromUnit || !toUnit) {
                return
            }
            
            ; Special handling for temperature
            if (selectedCategory = "Temperature") {
                result := this.ConvertTemperature(inputValue, fromUnit, toUnit)
            } else {
                result := this.ConvertStandardUnits(inputValue, selectedCategory, fromUnit, toUnit)
            }
            
            if (result !== "") {
                ; Format result
                formattedResult := this.FormatNumber(result)
                this.OutputValue.Text := formattedResult
                
                ; Update result text
                this.ResultText.Text := inputText " " fromUnit " = " formattedResult " " toUnit
                
                ; Update GUI (history removed for simplicity)
            }
            
        } catch as e {
            this.OutputValue.Text := "Error"
            this.ResultText.Text := "Conversion error: " e.Message
        }
    }
    
    ; Convert standard units (non-temperature)
    ConvertStandardUnits(value, category, fromUnit, toUnit) {
        if (!this.UnitCategories.Has(category)) {
            return ""
        }
        
        unitMap := this.UnitCategories[category]
        
        if (!unitMap.Has(fromUnit) || !unitMap.Has(toUnit)) {
            return ""
        }
        
        ; Convert to base unit, then to target unit
        baseValue := value * unitMap[fromUnit]
        result := baseValue / unitMap[toUnit]
        
        return result
    }
    
    ; Convert temperature (requires special formulas)
    ConvertTemperature(value, fromUnit, toUnit) {
        ; Temperature conversion requires special handling
        
        ; Convert to Celsius first
        celsius := 0
        switch fromUnit {
            case "Celsius (°C)":
                celsius := value
            case "Fahrenheit (°F)":
                celsius := (value - 32) * 5/9
            case "Kelvin (K)":
                celsius := value - 273.15
            case "Rankine (°R)":
                celsius := (value - 491.67) * 5/9
            default:
                return ""
        }
        
        ; Convert from Celsius to target
        switch toUnit {
            case "Celsius (°C)":
                return celsius
            case "Fahrenheit (°F)":
                return celsius * 9/5 + 32
            case "Kelvin (K)":
                return celsius + 273.15
            case "Rankine (°R)":
                return (celsius + 273.15) * 9/5
            default:
                return ""
        }
    }
    
    ; Format number for display
    FormatNumber(num) {
        ; Handle very small numbers
        if (Abs(num) < 0.001 && num != 0) {
            return Format("{:.2e}", num)
        }
        
        ; Handle very large numbers
        if (Abs(num) >= 1000000) {
            return Format("{:.2e}", num)
        }
        
        ; Standard formatting
        if (Abs(num) >= 1) {
            return Format("{:.6g}", num)
        } else {
            return Format("{:.8g}", num)
        }
    }
    
    ; Swap from and to units
    SwapUnits() {
        try {
            fromUnit := this.FromUnitDropdown.Text
            toUnit := this.ToUnitDropdown.Text
            
            ; Swap the units
            this.FromUnitDropdown.Text := toUnit
            this.ToUnitDropdown.Text := fromUnit
            
            ; Trigger conversion if we have a value
            if (this.InputValue.Text != "") {
                this.PerformConversion()
            }
        } catch as e {
            ; Handle error silently
        }
    }
    
    ; Quick conversion methods
    QuickTemperatureConversion() {
        this.CategoryDropdown.Text := "Temperature"
        this.OnCategoryChange()
        this.FromUnitDropdown.Text := "Celsius (°C)"
        this.ToUnitDropdown.Text := "Fahrenheit (°F)"
        this.InputValue.Focus()
    }
    
    QuickDistanceConversion() {
        this.CategoryDropdown.Text := "Length"
        this.OnCategoryChange()
        this.FromUnitDropdown.Text := "Kilometer (km)"
        this.ToUnitDropdown.Text := "Mile (mi)"
        this.InputValue.Focus()
    }
    
    QuickWeightConversion() {
        this.CategoryDropdown.Text := "Weight"
        this.OnCategoryChange()
        this.FromUnitDropdown.Text := "Kilogram (kg)"
        this.ToUnitDropdown.Text := "Pound (lb)"
        this.InputValue.Focus()
    }
    
    QuickVolumeConversion() {
        this.CategoryDropdown.Text := "Volume"
        this.OnCategoryChange()
        this.FromUnitDropdown.Text := "Liter (l)"
        this.ToUnitDropdown.Text := "Gallon (US)"
        this.InputValue.Focus()
    }
    
    ; Copy result to clipboard
    CopyResult() {
        if (this.ResultText.Text != "") {
            A_Clipboard := this.ResultText.Text
            ShowMouseTooltip("Result copied to clipboard!", 1500)
        }
    }
    
    ; Clear input fields
    ClearFields() {
        this.InputValue.Text := ""
        this.OutputValue.Text := ""
        this.ResultText.Text := ""
    }
    

    
    ; Helper method to check if category exists
    HasCategory(categoryName) {
        return this.UnitCategories.Has(categoryName)
    }
    
    ; Helper method to check if unit exists in category
    HasUnitInCategory(categoryName, unitName) {
        if (!this.UnitCategories.Has(categoryName)) {
            return false
        }
        
        return this.UnitCategories[categoryName].Has(unitName)
    }
    
    ; Auto-select a good "to" unit for common conversions
    AutoSelectToUnit(category, fromUnit) {
        ; Common conversion pairs
        conversionPairs := Map(
            ; Length conversions
            "Meter (m)", "Foot (ft)",
            "Foot (ft)", "Meter (m)",
            "Kilometer (km)", "Mile (mi)",
            "Mile (mi)", "Kilometer (km)",
            "Centimeter (cm)", "Inch (in)",
            "Inch (in)", "Centimeter (cm)",
            
            ; Weight conversions
            "Kilogram (kg)", "Pound (lb)",
            "Pound (lb)", "Kilogram (kg)",
            "Gram (g)", "Ounce (oz)",
            "Ounce (oz)", "Gram (g)",
            
            ; Volume conversions
            "Liter (l)", "Gallon (US)",
            "Gallon (US)", "Liter (l)",
            "Milliliter (ml)", "Fluid Ounce (fl oz)",
            "Fluid Ounce (fl oz)", "Milliliter (ml)",
            
            ; Temperature conversions
            "Celsius (°C)", "Fahrenheit (°F)",
            "Fahrenheit (°F)", "Celsius (°C)",
            "Kelvin (K)", "Celsius (°C)",
            
            ; Area conversions
            "Square Meter (m²)", "Square Foot (ft²)",
            "Square Foot (ft²)", "Square Meter (m²)",
            
            ; Speed conversions
            "Kilometer/Hour (km/h)", "Mile/Hour (mph)",
            "Mile/Hour (mph)", "Kilometer/Hour (km/h)"
        )
        
        ; Try to find a good conversion pair
        if (conversionPairs.Has(fromUnit)) {
            suggestedUnit := conversionPairs[fromUnit]
            if (this.HasUnitInCategory(category, suggestedUnit)) {
                this.ToUnitDropdown.Text := suggestedUnit
                return
            }
        }
        
        ; Fallback: select the first different unit in the category
        if (this.UnitCategories.Has(category)) {
            for unit in this.UnitCategories[category] {
                if (unit != fromUnit) {
                    this.ToUnitDropdown.Text := unit
                    return
                }
            }
        }
    }
}