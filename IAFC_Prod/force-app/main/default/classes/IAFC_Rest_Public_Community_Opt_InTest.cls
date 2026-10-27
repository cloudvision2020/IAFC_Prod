@isTest
public  class IAFC_Rest_Public_Community_Opt_InTest {
    static testMethod void doOptInTest(){
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/PublicCommunityOptIn?community=a0M2g000000AxmwEAC&username=dasamigo@gmail.com';  
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        string results = IAFC_Rest_Public_Community_Opt_In.doOptIn();
        Test.stopTest();
    }
    
    static testMethod void checkOptInTest(){
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/PublicCommunityOptIn?community=a0M2g000000AxmwEAC&username=dasamigo@gmail.com';  
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Boolean results = IAFC_Rest_Public_Community_Opt_In.checkOptIn();
        Test.stopTest();
	}

}