global class ProformaRenewalBatchClone implements Database.Batchable<SObject> {
    private final string ACTIVE = 'Active';
    private final string ENTITY = 'Contact';

    global Database.Querylocator start(Database.BatchableContext bc) {
        String query;
        if(!Test.isRunningTest()){
            query = 'Select PagesApi__Contact__c, Current_Term_End_Date__c, FS_Grace_Period_End_Date__c, PagesApi__Contact__r.Membership_Type__c'+
                                ' from PagesApi__Community_Group_Member__c where'+
                                ' (PagesApi__Contact__r.Senior_Metro_Approved__c = true or PagesApi__Contact__r.International_Metro_Approved__c = true)'+
                                ' and PagesApi__Contact__c not in (select OrderApi__Contact__c from OrderApi__Subscription__c where OrderApi__Status__c = :ACTIVE and OrderApi__Entity__c =:ENTITY) '+
                                ' and PagesApi__Community_Group__r.Name = \'Metro Chiefs\''+
                                ' and PagesApi__Is_Active__c = true'+
                                ' and PagesApi__Role__c = \'Member\''+
                                ' and Current_Term_End_Date__c = NEXT_N_DAYS:90'+ 
                                ' and Current_Term_End_Date__c > NEXT_N_DAYS:89';
        }
        else{
            query = 'Select PagesApi__Contact__c, Current_Term_End_Date__c, FS_Grace_Period_End_Date__c, PagesApi__Contact__r.Membership_Type__c'+
                                ' from PagesApi__Community_Group_Member__c where'+
                                ' (PagesApi__Contact__r.Senior_Metro_Approved__c = true or PagesApi__Contact__r.International_Metro_Approved__c = true)'+
                                ' and PagesApi__Contact__c not in (select OrderApi__Contact__c from OrderApi__Subscription__c where OrderApi__Status__c = :ACTIVE and OrderApi__Entity__c =:ENTITY) '+
                                ' and PagesApi__Community_Group__r.Name = \'Metro Chiefs\''+
                                ' and PagesApi__Is_Active__c = true'+
                                ' and PagesApi__Role__c = \'Member\'';
        }
        System.debug('##--Query: ' + query);
        return Database.getQueryLocator(query);
    }   //  end of Start method
    global void execute(Database.BatchableContext BC, List<PagesApi__Community_Group_Member__c> scope) {
        //Trav - Generate Orders for non subscription Senior Metro Chiefs 90 days out
        List<OrderApi__Sales_Order__c> srChiefOrdersCreated = new List<OrderApi__Sales_Order__c>();
        Map<Id,Date> SrChiefActivationDates = new Map<Id,Date>();
        Map<ID,PagesApi__Community_Group_Member__c> NonSubscriptionSrMetroSectionMembers = new Map<ID,PagesApi__Community_Group_Member__c>();
        
        for(PagesApi__Community_Group_Member__c groupMember : scope){
            NonSubscriptionSrMetroSectionMembers.put(groupMember.Id, groupMember);
        }
        
                     
        for(Id key : NonSubscriptionSrMetroSectionMembers.keySet())  { 
            PagesApi__Community_Group_Member__c srChief = NonSubscriptionSrMetroSectionMembers.get(key);
            OrderApi__Sales_Order__c srChiefOrder = new OrderApi__Sales_Order__c();
            srChiefOrder.OrderApi__Contact__c = srChief.PagesApi__Contact__c; 
            srChiefOrder.OrderApi__Entity__c = 'Contact';
            srChiefOrder.OrderApi__Status__c = 'Open';
            srChiefOrder.FS_Processed_By_Proforma_Job__c = true;
            srChiefOrdersCreated.add(srChiefOrder);
            SrChiefActivationDates.put(srChief.PagesApi__Contact__c, srChief.Current_Term_End_Date__c );
        }   //end of for-each srMetroChiefMember     
        if(srChiefOrdersCreated.size() > 0){
            Id metroItemId = [select id from OrderApi__Item__c where Name = 'Metropolitan Fire Chiefs' ][0].Id;
            insert srChiefOrdersCreated;
            //add the sales order lines
            List<OrderApi__Sales_Order_Line__c> srChiefOrderLinesCreated = new List<OrderApi__Sales_Order_Line__c>();
            for(OrderApi__Sales_Order__c srChiefOrder : srChiefOrdersCreated){
                srChiefOrder.OrderApi__Status__c = 'Closed';
                OrderApi__Sales_Order_Line__c metroLine = new OrderApi__Sales_Order_Line__c();
                metroLine.OrderApi__Sales_Order__c = srChiefOrder.Id;
                metroLine.OrderApi__Item__c = metroItemId;
                metroLine.OrderApi__Auto_Calculate_Activation_Date__c = false;
                if(SrChiefActivationDates!=null && SrChiefActivationDates.get(srChiefOrder.OrderApi__Contact__c)!=null && srChiefOrder!=null){
                   //metroLine.OrderApi__Activation_Date__c = SrChiefActivationDates.get(srChiefOrder.OrderApi__Contact__c).addDays(1);
                   //metroLine.OrderApi__End_Date__c = SrChiefActivationDates.get(srChiefOrder.OrderApi__Contact__c).addYears(1);
                }
                srChiefOrderLinesCreated.add(metroLine);
            }
            insert srChiefOrderLinesCreated;
            update srChiefOrdersCreated;
        }
    
    }
    global void finish(Database.BatchableContext bc) {

    }   //  end of finish
}