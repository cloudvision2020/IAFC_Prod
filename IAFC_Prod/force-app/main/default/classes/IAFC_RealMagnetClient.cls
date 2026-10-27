public with sharing class IAFC_RealMagnetClient {

 
    //Welcome Email 17059070
    //Abandoned Cart 17059072
    //Receipt 17441616
    public  Map<String, Object> authMap = new Map<String, Object>();
    public  boolean htmlLink = true;
    public  boolean textLink = true;
    public  String identifier = 'email';
    public  String fromAddress = 'membership@iafc.org';
    public  String sessionId = '';
    public  String userId = '';
    public  Integer loginId = 0;
        
    public IAFC_RealMagnetClient(){
        authenticate();
    }

    /* Send the standard welcome email for membership */
    public String SendWelcomeEmail(List<Contact> contacts)
    {
        List<Contact> lookedupcontacts = [select ID, Name, Email from Contact where ID IN :contacts and email != '']; 
        List<string> emails = new List<string>();
        IAFC_RealMagnetClient_Settings__c settings = IAFC_RealMagnetClient_Settings__c.getValues('Welcome'); 
        for(Contact c : lookedupcontacts){
            emails.add(c.Email);
        }

        HttpResponse result = new HttpResponse();
        if(!Test.isRunningTest()){
            result = sendToIndividuals(settings.MessageID__c, settings.Subject__c, emails);
        }
        return result.getBody();
    } 

    @future(callout=true)
    public static void SendReceiptEmailAsync(string receiptId, List<string> emails ) //test rec a1C1k000000ByVmEAK
    {
        try{
            IAFC_RealMagnetClient client = new IAFC_RealMagnetClient();
            String result = client.SendReceiptEmail(receiptId, emails);
            System.debug(result);
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }

    /* Given a receipt id this will send the reciept email to the provided email */
    public String SendReceiptEmail(string receiptId, List<string> emails ) //test rec a1C1k000000ByVmEAK
    {
        IAFC_RealMagnetClient_Settings__c settings = IAFC_RealMagnetClient_Settings__c.getValues('MembershipReceipt');  
        HttpResponse result = new HttpResponse();
        RecipientUpload r = new RecipientUpload(authMap);
        r.data = '\"'+emails[0]+'\",\"'+receiptId+'\"'; 
        r.Mapping.Add(new UploadKeyValueMap(1,'Email'));
        r.Mapping.Add(new UploadKeyValueMap(2, 'custom2')); 
        
        if(!Test.isRunningTest()){        
            uploadRecipients(r);
            result = sendToIndividuals(settings.MessageID__c, settings.Subject__c, emails);
        }
        
        return result.getBody();
	}


    /* Authenticate and activate client for callouts.*/
    @TestVisible
    private Map<String, Object> authenticate() {
        if(authMap.size() == 0){
            Http http = new Http(); 
            HttpRequest req = new HttpRequest(); 
            req.setMethod('POST'); 
            req.setHeader('Content-Type','application/json'); 
            req.setHeader('Accept','application/json'); 
            req.setEndpoint('callout:RealMagnetApi');  
            req.setBody('{!$Credential.Password}');
                HttpResponse response = http.send(req);  
                // Parse the JSON response
                if (response.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected: ' +
                    response.getStatusCode() + ' ' + response.getStatus());
                }
                //else { System.debug(response.getBody()); }
                
                String jsonString = response.getBody();
                object jsonObj = JSON.deserializeUntyped(jsonString);
                Map<String, Object> objMap = (Map<String, Object>)jsonObj;
                authMap = objMap;
                sessionId = authMap.containsKey('SessionID') ? (String)authMap.get('SessionID') : '';
                userId = authMap.containsKey('UserID') ? (String)authMap.get('UserID') : '';
                loginId = authMap.containsKey('LoginID') ? (Integer)authMap.get('LoginID') : 0;
  
        }
        return authMap;
    }
    
    
    /* Upserts a recipient's info */
    @TestVisible
    private  HttpResponse uploadRecipients(RecipientUpload recipient ) {
        HttpResponse response; 
        String requestString =  JSON.serialize(recipient);
        
      
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://dna.magnetmail.net/ApiAdapter/Rest/UploadRecipients/');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setHeader('Accept','application/json'); 
            request.setBody(requestString); 
            response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 201) {
                System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
            } else {
                System.debug(response.getBody());
            }  
            return response;
        
    } 
    
    /* Send Single Message to a list of individuals */
    @TestVisible
    private  HttpResponse sendToIndividuals(String messageId, String subject, String[] recipients) {
        HttpResponse response;
        String emailList = JSON.serialize(recipients);
        String requestString = 
            '{' + 
                '"SessionID":"'+ sessionId +'",' +
                '"UserID":"'+ userId +'",' +
                '"From":"'+ fromAddress +'",' +
                '"Recipients":'+ emailList +',' +
                '"HTMLWVLink" : ' + htmlLink + ',' +
                '"MessageID":'+ messageId +',' +
                '"Identifier" : "' + identifier + '",' +
                '"Subject":"'+ subject+'",' +
                '"TXTWVLink" :' + textLink + ',' +           
            '}';
         
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://dna.magnetmail.net/ApiAdapter/Rest/SendEmailToIndividual/');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setHeader('Accept','application/json'); 
            request.setBody(requestString); 
            response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 201) {
                System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
            } else {
                System.debug(response.getBody());
            }  
            return response;
    }  


    /* public HttpResponse sendToGroup(String messageId, String groupId, String fromAddress, String subject) {
        authMap = getAuthMap();
        String sessionId = (String)authMap.get('SessionID');
        Integer loginId = (Integer)authMap.get('LoginID');
        String userId = (String)authMap.get('UserID');
        
        DateTime NOW = datetime.now();
        DateTime scheduledTime = NOW.addMinutes(5);
        
        String requestString = 
            '{' + 
                '"SessionID":"'+ sessionId +'",' +
                '"UserID":"'+ userId +'",' +
                '"AdHocList" : [],' +
                '"FaxResolution" : "",' +
                '"FilteredGroups" : [],' +
                '"From":"'+ fromAddress +'",' +
                '"GroupIDs":['+ groupId +'],' +
                '"HTMLWVL" : true,' +
                '"IgnoreDedupe" : true,' +
                '"LoginID" : '+ loginId +',' +
                '"MessageID":'+ messageId +',' +
                '"RssType" : 0,' +
                '"ScheduledDate":"'+ scheduledTime +'",' +
                '"SendDespiteArchived" : true,' +
                '"SendDespiteBadFrom" : true,' +
                '"SendFaxOrEmailOnFailure" : true,' +
                '"SendType" : "EmailOnly",' +
                '"Subject":"'+ subject+'",' +
                '"TXTWVL" : false' +
            '}';
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://dna.magnetmail.net/ApiAdapter/Rest/SendEmailToGroup/');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Accept','application/json'); 
        request.setBody(requestString);
        System.debug(request.getBody());
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
            response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
        } else {
            System.debug(response.getBody());
        }
        return response;
    }*/
    


    @TestVisible
    private class RecipientUpload { 
        public String SessionID;
        public String UserID;
        public Integer LoginID;
        public String AddOrReplace = 'Add';
        public Boolean ContainsUnicode = false;
        public String Data;
        public Integer GroupId = 7268763;
        public Boolean HasHeaderRow = false; 
        public Boolean UpdateExistingRecipients = true;
        public List<UploadKeyValueMap> Mapping = new List<UploadKeyValueMap>();

        public RecipientUpload(Map<String, Object> auth){
            SessionID = auth.containsKey('SessionID') ? (String)auth.get('SessionID') : '';
            UserID = auth.containsKey('UserID') ? (String)auth.get('UserID') : '';
            LoginID = auth.containsKey('LoginID') ? (Integer)auth.get('LoginID') : 0;
        }
    }

    @TestVisible
    private class UploadKeyValueMap{
        public Integer Key;
        public String Value;

        public UploadKeyValueMap(Integer k, String v){
           Key = k;
           Value = v;
        }
    }
}