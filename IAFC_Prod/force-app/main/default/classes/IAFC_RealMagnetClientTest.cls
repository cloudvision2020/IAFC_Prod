@isTest
class IAFC_RealMagnetClientTest {

    @isTest
    public static void IAFC_RealMagnetClientTest()
    {
        IAFC_Mock_SingleRequest fakeResponse = new IAFC_Mock_SingleRequest(200,'OK','{"LoginID": 123,"SessionID": "abc","UserID": "IAFC"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        //Test.setMock(HttpCalloutMock.class, fakeResponse);
        IAFC_RealMagnetClient client = new IAFC_RealMagnetClient();  
        system.assertEquals('abc', client.sessionId);
        system.assertEquals('IAFC', client.userId);
        system.assertEquals(123, client.loginId); 
	} 

     
    @isTest
    public static void SendWelcomeEmailTest()
    {
        Map<String, HttpCalloutMock> endpoints2TestResp = new Map<String,HttpCalloutMock>();
        IAFC_Mock_SingleRequest fakeauthresp = new IAFC_Mock_SingleRequest(200,'OK','{"LoginID": 123,"SessionID": "abc","UserID": "IAFC"}', null);
        IAFC_Mock_SingleRequest fakesend2individualresp = new IAFC_Mock_SingleRequest(200,'OK','{"Message": "The message has been sent","Status": 1}', null);
            endpoints2TestResp.put('callout:RealMagnetApi',fakeauthresp);
            endpoints2TestResp.put('https://dna.magnetmail.net/ApiAdapter/Rest/SendEmailToIndividual/',fakesend2individualresp); 
        HttpCalloutMock multiCalloutMock = new IAFC_Mock_MultiRequest(endpoints2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        IAFC_RealMagnetClient client = new IAFC_RealMagnetClient();
        String results = client.SendWelcomeEmail(new List<Contact>());
        system.assertNotEquals(null, results); 
	} 
   
    @isTest
    public static void SendReceiptEmailTest()
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
        List<string> emails = new list<string>();
        emails.add('test@test.com');
        String results = client.SendReceiptEmail('test',emails);
        system.assertEquals('abc', client.sessionId);
        system.assertEquals('IAFC', client.userId);
        system.assertEquals(123, client.loginId); 
	} 

    @isTest
    public static void SendReceiptEmailAsyncTest()
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

        List<string> emails = new list<string>();
        emails.add('test@test.com');
        String results;
        IAFC_RealMagnetClient.SendReceiptEmailAsync('test',emails);
        system.assertEquals(null, results);  
	} 

    @isTest
    public static void AuthenticateTest()
    { 
        IAFC_Mock_SingleRequest fakeResponse = new IAFC_Mock_SingleRequest(200,'OK','{"LoginID": 123,"SessionID": "abc","UserID": "IAFC"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        //Test.setMock(HttpCalloutMock.class, fakeResponse);
        IAFC_RealMagnetClient client = new IAFC_RealMagnetClient(); 
        Map<String, Object> results = client.authenticate();
        system.assertEquals('abc', client.sessionId);
        system.assertEquals('IAFC', client.userId);
        system.assertEquals(123, client.loginId);
        system.assertNotEquals(null, results); 
	}

    @IsTest(SeeAllData=true)
    public static void SendToIndividualsTest()
    { 
        IAFC_RealMagnetClient_Settings__c settings = IAFC_RealMagnetClient_Settings__c.getValues('MembershipReceipt');  
        system.assertNotEquals(null, settings);
        system.assertNotEquals('', settings.MessageID__c);
        system.assertNotEquals('', settings.Subject__c);

        Map<String, HttpCalloutMock> endpoints2TestResp = new Map<String,HttpCalloutMock>();
        IAFC_Mock_SingleRequest fakeauthresp = new IAFC_Mock_SingleRequest(200,'OK','{"LoginID": 123,"SessionID": "abc","UserID": "IAFC"}', null);
        IAFC_Mock_SingleRequest fakesend2individualresp = new IAFC_Mock_SingleRequest(200,'OK','{"Message": "The message has been sent","Status": 1}', null);
            endpoints2TestResp.put('callout:RealMagnetApi',fakeauthresp);
            endpoints2TestResp.put('https://dna.magnetmail.net/ApiAdapter/Rest/SendEmailToIndividual/',fakesend2individualresp);
        HttpCalloutMock multiCalloutMock = new IAFC_Mock_MultiRequest(endpoints2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);


        List<string> emails = new list<string>();
        emails.add('test@test.com');

        IAFC_RealMagnetClient client = new IAFC_RealMagnetClient(); 
        HttpResponse results = client.sendToIndividuals(settings.MessageID__c, settings.Subject__c, emails);
        system.assertEquals('abc', client.sessionId);
        system.assertEquals('IAFC', client.userId);
        system.assertEquals(123, client.loginId);
        system.assertNotEquals(null, results); 
	}

    @IsTest(SeeAllData=true)
    public static void uploadRecipients()
    { 
        IAFC_RealMagnetClient_Settings__c settings = IAFC_RealMagnetClient_Settings__c.getValues('MembershipReceipt');  
        system.assertNotEquals(null, settings);
        system.assertNotEquals('', settings.MessageID__c);
        system.assertNotEquals('', settings.Subject__c);

        Map<String, HttpCalloutMock> endpoints2TestResp = new Map<String,HttpCalloutMock>();
        IAFC_Mock_SingleRequest fakeauthresp = new IAFC_Mock_SingleRequest(200,'OK','{"LoginID": 123,"SessionID": "abc","UserID": "IAFC"}', null);
        IAFC_Mock_SingleRequest fakeuploadresp = new IAFC_Mock_SingleRequest(200,'OK','{"Details": "The upload request has successfully been submitted!","ID": 21105173,"Result": null,"Success": true}', null);
            endpoints2TestResp.put('callout:RealMagnetApi',fakeauthresp);
            endpoints2TestResp.put('https://dna.magnetmail.net/ApiAdapter/Rest/UploadRecipients/',fakeuploadresp);
        HttpCalloutMock multiCalloutMock = new IAFC_Mock_MultiRequest(endpoints2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);


        IAFC_RealMagnetClient client = new IAFC_RealMagnetClient(); 
        system.assertEquals('abc', client.sessionId);
        system.assertEquals('IAFC', client.userId);
        system.assertEquals(123, client.loginId);
        
        IAFC_RealMagnetClient.RecipientUpload r = new IAFC_RealMagnetClient.RecipientUpload(client.authMap);
        HttpResponse results = client.uploadRecipients(r);
        system.assertNotEquals(null, results); 
	}

}