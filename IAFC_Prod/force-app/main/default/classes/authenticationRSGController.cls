public without sharing class authenticationRSGController {
    public authenticationRSGController() {

    }

    /**
    *   Method : saveAccountInfo
    *   @description  : 
    */ 
    @AuraEnabled(cacheable=true)
    public static Contact getRSGUser(String contactId) {

        Contact con = new Contact();

        if(contactId == null){
            String userId = Userinfo.getUserId();
            List<User> lstUser = [Select Id, ContactId from User where Id=:userId];
            contactId = lstUser[0].ContactId;
        }
        
        List<Contact> lstCon = [Select Id, RSG_Registration_Complete__c, AccountId, Account.Name, Account.RSG_Registration_Complete__c, Account.Organization_Type__c,
                                Account.BillingCity, Account.Organization_State__c, Account.BillingPostalCode, Account.BillingCountryCode, 
                                Account.RSG_Account_Email__c, Account.RSG_Account_Website__c, Account.BillingStreet, Account.BillingCountry,
                                Account.Phone, Account.Email__c, Account.Website, Account.RSG_Status__c, Account.BillingState,
                                Account.Department_Type__c,Account.Department_Size__c,Account.Utilization_of_Programs__c,Account.Programs__c,
                                Account.Population_Served_Size__c,Account.Size_Of_Area_Served__c,Account.Wildland_Urban_Interface_Area_Own__c,
                                Account.Age_Of_Building_Stock__c,Account.Red_Carded_Member__c,Account.Dominant_Landowner__c,Account.Constitutes_Threatened_by_Wildland_Fire__c,
                                Account.Major_Risks_Wildland_Fire_Urban_Dev__c,Account.Population_Service_English_2nd_Language__c,Account.Relationship_Dialogue__c,
                                Account.Interaction_with_Dept_Org__c,Account.Federal_Agencies_agreement__c,Account.CWPP_Community__c,
                                Account.Plan_Role_of_Organization__c,Account.Evacuation_Plans__c,Account.Role_of_Organization__c,Account.Role_Education_and_Outreach__c,
                                Account.Safety_Preparedness_Challenges__c,Account.Challenges_in_Wildland_Fire_Outreach__c,
                                Account.RSG_Mailing_Street__c,
                                Account.RSG_Mailing_City__c,
                                Account.RSG_County__c,
                                Account.RSG_Mailing_State__c,
                                Account.RSG_Mailing_Postal_Code__c,
                                Account.RSG_Phone__c,
                                Account.RSG_Description__c,
                                Is_Email__c
                                from Contact where Id=:contactId];
        con = lstCon[0];
        return con;
    }

    /**
    *   Method : saveAccountInfos
    *   @description  : 
    */ 
    @AuraEnabled
    public static Contact updateContact(String contactId) {

        if(contactId != null){
            List<Contact> lstCon = [Select Id, AccountId, Account.Organization_State__c, Account.RSG_Status__c from Contact where Id=:contactId];
            if(lstCon.size() > 0){
                Contact con = new Contact();
                con.RSG_Registration_Complete__c = true;
                con.RSG_Contact__c = true;
                con.Id = lstCon[0].Id;
                update con;

                Account acnt = new Account();
                //acnt.RSG_County__c = 'United States';
                //acnt.BillingState = lstCon[0].Account.Organization_State__c;
                acnt.Id = lstCon[0].AccountId;
                acnt.RSG_Registration_Complete__c = true;
                if(lstCon[0].Account.RSG_Status__c != 'Active'){
                    acnt.RSG_Status__c = 'Pending';
                }
                update acnt;
                
                return [Select Id, Account.RSG_Mailing_Street__c, RSG_Registration_Complete__c, Account.RSG_Status__c, Account.RSG_Registration_Complete__c from Contact where Id=:contactId];
            }
        }
        return null;
    }

    @AuraEnabled
    public static String updateEmail(String contactId){
        Contact con = new Contact();
        con.Is_Email__c = true;
        con.Id = contactId;
        update con;
        return null;
    }
        
}