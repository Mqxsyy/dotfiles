.pragma library

// Unit conversion for the launcher: "10 km to mi", "72 f in c", "3*12 in to cm".
// parse() splits the query into an amount expression and two unit names;
// convert() turns an amount from one unit into another.

// Every unit, grouped by what it measures. Keys are space-separated names for
// the same unit; values are the factor to the group's base unit (factor 1).
// Temperature also needs an offset, so its values are [factor, offset].
const dimensions = {
    length: {
        "mm millimeter millimeters millimetre millimetres": 0.001,
        "cm centimeter centimeters centimetre centimetres": 0.01,
        "m meter meters metre metres": 1,
        "km kilometer kilometers kilometre kilometres": 1000,
        "in inch inches": 0.0254,
        "ft foot feet": 0.3048,
        "yd yard yards": 0.9144,
        "mi mile miles": 1609.344,
        "nmi": 1852,
    },
    area: {
        "cm2 cm²": 0.0001,
        "m2 m² sqm": 1,
        "km2 km²": 1e6,
        "ha hectare hectares": 1e4,
        "ft2 ft² sqft": 0.09290304,
        "acre acres": 4046.8564224,
        "mi2 mi²": 2589988.110336,
    },
    volume: {
        "ml milliliter milliliters millilitre millilitres": 0.001,
        "cl": 0.01,
        "dl": 0.1,
        "l liter liters litre litres": 1,
        "m3 m³": 1000,
        "tsp teaspoon teaspoons": 0.00492892159375,
        "tbsp tablespoon tablespoons": 0.01478676478125,
        "floz": 0.0295735295625,
        "cup cups": 0.2365882365,
        "pt pint pints": 0.473176473,
        "qt quart quarts": 0.946352946,
        "gal gallon gallons": 3.785411784,
    },
    mass: {
        "mg milligram milligrams": 1e-6,
        "g gram grams": 0.001,
        "kg kilogram kilograms": 1,
        "t tonne tonnes": 1000,
        "oz ounce ounces": 0.028349523125,
        "lb lbs pound pounds": 0.45359237,
        "st stone stones": 6.35029318,
    },
    time: {
        "ms millisecond milliseconds": 0.001,
        "s sec secs second seconds": 1,
        "min mins minute minutes": 60,
        "h hr hrs hour hours": 3600,
        "d day days": 86400,
        "wk week weeks": 604800,
        "yr year years": 31557600,
    },
    speed: {
        "m/s mps": 1,
        "km/h kmh kph": 1 / 3.6,
        "mph": 0.44704,
        "ft/s fps": 0.3048,
        "kn knot knots": 1852 / 3600,
    },
    data: {
        "bit bits": 0.125,
        "b byte bytes": 1,
        "kb": 1e3,
        "mb": 1e6,
        "gb": 1e9,
        "tb": 1e12,
        "kib": 1024,
        "mib": 1024 ** 2,
        "gib": 1024 ** 3,
        "tib": 1024 ** 4,
    },
    angle: {
        "rad radian radians": 1,
        "deg degree degrees °": Math.PI / 180,
        "turn turns": 2 * Math.PI,
    },
    temperature: {
        "k kelvin": [1, 0],
        "c °c celsius": [1, 273.15],
        "f °f fahrenheit": [5 / 9, 459.67 * 5 / 9],
    },
};

// name -> { dimension, factor, offset }, built once from the table above.
const units = Object.create(null);
for (const dimension in dimensions) {
    for (const names in dimensions[dimension]) {
        const spec = dimensions[dimension][names];
        const [factor, offset] = Array.isArray(spec) ? spec : [spec, 0];
        for (const name of names.split(" "))
            units[name] = { dimension: dimension, factor: factor, offset: offset };
    }
}

// "<amount with a digit> <unit> to|in|as <unit>". The amount may be any calc
// expression; the greedy match keeps "5 in in cm" working.
const conversionPattern = /^(.*\d.*?)\s*([a-z°µ²³/]+[23]?)\s+(?:to|in|as)\s+([a-z°µ²³/]+[23]?)$/i;

// { amount, from, to } when the text is shaped like a conversion, else null.
// Unit names are not checked here, so "10 km to xyz" still counts as one.
function parse(text) {
    const match = text.trim().match(conversionPattern);
    if (match === null)
        return null;
    return { amount: match[1], from: match[2].toLowerCase(), to: match[3].toLowerCase() };
}

// The amount in the target unit, or null for unknown or mismatched units.
function convert(amount, from, to) {
    const source = units[from];
    const target = units[to];
    if (!source || !target || source.dimension !== target.dimension)
        return null;
    const base = amount * source.factor + source.offset;
    return (base - target.offset) / target.factor;
}
