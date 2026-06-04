/**
 * @description Evaluates a Product Rule's Advanced_Condition__c formula against a
 * map of condition results keyed by Rule_Condition__c.Index__c.
 *
 * Grammar:
 *   expr    := term  ( 'OR'  term  )*
 *   term    := factor ( 'AND' factor )*
 *   factor  := 'NOT'? primary
 *   primary := '(' expr ')' | INTEGER
 *
 * Operator precedence: NOT > AND > OR. Use parentheses to force grouping.
 * Token matching is case-insensitive. References to indices that are not
 * present in the results map evaluate to false (defensive — usually means
 * the formula references a deleted condition).
 *
 * @author Sales Cloud ERP Integration Team
 */
public inherited sharing class CustomConditionEvaluator {

    /**
     * @description Exception thrown when an Advanced Condition formula is empty or malformed.
     */
    public class FormulaException extends Exception {}

    /**
     * @description Evaluates the given boolean formula against the supplied condition results.
     * @param formula The Advanced Condition formula expression to evaluate.
     * @param resultsByIndex Condition results keyed by Rule_Condition__c.Index__c.
     * @return The boolean result of evaluating the formula.
     */
    public static Boolean evaluate(String formula, Map<Integer, Boolean> resultsByIndex) {
        if (String.isBlank(formula)) {
            throw new FormulaException('Advanced Condition formula is empty.');
        }
        Parser p = new Parser(formula, resultsByIndex == null ? new Map<Integer, Boolean>() : resultsByIndex);
        Boolean result = p.parseExpression();
        p.expectEnd();
        return result;
    }

    private class Parser {
        private final String src;
        private final Map<Integer, Boolean> results;
        private Integer pos;

        Parser(String src, Map<Integer, Boolean> results) {
            this.src = src;
            this.results = results;
            this.pos = 0;
        }

        Boolean parseExpression() {
            Boolean left = parseTerm();
            while (matchKeyword('OR')) {
                Boolean right = parseTerm();
                left = left || right;
            }
            return left;
        }

        Boolean parseTerm() {
            Boolean left = parseFactor();
            while (matchKeyword('AND')) {
                Boolean right = parseFactor();
                left = left && right;
            }
            return left;
        }

        Boolean parseFactor() {
            skipWhitespace();
            if (matchKeyword('NOT')) {
                return !parsePrimary();
            }
            return parsePrimary();
        }

        Boolean parsePrimary() {
            skipWhitespace();
            if (pos >= src.length()) {
                throw new FormulaException('Unexpected end of formula.');
            }
            if (src.substring(pos, pos + 1) == '(') {
                pos++;
                Boolean nested = parseExpression();
                skipWhitespace();
                if (pos >= src.length() || src.substring(pos, pos + 1) != ')') {
                    throw new FormulaException('Missing closing parenthesis at position ' + pos + '.');
                }
                pos++;
                return nested;
            }
            Integer idx = readInteger();
            if (idx == null) {
                throw new FormulaException('Expected an index or "(" at position ' + pos + '.');
            }
            return results.containsKey(idx) ? results.get(idx) : false;
        }

        Boolean matchKeyword(String kw) {
            skipWhitespace();
            Integer len = kw.length();
            if (pos + len > src.length()) {
                return false;
            }
            String slice = src.substring(pos, pos + len);
            if (!slice.equalsIgnoreCase(kw)) {
                return false;
            }
            // Must be followed by whitespace, '(' , end-of-string, or another operator boundary.
            if (pos + len < src.length()) {
                String next = src.substring(pos + len, pos + len + 1);
                if (next != ' ' && next != '\t' && next != '(' && next != ')') {
                    return false;
                }
            }
            pos += len;
            return true;
        }

        Integer readInteger() {
            skipWhitespace();
            Integer start = pos;
            while (pos < src.length()) {
                String ch = src.substring(pos, pos + 1);
                if (ch >= '0' && ch <= '9') {
                    pos++;
                } else {
                    break;
                }
            }
            if (pos == start) {
                return null;
            }
            return Integer.valueOf(src.substring(start, pos));
        }

        void skipWhitespace() {
            while (pos < src.length()) {
                String ch = src.substring(pos, pos + 1);
                if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
                    pos++;
                } else {
                    break;
                }
            }
        }

        void expectEnd() {
            skipWhitespace();
            if (pos != src.length()) {
                throw new FormulaException(
                    'Unexpected token "' + src.substring(pos, Math.min(pos + 8, src.length()))
                    + '" at position ' + pos + '.');
            }
        }
    }
}
