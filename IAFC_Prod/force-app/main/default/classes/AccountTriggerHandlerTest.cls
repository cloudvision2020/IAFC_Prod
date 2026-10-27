@isTest
public class AccountTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i, BillingStreet = '123 Test St', BillingCity = 'Test City', BillingState = 'Washington', BillingPostalCode = '12345', BillingCountry = 'United States'));
        }
        insert accounts;

        // Create test Contacts
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(LastName = 'Test Contact', AccountId = acc.Id));
        }
        insert contacts;
    }
    
    @isTest
    static void testAccountTriggerHandler() {
        List<Account> accounts = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account];
        for (Account acc : accounts) {
            acc.BillingStreet = '456 Updated St';
        }
        update accounts;
    }
}