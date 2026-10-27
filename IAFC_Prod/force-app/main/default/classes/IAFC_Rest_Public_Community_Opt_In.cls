@RestResource(urlMapping='/PublicCommunityOptIn')
global class IAFC_Rest_Public_Community_Opt_In {
    @HttpGet  
    global static Boolean checkOptIn(){
        //RestContext.response.addHeader('Content-Type', 'application/json');
        String username = RestContext.request.params.get('username');
        String communityid = RestContext.request.params.get('community'); 
        if(username != null && communityid != null){
            List<User> usr = [select ContactId from User where username = :username and ContactId != '' ];
            Id contactid = usr[0].ContactId;
            List<PagesApi__Community_Group_Member__c> cgm = [select ID from PagesApi__Community_Group_Member__c where PagesApi__Community_Group__c = :communityid 
                and PagesApi__Contact__c = :contactid 
                and PagesApi__Community_Group__r.allow_public_opt_in__c = true
                and PagesApi__Is_Active__c = true];

            return cgm.size() > 0;
        }
        return null;
    }

    @HttpPost 
    global static string doOptIn(){
        //RestContext.response.addHeader('Content-Type', 'application/json');
        String username = RestContext.request.params.get('username');
        String communityid = RestContext.request.params.get('community'); 
        string results = 'error';
        if(username != null && communityid != null){
            List<User> usr = [select ContactId from User where username = :username and ContactId != '' ];
            Id contactid = usr[0].ContactId;
            List<PagesApi__Community_Group_Member__c> cgm = [select ID from PagesApi__Community_Group_Member__c where PagesApi__Community_Group__c = :communityid 
                and PagesApi__Contact__c = :contactid 
                and PagesApi__Community_Group__r.allow_public_opt_in__c = true
                and PagesApi__Is_Active__c = true];

            //if it doesnt exist create it
            if(cgm.size() == 0 ){
                PagesApi__Community_Group_Member__c x = new PagesApi__Community_Group_Member__c();
                x.PagesApi__Community_Group__c = communityid;
                x.PagesApi__Contact__c = contactid;
                insert x;
                results = x.Id;
            }else{
                results = cgm[0].Id;
            } 
        }
        return results;
    }
}