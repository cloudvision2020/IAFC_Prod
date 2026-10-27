@RestResource(urlMapping='/Auth0LogEvent')
global class IAFC_Rest_Auth0_Log_Event {
    @HttpPost
    global static void createLogEvent(){ //CANNOT ACCEPT Params since auth0 sends as text lines and apex rest only accepts json params. If the Apex method has no parameters, Apex REST copies the HTTP request body into the RestRequest.requestBody property.
        
        RestRequest req = RestContext.request; 
        if(req.requestBody.toString() != ''){ 
        

            List<String> valid_events = new List<String>{'s', 'fcpr','fp','fu', 'fcp', 'limit_wc', 'scp', 'sv', 'fv'};
            List<Auth0EventData> lst = new List<Auth0EventData>();
            List<Helix_SSO_Log_Entry__c> entries = new List<Helix_SSO_Log_Entry__c>();
            List<Helix_SSO_Log_Entry__c> oldentries = new List<Helix_SSO_Log_Entry__c>();
            Integer max_retention = 25;
            //replace reserved names
            string temp = req.requestBody.toString().replace('"date\":', '"logdate\":'); 
            temp = temp.replace('"type\":', '"eventtype\":');
            
            //parse to objects to vallidate
            List<string> body = temp.split('\n');
            for(string entry : body){ 
                Auth0EventData evt = (Auth0EventData) System.JSON.deserialize(entry, Auth0EventData.class);
                //if this is an event we want to track
                if(valid_events.contains(evt.data.eventtype)){
                    List<User> c =  [ SELECT Id,ContactId FROM User WHERE username = :evt.data.user_name AND ContactId != null];
                    
                    //if the contact exists....
                    if(c.size() > 0){
                        List<Helix_SSO_Log_Entry__c> existing =  [ SELECT Id FROM Helix_SSO_Log_Entry__c WHERE Contact__c = :c[0].ContactId  Order By When__c DESC];
                        for(Integer i = max_retention; i< existing.size(); i++){
                            oldentries.add(existing[i]);
                        }
                    
                        Helix_SSO_Log_Entry__c e = new Helix_SSO_Log_Entry__c();
                        e.When__c = evt.data.logdate;
                        e.Event_Code__c = evt.data.eventtype;
                        e.User_Agent__c = evt.data.user_agent;
                        e.Username_Used__c = evt.data.user_name;
                        e.Target_App__c = evt.data.client_name;
                        e.Contact__c = c[0].ContactId;
                        e.Raw_Data__c = entry;
                        entries.add(e);
                    }
                }
            }

            if(oldentries.size() > 0){
                delete oldentries;
            }
            if(entries.size() > 0){
                insert entries;
            }
            

        //return lst[0].data.eventtype;
        //return JSON.serialize(lst); 
        }
    }

    

    public class Auth0EventData { 
        public String log_id {get;set;} 
        public Data data {get;set;}   
    }

    public class Data {
        
        public Datetime logdate {  get;  set; } 
        public String eventtype {get;set;}  
        public String client_id {get;set;} 
        public String client_name {get;set;} 
        public String ip {get;set;} 
        public String user_agent {get;set;}  
        public String hostname {get;set;} 
        public String user_id {get;set;} 
        public String user_name {get;set;}  
        public String log_id {get;set;}  

    }


}