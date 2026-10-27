@isTest
public class IAFC_CreateAccountTest { 
   
    static testMethod void IAFC_CreateAccountTest(){
         Test.startTest();
         Account testaccount = new Account();
         testAccount.Name = 'TestAccount';
         List<Account> a = new List<Account>();
         a.add(testaccount);
         a = IAFC_CreateAccount.CreateAccount(a);
         system.assertNotEquals(null,a);
         Test.stopTest();
     }
}