global class ProformaRenewalBatch implements Database.Batchable<SObject>, Schedulable {
        //private OrderApi__Item_Class__c DIVISION_ITEM_CLASS;
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
        
        List<OrderApi__Sales_Order_Line__c> priceResetLines = new List<OrderApi__Sales_Order_Line__c>();
        List<OrderApi__Sales_Order__c> lstUpdatedSalesOrders = new List<OrderApi__Sales_Order__c>();

        List<OrderApi__Sales_Order_Line__c> lstSalesLineItemsAll = new List<OrderApi__Sales_Order_Line__c>();
        List<OrderApi__Sales_Order__c> lstSalesOrders = scope;

        Set<Id> setUpdatedSalesOrders = new Set<Id>();
        
        LST_DIVISION_ITEMS = [SELECT Id, Name, FS_Community_Group__r.Name FROM OrderApi__Item__c WHERE OrderApi__Is_Active__c=true AND OrderApi__Item_Class__r.name='Divisions'];
        LST_SECTION_ITEMS = [SELECT Id, Name, FS_Community_Group__r.Name FROM OrderApi__Item__c WHERE OrderApi__Is_Active__c=true AND OrderApi__Item_Class__r.name='Sections'];

        String salesOrderId;
        //Step - 1 - Update subscription lines that need items changed due to functional titles changing and such
        List<OrderApi__Sales_Order_Line__c> lstUpdatedLineItems = orderLinesToBeUpdated(lstSalesOrders, setUpdatedSalesOrders);
        if(! lstUpdatedLineItems.isEmpty()){
            System.debug('##--Sales Line items to be updated: ' + lstUpdatedLineItems.size() + ' -- ' + lstUpdatedLineItems);
            update lstUpdatedLineItems;
        }
        //  Step - 2
        List<OrderApi__Sales_Order_Line__c> lstSalesLineItems = createSalesOrderLinesForDivision(lstSalesOrders, setUpdatedSalesOrders);
        if(! lstSalesLineItems.isEmpty()){
            System.debug('##--Creating Sales Line items for Division: ' + lstSalesLineItems.size() + ' -- ' + lstSalesLineItems);
            lstSalesLineItemsAll.addAll(lstSalesLineItems );
        } 
        //  Step - 3
        List<OrderApi__Sales_Order_Line__c> lstSectionSalesLineItems = createSalesOrderLinesForSection(lstSalesOrders, setUpdatedSalesOrders);
        if(!lstSectionSalesLineItems.isEmpty()){
            System.debug('##--Creating Section Sales Items: ' + lstSectionSalesLineItems.size() + ' -- ' + lstSectionSalesLineItems);
            lstSalesLineItemsAll.addAll(lstSectionSalesLineItems);
        }
        if(!lstSalesLineItemsAll.isEmpty()){
            insert lstSalesLineItemsAll;
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
                salesOrderId = line.OrderApi__Sales_Order__c;
                if(set2YrSalesOrders.contains(line.OrderApi__Sales_Order__c)){
                    line.OrderApi__Price_Override__c = true;
                    //line.OrderApi__Sale_Price__c = line.OrderApi__Sale_Price__c * 2; 
                    line.OrderApi__Quantity__c = 2;
                    line.OrderApi__Overall_Total__c = line.OrderApi__Sale_Price__c * line.OrderApi__Quantity__c;
					line.OrderApi__Balance_Due__c = line.OrderApi__Overall_Total__c;
                }else if(set3YrSalesOrders.contains(line.OrderApi__Sales_Order__c)){
                    line.OrderApi__Price_Override__c = true;
                    //line.OrderApi__Sale_Price__c = line.OrderApi__Sale_Price__c * 3; 
                    line.OrderApi__Quantity__c = 3;
                    line.OrderApi__Overall_Total__c = line.OrderApi__Sale_Price__c * line.OrderApi__Quantity__c;
					line.OrderApi__Balance_Due__c = line.OrderApi__Overall_Total__c;
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
            Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', true);
            update lstUpdatedSalesOrders; 
            Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', false);
        }

        lstUpdatedSalesOrders = getSalesOrdersWithDepMemItems(lstSalesOrders);
        if(! lstUpdatedSalesOrders.isEmpty()){
            System.debug('##--Updating Sales Orders Departmental Membership: ' + lstUpdatedSalesOrders.size() + ' -- ' + lstUpdatedSalesOrders);
            Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', true);
            update lstUpdatedSalesOrders;
            Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', false);
        }

        // Update the Overall Total
        List<OrderApi__Sales_Order__c> lstSOL = [SELECT Id, OrderApi__Total__c, OrderApi__Overall_Total__c  FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId];

        for(OrderApi__Sales_Order__c sol : lstSOl){
            sol.OrderApi__Overall_Total__c = sol.OrderApi__Total__c;
        }

        Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', true);
        update lstSOL;
        Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', false);
    }
    global void finish(Database.BatchableContext bc) {
        Database.executeBatch(new ProformaRenewalBatchClone(),Integer.valueOf(Label.ProformaRenewalBatch_Size) );
    } 
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ProformaRenewalBatch(),Integer.valueOf(Label.ProformaRenewalBatch_Size));
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
    }   //  end of order
    private OrderApi__Sales_Order_Line__c updateItemOnSalesLine(OrderApi__Sales_Order_Line__c objOrderLine, List<OrderApi__Item__c> lstItems){
        for(OrderApi__Item__c objItem : lstItems){
            if(objItem.FS_Item_Functional_Titles__c.contains(objOrderLine.OrderApi__Contact__r.Functional_Title__c)){
                objOrderLine.OrderApi__Item__c = objItem.Id;
                break;
            }
        }   //  end of for-each Item
        return objOrderLine;
    }   //  end of updateItemOnSalesLine
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
    private List<OrderApi__Sales_Order_Line__c> createSalesOrderLinesForDivision(List<OrderApi__Sales_Order__c> lstSalesOrders, Set<Id> setUpdatedSalesOrders){
        List<OrderApi__Sales_Order_Line__c> lstSalesLineItems = new List<OrderApi__Sales_Order_Line__c>();
        for (OrderApi__Sales_Order__c objSaleOrder : lstSalesOrders) {
            if (! objSaleOrder.OrderApi__Contact__r.Division_Opt_Out__c) {
                OrderApi__Sales_Order_Line__c objOrderLine = createNewLineItemForDivision(objSaleOrder);
                if(objOrderLine != null){
                    lstSalesLineItems.add(objOrderLine);
                    setUpdatedSalesOrders.add(objSaleOrder.Id);
                }

            }
        }   //end of for-each Sales Order
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
        }   //end of for-each Sales Order

        //construct a map of COntact and list of section community member name
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
    }   //  
    private Boolean hasDepMemItems(OrderApi__Sales_Order__c objSaleOrder){
        
        for(OrderApi__Sales_Order_Line__c objOrderLine : objSaleOrder.OrderApi__Sales_Order_Lines__r){
            if('Departmental Membership'.equalsIgnoreCase(objOrderLine.OrderApi__Item__r.Name)){
                return true;
            }
        }   //  end of for-each Sales Order Line
        return false;
    }   //  end of hasDepMemItems
}