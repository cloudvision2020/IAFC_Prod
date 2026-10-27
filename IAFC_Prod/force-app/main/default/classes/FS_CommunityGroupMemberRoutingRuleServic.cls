/**
 * Helper class for FS_CommunityGroupMemberRoutingRule
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-18
 */

public class FS_CommunityGroupMemberRoutingRuleServic {
    public static void afterInsert(List<PagesApi__Community_Group_Member__c> records) {
        processRecords(records, null, 'afterInsert');
    }

    public static void afterUpdate(List<PagesApi__Community_Group_Member__c> records, Map<Id, PagesApi__Community_Group_Member__c> oldMap) {
        processRecords(records, oldMap, 'afterUpdate');
    }

    public static void afterDelete(List<PagesApi__Community_Group_Member__c> records) {
        processRecords(records, null, 'afterDelete');
    }

    public static void processRecords(List<PagesApi__Community_Group_Member__c> records, Map<Id, PagesApi__Community_Group_Member__c> oldMap, String operation) {
        Set<Id> contactIdsWithActiveCommunityGroupMember = new Set<Id>();
        for (PagesApi__Community_Group_Member__c tempCommunityGroupMember : records) {
            if (operation.equals('afterDelete')) {
                contactIdsWithActiveCommunityGroupMember.add(tempCommunityGroupMember.PagesApi__Contact__c);
            } else {
                if (oldMap == null) {
                    if (tempCommunityGroupMember.PagesApi__Status__c.equals('Active') && tempCommunityGroupMember.PagesApi__Is_Active__c) {
                        contactIdsWithActiveCommunityGroupMember.add(tempCommunityGroupMember.PagesApi__Contact__c);
                    }
                } else {
                    if (!tempCommunityGroupMember.PagesApi__Status__c.equals(oldMap.get(tempCommunityGroupMember.Id).PagesApi__Status__c)
                            && tempCommunityGroupMember.PagesApi__Is_Active__c != oldMap.get(tempCommunityGroupMember.Id).PagesApi__Is_Active__c) {
                        contactIdsWithActiveCommunityGroupMember.add(tempCommunityGroupMember.PagesApi__Contact__c);
                    }
                }
            }
        }

        if (!contactIdsWithActiveCommunityGroupMember.isEmpty()) {
            updateContactSections(contactIdsWithActiveCommunityGroupMember);
        }
    }

    public static void updateContactSections(Set<Id> contactIdsWithActiveCommunityGroupMember) {
        List<Contact> contactsNeedToUpdate = new List<Contact>();

        for (Contact tempContact : [SELECT Id, Sections__c, (SELECT Id, PagesApi__Community_Group__r.Name, PagesApi__Status__c, PagesApi__Is_Active__c,
                PagesApi__Community_Group__r.PagesApi__Type__c FROM PagesApi__Community_Group_Members__r ORDER BY
                PagesApi__Community_Group__r.Name ASC) FROM Contact WHERE Id IN :contactIdsWithActiveCommunityGroupMember]) {
            String sections = '';
            for (Integer i = 0; i < tempContact.PagesApi__Community_Group_Members__r.size(); i++) {
                PagesApi__Community_Group_Member__c tempCommunityGroupMember = tempContact.PagesApi__Community_Group_Members__r[i];
                if (tempCommunityGroupMember.PagesApi__Is_Active__c && tempCommunityGroupMember.PagesApi__Status__c.equals('Active')
                        && tempCommunityGroupMember.PagesApi__Community_Group__r.PagesApi__Type__c.equals('Section')) {
                    sections += (tempCommunityGroupMember.PagesApi__Community_Group__r.Name + ', ');
                }
            }
            if (!sections.equals('') && tempContact.Sections__c != sections) {
                tempContact.Sections__c = sections.removeEnd(', ');
                contactsNeedToUpdate.add(tempContact);
            } else {
                tempContact.Sections__c = null;
                contactsNeedToUpdate.add(tempContact);
            }
        }

        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }
}