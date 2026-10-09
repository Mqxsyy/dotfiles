.pragma library

// fzf-style fuzzy matching. score(query, text) returns null when `text` does
// not contain every query character in order, otherwise a number where higher
// means a better match.

const bonus = {
    char: 1,        // every matched character
    run: 4,         // character directly follows the previous match
    wordStart: 6,   // character starts a word ("Studio" in "Visual Studio Code")
    initials: 15,   // query is a prefix of the word initials ("vsc")
    substring: 10,  // query appears as one piece
    prefix: 20,     // text starts with the query
};

const gapPenalty = 0.5;     // per skipped character, capped at 5 per match
const lengthPenalty = 0.05; // per text character, so shorter names win ties

const separator = /[\s\-_./]/;

function isWordStart(text, i) {
    if (i === 0)
        return true;
    const prev = text[i - 1];
    const current = text[i];
    const camelHump = prev === prev.toLowerCase() && current !== current.toLowerCase();
    return separator.test(prev) || camelHump;
}

function initials(text) {
    let result = "";
    for (let i = 0; i < text.length; i++) {
        if (!separator.test(text[i]) && isWordStart(text, i))
            result += text[i];
    }
    return result.toLowerCase();
}

function score(query, text) {
    const q = query.toLowerCase().replace(/\s+/g, "");
    const t = text.toLowerCase();
    if (q.length === 0)
        return 0;

    let total = 0;
    let from = 0;
    let last = -2;
    for (const ch of q) {
        const i = t.indexOf(ch, from);
        if (i === -1)
            return null;
        total += bonus.char;
        if (i === last + 1)
            total += bonus.run;
        if (isWordStart(text, i))
            total += bonus.wordStart;
        total -= Math.min(i - from, 5) * gapPenalty;
        last = i;
        from = i + 1;
    }

    const at = t.indexOf(q);
    if (at === 0)
        total += bonus.prefix;
    else if (at > 0)
        total += bonus.substring;
    if (initials(text).startsWith(q))
        total += bonus.initials;

    return total - t.length * lengthPenalty;
}

function asText(value) {
    if (value === undefined || value === null)
        return "";
    return typeof value === "string" ? value : Array.from(value).join(" ");
}

// Sort `items` by best match. `fields` maps an item property to how much a hit
// in that property counts, e.g. { name: 1, keywords: 0.5 }. Items that match
// in no field are dropped; equal scores keep their original order.
function rank(query, items, fields) {
    if (query.trim().length === 0)
        return items;

    const scored = [];
    for (let index = 0; index < items.length; index++) {
        const item = items[index];
        let best = null;
        for (const key in fields) {
            const s = score(query, asText(item[key]));
            if (s !== null && (best === null || s * fields[key] > best))
                best = s * fields[key];
        }
        if (best !== null)
            scored.push({ item: item, score: best, index: index });
    }
    scored.sort((a, b) => b.score - a.score || a.index - b.index);
    return scored.map(entry => entry.item);
}
