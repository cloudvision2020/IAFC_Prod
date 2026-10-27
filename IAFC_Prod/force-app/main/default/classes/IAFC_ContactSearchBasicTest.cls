@isTest
public class IAFC_ContactSearchBasicTest {
	static testMethod void testSearch(){
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;

		Contact con = new Contact();
		con.FirstName = 'test';
        con.LastName = 'last';
        con.AccountId = acc.Id;
        insert con;
        
        req.requestURI = '/ContactSearchBasic?firstName=test&lastName=last&orgId='+acc.Id;  
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        list<Contact> results = IAFC_ContactSearchBasic.searchContacts();
        Test.stopTest();
	}
}