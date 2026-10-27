@isTest
public class IAFC_AccountSearchBasicTest {
    static testMethod void testSearch(){
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/AccountSearchBasic?term=Pep';  
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        list<Account> results = IAFC_AccountSearchBasic.searchAccounts();
        Test.stopTest();
	}
}