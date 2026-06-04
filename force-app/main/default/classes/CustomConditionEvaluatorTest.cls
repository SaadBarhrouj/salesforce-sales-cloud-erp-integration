/**
 * @description Tests for CustomConditionEvaluator: grammar, precedence, parens, NOT,
 * missing indices, malformed input.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class CustomConditionEvaluatorTest {

    private static Map<Integer, Boolean> results(Boolean v1, Boolean v2, Boolean v3) {
        return new Map<Integer, Boolean>{ 1 => v1, 2 => v2, 3 => v3 };
    }

    @IsTest
    static void simpleIndexReference() {
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('1', new Map<Integer, Boolean>{1 => true}));
        System.assertEquals(false, CustomConditionEvaluator.evaluate('1', new Map<Integer, Boolean>{1 => false}));
    }

    @IsTest
    static void andOperator() {
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('1 AND 2', results(true, true, false)));
        System.assertEquals(false, CustomConditionEvaluator.evaluate('1 AND 2', results(true, false, false)));
    }

    @IsTest
    static void orOperator() {
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('1 OR 2', results(false, true, false)));
        System.assertEquals(false, CustomConditionEvaluator.evaluate('1 OR 2', results(false, false, false)));
    }

    @IsTest
    static void notOperator() {
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('NOT 1', results(false, false, false)));
        System.assertEquals(false, CustomConditionEvaluator.evaluate('NOT 1', results(true, false, false)));
    }

    @IsTest
    static void andHasHigherPrecedenceThanOr() {
        // 1 OR 2 AND 3  ==  1 OR (2 AND 3)
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('1 OR 2 AND 3', results(true, false, false)));
        System.assertEquals(false, CustomConditionEvaluator.evaluate('1 OR 2 AND 3', results(false, true, false)));
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('1 OR 2 AND 3', results(false, true, true)));
    }

    @IsTest
    static void parenthesesOverridePrecedence() {
        // (1 OR 2) AND 3
        System.assertEquals(false, CustomConditionEvaluator.evaluate('(1 OR 2) AND 3', results(true, false, false)));
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('(1 OR 2) AND 3', results(true, false, true)));
    }

    @IsTest
    static void nestedExpressionWithNot() {
        // (1 AND 2) OR (3 AND NOT 1)
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('(1 AND 2) OR (3 AND NOT 1)', results(true, true, false)));
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('(1 AND 2) OR (3 AND NOT 1)', results(false, true, true)));
        System.assertEquals(false, CustomConditionEvaluator.evaluate('(1 AND 2) OR (3 AND NOT 1)', results(true, false, true)));
    }

    @IsTest
    static void keywordsAreCaseInsensitive() {
        System.assertEquals(true, CustomConditionEvaluator.evaluate('1 and 2 or NoT 3', results(true, true, false)));
    }

    @IsTest
    static void missingIndexEvaluatesToFalse() {
        // Index 9 is not in the map — treated as false.
        System.assertEquals(false, CustomConditionEvaluator.evaluate('1 AND 9', results(true, false, false)));
        System.assertEquals(true,  CustomConditionEvaluator.evaluate('1 OR 9',  results(true, false, false)));
    }

    @IsTest
    static void blankFormulaThrows() {
        try {
            CustomConditionEvaluator.evaluate(null, results(true, true, true));
            System.assert(false, 'Null formula should have thrown');
        } catch (CustomConditionEvaluator.FormulaException ex) {
            System.assert(ex.getMessage().containsIgnoreCase('empty'), 'Expected empty-formula error');
        }
        try {
            CustomConditionEvaluator.evaluate('   ', results(true, true, true));
            System.assert(false, 'Blank formula should have thrown');
        } catch (CustomConditionEvaluator.FormulaException ex) {
            System.assert(true);
        }
    }

    @IsTest
    static void missingClosingParenthesisThrows() {
        try {
            CustomConditionEvaluator.evaluate('(1 AND 2', results(true, true, true));
            System.assert(false, 'Should have thrown for unmatched paren');
        } catch (CustomConditionEvaluator.FormulaException ex) {
            System.assert(ex.getMessage().containsIgnoreCase('parenthesis'), 'Expected parenthesis error');
        }
    }

    @IsTest
    static void trailingGarbageThrows() {
        try {
            CustomConditionEvaluator.evaluate('1 AND 2 XYZ', results(true, true, true));
            System.assert(false, 'Trailing token should have thrown');
        } catch (CustomConditionEvaluator.FormulaException ex) {
            System.assert(ex.getMessage().containsIgnoreCase('unexpected'));
        }
    }

    @IsTest
    static void missingOperandThrows() {
        try {
            CustomConditionEvaluator.evaluate('1 AND', results(true, true, true));
            System.assert(false, 'Missing operand should have thrown');
        } catch (CustomConditionEvaluator.FormulaException ex) {
            System.assert(ex.getMessage().containsIgnoreCase('end') || ex.getMessage().containsIgnoreCase('expected'));
        }
    }
}
