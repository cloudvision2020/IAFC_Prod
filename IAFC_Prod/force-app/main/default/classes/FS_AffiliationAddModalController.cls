/**
 * Created by dwu on 2019-01-22.
 */

public without sharing class FS_AffiliationAddModalController {

    @AuraEnabled
    public static List<Account> getResults(String searchString, Boolean isJoinProcessPage) {
        User u = [SELECT ContactId, Contact.AccountId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String queryString = '';
        if (isJoinProcessPage) {
            queryString = 'SELECT Id, Name, BillingCity, BillingState, BillingCountry FROM Account WHERE Id != \'' + u.Contact.AccountId + '\' AND Name LIKE \'%' + searchString + '%\' LIMIT 10';
        } else {
            queryString = 'SELECT Id, Name, BillingCity, BillingState, BillingCountry FROM Account WHERE Id NOT IN (SELECT AccountId FROM AccountContactRelation WHERE ContactId = \'' + u.ContactId + '\') AND Name LIKE \'%' + searchString + '%\' LIMIT 10';
        }
        return Database.query(queryString);
    }

    @AuraEnabled
    public static Map<String, Object> insertAffiliation(String accountRecordId, Boolean isJoinProcessPageAndExistingAffiliation, Boolean isNoOrganization) {
        Map<String, Object> result = new Map<String, Object>();
        User u = [SELECT ContactId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Database.SaveResult sr;
        if (!isNoOrganization) {
            if (!isJoinProcessPageAndExistingAffiliation) {
                AccountContactRelation acr = new AccountContactRelation();
                acr.AccountId = accountRecordId;
                acr.ContactId = u.ContactId;
                acr.FS_Is_Primary__c = true;
                sr = Database.insert(acr);
            } else {
                AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :accountRecordId AND ContactId = :u.ContactId];
                acr.FS_Is_Primary__c = true;
                sr = Database.update(acr);
            }
        } else {
            Id noOrgId = [SELECT Id FROM Account WHERE Name = 'No Organization Selected'][0].Id;
            AccountContactRelation[] acrs = [SELECT Id, AccountId, ContactId, FS_Is_Primary__c FROM AccountContactRelation WHERE ContactId = :u.ContactId AND AccountId = :noOrgId];
            if (acrs.isEmpty()) {
                AccountContactRelation acr = new AccountContactRelation();
                acr.AccountId = noOrgId;
                acr.ContactId = u.ContactId;
                acr.FS_Is_Primary__c = true;
                sr = Database.insert(acr);
            } else {
                acrs[0].FS_Is_Primary__c = true;
                sr = Database.update(acrs[0]);
            }
        }
        result.put('Status', sr.isSuccess());
        result.put('Contact', [SELECT Id, FirstName, MiddleName, LastName, Title, Suffix, MailingStreet, MailingCity, MailingStateCode,
                MailingCountryCode, MailingPostalCode, OrderApi__Preferred_Email_Type__c, OrderApi__Preferred_Phone_Type__c,
                OrderApi__Work_Email__c, OrderApi__Other_Email__c, OrderApi__Work_Phone__c, MobilePhone, OtherPhone,
                Functional_Title__c, New_Mem_Fee__c, Division__c, AccountId, Account.Name, Account.FS_Account_Division__c,
                Account.Population_Served_Size__c, Account.OrderApi__Outstanding_Credits__c, Account.Organization_Type__c,
        (SELECT Id FROM OrderApi__Subscriptions__r WHERE OrderApi__Status__c = 'Active'),
        (SELECT Id FROM OrderApi__Sales_Orders__r WHERE OrderApi__Status__c = 'Open' OR (OrderApi__Status__c = 'Closed'
        AND OrderApi__Posting_Status__c = 'Pending') ORDER BY LastModifiedDate DESC)
        FROM Contact WHERE Id = :u.ContactId]);
        return result;
    }
}