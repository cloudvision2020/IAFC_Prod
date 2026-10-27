public class RenewalRoutingRuleService {
    public static void afterInsert(List<OrderApi__Renewal__c> records) {
        processRecords(records, null);
    }
    public static void afterUpdate(List<OrderApi__Renewal__c> records, Map<Id, OrderApi__Renewal__c> oldMap) {
        updateBadges(records, oldMap);
    }
    public static void processRecords(List<OrderApi__Renewal__c> records, Map<Id, OrderApi__Renewal__c> oldMap) {
        Set<Id> subIds = new Set<Id>();
        for (OrderApi__Renewal__c tempSubscription : records) {
            subIds.add(tempSubscription.OrderApi__Subscription__c);   
        } 
        createCommunityGroupMemberAndCommunityGroupMemberHistory(subIds); 
    }
    public static void createCommunityGroupMemberAndCommunityGroupMemberHistory(Set<Id> subscriptionIdForCommunityGroupMember) {
        System.debug('>>>>>>>>>>111111111'+subscriptionIdForCommunityGroupMember);

        List<PagesApi__Community_Group_Member__c> communityGroupMembersNeedToUpsert = new List<PagesApi__Community_Group_Member__c>();
        List<Community_Group_Member_History__c> communityGroupMemberHistoriesNeedToCreate = new List<Community_Group_Member_History__c>();

        Map<Id, Id> salesOrderIdToTermIds = new Map<Id, Id>();
        Map<Id, OrderApi__Renewal__c> salesOrderIdToTerm = new Map<Id, OrderApi__Renewal__c>();

        Map<Id, PagesApi__Community_Group_Member__c> salesOrderLineIdToCommunityGroupMember = new Map<Id, PagesApi__Community_Group_Member__c>();

        Set<Id> contactIds = new Set<Id>();

        Map<Id, Set<Id>> contactIdToCommunityGroupIdsExisting = new Map<Id, Set<Id>>();
        Map<Id, Map<Id, PagesApi__Community_Group_Member__c>> contactIdToCommunityGroupIdToCommunityGroupMemberExisting = new Map<Id, Map<Id, PagesApi__Community_Group_Member__c>>();

        //get terms and sub details from sub
        for (OrderApi__Subscription__c tempSubscription : [SELECT Id, OrderApi__Sales_Order_Line__c, OrderApi__Contact__c,
            OrderApi__Item__r.FS_Community_Group__c, (SELECT Id, OrderApi__Term_Start_Date__c, OrderApi__Term_End_Date__c,
            OrderApi__Grace_Period_End_Date__c, OrderApi__Sales_Order_Line__c, OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c FROM OrderApi__Renewals__r ORDER BY Id DESC),
            OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c FROM OrderApi__Subscription__c WHERE Id IN
            :subscriptionIdForCommunityGroupMember AND OrderApi__Item__r.OrderApi__Is_Subscription__c = true]) {
            
            System.debug('>>>>>>>>>>OrderApi__Renewals__r'+tempSubscription.OrderApi__Renewals__r);

            //populate map<salesorderid, most recent term id>
            salesOrderIdToTermIds.put(tempSubscription.OrderApi__Renewals__r[0].OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c, tempSubscription.OrderApi__Renewals__r[0].Id);
            //populate map<salesorderid, most recent term object>
            salesOrderIdToTerm.put(tempSubscription.OrderApi__Renewals__r[0].OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c, tempSubscription.OrderApi__Renewals__r[0]);
            //grab subscription's contact id
            contactIds.add(tempSubscription.OrderApi__Contact__c);
        }
        System.debug('>>>>>>>>>>22222222'+salesOrderIdToTermIds);
        System.debug('>>>>>>>>>>33333333'+salesOrderIdToTerm);

        //for each of the community group members belonging to the contacts grabbed in the above query
        for (PagesApi__Community_Group_Member__c tempCommunityGroupMember : [SELECT Id, PagesApi__Contact__c,
                PagesApi__Is_Active__c, PagesApi__Status__c, PagesApi__Community_Group__c FROM PagesApi__Community_Group_Member__c WHERE PagesApi__Contact__c IN :contactIds]) {
            
            //populate contactIdToCommunityGroupIdsExisting as map<contactid, Set<CG id>>
            if (!contactIdToCommunityGroupIdsExisting.containsKey(tempCommunityGroupMember.PagesApi__Contact__c)) {
                contactIdToCommunityGroupIdsExisting.put(tempCommunityGroupMember.PagesApi__Contact__c, new Set<Id>{tempCommunityGroupMember.PagesApi__Community_Group__c});
            } else {
                contactIdToCommunityGroupIdsExisting.get(tempCommunityGroupMember.PagesApi__Contact__c).add(tempCommunityGroupMember.PagesApi__Community_Group__c);
            }
            //populate contactIdToCommunityGroupIdToCommunityGroupMemberExisting as map <contactid, map<CG id, CGM object>
            if (!contactIdToCommunityGroupIdToCommunityGroupMemberExisting.containsKey(tempCommunityGroupMember.PagesApi__Contact__c)) {
                contactIdToCommunityGroupIdToCommunityGroupMemberExisting.put(tempCommunityGroupMember.PagesApi__Contact__c, new Map<Id, PagesApi__Community_Group_Member__c>{tempCommunityGroupMember.PagesApi__Community_Group__c=>tempCommunityGroupMember});
            } else {
                contactIdToCommunityGroupIdToCommunityGroupMemberExisting.get(tempCommunityGroupMember.PagesApi__Contact__c).put(tempCommunityGroupMember.PagesApi__Community_Group__c, tempCommunityGroupMember);
            }
        }
        System.debug('>>>>>>>>>>4444444'+contactIdToCommunityGroupIdsExisting);
        System.debug('>>>>>>>>>>5555555'+contactIdToCommunityGroupIdToCommunityGroupMemberExisting);

        //using the salesorder from the new term get all the section and division sales order lines that are not on a deparmental membership salesorder
        for (OrderApi__Sales_Order_Line__c tempSalesOrderLine : [SELECT Id, OrderApi__Sales_Order__c, OrderApi__Contact__c,
                OrderApi__Item__r.FS_Community_Group__c FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c IN
                :salesOrderIdToTermIds.keySet() AND (OrderApi__Item__r.OrderApi__Item_Class__r.Name =
                'Divisions' OR OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections') AND OrderApi__Sales_Order__r.FS_Departmental_Membership__c != TRUE]) {
            
            //if contactIdToCommunityGroupIdsExisting doesn't have the contact or the contact did not have an existing CGM for that community then create the CGM for that contact for that community
            if (!contactIdToCommunityGroupIdsExisting.containsKey(tempSalesOrderLine.OrderApi__Contact__c) || !contactIdToCommunityGroupIdsExisting.get(tempSalesOrderLine.OrderApi__Contact__c).contains(tempSalesOrderLine.OrderApi__Item__r.FS_Community_Group__c)) {
                PagesApi__Community_Group_Member__c tempCommunityGroupMember = new PagesApi__Community_Group_Member__c(
                        PagesApi__Contact__c = tempSalesOrderLine.OrderApi__Contact__c,
                        PagesApi__Community_Group__c = tempSalesOrderLine.OrderApi__Item__r.FS_Community_Group__c,
                        PagesApi__Role__c = 'Member',
                        PagesApi__Activated_Date__c = salesOrderIdToTerm.get(tempSalesOrderLine.OrderApi__Sales_Order__c).OrderApi__Term_Start_Date__c,
                        PagesApi__Join_Request_Date__c = salesOrderIdToTerm.get(tempSalesOrderLine.OrderApi__Sales_Order__c).OrderApi__Term_Start_Date__c,
                        FS_Grace_Period_End_Date__c = salesOrderIdToTerm.get(tempSalesOrderLine.OrderApi__Sales_Order__c).OrderApi__Grace_Period_End_Date__c,
                        PagesApi__Is_Active__c = true,
                        PagesApi__Status__c = 'Active',
                        Term__c = salesOrderIdToTermIds.get(tempSalesOrderLine.OrderApi__Sales_Order__c)
                );
                communityGroupMembersNeedToUpsert.add(tempCommunityGroupMember);
                
                //capture the CGM to match with the sales order line
                salesOrderLineIdToCommunityGroupMember.put(tempSalesOrderLine.Id, tempCommunityGroupMember);

            } else {//If the CGM already exists
                PagesApi__Community_Group_Member__c tempCommunityGroupMember = contactIdToCommunityGroupIdToCommunityGroupMemberExisting.get(tempSalesOrderLine.OrderApi__Contact__c).get(tempSalesOrderLine.OrderApi__Item__r.FS_Community_Group__c);
                //If it is not active
                if (!tempCommunityGroupMember.PagesApi__Is_Active__c && tempCommunityGroupMember.PagesApi__Status__c != 'Active') {
                    //Update it to active
                    communityGroupMembersNeedToUpsert.add(new PagesApi__Community_Group_Member__c(
                            Id = tempCommunityGroupMember.Id,
                            PagesApi__Is_Active__c = true,
                            PagesApi__Status__c = 'Active',
                            PagesApi__Activated_Date__c = salesOrderIdToTerm.get(tempSalesOrderLine.OrderApi__Sales_Order__c).OrderApi__Term_Start_Date__c,
                            FS_Grace_Period_End_Date__c = salesOrderIdToTerm.get(tempSalesOrderLine.OrderApi__Sales_Order__c).OrderApi__Grace_Period_End_Date__c,
                            Term__c = salesOrderIdToTermIds.get(tempSalesOrderLine.OrderApi__Sales_Order__c)

                        ));
                } else {
                    //otherwise update its  FS_Grace_Period_End_Date__c
                    communityGroupMembersNeedToUpsert.add(new PagesApi__Community_Group_Member__c(
                        Id = tempCommunityGroupMember.Id,
                        FS_Grace_Period_End_Date__c = salesOrderIdToTerm.get(tempSalesOrderLine.OrderApi__Sales_Order__c).OrderApi__Grace_Period_End_Date__c,
                        Term__c = salesOrderIdToTermIds.get(tempSalesOrderLine.OrderApi__Sales_Order__c)
                    ));
                }
            }
            System.debug('>>>>>>>>>>66666666'+communityGroupMembersNeedToUpsert);
            System.debug('>>>>>>>>>>77777777'+communityGroupMemberHistoriesNeedToCreate);
        }

        //do the CGM Upsert
        if (!communityGroupMembersNeedToUpsert.isEmpty()) {
            upsert communityGroupMembersNeedToUpsert;
        }
        //update the sales order lines with their CGM term ids  
        if (!salesOrderIdToTermIds.isEmpty()) {
            updateTermsOnSalesOrderLine(salesOrderIdToTermIds);
        }
    }

    public static void updateBadges(List<OrderApi__Renewal__c> records, Map<Id, OrderApi__Renewal__c> oldMap) {
        Map<Id,OrderApi__Renewal__c> mapOfTerms = new Map<Id, OrderApi__Renewal__c>();
        Set<Id> conIds = new Set<Id>();
        Set<Id> lineIds = new Set<Id>();
        Set<Id> renewalIds = new Set<Id>();

        for(OrderApi__Renewal__c renewal : records){
            if(!renewal.OrderAPI__is_Active__c  
                && renewal.OrderAPI__is_Active__c != oldMap.get(renewal.Id).OrderAPI__is_Active__c){
                mapOfTerms.put(renewal.OrderApi__Sales_Order__c,renewal);
                conIds.add(renewal.OrderApi__Contact__c);
                renewalIds.add(renewal.id);
            }
        }
        List<PagesApi__Community_Group_Member__c> membersToDeactivate = [SELECT Id, PagesApi__Contact__c,
                PagesApi__Is_Active__c, PagesApi__Status__c, 
                PagesApi__Community_Group__c 
                FROM PagesApi__Community_Group_Member__c WHERE Term__c IN :renewalIds];
        
        for(PagesApi__Community_Group_Member__c member : membersToDeactivate ) {
            member.PagesApi__Is_Active__c = false;
            member.PagesApi__Status__c = 'Deactivated'; 
        }
        if(!membersToDeactivate.isEmpty()){
            update membersToDeactivate;
        }

        //using the salesorder from the new term get all the section and division sales order lines that are not on a deparmental membership salesorder
        for (OrderApi__Sales_Order_Line__c tempSalesOrderLine : [SELECT Id, OrderApi__Sales_Order__c, OrderApi__Contact__c,
         OrderApi__Item__r.FS_Community_Group__c FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c IN
         :mapOfTerms.keySet() AND OrderApi__Contact__c=:conIds AND (OrderApi__Item__r.OrderApi__Item_Class__r.Name =
         'Divisions' OR OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections') AND OrderApi__Sales_Order__r.FS_Departmental_Membership__c != TRUE]) {
            lineIds.add(tempSalesOrderLine.Id);
            
        } 
        List<OrderAPI__Badge__c> badges = [SELECT Id, OrderApi__Is_Active__c, OrderApi__Sales_Order_Line__c,
                                            OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c 
                                            From OrderAPI__Badge__c 
                                            Where orderAPI__Is_Active__c=true
                                            AND OrderApi__Sales_Order_Line__c=:lineIds
                                            AND OrderApi__Contact__c=:conIds]; 
        
                    //using the salesorder from the new term get all the section and division sales order lines that are not on a deparmental membership salesorder
        for (OrderAPI__Badge__c badge : badges) {
            badge.OrderApi__Is_Active__c = false; 
            badge.OrderApi__Expired_Date__c = date.today()-1;                                                       
            if(mapOfTerms.get(badge.OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c)!=null)
                badge.OrderApi__Expired_Date__c = mapOfTerms.get(badge.OrderApi__Sales_Order_Line__r.OrderApi__Sales_Order__c).OrderApi__Term_End_Date__c;                                                        
        }   
        if(!badges.isEmpty()){
            update badges;
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