@isTest
private class CloneServiceTest {

    @testSetup
    static void setup() {
        // Create an Account as a generic parent (Master object for tests)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Child Contacts (Master-Detail link to Account)
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Child ' + i,
                AccountId = acc.Id
            ));
        }
        insert contacts;
    }

    @isTest
    static void testGetRelatedChildRecords() {
        Account parent = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<CloneService.ChildRelationshipWrapper> wrappers = CloneService.getRelatedChildRecords(parent.Id);
        Test.stopTest();

        // Account usually has Contacts as children
        System.assert(!wrappers.isEmpty(), 'Should find at least one child relationship');
        Boolean foundContacts = false;
        for (CloneService.ChildRelationshipWrapper wrap : wrappers) {
            if (wrap.relationshipName == 'Contacts') {
                foundContacts = true;
                System.assertEquals(5, wrap.records.size(), 'Should have 5 contacts');
            }
        }
        System.assert(foundContacts, 'Should have found the Contacts relationship');
    }

    @isTest
    static void testCloneWithSelectedChildren() {
        Account parent = [SELECT Id, Name FROM Account LIMIT 1];
        List<Contact> children = [SELECT Id FROM Contact WHERE AccountId = :parent.Id];
        
        // Select 2 contacts
        List<Id> selectedContactIds = new List<Id>{
            children[0].Id,
            children[1].Id
        };
        
        Map<String, Object> selectedMap = new Map<String, Object>{
            'Contacts' => selectedContactIds
        };

        Test.startTest();
        Id newParentId = CloneService.cloneRecordWithChildren(parent.Id, selectedMap);
        Test.stopTest();

        // Assert parent was cloned
        Account clonedParent = [SELECT Id, Name FROM Account WHERE Id = :newParentId];
        System.assertNotEquals(parent.Id, clonedParent.Id, 'New record should have a different ID');
        System.assertEquals(parent.Name, clonedParent.Name, 'Names should match');

        // Assert only 2 contacts were cloned
        List<Contact> clonedContacts = [SELECT Id, FirstName, LastName FROM Contact WHERE AccountId = :newParentId];
        System.assertEquals(2, clonedContacts.size(), 'Only 2 contacts should have been cloned');
        
        // Assert field values
        System.assertEquals('Test', clonedContacts[0].FirstName);
    }

    @isTest
    static void testCloneEmptySelection() {
        Account parent = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> selectedMap = new Map<String, Object>();

        Test.startTest();
        Id newParentId = CloneService.cloneRecordWithChildren(parent.Id, selectedMap);
        Test.stopTest();

        Account clonedParent = [SELECT Id FROM Account WHERE Id = :newParentId];
        System.assertNotEquals(null, clonedParent);
        
        List<Contact> clonedContacts = [SELECT Id FROM Contact WHERE AccountId = :newParentId];
        System.assertEquals(0, clonedContacts.size(), 'No contacts should have been cloned');
    }
}