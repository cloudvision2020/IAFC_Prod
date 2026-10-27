/**
 * Test class for FS_ContactRoutingRule and FS_ContactRoutingRuleService
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

@isTest
public class FS_ContactRoutingRuleTest {
    @TestSetup
    private static void install() {
        Framework.Installer.install();
        PagesApi.PackageScripts.install();
        OrderApi.PackageScripts.install();
        EventApi.PackageScripts.install();

        Framework.RoutingRule[] rules = new List<Framework.RoutingRule>();
        Framework.RoutingRule contactRoutingRule = new Framework.RoutingRule();
        contactRoutingRule.apexClass = FS_ContactRoutingRule.class.getName();
        contactRoutingRule.namespace = ' ';
        contactRoutingRule.isEnabled = true;
        contactRoutingRule.sObjectName = SObjectType.Contact.getName();
        contactRoutingRule.executionOrder = 10;
        rules.add(contactRoutingRule);

        Framework.Config.push(rules);
    }

    @isTest static void test() {
        OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='International Society of Automation');
        insert businessGroup;

        Account acc = new Account(Name='Test');
        insert acc;

        Contact con = new Contact(LastName='Test1', AccountId=acc.Id, Division_Opt_Out__c=true);
        insert con;

        Test.startTest();
        System.assertEquals(false, [SELECT Id, Division_Opt_Out__c FROM Contact WHERE Id = :con.Id].Division_Opt_Out__c);
        Test.stopTest();
    }

    @IsTest
    private static void testUpdatingContactEmail_UserEmailAndUsernameShouldBeUpdated(){
        Test.startTest();
        Account a = FS_TestUtils.createAccount('TestAccount');
        insert a;

        Contact testContact = FS_TestUtils.createContact('testContact1','fsEmailUpdateTest@example.com');
        testContact.AccountId =a.Id;
        testContact.OrderApi__Preferred_Email_Type__c = 'Personal';
        insert testContact;


        Profile prf = [SELECT Id FROM Profile WHERE Name = 'Fonteva Customer Community Login User'];

        User testUser = new User(
                Username='fsemailupdatetest@example.com',
                Email='fsemailupdatetest@example.com',
                LastName='test',
                Alias='test',
                CommunityNickname='test12341234',
                TimeZoneSidKey='America/Los_Angeles',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                EmailEncodingKey='UTF-8',
                ProfileId = prf.Id,
                ContactId=testContact.Id);
        insert testUser;

        testContact.Email = 'fsnewemail@example.com';
        update testContact;

        Test.stopTest();

        System.assertEquals('fsnewemail@example.com',[SELECT Email FROM User WHERE ContactId=:testContact.Id].Email);
        System.assertEquals('fsnewemail@example.com',[SELECT Username FROM User WHERE ContactId=:testContact.Id].Username);
        //System.assertEquals('fsNewEmail@example.com',testUser.Email);


    }
}