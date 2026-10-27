@isTest
public class ContactTriggerHandlerTest {
    
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
            contacts.add(new Contact(LastName = 'Test Contact', AccountId = acc.Id,Membership_Type__c = 'Associate'));
        }
        insert contacts;
        
        PagesApi__Community_Group__c cg = new PagesApi__Community_Group__c();
        cg.Name = 'Test';
        insert cg;

        // Create test Community Group Members
        List<PagesApi__Community_Group_Member__c> groupMembers = new List<PagesApi__Community_Group_Member__c>();
        for (Contact con : contacts) {
            groupMembers.add(new PagesApi__Community_Group_Member__c(PagesApi__Contact__c = con.Id, PagesApi__Status__c = 'Active', PagesApi__Community_Group__c = cg.Id));
        }
        insert groupMembers;
    }
    
    @isTest
    static void testContactTriggerHandler() {
        List<Contact> contacts = [SELECT Id, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact];
        for (Contact con : contacts) {
            con.MailingStreet = '789 Contact St';
        }
        update contacts;
    }
}