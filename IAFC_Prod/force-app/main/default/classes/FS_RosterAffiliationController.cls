/**
 * Created by dwu on 2019-01-23.
 */

public without sharing class FS_RosterAffiliationController {

    @AuraEnabled
    public static Map<String, Object> getJSONCountriesAndStates() {
        return FS_JoinProcess_VerifyProfile_Controller.getJSONCountriesAndStates();
    }

    @AuraEnabled
    public static Map<String, String> getPopulationPicklistValues() {

        Map<String, String> picklistValuesMap = new Map<String,String>();

        Schema.DescribeFieldResult fieldResult = Account.Population_Served_Size__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry pickListVal : picklistEntries){
            if(picklistVal.isActive()) {
                picklistValuesMap.put(picklistVal.getValue(), picklistVal.getLabel());

            }
        }

        return picklistValuesMap;
    }

    @AuraEnabled
    public static Boolean insertAccount(Account accountRecord) {

        System.debug(accountRecord);

        accountRecord.OwnerId = Label.FS_AdministratorId;
        Database.SaveResult sr = Database.insert(accountRecord);

        User u = [SELECT ContactId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = accountRecord.Id;
        acr.ContactId = u.ContactId;
        acr.FS_Is_Primary__c = true;

        Database.SaveResult sr1 = Database.insert(acr);

        return sr.isSuccess() && sr1.isSuccess();
    }
}