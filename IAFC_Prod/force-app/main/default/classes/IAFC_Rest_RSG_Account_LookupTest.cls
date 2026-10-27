@isTest
public with sharing class IAFC_Rest_RSG_Account_LookupTest {
    static testMethod void rsgAccountLookupTest() {
        Test.startTest();
         RestRequest req = new RestRequest(); 
         RestResponse res = new RestResponse();
         String JsonMsg = '{"log_id":"90020200305162923917000760084043897383180997546892853330","data":{"date":"2020-03-05T16:29:20.354Z","type":"s","connection":"Helix","connection_id":"con_ypdK7BabwURkECyr","client_id":"0BdCkLRs2gOEEkxdlTLCPCXoYRZnt4aF","client_name":"Fellowship Management System","ip":"107.77.203.71","user_agent":"Mozilla/5.0 (iPhone; CPU iPhone OS 13_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Mobile/15E148 Safari/604.1","details":{"prompts":[{"name":"lock-password-authenticate","initiatedAt":1583425757867,"completedAt":1583425759418,"connection":"Helix","connection_id":"con_ypdK7BabwURkECyr","strategy":"auth0","identity":"0053m00000AcIW7AAN","stats":{"loginsCount":14},"session_user":"5e6128de9fcbc70d8e045fde","elapsedTime":1551},{"name":"login","flow":"login","initiatedAt":1583425753237,"completedAt":1583425759438,"timers":{"rules":855},"user_id":"auth0|0053m00000AcIW7AAN","user_name":"asweed7077@icloud.com","elapsedTime":6201}],"initiatedAt":1583425753235,"completedAt":1583425760353,"elapsedTime":7118,"session_id":"RkrWAu5WLAUNh_ltI8ufkr0pDJpbHrv8","device_id":"v0:1b581640-5c9d-11ea-b4fc-a90b31b954f3","stats":{"loginsCount":14}},"hostname":"helix.auth0.com","user_id":"auth0|0053m00000AcIW7AAN","user_name":"dasamigo@gmail.com","strategy":"auth0","strategy_type":"database","log_id":"90020200305162923917000760084043897383180997546892853330"}}';
         
         req.requestURI = '/customer/rsgaccount?id=0031N00002Gi7YpQAJ';  
         req.httpMethod = 'POST';
         
         RestContext.request = req;
         RestContext.response = res;
         
         
         IAFC_Rest_RSG_Account_Lookup.rsgAccountLookup();
         //assert for  record 
         Test.stopTest(); 
     }
}