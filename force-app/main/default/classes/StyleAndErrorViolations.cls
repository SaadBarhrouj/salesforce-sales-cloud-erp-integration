global class StyleAndErrorViolations {
    // Violation: AvoidHardcodingId
    private static final String ACCOUNT_ID = '001000000000000AAA';

    // Violation: MethodNamingConventions (Starts with uppercase)
    // Violation: ApexDoc (Missing documentation)
    public void BadMethodName() {
        try {
            Integer i = 0;
            // Violation: IfStmtsMustUseBraces
            if (i == 0) System.debug('Zero');
            
            // Violation: EmptyIfStmt
            if (i == 1) {
            }
        } catch (Exception e) {
            // Violation: EmptyCatchBlock
        }
    }
    
    // Violation: AvoidGlobalModifier
    global void globalMethod() {
        // Violation: WhileLoopsMustUseBraces
        Integer x = 0;
        while (x < 1) x++;
    }
}
