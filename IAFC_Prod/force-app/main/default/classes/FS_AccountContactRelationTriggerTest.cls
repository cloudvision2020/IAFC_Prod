/**
 * Test class for FS_AccountContactRelationTrigger and FS_AccountContactRelationTriggerService
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

@IsTest
public class FS_AccountContactRelationTriggerTest {


    @IsTest
    private static void test() {

        Account unknownAccount = new Account(Name='Unknown');
        insert unknownAccount;
        Account testAccount1 = new Account(Name='testClass1');
        insert testAccount1;
        Account testAccount2 = new Account(Name='testClass2');
        insert testAccount2;
        Contact testContact = new Contact(LastName='testClass', AccountId=testAccount1.Id);
        insert testContact;

        String unknownAccountId = unknownAccount.Id;


        Test.startTest();

        FS_AccountContactRelationTriggerService.setTestUnknownAccountID(unknownAccount.Id);

        System.assertEquals(1, [SELECT Id FROM AccountContactRelation WHERE ContactId = :testContact.Id].size());
        System.assertEquals(true, [SELECT FS_Is_Primary__c FROM AccountContactRelation WHERE ContactId = :testContact.Id][0].FS_Is_Primary__c);

        testContact.AccountId = testAccount2.Id;
        update testContact;
        System.assertEquals(2, [SELECT Id FROM AccountContactRelation WHERE ContactId = :testContact.Id].size());
        System.assertEquals(false, [SELECT FS_Is_Primary__c FROM AccountContactRelation WHERE ContactId = :testContact.Id AND AccountId = :testAccount1.Id][0].FS_Is_Primary__c);

        AccountContactRelation accountContactRelation = [SELECT Id FROM AccountContactRelation WHERE ContactId = :testContact.Id AND AccountId = :testAccount1.Id];
        delete accountContactRelation;

        testContact.AccountId = null;
        update testContact;
//        String unknownAccountId = [SELECT FS_Account_Id__c FROM FS_Unknown_Account__mdt LIMIT 1].FS_Account_Id__c;
        System.assertEquals(unknownAccountId, [SELECT AccountId FROM Contact WHERE Id = :testContact.Id][0].AccountId);

        testContact.AccountId = testAccount2.Id;
        update testContact;
        AccountContactRelation accountContactRelation1 = [SELECT Id FROM AccountContactRelation WHERE ContactId = :testContact.Id AND AccountId = :testAccount2.Id];
        AccountContactRelation accountContactRelation2 = [SELECT Id FROM AccountContactRelation WHERE ContactId = :testContact.Id AND AccountId = :unknownAccountId];
        accountContactRelation1.IsActive = false;
        accountContactRelation2.IsActive = false;
        update accountContactRelation1;
        update accountContactRelation2;
        System.assertEquals(true, [SELECT IsActive FROM AccountContactRelation WHERE AccountId = :unknownAccountId][0].IsActive);

        Test.stopTest();
    }
}