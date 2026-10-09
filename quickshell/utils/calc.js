.pragma library

// Small calculator for the launcher. evaluate("2^10 / 4") returns 256, or null
// when the text is not a complete expression. No eval(): a recursive-descent
// parser over this grammar (lowest precedence first):
//
//   expr    = term (("+" | "-") term)*
//   term    = unary (("*" | "/" | "%") unary | unary)*   -- juxtaposition multiplies: 2pi, 3(4+1)
//   unary   = ("-" | "+") unary | power
//   power   = postfix ("^" unary)?                        -- right associative: 2^3^2 = 2^9
//   postfix = atom "!"*
//   atom    = number | constant | function unary | "(" expr ")"
//
// A missing closing ")" at the end is allowed, so "(2+3" already shows 5 while typing.

const constants = {
    pi: Math.PI,
    tau: 2 * Math.PI,
    e: Math.E,
};

const functions = {
    sqrt: Math.sqrt,
    cbrt: Math.cbrt,
    abs: Math.abs,
    sin: Math.sin,
    cos: Math.cos,
    tan: Math.tan,
    asin: Math.asin,
    acos: Math.acos,
    atan: Math.atan,
    ln: Math.log,
    log: Math.log10,
    exp: Math.exp,
    floor: Math.floor,
    ceil: Math.ceil,
    round: Math.round,
};

// Other ways of writing an operator.
const aliases = {
    "**": "^",
    "×": "*",
    "÷": "/",
};

const tokenPattern = /^\s*(\d*\.?\d+(?:e[+-]?\d+)?|[a-z]+|\*\*|[-+*/%^()!×÷])/i;

function has(table, key) {
    return Object.prototype.hasOwnProperty.call(table, key);
}

function isNumber(token) {
    return /^[\d.]/.test(token);
}

// Split text into tokens, or null when it contains something unknown.
function tokenize(text) {
    const tokens = [];
    let rest = text.trim();
    while (rest.length > 0) {
        const match = rest.match(tokenPattern);
        if (match === null)
            return null;
        const token = match[1].toLowerCase();
        tokens.push(has(aliases, token) ? aliases[token] : token);
        rest = rest.slice(match[0].length);
    }
    return tokens;
}

function factorial(n) {
    if (!Number.isInteger(n) || n < 0 || n > 170)
        return NaN;
    let result = 1;
    for (let i = 2; i <= n; i++)
        result *= i;
    return result;
}

function evaluate(text) {
    const tokens = tokenize(text.replace(/^=/, ""));
    if (tokens === null || tokens.length === 0)
        return null;

    let pos = 0;
    const peek = () => tokens[pos];
    const take = () => tokens[pos++];
    const startsOperand = token => token !== undefined && (isNumber(token) || /^[a-z(]/.test(token));

    function expr() {
        let value = term();
        while (peek() === "+" || peek() === "-")
            value = take() === "+" ? value + term() : value - term();
        return value;
    }

    function term() {
        let value = unary();
        for (;;) {
            const op = peek();
            if (op === "*") {
                take();
                value *= unary();
            } else if (op === "/") {
                take();
                value /= unary();
            } else if (op === "%") {
                take();
                value %= unary();
            } else if (startsOperand(op)) {
                value *= unary();
            } else {
                return value;
            }
        }
    }

    function unary() {
        if (peek() === "-") {
            take();
            return -unary();
        }
        if (peek() === "+") {
            take();
            return unary();
        }
        return power();
    }

    function power() {
        const base = postfix();
        if (peek() !== "^")
            return base;
        take();
        return Math.pow(base, unary());
    }

    function postfix() {
        let value = atom();
        while (peek() === "!") {
            take();
            value = factorial(value);
        }
        return value;
    }

    function atom() {
        const token = take();
        if (token === "(") {
            const value = expr();
            if (peek() === ")")
                take();
            return value;
        }
        if (token !== undefined && isNumber(token))
            return parseFloat(token);
        if (has(constants, token))
            return constants[token];
        if (has(functions, token))
            return functions[token](unary());
        throw new Error("unexpected token: " + token);
    }

    try {
        const value = expr();
        return pos === tokens.length && isFinite(value) ? value : null;
    } catch (error) {
        return null;
    }
}

// Whether the text is meant as math, so the launcher shows a result or
// "Invalid" for it. A leading "=" always counts. Otherwise it needs a digit
// and either an operator (math being typed, even if "2+" doesn't parse yet)
// or letters that compute ("2pi", "sqrt 2"). Lone numbers, words like "pi"
// and names like "1password" stay app searches.
function isExpression(text) {
    const trimmed = text.trim();
    if (trimmed.startsWith("="))
        return true;
    if (!/\d/.test(trimmed))
        return false;
    if (/[-+*/%^!()×÷]/.test(trimmed))
        return true;
    return /[a-z]/i.test(trimmed) && evaluate(trimmed) !== null;
}

// Round away float noise (0.1 + 0.2) and drop trailing zeros.
function format(value) {
    return String(parseFloat(value.toPrecision(12)));
}
