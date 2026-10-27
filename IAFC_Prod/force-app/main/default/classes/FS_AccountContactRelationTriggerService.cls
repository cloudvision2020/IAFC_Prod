/**
 * Helper class for FS_AccountContactRelationTrigger
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

public class FS_AccountContactRelationTriggerService {
    private static String testUnknownAccountID = null;

    @TestVisible
    private static void setTestUnknownAccountID(String accID) {
        testUnknownAccountID = accID;
    }

    public static void beforeInsert(List<AccountContactRelation> newRecords, String unknownAccountId) {
        if(Test.isRunningTest()) {
            unknownAccountId = testUnknownAccountID;
        }
        checkIsPrimary(newRecords, null, unknownAccountId);
    }

    public static void beforeUpdate(List<AccountContactRelation> newRecords, Map<Id, AccountContactRelation> oldRecordsMap, String unknownAccountId) {
        if(Test.isRunningTest()) {
            unknownAccountId = testUnknownAccountID;
        }
        checkIsPrimary(newRecords, oldRecordsMap, unknownAccountId);
    }

    public static void afterInsert(List<AccountContactRelation> newRecords, String unknownAccountId) {
        if(Test.isRunningTest()) {
            unknownAccountId = testUnknownAccountID;
        }
        processRecords(newRecords, null, unknownAccountId);
    }

    public static void afterUpdate(List<AccountContactRelation> newRecords, Map<Id, AccountContactRelation> oldRecordsMap, String unknownAccountId) {
        if(Test.isRunningTest()) {
            unknownAccountId = testUnknownAccountID;
        }
        processRecords(newRecords, oldRecordsMap, unknownAccountId);
    }

    public static void afterDelete(List<AccountContactRelation> oldRecords, String unknownAccountId) {
        if(Test.isRunningTest()) {
            unknownAccountId = testUnknownAccountID;
        }

        Set<Id> contactIds = new Set<Id>();
        Set<Id> contactIdsWithNoAccountContactRelations = new Set<Id>();

        for (AccountContactRelation tempAccountContactRelation : oldRecords) {
            contactIds.add(tempAccountContactRelation.ContactId);
        }

        for (Contact tempContact : [SELECT Id, (SELECT Id FROM AccountContactRelations) FROM Contact WHERE Id IN :contactIds]) {
            if (tempContact.AccountContactRelations.size() == 0) {
                contactIdsWithNoAccountContactRelations.add(tempContact.Id);
            }
        }

        if (!contactIds.isEmpty()) {
            linkUnknownAccountToContact(contactIdsWithNoAccountContactRelations, unknownAccountId);
        }
    }

    // Check Is Primary when IsDirect is true, used in beforeInsert and beforeUpdate
    public static void checkIsPrimary(List<AccountContactRelation> records, Map<Id, AccountContactRelation> oldMap, String unknownAccountId) {

        System.debug('unknownAccountId: ' + unknownAccountId);
        System.debug('records');
        System.debug(records);

        for (AccountContactRelation tempAccountContactRelation : records) {
            System.debug('Line 1');
            if ((oldMap == null && tempAccountContactRelation.IsDirect && !tempAccountContactRelation.FS_Is_Primary__c)
                    || (oldMap != null && tempAccountContactRelation.IsDirect && !oldMap.get(tempAccountContactRelation.Id).IsDirect)) {
                System.debug('Line 2');
                tempAccountContactRelation.FS_Is_Primary__c = true;
            }
            System.debug('Line 3');
            if (tempAccountContactRelation.FS_Is_Primary__c && !tempAccountContactRelation.IsActive && !tempAccountContactRelation.IsDirect
                    && !oldMap.get(tempAccountContactRelation.Id).IsDirect) {
                System.debug('Line 4');
                tempAccountContactRelation.IsActive = true;
            }

            System.debug('Line 5');
            if (oldMap != null && tempAccountContactRelation.AccountId == unknownAccountId && tempAccountContactRelation.IsDirect
                    && !oldMap.get(tempAccountContactRelation.Id).IsDirect && !oldMap.get(tempAccountContactRelation.Id).IsActive) {
                System.debug('Line 6');
                tempAccountContactRelation.IsActive = true;
            }
            System.debug('Line 7');
            if (tempAccountContactRelation.AccountId == unknownAccountId && !tempAccountContactRelation.isDirect
                    && !tempAccountContactRelation.FS_Is_Primary__c && tempAccountContactRelation.IsActive) {
                System.debug('Line 8');
                tempAccountContactRelation.IsActive = false;
            }
            System.debug('Line 9');
            if (oldMap != null && tempAccountContactRelation.AccountId == unknownAccountId && tempAccountContactRelation.IsDirect && oldMap.get(tempAccountContactRelation.Id).IsDirect
                    && (!tempAccountContactRelation.FS_Is_Primary__c && oldMap.get(tempAccountContactRelation.Id).FS_Is_Primary__c
                    || !tempAccountContactRelation.IsActive && oldMap.get(tempAccountContactRelation.Id).IsActive)) {
                System.debug('Line 10');
                tempAccountContactRelation.FS_Is_Primary__c = true;
                tempAccountContactRelation.IsActive = true;
            }
        }
    }

    // Process records, used in afterInsert and afterUpdate
    public static void processRecords(List<AccountContactRelation> newRecords, Map<Id, AccountContactRelation> oldRecordsMap, String unknownAccountId) {
        Map<Id, AccountContactRelation> contactIdToAccountContactRelation = new Map<Id, AccountContactRelation>();
        Map<Id, Id> contactIdToAccountId = new Map<Id, Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> contactIdsNeedToLinkUnknownAccount = new Set<Id>();

        for (AccountContactRelation tempAccountContactRelation : newRecords) {
            if (oldRecordsMap != null && !tempAccountContactRelation.IsActive && oldRecordsMap.get(tempAccountContactRelation.Id).IsActive
                    && tempAccountContactRelation.IsDirect && oldRecordsMap.get(tempAccountContactRelation.Id).IsDirect
                    && tempAccountContactRelation.FS_Is_Primary__c && oldRecordsMap.get(tempAccountContactRelation.Id).FS_Is_Primary__c) {
                contactIdsNeedToLinkUnknownAccount.add(tempAccountContactRelation.ContactId);
            } else if (oldRecordsMap != null && tempAccountContactRelation.IsActive && oldRecordsMap.get(tempAccountContactRelation.Id).IsActive
                    && tempAccountContactRelation.IsDirect && oldRecordsMap.get(tempAccountContactRelation.Id).IsDirect
                    && !tempAccountContactRelation.FS_Is_Primary__c && oldRecordsMap.get(tempAccountContactRelation.Id).FS_Is_Primary__c) {
                contactIdsNeedToLinkUnknownAccount.add(tempAccountContactRelation.ContactId);
            } else {
                if ((oldRecordsMap != null && (tempAccountContactRelation.FS_Is_Primary__c && !oldRecordsMap.get(tempAccountContactRelation.Id).FS_Is_Primary__c
                        || (tempAccountContactRelation.FS_Is_Primary__c && tempAccountContactRelation.IsActive && !oldRecordsMap.get(tempAccountContactRelation.Id).IsActive)))
                        || (oldRecordsMap == null && tempAccountContactRelation.FS_Is_Primary__c)) {
                    contactIdToAccountContactRelation.put(tempAccountContactRelation.ContactId, tempAccountContactRelation);
                    contactIdToAccountId.put(tempAccountContactRelation.ContactId, tempAccountContactRelation.AccountId);
                }
                if ((oldRecordsMap != null && !tempAccountContactRelation.IsActive && oldRecordsMap.get(tempAccountContactRelation.Id).IsActive)
                        || (oldRecordsMap == null && !tempAccountContactRelation.IsActive)) {
                    contactIds.add(tempAccountContactRelation.ContactId);
                }
            }
        }

        if (!contactIdToAccountContactRelation.isEmpty()) {
            updateAccountOnContact(contactIdToAccountContactRelation);
        }
        if (!contactIdToAccountId.isEmpty()) {
            unCheckIsPrimary(contactIdToAccountId);
        }
        if (!contactIds.isEmpty()) {
            checkIsActive(contactIds, unknownAccountId);
        }
        if (!contactIdsNeedToLinkUnknownAccount.isEmpty()) {
            linkUnknownAccountToContact(contactIdsNeedToLinkUnknownAccount, unknownAccountId);
        }
    }

    // Check IsActive on all AccountContactRelation records
    public static void checkIsActive(Set<Id> contactIds, String unknownAccountId) {
        Set<Id> contactIdsWithNoAccountContactRelations = new Set<Id>();
        List<AccountContactRelation> accountContactRelationsNeedToBeActive = new List<AccountContactRelation>();

        for (Contact tempContact : [SELECT Id, (SELECT Id, AccountId, IsActive FROM AccountContactRelations WHERE (IsActive =
                true) OR (IsActive = false AND AccountId = :unknownAccountId)) FROM Contact WHERE Id IN :contactIds]) {
            if (tempContact.AccountContactRelations.size() == 0) {
                contactIdsWithNoAccountContactRelations.add(tempContact.Id);
            }
            if (tempContact.AccountContactRelations.size() == 1 && !tempContact.AccountContactRelations[0].IsActive
                    && tempContact.AccountContactRelations[0].AccountId == unknownAccountId) {
                tempContact.AccountContactRelations[0].IsActive = true;
                tempContact.AccountContactRelations[0].FS_Is_Primary__c = true;
                accountContactRelationsNeedToBeActive.add(tempContact.AccountContactRelations[0]);
            }
        }

        if (!contactIdsWithNoAccountContactRelations.isEmpty()) {
            linkUnknownAccountToContact(contactIdsWithNoAccountContactRelations, unknownAccountId);
        }
        if (!accountContactRelationsNeedToBeActive.isEmpty()) {
            update accountContactRelationsNeedToBeActive;
        }
    }

    // Update Account on Contact when Is Primary on AccountContactRelation is true
    public static void updateAccountOnContact(Map<Id, AccountContactRelation> contactIdToAccountContactRelation) {
        List<Contact> contactsNeedToUpdate = new List<Contact>();
        Map<Id, Contact> contactIdToContact = new Map<Id, Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN :contactIdToAccountContactRelation.keySet()]);
        for (AccountContactRelation tempAccountContactRelation : contactIdToAccountContactRelation.values()) {
            if (tempAccountContactRelation.AccountId != contactIdToContact.get(tempAccountContactRelation.ContactId).AccountId) {
                contactsNeedToUpdate.add(
                        new Contact(
                                Id = tempAccountContactRelation.ContactId,
                                AccountId = tempAccountContactRelation.AccountId
                        )
                );
            }
        }

        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }

    // Update Is Primary on all other AccountContactRelation with same contact to false when Is Primary on one AccountRelation is set to true
    public static void unCheckIsPrimary(Map<Id, Id> contactIdToAccountId) {
        List<AccountContactRelation> accountContactRelationsNeedToUpdate = new List<AccountContactRelation>();
        for (AccountContactRelation tempAccountContactRelation : [SELECT Id FROM AccountContactRelation WHERE FS_Is_Primary__c
                = true AND ContactId IN :contactIdToAccountId.keySet() AND AccountId NOT IN
                :contactIdToAccountId.values()]) {
            accountContactRelationsNeedToUpdate.add(
                    new AccountContactRelation(
                            Id = tempAccountContactRelation.Id,
                            FS_Is_Primary__c = false
                    )
            );
        }

        if (!accountContactRelationsNeedToUpdate.isEmpty()) {
            update accountContactRelationsNeedToUpdate;
        }
    }

    // Create AccountContactRelation For Unknown Account
    public static void linkUnknownAccountToContact(Set<Id> contactIds, String unknownAccountId) {
        List<Contact> contactsNeedToUpdate = new List<Contact>();
        for (Id tempContactId : contactIds) {
            contactsNeedToUpdate.add(
                    new Contact(
                            AccountId = unknownAccountId,
                            Id = tempContactId
                    )
            );
        }
        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }
}