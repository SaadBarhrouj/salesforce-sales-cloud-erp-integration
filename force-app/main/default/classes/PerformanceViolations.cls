public class PerformanceViolations {
    public void doWork() {
        // Violation: AvoidDebugStatements
        System.debug('Starting work');

        List<Account> accs = [SELECT Id FROM Account LIMIT 10];
        
        // Violation: UnusedLocalVariable
        Integer unusedVar = 5;

        for (Account a : accs) {
            // Violation: OperationWithLimitsInLoop (SOQL)
            List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :a.Id];
            
            for (Contact c : contacts) {
                c.Description = 'Updated';
                // Violation: OperationWithLimitsInLoop (DML)
                update c;
            }
        }
        
        System.debug('Finished work');
    }
}
