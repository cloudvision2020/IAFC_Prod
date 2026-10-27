/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SubscriptionLineItemJoinAction
 * Author          : <YourName>
 * Created Date    : May 20, 2026
 * Last Modified By: <YourName>
 * Last Modified On: May 20, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  May 20, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public without sharing class SubscriptionLineItemJoinAction {

    private static final String ITEM_CLASS_ID = Label.Subscription_Item_Class_Id;
    private static final String FORMER_MEMBERSHIP_TYPE = 'Former';
    private static final List<String> ELIGIBLE_TERM_STATUSES = new List<String>{ 'Active', 'Pending' };
    // NEW: Subscriptions in these statuses never contribute sections
    private static final List<String> EXCLUDED_SUB_STATUSES = new List<String>{ 'Cancelled', 'Expired' };

    public class Request {
        @InvocableVariable(
            label='Contact Id'
            description='Id of the Contact whose active Subscription Lines to fetch'
            required=true
        )
        public Id contactId;
    }

    public class Result {
        @InvocableVariable(
            label='Active Sections Text'
            description='Final Active Sections value updated on Contact'
        )
        public String activeSectionsText;

        @InvocableVariable(
            label='Contact Updated'
            description='True if the Contact record was included in a successful update DML'
        )
        public Boolean contactUpdated;
    }

    @InvocableMethod(
        label='Update Contact Active Sections'
        description='Queries active/pending section Subscription Lines and updates Contact Active Sections field. Former members are always blanked out.'
        category='Subscription'
    )
    public static List<Result> updateContactActiveSections(List<Request> requests) {

        List<Result> results = new List<Result>();

        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Set<Id> contactIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.contactId != null) {
                contactIds.add(req.contactId);
            }
        }

        if (contactIds.isEmpty()) {
            return results;
        }

        Id itemClassId = (Id) ITEM_CLASS_ID;

        // Split contacts into Former (always blank) vs everyone else (needs the query)
        Map<Id, Contact> contactsById = new Map<Id, Contact>([
            SELECT Id, Membership_Type__c
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        Set<Id> formerContactIds = new Set<Id>();
        Set<Id> activeEligibleContactIds = new Set<Id>();

        for (Id cId : contactIds) {
            Contact c = contactsById.get(cId);
            if (c != null && c.Membership_Type__c == FORMER_MEMBERSHIP_TYPE) {
                formerContactIds.add(cId);
            } else {
                activeEligibleContactIds.add(cId);
            }
        }

        Map<Id, List<String>> contactToSectionNames = new Map<Id, List<String>>();

        if (!activeEligibleContactIds.isEmpty()) {
            List<OrderApi__Subscription_Line__c> subLines = [
                SELECT Id,
                       Contact__c,
                       Item_Name__c,
                       OrderApi__Item__c,
                       OrderApi__Item__r.Name,
                       OrderApi__Item_Class__c,
                       Term_Status__c,
                       OrderApi__Subscription__r.OrderApi__Status__c
                FROM OrderApi__Subscription_Line__c
                WHERE Contact__c IN :activeEligibleContactIds
                AND Term_Status__c IN :ELIGIBLE_TERM_STATUSES
                AND OrderApi__Item_Class__c = :itemClassId
                //AND OrderApi__Subscription__r.OrderApi__Status__c != 'Cancelled'
                AND OrderApi__Subscription__r.OrderApi__Status__c NOT IN :EXCLUDED_SUB_STATUSES   // CHANGED
                ORDER BY Item_Name__c ASC
            ];

            for (OrderApi__Subscription_Line__c sl : subLines) {
                if (sl.Contact__c == null) {
                    continue;
                }

                String itemName = String.isNotBlank(sl.Item_Name__c)
                    ? sl.Item_Name__c
                    : sl.OrderApi__Item__r.Name;

                if (String.isBlank(itemName)) {
                    continue;
                }

                if (!contactToSectionNames.containsKey(sl.Contact__c)) {
                    contactToSectionNames.put(sl.Contact__c, new List<String>());
                }

                if (!contactToSectionNames.get(sl.Contact__c).contains(itemName)) {
                    contactToSectionNames.get(sl.Contact__c).add(itemName);
                }
            }
        }

        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id, String> contactToFinalText = new Map<Id, String>();

        for (Id contactId : contactIds) {
            String finalActiveSections;

            if (formerContactIds.contains(contactId)) {
                finalActiveSections = '';
            } else {
                List<String> sectionNames = contactToSectionNames.containsKey(contactId)
                    ? contactToSectionNames.get(contactId)
                    : new List<String>();
                finalActiveSections = String.join(sectionNames, '; ');
            }

            contactToFinalText.put(contactId, finalActiveSections);

            contactsToUpdate.add(new Contact(
                Id = contactId,
                Active_Sections__c = finalActiveSections
            ));
        }

        // Track which contact Ids actually succeeded in the DML so Result.contactUpdated is accurate
        Set<Id> successfullyUpdatedIds = new Set<Id>();

        if (!contactsToUpdate.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.update(contactsToUpdate, false);

            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()) {
                    successfullyUpdatedIds.add(contactsToUpdate[i].Id);
                } else {
                    for (Database.Error err : saveResults[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'Failed to update Active_Sections__c for Contact ' + contactsToUpdate[i].Id +
                            ': ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }

        for (Request req : requests) {
            Result res = new Result();

            if (req != null && req.contactId != null) {
                res.activeSectionsText = contactToFinalText.get(req.contactId);
                res.contactUpdated = successfullyUpdatedIds.contains(req.contactId);
            } else {
                res.activeSectionsText = '';
                res.contactUpdated = false;
            }

            results.add(res);
        }

        return results;
    }
}