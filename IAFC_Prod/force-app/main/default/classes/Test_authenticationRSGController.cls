@isTest
public class Test_authenticationRSGController{
    
    static testMethod void Test_authenticationRSGControllerTest(){
        Account acc = new Account();
        Acc.Name = 'Test Acc';
        insert acc;
        
        Contact con = new Contact();
        con.email='test@mail.com';
        con.firstName ='Test1';
        con.lastName = 'Testing';
        con.accountId = acc.Id;
        insert con;
        
        test.startTest();
        
        authenticationRSGController ac = new authenticationRSGController();
        authenticationRSGController.getRSGUser(con.Id);
        authenticationRSGController.updateContact(con.Id);
        authenticationRSGController.updateEmail(con.Id);
            
        test.stopTest();
    }

}