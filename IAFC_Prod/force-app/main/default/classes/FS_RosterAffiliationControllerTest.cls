/**
 * Created by Jason Cookman on 6/4/19.
 */

@IsTest
public class FS_RosterAffiliationControllerTest {

    @IsTest
    private static void testGetJSONCountriesAndStates() {
        System.assert(FS_RosterAffiliationController.getJSONCountriesAndStates().size() > 0);
    }

    @IsTest
    private static void testGetPopulationPicklistValues() {
        System.assert(FS_RosterAffiliationController.getPopulationPicklistValues().size() > 0);
    }

    @IsTest
    private static void testInsertAccount() {
        Account toInsert = new Account(Name = 'Test Insert Account');

        Account account = new Account(Name='Test Account Name', Population_Served_Size__c='Less than 10,000');
        Account account2 = new Account(Name='Another Test Account', Population_Served_Size__c='Less than 10,000');
        Account account3 = new Account(Name='No Organization Selected', Population_Served_Size__c='Less than 10,000');

        List<Account> accountsToInsert = new List<Account>{account, account2, account3};
        insert accountsToInsert;

        Contact contact = new Contact(LastName='test', AccountId=account.Id, MailingStateCode='MD', MailingCountryCode='US');
        insert contact;

        Profile p = [SELECT Id FROM Profile WHERE Name='Fonteva Customer Community Login User'];

        User user = new User(Alias='standt', Email='test@example.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId=p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test@example.com', ContactId=contact.Id);
        insert user;

        System.runAs(user) {
            FS_RosterAffiliationController.insertAccount(toInsert);

            System.assert(toInsert.Id != null);
            System.assert([SELECT Id FROM Account WHERE Id = :toInsert.Id].size() > 0);
        }
    }
}