@isTest
public  class IAFC_Invoke_SendWelcomeEmailTest {
    @isTest
    public static void SendWelcomeEmailTest()
    {
        Map<String, HttpCalloutMock> endpoints2TestResp = new Map<String,HttpCalloutMock>();
        IAFC_Mock_SingleRequest fakeauthresp = new IAFC_Mock_SingleRequest(200,'OK','{"LoginID": 123,"SessionID": "abc","UserID": "IAFC"}', null);
        IAFC_Mock_SingleRequest fakeuploadresp = new IAFC_Mock_SingleRequest(200,'OK','{"Details": "The upload request has successfully been submitted!","ID": 21105173,"Result": null,"Success": true}', null);
        IAFC_Mock_SingleRequest fakesend2individualresp = new IAFC_Mock_SingleRequest(200,'OK','{"Message": "The message has been sent","Status": 1}', null);
            endpoints2TestResp.put('callout:RealMagnetApi',fakeauthresp);
            endpoints2TestResp.put('https://dna.magnetmail.net/ApiAdapter/Rest/SendEmailToIndividual/',fakesend2individualresp);
            endpoints2TestResp.put('https://dna.magnetmail.net/ApiAdapter/Rest/UploadRecipients/',fakeuploadresp);
        HttpCalloutMock multiCalloutMock = new IAFC_Mock_MultiRequest(endpoints2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        IAFC_RealMagnetClient client = new IAFC_RealMagnetClient();
        system.assertEquals('abc', client.sessionId);
        system.assertEquals('IAFC', client.userId);
        system.assertEquals(123, client.loginId); 
        
        String results = client.SendWelcomeEmail(new List<Contact>());
        system.assertNotEquals(null, results); 
	} 
}