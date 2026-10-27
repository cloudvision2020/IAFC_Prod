@isTest
private class Batch_UpdateOwnerJobTest {

    // Hardcoded owner ID used in the batch class
    private static final String MY_OWNER_ID = '0051N00000638B7';

    private static List<Account> createTestAccounts(Integer numAccounts) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < numAccounts; i++) {
            Account acc = new Account(Name = 'Test Account ' + i);
            accounts.add(acc);
        }
        insert accounts;
        return accounts;
    }

    private static List<Contact> createTestContacts(Integer numContacts) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numContacts; i++) {
            Contact con = new Contact(LastName = 'Test Contact ' + i);
            contacts.add(con);
        }
        insert contacts;
        return contacts;
    } 
    
    // Test the schedulable class for Account
    @isTest
    private static void testAccountSchedulable() {
        List<Account> accounts = createTestAccounts(5);

 		Test.startTest();
        Batch_UpdateAccountJobSchedule schedule = new Batch_UpdateAccountJobSchedule();
        System.schedule('Account Schedule Test', '0 0 * * * ?', schedule);
        Test.stopTest();

    }

    // Test the schedulable class for Contact
    @isTest
    private static void testContactSchedulable() {
        List<Contact> contacts = createTestContacts(5);

        Test.startTest();
        Batch_UpdateContactJobSchedule schedule = new Batch_UpdateContactJobSchedule();
        System.schedule('Contact Schedule Test', '0 0 * * * ?', schedule);
        Test.stopTest();

    }
}