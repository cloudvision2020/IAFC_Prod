global class FS_ProformaRenewalBatch implements Database.Batchable<SObject>, Schedulable {
    private OrderApi__Item_Class__c DIVISION_ITEM_CLASS;
    private List<OrderApi__Item__c> LST_DIVISION_ITEMS;
    private List<OrderApi__Item__c> LST_SECTION_ITEMS;
    private Set<Id> set2YrSalesOrders = new Set<Id>();
    private Set<Id> set3YrSalesOrders = new Set<Id>();

    global Database.Querylocator start(Database.BatchableContext bc) {

        String query = 'SELECT Id, OrderApi__Contact__c, OrderApi__Contact__r.Division_Opt_Out__c, OrderApi__Contact__r.Division__c, '+
                '       OrderApi__Contact__r.Functional_Title__c, FS_Processed_By_Proforma_Job__c, '+
                '       (SELECT Id, Name, OrderApi__Is_Subscription__c, OrderApi__Is_Renewal__c, OrderApi__Item__r.Name, '+
                '               OrderApi__Item__r.FS_Community_Group__r.Name '+
                '          FROM OrderApi__Sales_Order_Lines__r)'+
                ' FROM OrderApi__Sales_Order__c '+
                'WHERE FS_Processed_By_Proforma_Job__c!= true '+
                '  AND OrderApi__Status__c=\'Closed\' ' +
                '  AND OrderApi__Posting_Status__c=\'Pending\' '+
                '  AND OrderApi__Schedule_Type__c=\'Simple Receipt\' '+
                '  AND OrderApi__Posting_Entity__c=\'Receipt\' ';
        System.debug('##--Query: ' + query);
        return Database.getQueryLocator(query);
    }   //  end of start

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<OrderApi__Sales_Order__c> lstSalesOrders = scope;
        List<OrderApi__Sales_Order__c> lstUpdatedSalesOrders = new List<OrderApi__Sales_Order__c>();
        OrderApi__Item_Class__c sectionItemClass;
        Set<Id> setUpdatedSalesOrders = new Set<Id>();
        
        Set<Id> setOrdersWithDepMemItem = new Set<Id>();

        List<OrderApi__Sales_Order_Line__c> priceResetLines = new List<OrderApi__Sales_Order_Line__c>();

        List<OrderApi__Item_Class__c> lstItemClasses = [SELECT Id, Name FROM OrderApi__Item_Class__c WHERE Name='Divisions'];
        if(lstItemClasses != null && ! lstItemClasses.isEmpty()){
            DIVISION_ITEM_CLASS = lstItemClasses[0];
        }
        LST_DIVISION_ITEMS = [SELECT Id, Name, FS_Community_Group__r.Name FROM OrderApi__Item__c WHERE OrderApi__Is_Active__c=true AND OrderApi__Item_Class__c=:DIVISION_ITEM_CLASS.Id];

        lstItemClasses = [SELECT Id, Name FROM OrderApi__Item_Class__c WHERE Name='Sections'];
        if(lstItemClasses != null && ! lstItemClasses.isEmpty()){
            sectionItemClass = lstItemClasses[0];
        }
        LST_SECTION_ITEMS = [SELECT Id, Name, FS_Community_Group__r.Name FROM OrderApi__Item__c WHERE OrderApi__Is_Active__c=true AND OrderApi__Item_Class__c=:sectionItemClass.Id];

        //  Step - 1 - Update subscription lines that need items changed due to functional titles changing and such
        List<OrderApi__Sales_Order_Line__c> lstUpdatedLineItems = orderLinesToBeUpdated(lstSalesOrders, setUpdatedSalesOrders);
        if(! lstUpdatedLineItems.isEmpty()){
            System.debug('##--Sales Line items to be updated: ' + lstUpdatedLineItems.size() + ' -- ' + lstUpdatedLineItems);
            update lstUpdatedLineItems;
        }


        //  Step - 2
        List<OrderApi__Sales_Order_Line__c> lstSalesLineItems = createSalesOrderLinesForDivision(lstSalesOrders, setUpdatedSalesOrders);
        if(! lstSalesLineItems.isEmpty()){
            System.debug('##--Creating Sales Line items for Division: ' + lstSalesLineItems.size() + ' -- ' + lstSalesLineItems);
            insert lstSalesLineItems;
        }

        //  Step - 3
        List<OrderApi__Sales_Order_Line__c> lstSectionSalesLineItems = createSalesOrderLinesForSection(lstSalesOrders, setUpdatedSalesOrders);
        if(! lstSectionSalesLineItems.isEmpty()){
            System.debug('##--Creating Section Sales Items: ' + lstSectionSalesLineItems.size() + ' -- ' + lstSectionSalesLineItems);
            insert lstSectionSalesLineItems; 
        }

        // Step - 4 - Fix multi Year pricing - Trav - TODO: Extract method and add Test
        if((!lstSectionSalesLineItems.isEmpty() || !lstSalesLineItems.isEmpty()) && (!set2YrSalesOrders.isEmpty() || !set3YrSalesOrders.isEmpty())
          ){
            priceResetLines = [SELECT Id, OrderApi__Sale_Price__c, OrderApi__Price_Override__c, OrderApi__Sales_Order__c 
                FROM OrderApi__Sales_Order_Line__c 
                WHERE (OrderApi__Sales_Order__c in :set2YrSalesOrders or OrderApi__Sales_Order__c in :set3YrSalesOrders)
                and (OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Sections' OR OrderApi__Item__r.OrderApi__Item_Class__r.Name = 'Divisions')
                and OrderApi__Price_Override__c = false];

            for(OrderApi__Sales_Order_Line__c line: priceResetLines){
                if(set2YrSalesOrders.contains(line.OrderApi__Sales_Order__c)){
                    line.OrderApi__Price_Override__c = true;
                    line.OrderApi__Sale_Price__c = line.OrderApi__Sale_Price__c * 2; 
                }else if(set3YrSalesOrders.contains(line.OrderApi__Sales_Order__c)){
                    line.OrderApi__Price_Override__c = true;
                    line.OrderApi__Sale_Price__c = line.OrderApi__Sale_Price__c * 3; 
                }
            }
            update priceResetLines;
        }
 
        // TODO: update the sales order processed flag
        System.debug('##--Total Sales Order: ' + lstSalesOrders.size());
        System.debug('##--Sales Orders to be updated: ' + setUpdatedSalesOrders.size() + ' -- ' + setUpdatedSalesOrders);
        for(OrderApi__Sales_Order__c objSaleOrder : lstSalesOrders){
            if(setUpdatedSalesOrders.contains(objSaleOrder.Id)){
                objSaleOrder.FS_Processed_By_Proforma_Job__c=true;
                lstUpdatedSalesOrders.add(objSaleOrder);
                continue;
            }
        }   //  end of for-each sales order
        if(! lstUpdatedSalesOrders.isEmpty()){
            System.debug('##--Updating Sales Orders: ' + lstUpdatedSalesOrders.size() + ' -- ' + lstUpdatedSalesOrders);
            update lstUpdatedSalesOrders; 
        }


        lstUpdatedSalesOrders = getSalesOrdersWithDepMemItems(lstSalesOrders);
        if(! lstUpdatedSalesOrders.isEmpty()){
            System.debug('##--Updating Sales Orders Departmental Membership: ' + lstUpdatedSalesOrders.size() + ' -- ' + lstUpdatedSalesOrders);
            update lstUpdatedSalesOrders;
        }

        //Trav - Generate Orders for non subscription Senior Metro Chiefs 90 days out
        //TODO: Extract to method and create tests
        List<OrderApi__Sales_Order__c> srChiefOrdersCreated = new List<OrderApi__Sales_Order__c>();
        Map<Id,Date> SrChiefActivationDates = new Map<Id,Date>();
        Map<ID,PagesApi__Community_Group_Member__c> NonSubscriptionSrMetroSectionMembers = 
                        new Map<ID,PagesApi__Community_Group_Member__c>(
                            [select PagesApi__Contact__c, Current_Term_End_Date__c, FS_Grace_Period_End_Date__c, PagesApi__Contact__r.Membership_Type__c
                            from PagesApi__Community_Group_Member__c where 
                            (PagesApi__Contact__r.Senior_Metro_Approved__c = true or PagesApi__Contact__r.International_Metro_Approved__c = true)
                            and PagesApi__Contact__c not in (select OrderApi__Contact__c from OrderApi__Subscription__c where OrderApi__Status__c = 'Active' and OrderApi__Entity__c = 'Contact')
                            and PagesApi__Community_Group__r.Name = 'Metro Chiefs'
                            and PagesApi__Is_Active__c = true
                            and PagesApi__Role__c = 'Member'
                            and Current_Term_End_Date__c = NEXT_N_DAYS:90 
                            and Current_Term_End_Date__c > NEXT_N_DAYS:89]
                        ); 
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
                metroLine.OrderApi__Activation_Date__c = SrChiefActivationDates.get(srChiefOrder.OrderApi__Contact__c).addDays(1);
                metroLine.OrderApi__End_Date__c = SrChiefActivationDates.get(srChiefOrder.OrderApi__Contact__c).addYears(1);
                srChiefOrderLinesCreated.add(metroLine);
            }
            insert srChiefOrderLinesCreated;
            update srChiefOrdersCreated;
        }

    }   //  end of execute

    global void finish(Database.BatchableContext bc) {

    }   //  end of finish

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new FS_ProformaRenewalBatch());
    }


    private List<OrderApi__Sales_Order_Line__c> orderLinesToBeUpdated(List<OrderApi__Sales_Order__c> lstSalesOrders, Set<Id> setUpdatedSalesOrders){
        List<OrderApi__Sales_Order_Line__c> lstSalesLineItems = new List<OrderApi__Sales_Order_Line__c>();
        Set<Id> setSalesOrderIds = new Set<Id>();
        List<OrderApi__Item__c> lstItems = [SELECT Id, Name, FS_Item_Functional_Titles__c FROM OrderApi__Item__c WHERE OrderApi__Is_Active__c=true AND FS_Item_Functional_Titles__c!=null];

        for(OrderApi__Sales_Order__c objSaleOrder : lstSalesOrders){
            if(String.isNotBlank(objSaleOrder.OrderApi__Contact__r.Functional_Title__c)){
                setSalesOrderIds.add(objSaleOrder.Id);
            }   //  end of if
        }   //  end of for-each salesorder

        System.debug('##--setSalesOrderIds: ' + setSalesOrderIds);
        for(OrderApi__Sales_Order_Line__c objOrderLine : [SELECT Id, Name, OrderApi__Contact__c, OrderApi__Is_Subscription__c,
                OrderApi__Is_Renewal__c,
                OrderApi__Contact__r.Functional_Title__c,
                OrderApi__Item__c, OrderApi__Sales_Order__c,
                OrderApi__Item__r.FS_Item_Functional_Titles__c, 
                OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c
        FROM OrderApi__Sales_Order_Line__c
        WHERE OrderApi__Sales_Order__c IN :setSalesOrderIds]){
            if(objOrderLine.OrderApi__Is_Subscription__c == true &&
                    objOrderLine.OrderApi__Is_Renewal__c == true &&
                    isItemUpdateNeeded(objOrderLine, lstItems)){
                lstSalesLineItems.add(updateItemOnSalesLine(objOrderLine, lstItems));
                setUpdatedSalesOrders.add(objOrderLine.OrderApi__Sales_Order__c);
            }
            //capture 2yr orderids - trav
            if(objOrderLine.OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c == 24 && !set2YrSalesOrders.contains(objOrderLine.OrderApi__Sales_Order__c)){
                set2YrSalesOrders.add(objOrderLine.OrderApi__Sales_Order__c);
            }
            //capture 3yr orderids - trav
            if(objOrderLine.OrderApi__Subscription_Plan__r.OrderApi__Initial_Term_Months__c == 36 && !set3YrSalesOrders.contains(objOrderLine.OrderApi__Sales_Order__c)){
                set3YrSalesOrders.add(objOrderLine.OrderApi__Sales_Order__c);
            }

        }   //  end of for-each order-line

        return lstSalesLineItems;
    }   //  end of orderLinesToBeUpdated

    private List<OrderApi__Sales_Order_Line__c> createSalesOrderLinesForDivision(List<OrderApi__Sales_Order__c> lstSalesOrders, Set<Id> setUpdatedSalesOrders){
        List<OrderApi__Sales_Order_Line__c> lstSalesLineItems = new List<OrderApi__Sales_Order_Line__c>();
        // Set<

        for (OrderApi__Sales_Order__c objSaleOrder : lstSalesOrders) {
            if (! objSaleOrder.OrderApi__Contact__r.Division_Opt_Out__c) {
                OrderApi__Sales_Order_Line__c objOrderLine = createNewLineItemForDivision(objSaleOrder);
                if(objOrderLine != null){
                    lstSalesLineItems.add(objOrderLine);
                    setUpdatedSalesOrders.add(objSaleOrder.Id);
                }

            }
        }   //  end of for-each Sales Order


        return lstSalesLineItems;
    }   //  end of createSalesOrderLinesForDivision

    private List<OrderApi__Sales_Order_Line__c> createSalesOrderLinesForSection(List<OrderApi__Sales_Order__c> lstSalesOrders, Set<Id> setUpdatedSalesOrders){
        List<OrderApi__Sales_Order_Line__c> lstSalesLineItems = new List<OrderApi__Sales_Order_Line__c>();
        Map<String, Set<String>> mapContactSectionCommGrps = new Map<String, Set<String>>();
        Set<Id> setContactIds = new Set<Id>();

        for(OrderApi__Sales_Order__c objSaleOrder : lstSalesOrders){
            if(String.isNotBlank(objSaleOrder.OrderApi__Contact__c)){
                setContactIds.add(objSaleOrder.OrderApi__Contact__c);
            }
        }   //  end of for-each Sales Order

        //  construct a map of COntact and list of section community member name
        for(PagesApi__Community_Group_Member__c objCommMember : [SELECT Id, Name, PagesApi__Contact__c,
                PagesApi__Contact__r.Name, PagesApi__Community_Group__r.Name
        FROM PagesApi__Community_Group_Member__c
        WHERE PagesApi__Contact__c IN :setContactIds
        AND PagesApi__Status__c='Active'
        AND PagesApi__Community_Group__r.PagesApi__Type__c='Section']){
            if(mapContactSectionCommGrps.get(objCommMember.PagesApi__Contact__c) == null){
                mapContactSectionCommGrps.put(objCommMember.PagesApi__Contact__c, new Set<String>());
            }
            mapContactSectionCommGrps.get(objCommMember.PagesApi__Contact__c).add(objCommMember.PagesApi__Community_Group__r.Name);
        }   //  end of for-each Community Member

        for(OrderApi__Sales_Order__c objSaleOrder : lstSalesOrders){
            List<OrderApi__Sales_Order_Line__c> lstLines = createNewLineItemsForSections(objSaleOrder, mapContactSectionCommGrps.get(objSaleOrder.OrderApi__Contact__c));
            if(! lstLines.isEmpty()){
                lstSalesLineItems.addAll(lstLines);
                setUpdatedSalesOrders.add(objSaleOrder.Id);
            }
        }   //  end of for-each Sales Order

        return lstSalesLineItems;
    }   //  end of createSalesOrderLinesForSection

    private OrderApi__Sales_Order_Line__c createNewLineItemForDivision(OrderApi__Sales_Order__c objSaleOrder){
        for(OrderApi__Item__c objItem : LST_DIVISION_ITEMS){
            if(String.isNotBlank(objSaleOrder.OrderApi__Contact__r.Division__c) &&
                    objItem.FS_Community_Group__r.Name.equalsIgnoreCase(objSaleOrder.OrderApi__Contact__r.Division__c)){
                OrderApi__Sales_Order_Line__c objOrderLine = new OrderApi__Sales_Order_Line__c();
                objOrderLine.OrderApi__Sales_Order__c=objSaleOrder.Id;
                objOrderLine.OrderApi__Item__c=objItem.Id;
                return objOrderLine;
            }
        }
        return null;
    }   //  end of createNewLineItemForDivision

    private List<OrderApi__Sales_Order_Line__c> createNewLineItemsForSections(OrderApi__Sales_Order__c objSaleOrder, Set<String> setSectionItemNames){
        List<OrderApi__Sales_Order_Line__c> lstLines = new List<OrderApi__Sales_Order_Line__c>();
        //System.debug('##--objSaleOrder: ' + objSaleOrder);
        //System.debug('##--setSectionItemNames: ' + setSectionItemNames);
        for(OrderApi__Item__c objItem : LST_SECTION_ITEMS){
            if(setSectionItemNames != null && (canCreateLineItemForSection(objItem, objSaleOrder, setSectionItemNames))){
                OrderApi__Sales_Order_Line__c objOrderLine = new OrderApi__Sales_Order_Line__c();
                objOrderLine.OrderApi__Sales_Order__c=objSaleOrder.Id;
                objOrderLine.OrderApi__Item__c=objItem.Id;
                lstLines.add(objOrderLine);
            }
        }   //  end of for-each Section Item

        return lstLines;
    }   //  end of createNewLineItemsForSections

    private Boolean isItemUpdateNeeded(OrderApi__Sales_Order_Line__c objOrderLine, List<OrderApi__Item__c> lstItems){
        //System.debug('##--OrderLine: ' + objOrderLine.OrderApi__Contact__r.Functional_Title__c + '\n' + objOrderLine.OrderApi__Item__r.FS_Item_Functional_Titles__c);
        if(String.isNotBlank(objOrderLine.OrderApi__Contact__r.Functional_Title__c) &&
                String.isNotBlank(objOrderLine.OrderApi__Item__r.FS_Item_Functional_Titles__c) &&
                ! objOrderLine.OrderApi__Item__r.FS_Item_Functional_Titles__c.contains(objOrderLine.OrderApi__Contact__r.Functional_Title__c)){
            //System.debug('##--Item.Functional_Title__c: ' +objOrderLine.OrderApi__Item__r.FS_Item_Functional_Titles__c+' -- Contact.Functional: ' + objOrderLine.OrderApi__Contact__r.Functional_Title__c);
            return true;
        }
        return false;
    }   //  end of isItemUpdateNeeded

    private OrderApi__Sales_Order_Line__c updateItemOnSalesLine(OrderApi__Sales_Order_Line__c objOrderLine, List<OrderApi__Item__c> lstItems){
        for(OrderApi__Item__c objItem : lstItems){
            if(objItem.FS_Item_Functional_Titles__c.contains(objOrderLine.OrderApi__Contact__r.Functional_Title__c)){
                objOrderLine.OrderApi__Item__c = objItem.Id;
                break;
            }
        }   //  end of for-each Item
        return objOrderLine;
    }   //  end of updateItemOnSalesLine

    private Boolean canCreateLineItemForSection(OrderApi__Item__c objItem, OrderApi__Sales_Order__c objSaleOrder, Set<String> setSectionItemNames){
        if(! setSectionItemNames.contains(objItem.FS_Community_Group__r.Name)){
            return false;
        }

        for(OrderApi__Sales_Order_Line__c objOrderLine : objSaleOrder.OrderApi__Sales_Order_Lines__r){
            if(setSectionItemNames.contains(objOrderLine.OrderApi__Item__r.FS_Community_Group__r.Name)){
                return false;
            }
        }   //  end of 
        return true;
    }   //  end of canCreateLineItemForSection

    private List<OrderApi__Sales_Order__c> getSalesOrdersWithDepMemItems(List<OrderApi__Sales_Order__c> lstSalesOrders){
        List<OrderApi__Sales_Order__c> lstUpdatedSalesOrders = new List<OrderApi__Sales_Order__c>();

        for(OrderApi__Sales_Order__c objSaleOrder : [SELECT Id, OrderApi__Contact__c, OrderApi__Contact__r.Division_Opt_Out__c, OrderApi__Contact__r.Division__c, 
                                                           OrderApi__Contact__r.Functional_Title__c, FS_Processed_By_Proforma_Job__c, 
                                                           (SELECT Id, Name, OrderApi__Is_Subscription__c, OrderApi__Is_Renewal__c, OrderApi__Item__r.Name, 
                                                                   OrderApi__Item__r.FS_Community_Group__r.Name 
                                                              FROM OrderApi__Sales_Order_Lines__r)
                                                     FROM OrderApi__Sales_Order__c 
                                                     WHERE Id IN :lstSalesOrders]){
            if(hasDepMemItems(objSaleOrder)){
                lstUpdatedSalesOrders.add(new OrderApi__Sales_Order__c(Id=objSaleOrder.Id,
                                                                        FS_Departmental_Membership__c=true));
            }
        }   //  end of for-eac Sales Order

        return lstUpdatedSalesOrders;
    }   //  end of getSalesOrdersWithDepMemItems

    private Boolean hasDepMemItems(OrderApi__Sales_Order__c objSaleOrder){
        
        for(OrderApi__Sales_Order_Line__c objOrderLine : objSaleOrder.OrderApi__Sales_Order_Lines__r){
            if('Departmental Membership'.equalsIgnoreCase(objOrderLine.OrderApi__Item__r.Name)){
                return true;
            }
        }   //  end of for-each Sales Order Line
        return false;
    }   //  end of hasDepMemItems

}   //  end of FS_ProformaRenewalBatch