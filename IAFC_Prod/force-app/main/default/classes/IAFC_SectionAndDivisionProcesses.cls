public with sharing class IAFC_SectionAndDivisionProcesses {
    public IAFC_SectionAndDivisionProcesses() { }

    @InvocableMethod(label='Upsert CGM by Badge' description='Upsert a CGM by passing a badge')
    public static void  UpsertCGMByBadge(List<OrderApi__Badge__c> badge){
        list<OrderApi__Item__c> coms = [Select FS_Community_Group__c From OrderApi__Item__c where ID = :badge[0].OrderApi__Item__c];
        string community;
        if(coms.size() > 0 && badge[0].ORDERAPI__AWARDED_DATE__C != null &&  badge[0].ORDERAPI__EXPIRED_DATE__C  != null && badge[0].ORDERAPI__SALES_ORDER_LINE__C != null ){
            community = coms[0].FS_Community_Group__c;
            UpsertCGM(badge[0].ORDERAPI__CONTACT__C,community, badge[0].ORDERAPI__AWARDED_DATE__C, badge[0].ORDERAPI__EXPIRED_DATE__C, badge[0].ORDERAPI__SALES_ORDER_LINE__C);
        }
        System.debug(community);
    }

    public static PagesApi__Community_Group_Member__c  UpsertCGM(string contactid, string communityid, date termstart, date termend, string salesorderline){
        
        termend =  termend.addMonths(1).toStartofMonth().addDays(-1);
        date grace = termend.addDays(90).addMonths(1).toStartofMonth().addDays(-1);

        //get the contacts most recent Active CGM matching the community
        PagesApi__Community_Group_Member__c cgm;
        List<PagesApi__Community_Group_Member__c> cgmList = 
            [Select Id 
            FROM PagesApi__Community_Group_Member__c 
            WHERE PagesApi__Contact__c = :contactid //'0031N0000227dm8QAA' 
                //and PagesApi__Is_Active__c = true 
                and PagesApi__Community_Group__c = :communityid //'a0M1N00000E6YiIUAV'
                order by createdDate DESC limit 1]; 
        
        try { 
            //if none create the CGM
            if(cgmList.size() == 0){
                cgm = new PagesApi__Community_Group_Member__c(
                    PagesApi__Activated_Date__c = termstart,
                    PagesApi__Contact__c = contactid,
                    PagesApi__Community_Group__c = communityid,
                    PagesApi__Join_Request_Date__c = termstart,
                    PagesApi__Role__c = 'Member',
                    Term_Start_Date__c	= termstart,
                    Term_End_Date__c = termend,
                    FS_Grace_Period_End_Date__c = grace
                );
                insert cgm;
            }else{
                cgm = cgmList[0];
            }
            //update the CGM History if needed
            UpsertCGMHistory (cgm.Id, termstart, termend, salesorderline);
        } catch(DmlException e) {
            System.debug('UpsertCGM error has occurred: ' + e.getMessage());
            return cgm;
        }
        return cgm;
    }

    public static Community_Group_Member_History__c UpsertCGMHistory(string cgmId, date termstart, date termend, string salesorderline){

        termend = termend.addMonths(1).toStartofMonth().addDays(-1);
        date grace = termend.addDays(90).addMonths(1).toStartofMonth().addDays(-1);
        //If there is one check to see if it has a history matching the dates incoming
        Community_Group_Member_History__c h;
        List<Community_Group_Member_History__c> hList = 
                [Select Id, Term_End__c, Term_Start__c
                FROM Community_Group_Member_History__c 
                WHERE Community_Group_Member__c = :cgmId and FS_Grace_Period_End__c = :grace and Term_Start__c =: termstart
                ];
        try {  

            //if not, create the history
            if(hList.size() == 0){
                h = new Community_Group_Member_History__c( 
                    Community_Group_Member__c = cgmId,  
                    Term_End__c = termend,
                    Term_Start__c = termstart,
                    FS_Grace_Period_End__c = grace,
                    FS_Sales_Order_Line__c = salesorderline
                );
                insert h;
            }else{
                h = hList[0];
            }
            
        } catch(DmlException e) {
            System.debug('UpsertCGMHistory error has occurred: ' + e.getMessage());
            return h;
        }
        return h;
    }
}