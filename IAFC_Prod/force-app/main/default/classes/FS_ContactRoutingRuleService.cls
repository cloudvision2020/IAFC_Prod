/**
 * Helper class for FS_ContactRoutingRule
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

    public class FS_ContactRoutingRuleService {
    public static void beforeInsert(List<Contact> records) {
        processRecords(records, null);
    }

    public static void beforeUpdate(List<Contact> records, Map<Id, Contact> oldMap) {
        processRecords(records, oldMap);
    }

    public static void processRecords(List<Contact> records, Map<Id, Contact> oldMap) {
        Map<Id, Contact> accountIdsToContactWithDivisionOptOutTrue = new Map<Id, Contact>();
        for (Contact tempContact : records) {
            if (tempContact.Division_Opt_Out__c) {
                if (oldMap == null) {
                    accountIdsToContactWithDivisionOptOutTrue.put(tempContact.AccountId, tempContact);
                } else {
                    if (!oldMap.get(tempContact.Id).Division_Opt_Out__c || tempContact.AccountId != oldMap.get(tempContact.Id).AccountId) {
                        accountIdsToContactWithDivisionOptOutTrue.put(tempContact.AccountId, tempContact);
                    }
                }
            }
        }

        if (!accountIdsToContactWithDivisionOptOutTrue.isEmpty()) {
            updateDivisionOptOut(accountIdsToContactWithDivisionOptOutTrue);
        }
    }

    public static void updateDivisionOptOut(Map<Id, Contact> accountIdsToContactWithDivisionOptOutTrue) {
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Department_Type__c FROM Account WHERE Id IN :accountIdsToContactWithDivisionOptOutTrue.keySet()]);
        for (Id accountId : accountIdsToContactWithDivisionOptOutTrue.keySet()) {
            if (accounts.get(accountId).Department_Type__c == null || !accounts.get(accountId).Department_Type__c.equals('Federal/Military')) {
                accountIdsToContactWithDivisionOptOutTrue.get(accountId).Division_Opt_Out__c = false;
            }
        }
    }


    public static void updateUserEmail(List<Contact> records, Map<Id,Contact> oldMap) {

        Map<Id, Contact> contactIds = new Map<Id, Contact>();
        for (Contact con : records) {
            // check if email changed or if oldmap = null
            // add to contact list
            if (oldMap == null || con.Email != oldMap.get(con.Id).Email
                    || con.FirstName != oldMap.get(con.Id).FirstName
                    || con.MiddleName != oldMap.get(con.Id).MiddleName
                    || con.LastName != oldMap.get(con.Id).LastName
                    || con.MailingStreet != oldMap.get(con.Id).MailingStreet
                    || con.MailingCity != oldMap.get(con.Id).MailingCity
                    || con.MailingStateCode != oldMap.get(con.Id).MailingStateCode
                    || con.MailingCountryCode != oldMap.get(con.Id).MailingCountryCode
                    || con.Phone != oldMap.get(con.Id).Phone
                    || con.Fax != oldMap.get(con.Id).Fax
                    || con.Department != oldMap.get(con.Id).Department
                    || con.MobilePhone != oldMap.get(con.Id).MobilePhone
                    || con.Title != oldMap.get(con.Id).Title
                    ) {
                contactIds.put(con.Id, con);
            }
        }

        if (contactIds.size() > 0) {
            //call future method
            updateUsers(contactIds.keySet());

        }
    }
    @future
    public static void updateUsers(Set<Id> contactIds){
        List<User> users = [SELECT Id, Email, Username, ContactId,
                Contact.Email, Contact.FirstName, Contact.MiddleName, Contact.LastName,
                Contact.MailingStreet, Contact.MailingCity, Contact.MailingStateCode, Contact.MailingCountryCode,
                Contact.Phone, Contact.Fax, Contact.Department, Contact.MobilePhone, Contact.Title
        FROM User WHERE ContactId IN :contactIds];
        // get users for those contacts

        List<User> usersToUpdate = new List<User>();
        // change username and email on users
        for (User currentUser : users) {
            String newEmail = currentUser.Contact.Email;
            if (newEmail != null){
                currentUser.Email = newEmail;
                currentUser.Username = newEmail;
                usersToUpdate.add(currentUser);
            }

            currentUser.FirstName = currentUser.Contact.FirstName;
            currentUser.MiddleName = currentUser.Contact.MiddleName;
            currentUser.LastName = currentUser.Contact.LastName;
            currentUser.Street = currentUser.Contact.MailingStreet;
            currentUser.City = currentUser.Contact.MailingCity;
            currentUser.StateCode = currentUser.Contact.MailingStateCode;
            currentUser.CountryCode = currentUser.Contact.MailingCountryCode;
            currentUser.Phone = currentUser.Contact.Phone;
            currentUser.Fax = currentUser.Contact.Fax;
            currentUser.Department = currentUser.Contact.Department;
            currentUser.MobilePhone = currentUser.Contact.MobilePhone;
            currentUser.Title = currentUser.Contact.Title;

        }
        // re-insert changed users
        Database.update(usersToUpdate); //
    }
}