/**
 * Helper class for FS_SubscriptionRoutingRule
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

 public class FS_SubscriptionRoutingRuleService {
    public static void afterInsert(List<OrderApi__Subscription__c> records) {
        processRecords(records, null);
    }

    public static void afterUpdate(List<OrderApi__Subscription__c> records, Map<Id, OrderApi__Subscription__c> oldMap) {
        processRecords(records, oldMap);
    }

    public static void processRecords(List<OrderApi__Subscription__c> records, Map<Id, OrderApi__Subscription__c> oldMap) {
        Map<Id, Date> contactIdToOriginalJoinDate = new Map<Id, Date>();
        Set<Id> contactIdsWithInactiveSubscriptions = new Set<Id>();
        Set<Id> contactIdsWithActiveSubscriptions = new Set<Id>();
        Map<Id, OrderApi__Subscription__c> contactIdToSubscriptionRejoinDateNew = new Map<Id, OrderApi__Subscription__c>();
        Map<Id, OrderApi__Subscription__c> contactIdToSubscriptionRejoinDateOld = new Map<Id, OrderApi__Subscription__c>();
        Set<Id> subscriptionIdForCommunityGroupMember = new Set<Id>();
        Set<Id> subscriptionIdForCommunityGroupMemberForRenewals = new Set<Id>();

        for (OrderApi__Subscription__c tempSubscription : records) {
            //if the subscription record is new
            if (oldMap == null) { 
                if (tempSubscription.OrderApi__Is_Active__c && ((contactIdToOriginalJoinDate.containsKey(tempSubscription.OrderApi__Contact__c)
                        && tempSubscription.OrderApi__Current_Term_Start_Date__c < contactIdToOriginalJoinDate.get(tempSubscription.OrderApi__Contact__c))
                        || !contactIdToOriginalJoinDate.containsKey(tempSubscription.OrderApi__Contact__c))) {
                    contactIdToOriginalJoinDate.put(tempSubscription.OrderApi__Contact__c, tempSubscription.OrderApi__Current_Term_Start_Date__c);
                }
                if (tempSubscription.OrderApi__Is_Active__c) {
                    contactIdToSubscriptionRejoinDateNew.put(tempSubscription.OrderApi__Contact__c, tempSubscription); 
                }
                subscriptionIdForCommunityGroupMember.add(tempSubscription.Id);
            }
            //If the subscription has gained a term
            if (oldMap != null && 
                tempSubscription.OrderApi__Status__c !=oldMap.get(tempSubscription.Id).OrderApi__Status__c 
                && (tempSubscription.OrderApi__Status__c.equals('Expired') 
                || tempSubscription.OrderApi__Status__c.equals('Cancelled')
                || tempSubscription.OrderApi__Status__c.equals('Suspended'))) {

                subscriptionIdForCommunityGroupMemberForRenewals.add(tempSubscription.Id);
            }
            //If the subscription is becoming inactive
            if ((oldMap != null && !tempSubscription.OrderApi__Is_Active__c && !tempSubscription.OrderApi__Status__c.equals('Active')
                    && oldMap.get(tempSubscription.Id).OrderApi__Is_Active__c && oldMap.get(tempSubscription.Id).OrderApi__Status__c.equals('Active'))
                    || (oldMap == null && !tempSubscription.OrderApi__Is_Active__c && !tempSubscription.OrderApi__Status__c.equals('Active'))) {
                contactIdsWithInactiveSubscriptions.add(tempSubscription.OrderApi__Contact__c);
            }
            //If the subscription isbecoming active
            if ((oldMap != null && tempSubscription.OrderApi__Is_Active__c && tempSubscription.OrderApi__Status__c.equals('Active')
                    && !oldMap.get(tempSubscription.Id).OrderApi__Is_Active__c && !oldMap.get(tempSubscription.Id).OrderApi__Status__c.equals('Active'))
                    || (oldMap == null && tempSubscription.OrderApi__Is_Active__c && tempSubscription.OrderApi__Status__c.equals('Active'))
                        //Added this line so renewals will trigger populateMembershipExpiration ~ Trav
                    || (oldMap != null && tempSubscription.OrderApi__Is_Active__c && tempSubscription.OrderApi__Status__c.equals('Active') && tempSubscription.OrderApi__Entity__c.equals('Contact'))
                    ) {
                contactIdsWithActiveSubscriptions.add(tempSubscription.OrderApi__Contact__c);
            }
            //if this is a rejoin
            if (oldMap != null && tempSubscription.OrderApi__Is_Active__c && tempSubscription.OrderApi__Days_To_Lapse__c > 0
                    && oldMap.get(tempSubscription.Id).OrderApi__Days_To_Lapse__c < -90) {
                contactIdToSubscriptionRejoinDateOld.put(tempSubscription.OrderApi__Contact__c, tempSubscription);
            }
        }

        Set<Id> contactIdsWithActiveOrInactiveSubscriptions = new Set<Id>();
        contactIdsWithActiveOrInactiveSubscriptions.addAll(contactIdsWithActiveSubscriptions);
        contactIdsWithActiveOrInactiveSubscriptions.addAll(contactIdsWithInactiveSubscriptions);

        /*if (!subscriptionIdForCommunityGroupMember.isEmpty()) {
            System.debug('>>>>>>>>>>'+subscriptionIdForCommunityGroupMember);
            createCommunityGroupMemberAndCommunityGroupMemberHistory(subscriptionIdForCommunityGroupMember);
        }*/

        if (!subscriptionIdForCommunityGroupMemberForRenewals.isEmpty()) {
            updateCommunityGroupMemberAndCommunityGroupMemberHistoryRenewal(subscriptionIdForCommunityGroupMemberForRenewals);
        }

        if (oldMap == null) {
            populateOriginalJoinDate(contactIdToOriginalJoinDate);
        }
        if (!contactIdsWithActiveOrInactiveSubscriptions.isEmpty()) {
            checkNewMemFee(contactIdsWithActiveOrInactiveSubscriptions);
            populateMembershipExpiration(contactIdsWithActiveOrInactiveSubscriptions);
            populateMembershipType(contactIdsWithActiveOrInactiveSubscriptions);
        }
        if (!contactIdToSubscriptionRejoinDateNew.isEmpty() || !contactIdToSubscriptionRejoinDateOld.isEmpty()) {
            populateRejoinDate(contactIdToSubscriptionRejoinDateNew, contactIdToSubscriptionRejoinDateOld); 
        }
    }

    public static void checkNewMemFee(Set<Id> contactIdsWithActiveOrInactiveSubscriptions) {
        List<Contact> contactsNeedToUpdate = new List<Contact>();

        for (Contact tempContact : [SELECT Id, New_Mem_Fee__c, (SELECT Id FROM OrderApi__Subscriptions__r WHERE OrderApi__Is_Active__c
                = true AND OrderApi__Status__c = 'Active') FROM Contact WHERE Id IN :contactIdsWithActiveOrInactiveSubscriptions]) {
            if (tempContact.OrderApi__Subscriptions__r.size() == 0 && !tempContact.New_Mem_Fee__c) {
                tempContact.New_Mem_Fee__c = true;
                contactsNeedToUpdate.add(tempContact);
            }
            if (tempContact.OrderApi__Subscriptions__r.size() > 0 && tempContact.New_Mem_Fee__c) {
                tempContact.New_Mem_Fee__c = false;
                contactsNeedToUpdate.add(tempContact);
            }
        }

        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }

    public static void populateOriginalJoinDate(Map<Id, Date> contactIdToOriginalJoinDate) {
        List<Contact> contactsNeedToUpdate = new List<Contact>();

        for (Contact tempContact : [SELECT Id, Original_Join_Date__c FROM Contact WHERE Id IN :contactIdToOriginalJoinDate.keySet()]) {
            if (tempContact.Original_Join_Date__c == null || tempContact.Original_Join_Date__c > contactIdToOriginalJoinDate.get(tempContact.Id)) {
                tempContact.Original_Join_Date__c = contactIdToOriginalJoinDate.get(tempContact.Id);
                contactsNeedToUpdate.add(tempContact);
            }
        }

        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }

    //runs if you are creating this sub and its active or if you are updating it and it's going from inactive to active.
    public static void populateRejoinDate(Map<Id, OrderApi__Subscription__c> contactIdToSubscriptionRejoinDateNew, Map<Id, OrderApi__Subscription__c> contactIdToSubscriptionRejoinDateOld) {
        List<Contact> contactsNeedToUpdate = new List<Contact>();

        Map<Id, Contact> contacts = new Map<Id, Contact>(
            [SELECT Id, 
                (SELECT Id, OrderApi__Days_To_Lapse__c,OrderApi__Is_Active__c  FROM OrderApi__Subscriptions__r 
                    WHERE (OrderApi__Is_Active__c = true) and 
                        OrderApi__Entity__c = 'Contact' //should ignore account subs
                    //Fusion Spans old  Where clause... WHERE (OrderApi__In_Grace_Period__c = true OR OrderApi__Is_Active__c = false ) 
                    ORDER BY OrderApi__Current_Term_End_Date__c DESC) 
            FROM Contact WHERE Id IN :contactIdToSubscriptionRejoinDateNew.keySet() OR Id IN :contactIdToSubscriptionRejoinDateOld.keySet()]); 
        
        //this runs on subscription object being INSERTED as active
        for (Id tempContactId : contactIdToSubscriptionRejoinDateNew.keySet()) {
            OrderApi__Subscription__c tempSubscription = contactIdToSubscriptionRejoinDateNew.get(tempContactId); 
            //If there are no active contact subscriptions besides this one being created set the rejoin date because it's the first
            if (contacts.get(tempContactId).OrderApi__Subscriptions__r.size() <= 1) {
                contacts.get(tempContactId).Rejoin_Date__c = tempSubscription.OrderApi__Current_Term_Start_Date__c;
                contactsNeedToUpdate.add(contacts.get(tempContactId));
            } 
            //if there are more than just this one being created the most recent one should be this one...
            /*if (contacts.get(tempContactId).OrderApi__Subscriptions__r.size() > 1) {
                //... so if the next most recent is not active it's a rejoin under a different product or a rejoin and it wasnt linked to the previous sub. Either way set the rejoin date.
                if (contacts.get(tempContactId).OrderApi__Subscriptions__r[1].OrderApi__Is_Active__c = false){//.OrderApi__Days_To_Lapse__c < -90) {
                    contacts.get(tempContactId).Rejoin_Date__c = tempSubscription.OrderApi__Current_Term_Start_Date__c;
                    contactsNeedToUpdate.add(contacts.get(tempContactId));
                }
            }*/
        }

        //This runs on subs being UPDATED to active from inactive
        for (Id tempContactId : contactIdToSubscriptionRejoinDateOld.keySet()) {
            OrderApi__Subscription__c tempSubscription = contactIdToSubscriptionRejoinDateOld.get(tempContactId);
            contacts.get(tempContactId).Rejoin_Date__c = tempSubscription.OrderApi__Last_Renewed_Date__c;
            contactsNeedToUpdate.add(contacts.get(tempContactId));
        }

        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }

    public static void populateMembershipType(Set<Id> contactIdsWithActiveOrInactiveSubscriptions) {
        Map<String, String> subscriptionItemToMembershipType = new Map<String, String>{
                'Full Membership' => 'Full', 
                'Full Membership Renewal' => 'Full',
                'Associate Membership' => 'Associate',
                'Affiliate Membership' => 'Affiliate', 
                'Basic Membership' => 'Basic'
        };
        List<Contact> contactsNeedToUpdate = new List<Contact>();

        for (Contact tempContact : [SELECT Id, Original_Join_Date__c, (SELECT Id,OrderApi__Status__c, OrderApi__Is_Active__c,
                OrderApi__In_Grace_Period__c, Subscription_Item_Name__c FROM OrderApi__Subscriptions__r WHERE OrderApi__Status__c
                = 'Active' AND OrderApi__Is_Active__c = true) FROM Contact WHERE Id IN :contactIdsWithActiveOrInactiveSubscriptions]) {
            
            //If they only have 1 sub and it's one of the mapped ones above, set it to that membership type
            if (tempContact.OrderApi__Subscriptions__r.size() == 1 && subscriptionItemToMembershipType.containsKey(tempContact.OrderApi__Subscriptions__r[0].Subscription_Item_Name__c)) {
                tempContact.Membership_Type__c = subscriptionItemToMembershipType.get(tempContact.OrderApi__Subscriptions__r[0].Subscription_Item_Name__c);
                contactsNeedToUpdate.add(tempContact);
            }

            //if they have 2 active subs set it to the membershyp type of the one not in a grace period
            if (tempContact.OrderApi__Subscriptions__r.size() == 2) {
                if (!tempContact.OrderApi__Subscriptions__r[0].OrderApi__In_Grace_Period__c && subscriptionItemToMembershipType.containsKey(tempContact.OrderApi__Subscriptions__r[0].Subscription_Item_Name__c)) {
                    tempContact.Membership_Type__c = subscriptionItemToMembershipType.get(tempContact.OrderApi__Subscriptions__r[0].Subscription_Item_Name__c);
                    contactsNeedToUpdate.add(tempContact);
                }
                if (!tempContact.OrderApi__Subscriptions__r[1].OrderApi__In_Grace_Period__c && subscriptionItemToMembershipType.containsKey(tempContact.OrderApi__Subscriptions__r[1].Subscription_Item_Name__c)) {
                    tempContact.Membership_Type__c = subscriptionItemToMembershipType.get(tempContact.OrderApi__Subscriptions__r[1].Subscription_Item_Name__c);
                    contactsNeedToUpdate.add(tempContact);
                }
            }
            
            //If they have no active sub but was a member at one point set it to former.
            if (tempContact.OrderApi__Subscriptions__r.size() == 0 && tempContact.Original_Join_Date__c != null) {
                tempContact.Membership_Type__c = 'Former';
                contactsNeedToUpdate.add(tempContact);
            } 
            //If they have no active sub set it to null.
            else if (tempContact.OrderApi__Subscriptions__r.size() == 0) {
                tempContact.Membership_Type__c = null;
                contactsNeedToUpdate.add(tempContact);
            }
        }

        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }

    public static void populateMembershipExpiration(Set<Id> contactIdsWithActiveOrInactiveSubscriptions) {
        List<Contact> contactsNeedToUpdate = new List<Contact>();
        for (Contact tempContact : [SELECT Id, Membership_Type__c, IAFC_Member__c, (SELECT Id,OrderApi__Status__c, OrderApi__Is_Active__c,
                OrderApi__In_Grace_Period__c, Subscription_Item_Name__c, OrderApi__Paid_Through_Date__c FROM OrderApi__Subscriptions__r WHERE OrderApi__Is_Active__c
                = true AND OrderApi__Status__c = 'Active') FROM Contact WHERE Id IN :contactIdsWithActiveOrInactiveSubscriptions]) {
            Date furthestPaidDate = null;

            for (OrderApi__Subscription__c tempSubscription : tempContact.OrderApi__Subscriptions__r) {
                //Trav - 1/30/2020 - If they are an active individual member and this is a departmental subsciption, dont populate the date with this sub
                if(!(tempContact.IAFC_Member__c && tempContact.Membership_Type__c != 'Departmental User' && tempSubscription.Subscription_Item_Name__c == 'Departmental Membership')){
                    if (furthestPaidDate == null) {
                        furthestPaidDate = tempSubscription.OrderApi__Paid_Through_Date__c;
                    } else {
                        if (furthestPaidDate < tempSubscription.OrderApi__Paid_Through_Date__c) {
                            furthestPaidDate = tempSubscription.OrderApi__Paid_Through_Date__c;
                        }
                    }
                }
            }

            if (furthestPaidDate != null) {
                tempContact.Membership_Expiration__c = furthestPaidDate;
                contactsNeedToUpdate.add(tempContact);
            }
        }

        if (!contactsNeedToUpdate.isEmpty()) {
            update contactsNeedToUpdate;
        }
    }
    //Updated the logic on 15 feb by Drashti
    public static void updateCommunityGroupMemberAndCommunityGroupMemberHistoryRenewal(Set<Id> subscriptionIdForCommunityGroupMember) {
        System.debug('>>>>>>>>>>111111111'+subscriptionIdForCommunityGroupMember);

        List<PagesApi__Community_Group_Member__c> communityGroupMembersNeedToUpdate = new List<PagesApi__Community_Group_Member__c>();
        
        Map<Id, Id> salesOrderIdToTermIds = new Map<Id, Id>();

        Set<Id> contactIds = new Set<Id>();

        Set<Id> groupId = new Set<Id>();

        //get terms and sub details from sub
        for (OrderApi__Subscription__c tempSubscription : [SELECT Id, OrderApi__Sales_Order_Line__c, OrderApi__Contact__c,
            OrderApi__Item__r.FS_Community_Group__c, 
            OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c FROM OrderApi__Subscription__c WHERE Id IN
            :subscriptionIdForCommunityGroupMember AND OrderApi__Item__r.OrderApi__Is_Subscription__c = true]){
            //populate map<salesorderid, most recent term id>
            salesOrderIdToTermIds.put(tempSubscription.OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c, tempSubscription.Id);
            //grab subscription's contact id
            contactIds.add(tempSubscription.OrderApi__Contact__c);
        }
        System.debug('>>>>>>>>>>22222222'+salesOrderIdToTermIds);

        //using the salesorder from the new term get all the section and division sales order lines that are not on a deparmental membership salesorder
        for (OrderApi__Sales_Order_Line__c tempSalesOrderLine : [SELECT Id, OrderApi__Sales_Order__c, OrderApi__Contact__c,
                OrderApi__Item__r.FS_Community_Group__c FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c IN
                :salesOrderIdToTermIds.keySet() AND (OrderApi__Item__r.OrderApi__Item_Class__r.Name =
                'Divisions' OR OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections') AND OrderApi__Sales_Order__r.FS_Departmental_Membership__c != TRUE]) {
                    
                groupId.add(tempSalesOrderLine.OrderApi__Item__r.FS_Community_Group__c);
        }

        //for each of the community group members belonging to the contacts grabbed in the above query
        for (PagesApi__Community_Group_Member__c tempCommunityGroupMember : [SELECT Id, PagesApi__Contact__c,
                PagesApi__Is_Active__c, PagesApi__Status__c, PagesApi__Community_Group__c FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c IN :contactIds 
                AND PagesApi__Community_Group__c=:groupId]) {
            
            tempCommunityGroupMember.PagesApi__Status__c = 'Deactivated';
            communityGroupMembersNeedToUpdate.add(tempCommunityGroupMember);
        }
        //do the CGM Upsert
        if (!communityGroupMembersNeedToUpdate.isEmpty()) {
            update communityGroupMembersNeedToUpdate;
        }
    }

    public static void updateTermsOnSalesOrderLine(Map<Id, Id> salesOrderIdToTermIds) {
        List<OrderApi__Sales_Order_Line__c> salesOrderLinesNeedToUpdate = new List<OrderApi__Sales_Order_Line__c>();

        for (OrderApi__Sales_Order_Line__c tempSalesOrderLine: [SELECT Id, OrderApi__Sales_Order__c FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c IN :salesOrderIdToTermIds.keySet()]) {
            tempSalesOrderLine.FS_Community_Group_Subscription_Term__c = salesOrderIdToTermIds.get(tempSalesOrderLine.OrderApi__Sales_Order__c);
            salesOrderLinesNeedToUpdate.add(tempSalesOrderLine);
        }

        if (!salesOrderLinesNeedToUpdate.isEmpty()) {
            update salesOrderLinesNeedToUpdate;
        }
    }
}