public class ItemTriggerHandler2 { 

    // Prevent recursive execution
    public static Boolean isProcessing = false;

    // Accumulates log messages for centralized logging
    public static String logMessage = '';

    // Fonteva object API names for dynamic referencing
    private static final Map<String, String> PACKAGE_OBJECTS = new Map<String, String>{
        'SALES_ORDER'         => 'OrderApi__Sales_Order__c',
        'SALES_ORDER_LINE'    => 'OrderApi__Sales_Order_Line__c',
        'ITEM'                => 'OrderApi__Item__c',
        'BUSINESS_GROUP'      => 'OrderApi__Business_Group__c',
        'ITEM_CLASS'          => 'OrderApi__Item_Class__c',
        'PAYMENT_TERMS'       => 'OrderApi__Payment_Terms__c',
        'PRICE_RULE'          => 'OrderApi__Price_Rule__c',
        'CREDIT_NOTE'         => 'OrderApi__Credit_Note__c',
        'SYSTEM_LOG'          => 'Framework__System_Log__c'
    };

    // Logs errors with consistent debug format
    public static void logError(String message) {
        logMessage += '\n >> ' + message;
        System.debug('>> logError >> ' + message);
    }

    // Inserts system log with error details
    public static void insertLog(String message) {
        try {
            if(!String.isBlank(message)) {
                SObject logRecord = Schema.getGlobalDescribe()
                    .get(PACKAGE_OBJECTS.get('SYSTEM_LOG'))
                    .newSObject();
                logRecord.put('Framework__Type__c', 'ShowCycle-Fonteva Integration');
                logRecord.put('Framework__Exception_Data__c', message);
                insert logRecord;
            }
        } catch (Exception e) {
            System.debug('>> insertLog >> Failed to insert log: ' + e.getMessage());
        }
    }

    // Checks if Fonteva is installed by validating object availability
    private static Boolean isFontevaInstalled() {
        final String methodName = 'isFontevaInstalled';
        try {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            for (String key : new List<String>{'SALES_ORDER', 'SALES_ORDER_LINE'}) {
                String objectApiName = PACKAGE_OBJECTS.get(key);
                if (String.isBlank(objectApiName) || !globalDescribe.containsKey(objectApiName)) {
                    return false;
                }
            }
            return true;
        } catch (Exception e) {
            logError('>> ' + methodName + ' >> Exception while checking Fonteva installation: ' +
                     e.getMessage() + '\nStack trace: ' + e.getStackTraceString());
            return false;
        }
    }

    // Wrapper class to collect related data for item processing
    public class DataWrapper {
        public s7e__Item__c newItemRecord;
        public s7e__Item__c oldItemRecord;
        public Id account;
        public Id opportunity;
        public Id SOIdOnOpportunity;
        public Id contact;
        public Id ocr;
        public SObject showRecord;
        public Decimal quantity;
        public Decimal oldQuantity;
        public Decimal newQuantity;
        public Decimal numberOfOpenCorners;
        public Boolean isBooth;
        public String boothDescription;
        public SObject mainSalesOrderLine;
        public SObject cornerSalesOrderLine;
        public Decimal boothArea;
        public Decimal boothBasePrice;
        public Decimal boothCornerPrice;
        public SObject salesOrder;
        public Boolean isSalesOrderPosted;
        public List<SObject> salesOrderLines = new List<SObject>();
        public Id businessGroup;
        public SObject item;
        public SObject cornerItem;
        public SObject priceRule;
        public SObject cornerPriceRule;
        public SObject itemClass;
        public SObject paymentTerms;
        // fields for processing fee soli
        public SObject processingFeeItem; // OrderApi__Item__c for the fee
        public Decimal processingFeePercentage; // Percentage from OrderApi__Price__c
        public SObject cancelFeeItem; // OrderApi__Item__c for the fee
        public Decimal cancelFeePercentage; 
        public Decimal totalLineItemPrice; // Sum of main and corner line item prices
        public SObject processingFeeLineItem; // The fee line item to be inserted
    }
    
    // handle items
    @testVisible
    public static void handleItem(Map<Id, s7e__Item__c> newItemMap, Map<Id, s7e__Item__c> oldItemMap) {
        if (newItemMap == null || newItemMap.isEmpty()) return;
    
        Set<Id> itemIdsToProcess = new Set<Id>();
        Set<Id> showIds = new Set<Id>();
        Map<Id, String> recordTypeMap = new Map<Id, String>();
        Map<Id, s7e__Show__c> showMap = new Map<Id, s7e__Show__c>();
        Map<Id, DataWrapper> itemToDataWrapperMap = new Map<Id, DataWrapper>();
    
        Set<Id> assignItemIds = new Set<Id>();
        Set<Id> vacateItemIds = new Set<Id>();
        Set<Id> sponsorItemIds = new Set<Id>();
    
        // RecordType mapping
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = 's7e__Item__c']) {
            recordTypeMap.put(rt.Id, rt.Name);
        }
    
        // Collect show Ids
        for (s7e__Item__c item : newItemMap.values()) {
            if (String.isNotEmpty(item.s7e__Show__c)) {
                showIds.add(item.s7e__Show__c);
            }
        }
    
        if (!showIds.isEmpty()) {
            String showQuery = 'SELECT Id, Name, s7e__X1st_Payment_Due_Date__c, s7e__X2nd_Payment_Due_Date__c, ' +
                              's7e__X3rd_Payment_Due_Date__c, s7e__Initial_Payment__c, s7e__X1st_Payment__c, ' +
                              's7e__X2nd_Payment__c, s7e__X3rd_Payment__c, Fonteva_Business_Group__c, ' +
                              'Fonteva_Event__c, s7e__Financials__c, s7e__Financial_System__c, s7e__Current_Cancellation_Per__c, scyc_Add_Processing_Fee__c ' +
                              'FROM s7e__Show__c WHERE Id IN :showIds';
            showMap = new Map<Id, s7e__Show__c>((List<s7e__Show__c>) Database.query(showQuery));
            //showMap = new Map<Id, s7e__Show__c>([ SELECT Id, Name, s7e__Financials__c, s7e__Financial_System__c FROM s7e__Show__c WHERE Id IN :showIds ]);
        }
    
        // Determine itemIds to process
        for (s7e__Item__c item : newItemMap.values()) {
            s7e__Item__c oldItem = oldItemMap != null ? oldItemMap.get(item.Id) : null;
            String recordTypeName = recordTypeMap.get(item.RecordTypeId);
    
            //EXP-162
            s7e__Showcycle_Setting__mdt ShowSett = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, s7e__Max_Zoom__c, s7e__Meter_Default_Scale__c, 
                        s7e__Min_Zoom__c, s7e__PFP_Batch_End_Time__c, s7e__PFP_Batch_Frequency__c, s7e__PFP_Batch_Size__c, s7e__PFP_Batch_Start_Time__c, s7e__Fonteva_Business_Group__c, s7e__Fonteva_Item_Retrieval_Field__c, s7e__Fonteva_Event__c, s7e__Fonteva_Item_Class_List__c,
                        s7e__Feet_Default_Scale__c FROM s7e__Showcycle_Setting__mdt WITH SECURITY_ENFORCED limit 1];
                        
            //Trimming spaces from the labels
            String labels = ShowSett.s7e__Fonteva_Item_Class_List__c;

            Set<String> productClassList = new Set<String>();
            for (String label : labels.split(',')) {
                productClassList.add(label.trim());
            }
            //

            //EXP-162
            // Boolean isEligibleRecordType = recordTypeName == 'Exhibit Space' || recordTypeName == 'Sponsorship' /*SH-1063 Add-On*/ || recordTypeName == 'Add-On';
			Boolean isEligibleRecordType = productClassList.contains(recordTypeName) || recordTypeName == 'Exhibit Space'; //EXP-162 - checking the record type eligibility from the custom metadata

			
            if (isEligibleRecordType && oldItem != null) {
                Boolean isAssignmentConditionMet =
                    ((oldItem.s7e__Status__c == null || oldItem.s7e__Status__c == 'Hold') &&
                     item.s7e__Status__c == 'Confirmed' &&
                     String.isNotBlank(item.s7e__Ex_ProductId__c)) ||
    
                    ((oldItem.s7e__Status__c == 'Confirmed') &&
                     (item.s7e__Status__c == null || item.s7e__Status__c == '') &&
                     String.isNotBlank(oldItem.s7e__Ex_ProductId__c)) ||
    
                    ((oldItem.s7e__Status__c == null || oldItem.s7e__Status__c == '') &&
                     item.s7e__Status__c == 'Confirmed' &&
                     String.isBlank(oldItem.s7e__Ex_ProductId__c) &&
                     String.isNotBlank(item.s7e__Ex_ProductId__c)) ||
    
                    (oldItem.s7e__Status__c == 'Committed' &&
                     item.s7e__Status__c == 'Confirmed' && String.isNotBlank(item.s7e__Ex_ProductId__c) ) ||
    
                    (item.s7e__Status__c == 'Confirmed' &&
                     item.s7e__Item_Quantity__c != oldItem.s7e__Item_Quantity__c &&
                     String.isNotBlank(item.s7e__Ex_ProductId__c)) ||
                     
                     //SH-1204
                     (oldItem.s7e__Status__c == 'Contract Created' &&
                     item.s7e__Status__c == 'Confirmed' && String.isNotBlank(item.s7e__Ex_ProductId__c) );

                //SH-1063 Add-On
                // Boolean isSponsorCancellation = (recordTypeName == 'Sponsorship' || recordTypeName == 'Add-On') &&
                //                                (oldItem.Status__c != 'Cancelled' && oldItem.Status__c != 'Canceled') &&
                //                                (item.Status__c == 'Cancelled' || item.Status__c == 'Canceled');
                Boolean isSponsorCancellation = recordTypeName != 'Exhibit Space' &&
                                               (oldItem.s7e__Status__c != 'Cancelled' && oldItem.s7e__Status__c != 'Canceled') &&
                                               (item.s7e__Status__c == 'Cancelled' || item.s7e__Status__c == 'Canceled');
    
                if (isAssignmentConditionMet) {
                    itemIdsToProcess.add(item.Id);
                }

                if (isSponsorCancellation) {
                    sponsorItemIds.add(item.Id);
                }

            } else if (/*SH-1063 Add-On*/ recordTypeName != 'Exhibit Space' && (item.s7e__Status__c == 'Confirmed' || item.s7e__Status__c == 'Committed') && String.isNotBlank(item.s7e__Ex_ProductId__c)) { // Sponsorship from Exp Portal
                itemIdsToProcess.add(item.Id);
            }
        }
    
        System.debug('>> handleItem >> itemIdsToProcess size : ' + itemIdsToProcess.size());
    
        try {
            if ((!itemIdsToProcess.isEmpty() || !sponsorItemIds.isEmpty()) && isFontevaInstalled() && !isProcessing) {
                isProcessing = true;
    
                for (Id itemId : itemIdsToProcess) {
                    s7e__Item__c item = newItemMap.get(itemId);
                    
                    if (item != null && showMap.containsKey(item.s7e__Show__c)) {
                        s7e__Show__c relatedShow = showMap.get(item.s7e__Show__c);
                        
                        if (relatedShow != null && relatedShow.s7e__Financials__c &&
                            relatedShow.s7e__Financial_System__c == 'Fonteva' &&
                            !item.s7e__IsReserved__c) {
                                
                                s7e__Item__c oldItem = oldItemMap != null ? oldItemMap.get(itemId) : null;
                                String oldItemStatus = oldItem != null ? oldItem.s7e__Status__c : null;
                                String itemStatus = item.s7e__Status__c;
                                
                                if (String.isBlank(oldItemStatus) && oldItemStatus == itemStatus) {
                                    continue;
                                }
                                
                                if (itemStatus == 'Confirmed') {
                                    String recordTypeName = recordTypeMap.get(item.RecordTypeId);
                                    if (recordTypeName == 'Exhibit Space') {
                                        assignItemIds.add(item.Id);
                                        //EXP-162
                                    } else {
                                        sponsorItemIds.add(item.Id);
                                    }
                                } else if (String.isBlank(itemStatus) || itemStatus == 'Canceled') {
                                    vacateItemIds.add(item.Id);
                                }
                            }
                    }
                }
    
                System.debug('>> handleItem >> assignItemIds size : ' + assignItemIds.size());
                System.debug('>> handleItem >> vacateItemIds size : ' + vacateItemIds.size());
                System.debug('>> handleItem >> sponsorItemIds size : ' + sponsorItemIds.size());
    
                Boolean isProcessingRequired = !assignItemIds.isEmpty() || !vacateItemIds.isEmpty() || !sponsorItemIds.isEmpty();
    
                if (isProcessingRequired) {
                    
                    Set<Id> allItemsForData = new Set<Id>();
                    allItemsForData.addAll(assignItemIds);
                    allItemsForData.addAll(vacateItemIds);
                    allItemsForData.addAll(sponsorItemIds);
                    
                    itemToDataWrapperMap = generateItemFontevaDataWrapper(allItemsForData, newItemMap, oldItemMap, recordTypeMap);
                    
                    if (!assignItemIds.isEmpty()) {
                        // method to process assign operation
                        handleAssign(assignItemIds, itemToDataWrapperMap);
                    }
    
                    if (!vacateItemIds.isEmpty()) {
                        // method to process vacate operation
                        handleVacate(vacateItemIds, itemToDataWrapperMap);
                    }
                    
                    if (!sponsorItemIds.isEmpty()) {
                        handleSponsor(sponsorItemIds, itemToDataWrapperMap);
                    }
                }
            }
        } catch (Exception e) {
            LogError('>> handleItem >> ERROR >> ' + e.getMessage() + '\nStack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('>> handleItem >> ERROR >> ' + e.getMessage());
        } finally {
            if (!itemIdsToProcess.isEmpty() || !sponsorItemIds.isEmpty()) {
                // Changed here: Now starting with PostSalesOrderLinesQueueable instead of PostSalesOrdersQueueable
                System.enqueueJob(new PostSalesOrderLinesQueueable(itemIdsToProcess, sponsorItemIds, newItemMap, oldItemMap, recordTypeMap, showMap));
                insertLog(logMessage);
            }
    
            isProcessing = false;
        }
    }
    
	// generate items data
    private static Map<Id, DataWrapper> generateItemFontevaDataWrapper(Set<Id> itemIds, Map<Id, s7e__Item__c> newItemsMap, Map<Id, s7e__Item__c> oldItemsMap, Map<Id, String> recordTypeMap) {
        // AMCP-34: Initialize all collections to prevent null pointer exceptions
        Map<Id, DataWrapper> itemData = new Map<Id, DataWrapper>();
        
        // Initialize collections for querying related data
        Set<Id> showIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<String> externalProductIdSet = new Set<String>();
        Set<String> externalLineItemIdSet = new Set<String>();
        
        Map<Id, Id> itemIdToOpportunityIdMap = new Map<Id, Id>();
        Map<Id, s7e__Show__c> showMap = new Map<Id, s7e__Show__c>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        
        Set<String> salesOrderIds = new Set<String>();
        Map<Id, Id> opportunityToContactMap = new Map<Id, Id>();
        Map<Id, String> opportunityToSalesOrderIdMap = new Map<Id, String>();
        Set<Id> opptiesWithoutSalesOrder = new Set<Id>();
        Map<String, SObject> salesOrderMap = new Map<String, SObject>();
        Map<String, List<SObject>> salesOrderLineMap = new Map<String, List<SObject>>();
        
        Map<String, SObject> fontevaItemMap = new Map<String, SObject>();
        Map<String, SObject> itemClassMap = new Map<String, SObject>();
        Map<String, SObject> priceRuleMap = new Map<String, SObject>();
        Map<String, String> itemToPriceRuleMap = new Map<String, String>();
        Map<String, String> itemIdToClassIdMap = new Map<String, String>();
        SObject cornerItemRecord;
        SObject cornerPriceRule;
        SObject feeItemRecord;
        SObject cancelFeeItemRecord;
        
        Map<String, String> productIdToItemClassIdMap = new Map<String, String>(); // AMCP-34: Initialize map
        Map<String, String> productIdToPriceRuleIdMap = new Map<String, String>(); // AMCP-34: Initialize map
        
        // Collect related IDs from items
        for(Id itemId : itemIds) {
            // AMCP-34: Add null checks for maps
            if(!newItemsMap.containsKey(itemId)) {
                System.debug('Item not found in newItemsMap: ' + itemId);
                continue;
            }
            
            s7e__Item__c newItem = newItemsMap.get(itemId);
            s7e__Item__c oldItem = oldItemsMap != null ? oldItemsMap.get(itemId) : null;
            s7e__Item__c item = new s7e__Item__c();
            
            // AMCP-34: Add comprehensive null checks for record type
            if(newItem != null && newItem.s7e__Account__c != null && String.IsNotBlank(newItem.s7e__Account__c)){
                item = newItem;
            } else if(oldItem != null && recordTypeMap != null && newItem != null && newItem.RecordTypeId != null && 
                     recordTypeMap.containsKey(newItem.RecordTypeId) && 
                     recordTypeMap.get(newItem.RecordTypeId) == 'Exhibit Space') {
                item = oldItem;
            } else {
                item = newItem;
            }
            
            if (item != null) {
                // AMCP-34: Add null checks for all field accesses
                if (item.s7e__Show__c != null) {
                    showIdSet.add(item.s7e__Show__c);
                }
                if (item.s7e__Opportunity__c != null) {
                    opportunityIdSet.add(item.s7e__Opportunity__c);
                    itemIdToOpportunityIdMap.put(itemId, item.s7e__Opportunity__c);
                }
                if (String.isNotBlank(item.s7e__Ex_ProductId__c)) {
                    externalProductIdSet.add(item.s7e__Ex_ProductId__c);
                }
                if (String.isNotBlank(item.s7e__Ext_Line_Item_Id__c)) {
                    externalLineItemIdSet.add(item.s7e__Ext_Line_Item_Id__c);
                }
            }
        }
        
        // Query related Show records
        if (!showIdSet.isEmpty()) {
            String showQuery = 'SELECT Id, Name, s7e__X1st_Payment_Due_Date__c, s7e__X2nd_Payment_Due_Date__c, ' +
                              's7e__X3rd_Payment_Due_Date__c, s7e__Initial_Payment__c, s7e__X1st_Payment__c, ' +
                              's7e__X2nd_Payment__c, s7e__X3rd_Payment__c, Fonteva_Business_Group__c, ' +
                              'Fonteva_Event__c, s7e__Financials__c, s7e__Financial_System__c, s7e__Current_Cancellation_Per__c, scyc_Add_Processing_Fee__c, s7e__Enable_Membership_Pricing__c ' +
                              'FROM s7e__Show__c WHERE Id IN :showIdSet';
            List<s7e__Show__c> shows = Database.query(showQuery);
            showMap = shows != null ? new Map<Id, s7e__Show__c>(shows) : new Map<Id, s7e__Show__c>(); // AMCP-34: Null check
        }
        
        // Query related Opportunities
        if (!opportunityIdSet.isEmpty()) {
            String opportunityQuery = 'SELECT Id, AccountId, Amount, s7e__Ext_Sales_Order_ID__c, CloseDate, ' +
                                     '(SELECT Id, ContactId, IsPrimary FROM OpportunityContactRoles WHERE IsPrimary = true LIMIT 1) ' +
                                     'FROM Opportunity WHERE Id IN :opportunityIdSet';
            List<Opportunity> opportunities = Database.query(opportunityQuery);
            opportunityMap = opportunities != null ? new Map<Id, Opportunity>(opportunities) : new Map<Id, Opportunity>(); // AMCP-34: Null check
            
            // Process opportunities to collect contact & sales order information
            for (Opportunity opp : opportunityMap.values()) {
                if(opp == null) continue; // AMCP-34: Skip null opportunities
                
                Id primaryContactId;
                
                if (opp.OpportunityContactRoles != null && !opp.OpportunityContactRoles.isEmpty()) {
                    for (OpportunityContactRole ocr : opp.OpportunityContactRoles) {
                        if (ocr != null && ocr.IsPrimary) { // AMCP-34: Null check
                            primaryContactId = ocr.ContactId;
                            break;
                        }
                    }
                }
            
                if (primaryContactId != null) {
                    opportunityToContactMap.put(opp.Id, primaryContactId);
                } else {
                    System.debug('>> generateItemFontevaDataWrapper >> No primary contact found for Opp ' + opp.Id);
                }
            
                if (String.isNotBlank(opp.s7e__Ext_Sales_Order_ID__c)) {
                    salesOrderIds.add(opp.s7e__Ext_Sales_Order_ID__c);
                    opportunityToSalesOrderIdMap.put(opp.Id, opp.s7e__Ext_Sales_Order_ID__c);
                } else {
                    opptiesWithoutSalesOrder.add(opp.Id);
                    System.debug('>> generateItemFontevaDataWrapper >> No Sales Order for Opp ' + opp.Id);
                }
            }
        }
        
        // Query Sales Orders and Lines
        try {
            if (!salesOrderIds.isEmpty()) {
                // Query Sales Orders
                List<SObject> salesOrders = Database.query(
                    'SELECT Id, Name, OrderApi__Is_Closed__c, OrderApi__Overall_Total__c, OrderApi__Memo__c, OrderApi__Payment_Terms__c, OrderApi__Entity__c, OrderApi__Account__c, ' +
                    'OrderApi__Business_Group__c, OrderApi__Contact__c, OrderApi__Is_Posted__c ' + /*Add OrderApi__Amount_Paid__c field for handling processing fees on vacate*/ ', OrderApi__Amount_Paid__c ' +
                    'FROM OrderApi__Sales_Order__c WHERE Id IN :salesOrderIds'
                );
                
                if(salesOrders != null) { // AMCP-34: Null check
                    for (SObject so : salesOrders) {
                        if(so != null) { // AMCP-34: Null check
                            salesOrderMap.put((String)so.get('Id'), so);
                        }
                    }
                }
                System.debug('>> generateItemFontevaDataWrapper >> Queried ' + salesOrderMap.size() + ' sales orders');
        
                // Query Sales Order Lines
                List<SObject> orderLines = Database.query(
                    'SELECT Id, OrderApi__Sales_Order__c, OrderApi__Is_Adjustment__c, OrderApi__Item__c, OrderApi__Entity__c, OrderApi__Line_Description__c, OrderApi__Is_Line_Posted__c, Name ' +
                    'FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c IN :salesOrderIds'
                );
                
                if(orderLines != null) { // AMCP-34: Null check
                    for (SObject line : orderLines) {
                        if(line != null) { // AMCP-34: Null check
                            String parentId = (String)line.get('OrderApi__Sales_Order__c');
                            if (parentId != null) { // AMCP-34: Null check
                                if (!salesOrderLineMap.containsKey(parentId)) {
                                    salesOrderLineMap.put(parentId, new List<SObject>());
                                }
                                salesOrderLineMap.get(parentId).add(line);
                            }
                        }
                    }
                }
                System.debug('>> generateItemFontevaDataWrapper >> Queried ' + orderLines.size() + ' sales order lines');
            } 
        } catch (Exception e) {
            LogError('>> generateItemFontevaDataWrapper >> ERROR >> ' + e.getMessage() + '\nStack trace: ' + e.getStackTraceString());
        }
        
        if (!externalProductIdSet.isEmpty()) {
            try {
                // Assuming PACKAGE_OBJECTS is a static map defined elsewhere in the class
                String itemObjectName = PACKAGE_OBJECTS != null ? PACKAGE_OBJECTS.get('ITEM') : null; // AMCP-34: Null check
                String itemClassObjectName = PACKAGE_OBJECTS != null ? PACKAGE_OBJECTS.get('ITEM_CLASS') : null; // AMCP-34: Null check
                String priceRuleObjectName = PACKAGE_OBJECTS != null ? PACKAGE_OBJECTS.get('PRICE_RULE') : null; // AMCP-34: Null check
                
                if (itemObjectName == null || itemClassObjectName == null || priceRuleObjectName == null) {
                    //throw new CustomException('Package object names not properly defined');
                }
                
                // Query Items
                if(itemObjectName != null) { // AMCP-34: Null check
                    //SH-1204 Added flat rate field to the query
                    List<SObject> itemList = Database.query(
                        'SELECT Id, Name, OrderApi__Item_Class__c, OrderApi__Price__c, OrderApi__Line_Description__c, scyc_Is_Flat_Rate__c ' + 
                        'FROM ' + itemObjectName + ' WHERE Id IN :externalProductIdSet'
                    );
            
                    Set<String> itemClassIds = new Set<String>();
                    productIdToItemClassIdMap = new Map<String, String>();
                    
                    if(itemList != null) { // AMCP-34: Null check
                        for (SObject item : itemList) {
                            if(item != null) { // AMCP-34: Null check
                                String itemId = (String)item.get('Id');
                                fontevaItemMap.put(itemId, item);
                                String classId = (String)item.get('OrderApi__Item_Class__c');
                                if (classId != null) {
                                    itemClassIds.add(classId);
                                    productIdToItemClassIdMap.put(itemId, classId);
                                }
                            }
                        }
                    }
                    System.debug('>> generateItemFontevaDataWrapper >> Queried ' + fontevaItemMap.size() + ' Fonteva items');
            
                    // Query Item Classes
                    if (!itemClassIds.isEmpty() && itemClassObjectName != null) { // AMCP-34: Null check
                        List<SObject> classList = Database.query(
                            'SELECT Id, Name FROM ' + itemClassObjectName + ' WHERE Id IN :itemClassIds'
                        );
                        
                        if(classList != null) { // AMCP-34: Null check
                            for (SObject ic : classList) {
                                if(ic != null) { // AMCP-34: Null check
                                    itemClassMap.put((String)ic.get('Id'), ic);
                                }
                            }
                        }
                        System.debug('>> generateItemFontevaDataWrapper >> Queried ' + itemClassMap.size() + ' item classes');
            
                        // Query Default Price Rules
                        if(priceRuleObjectName != null) { // AMCP-34: Null check
                            List<SObject> ruleList = Database.query(
                                'SELECT Id, Name, OrderApi__Item__c FROM ' + priceRuleObjectName + 
                                ' WHERE OrderApi__Item__c IN :externalProductIdSet AND Name = \'DEFAULT\''
                            );
                            
                            productIdToPriceRuleIdMap = new Map<String, String>();
                            
                            if(ruleList != null) { // AMCP-34: Null check
                                for (SObject pr : ruleList) {
                                    if(pr != null) { // AMCP-34: Null check
                                        String itemId = (String)pr.get('OrderApi__Item__c');
                                        priceRuleMap.put((String)pr.get('Id'), pr);
                                        productIdToPriceRuleIdMap.put(itemId, (String)pr.get('Id'));
                                    }
                                }
                            }
                            System.debug('>> generateItemFontevaDataWrapper >> Queried ' + priceRuleMap.size() + ' price rules');
            
                            // Query "Corner" item
                            try {
                                if (!itemClassIds.isEmpty() && itemObjectName != null) { // AMCP-34: Null check
                                    String classId = itemClassIds.iterator().next();
                                    List<SObject> cornerItems = Database.query(
                                        'SELECT Id, Name, OrderApi__Item_Class__c, OrderApi__Price__c FROM ' + 
                                        itemObjectName + ' WHERE Name LIKE \'%Corner%\' AND OrderApi__Item_Class__c = :classId LIMIT 1'
                                    );
                                    
                                    if (cornerItems != null && !cornerItems.isEmpty()) { // AMCP-34: Null check
                                        cornerItemRecord = cornerItems[0];
                                        System.debug('>> generateItemFontevaDataWrapper >> Found corner item: ' + cornerItemRecord.get('Name'));
                                        
                                        String cornerItemId = (String)cornerItemRecord.get('Id');
                                        if(cornerItemId != null && priceRuleObjectName != null) { // AMCP-34: Null check
                                            List<SObject> cornerRules = Database.query(
                                                'SELECT Id, Name, OrderApi__Item__c FROM ' + priceRuleObjectName + 
                                                ' WHERE OrderApi__Item__c = :cornerItemId AND Name = \'DEFAULT\' LIMIT 1'
                                            );
                                            
                                            if (cornerRules != null && !cornerRules.isEmpty()) { // AMCP-34: Null check
                                                cornerPriceRule = cornerRules[0];
                                                System.debug('>> generateItemFontevaDataWrapper >> Found Price rule corner item: ' + cornerPriceRule.get('Id'));
                                            }
                                        }
                                    }
                                }
                            } catch (Exception e) {
                                System.debug('>> generateItemFontevaDataWrapper >> ERROR >> '+ e.getMessage() + 
                                          '\nStack trace: ' + e.getStackTraceString());
                            }
                        }
                    }
                    // Query Processing Fee Item
                    if (itemObjectName != null && itemClassObjectName != null) {
                        // query to fetch Processing Fee Item directly
                        String feeItemQuery = 
                            'SELECT Id, Name, OrderApi__Item_Class__c, OrderApi__Price__c ' +
                            'FROM ' + itemObjectName +
                            ' WHERE Name LIKE \'%Processing Fee%\' ' +
                            'AND OrderApi__Item_Class__r.Name = \'Fees\' ' +
                            'AND OrderApi__Item_Class__r.scyc_Is_ShowCycle__c = true ' +
                            'LIMIT 1';
                        
                        List<SObject> feeItems = Database.query(feeItemQuery);
                        if (!feeItems.isEmpty()) {
                            feeItemRecord = feeItems[0];
                            System.debug('>> generateItemFontevaDataWrapper >> Found processing fee item: ' + feeItemRecord.get('Name'));
                        } else {
                            System.debug('>> generateItemFontevaDataWrapper >> No processing fee item found');
                        }
                    }
                    // Query cancel Fee Item
                    if (itemObjectName != null && itemClassObjectName != null) {
                        // query to fetch Processing Fee Item directly
                        String feeItemQuery = 
                            'SELECT Id, Name, OrderApi__Item_Class__c, OrderApi__Price__c ' +
                            'FROM ' + itemObjectName +
                            ' WHERE Name LIKE \'%Cancellation Fee%\' ' +
                            'AND OrderApi__Item_Class__r.Name = \'Fees\' ' +
                            'AND OrderApi__Item_Class__r.scyc_Is_ShowCycle__c = true ' +
                            'LIMIT 1';
                        
                        List<SObject> feeItems = Database.query(feeItemQuery);
                        if (!feeItems.isEmpty()) {
                            cancelFeeItemRecord = feeItems[0];
                            System.debug('>> generateItemFontevaDataWrapper >> Found cancellation fee item: ' + cancelFeeItemRecord.get('Name'));
                        } else {
                            System.debug('>> generateItemFontevaDataWrapper >> No cancellation fee item found');
                        }
                    }
                }
            } catch (Exception e) {
                LogError('>> generateItemFontevaDataWrapper >> ERROR >> '+ e.getMessage() + 
                      '\nStack trace: ' + e.getStackTraceString());
            }
        }
        
        // Process items and create data wrappers
        for (Id itemId : itemIds) {
            // AMCP-34: Skip if item not in map
            if(!newItemsMap.containsKey(itemId)) {
                continue;
            }
            
            s7e__Item__c newItem = newItemsMap.get(itemId);
            s7e__Item__c oldItem = oldItemsMap != null ? oldItemsMap.get(itemId) : null;
            s7e__Item__c item = new s7e__Item__c();
            
            // AMCP-34: Updated null-safe item assignment
            if(newItem != null) {
                if((newItem.s7e__Account__c == null || String.IsBlank(newItem.s7e__Account__c)) && 
                   recordTypeMap != null && newItem.RecordTypeId != null && 
                   recordTypeMap.containsKey(newItem.RecordTypeId) && 
                   recordTypeMap.get(newItem.RecordTypeId) == 'Exhibit Space') {
                    item = oldItem != null ? oldItem : newItem;
                } else {
                    item = newItem;
                }
            }
            
            if (item != null) {
                // AMCP-34: Initialize wrapper with default values
                DataWrapper wrapper = new DataWrapper();
                wrapper.newItemRecord = newItem;
                wrapper.oldItemRecord = oldItem;
                wrapper.account = item.s7e__Account__c;
                wrapper.opportunity = item.s7e__Opportunity__c;
                wrapper.numberOfOpenCorners = item.s7e__No_of_Open_Corners__c != null ? item.s7e__No_of_Open_Corners__c : 0;
                wrapper.boothArea = item.s7e__Area__c != null ? item.s7e__Area__c : 0;
                
                // AMCP-34: Safe show record access
                if(item.s7e__Show__c != null && showMap.containsKey(item.s7e__Show__c)) {
                    s7e__Show__c relatedShow = showMap.get(item.s7e__Show__c);
                    wrapper.showRecord = relatedShow;
                    wrapper.businessGroup = relatedShow != null ? relatedShow.Fonteva_Business_Group__c : null;
                }
                
                // AMCP-34: Safe contact access
                if(item.s7e__Opportunity__c != null) {
                    wrapper.contact = opportunityToContactMap.get(item.s7e__Opportunity__c);
                }
                
                // AMCP-34: Safe record type check
                if(item.RecordTypeId != null && recordTypeMap != null && recordTypeMap.containsKey(item.RecordTypeId)) {
                    String rtName = recordTypeMap.get(item.RecordTypeId);
                    wrapper.isBooth = rtName == 'Exhibit Space';
                    
                    if(wrapper.isBooth) {
                        wrapper.quantity = item.s7e__Area__c != null ? item.s7e__Area__c : 0;
                    } else {
                        wrapper.quantity = item.s7e__Item_Quantity__c != null ? item.s7e__Item_Quantity__c : 0;
                        wrapper.newQuantity = newItem != null && newItem.s7e__Item_Quantity__c != null ? newItem.s7e__Item_Quantity__c : 0;
                        wrapper.oldQuantity = oldItem != null && oldItem.s7e__Item_Quantity__c != null ? oldItem.s7e__Item_Quantity__c : 0;
                    }
                }
                
                // AMCP-34: Safe product ID access
                if(String.isNotBlank(item.s7e__Ex_ProductId__c)) {
                    wrapper.item = fontevaItemMap.get(item.s7e__Ex_ProductId__c);
                    
                    if(productIdToItemClassIdMap != null) {
                        String itemClassId = productIdToItemClassIdMap.get(item.s7e__Ex_ProductId__c);
                        wrapper.itemClass = itemClassId != null ? itemClassMap.get(itemClassId) : null;
                    }
                    
                    if(productIdToPriceRuleIdMap != null) {
                        String priceRuleId = productIdToPriceRuleIdMap.get(item.s7e__Ex_ProductId__c);
                        wrapper.priceRule = priceRuleId != null ? priceRuleMap.get(priceRuleId) : null;
                    }
                }
                
                wrapper.cornerItem = cornerItemRecord;
                
                if (wrapper.cornerItem != null && wrapper.numberOfOpenCorners != null) {
                    wrapper.cornerPriceRule = cornerPriceRule;
                    Decimal cornerPrice = wrapper.cornerItem.get('OrderApi__Price__c') != null ? 
                        (Decimal) wrapper.cornerItem.get('OrderApi__Price__c') : 0; // AMCP-34: Null check
                    wrapper.boothCornerPrice = cornerPrice * wrapper.numberOfOpenCorners;
                }
                
                if (wrapper.item != null && wrapper.boothArea != null) {
                    Decimal basePrice = wrapper.item.get('OrderApi__Price__c') != null ? 
                        (Decimal) wrapper.item.get('OrderApi__Price__c') : 0; // AMCP-34: Null check
                    wrapper.boothBasePrice = basePrice * wrapper.boothArea;
                    if (wrapper.isBooth) {
                        wrapper.boothDescription = 'Booth ' + (item.s7e__Booth_Number__c != null ? item.s7e__Booth_Number__c : ''); // AMCP-34: Null check
                    }
                }
                
                if(item.s7e__Opportunity__c != null) { // AMCP-34: Null check
                    String salesOrderId = opportunityToSalesOrderIdMap.get(item.s7e__Opportunity__c);
                    if (salesOrderId != null) {
                        wrapper.SOIdOnOpportunity = salesOrderId;
                        wrapper.salesOrder = salesOrderMap.get(salesOrderId);
                        wrapper.isSalesOrderPosted = (wrapper.salesOrder != null && wrapper.salesOrder.get('OrderApi__Is_Posted__c') != null)
                            ? (Boolean) wrapper.salesOrder.get('OrderApi__Is_Posted__c')
                            : null;
                
                        if (salesOrderLineMap.containsKey(salesOrderId)) {
                            wrapper.salesOrderLines = salesOrderLineMap.get(salesOrderId);
                        }
                    }
                }
                
                // In the item processing loop
                wrapper.processingFeeItem = feeItemRecord;
                wrapper.processingFeePercentage = feeItemRecord != null ? (Decimal)feeItemRecord.get('OrderApi__Price__c') : 0;
                wrapper.cancelFeeItem = cancelFeeItemRecord;
                wrapper.cancelFeePercentage = cancelFeeItemRecord != null ? (Decimal)cancelFeeItemRecord.get('OrderApi__Price__c') : 0;
                itemData.put(itemId, wrapper);
            }
        }
        
        return itemData;
    }
    
    // Add a helper method to calculate line item subtotal
    @testVisible
    private static Decimal calculateLineItemSubtotal(SObject lineItem) {
        Decimal price = (Decimal)lineItem.get('OrderApi__Sale_Price__c') != null ? (Decimal)lineItem.get('OrderApi__Sale_Price__c') : 0;
        Decimal quantity = (Decimal)lineItem.get('OrderApi__Quantity__c') != null ? (Decimal)lineItem.get('OrderApi__Quantity__c') : 0;
        return price * quantity;
    }
    
    // Generate payment memo with schedule
    //public static String generateMemoForSalesOrder(Decimal totalAmount, Date todayDate, SObject showObj, Decimal processingFeeAmount) {
    public static String generateMemoForSalesOrder(Decimal totalAmount, Date todayDate, SObject showObj) {

        s7e__Show__c show = (s7e__Show__c) showObj;
    	//Decimal adjustedTotal = totalAmount + (processingFeeAmount != null ? processingFeeAmount : 0);
        try {
            List<Map<String, Object>> paymentSchedule = new List<Map<String, Object>>();
    
            // Initial payment
            if (show.s7e__Initial_Payment__c != null) {
                paymentSchedule.add(new Map<String, Object>{
                    'label' => 'Initial Payment',
                    'percent' => show.s7e__Initial_Payment__c,
                    'dueDate' => todayDate
                });
            }
    
            // Add installments
            if (show.s7e__X1st_Payment__c != null && show.s7e__X1st_Payment_Due_Date__c != null) {
                paymentSchedule.add(new Map<String, Object>{
                    'label' => '1st Installment',
                    'percent' => show.s7e__X1st_Payment__c,
                    'dueDate' => show.s7e__X1st_Payment_Due_Date__c
                });
            }
    
            if (show.s7e__X2nd_Payment__c != null && show.s7e__X2nd_Payment_Due_Date__c != null) {
                paymentSchedule.add(new Map<String, Object>{
                    'label' => '2nd Installment',
                    'percent' => show.s7e__X2nd_Payment__c,
                    'dueDate' => show.s7e__X2nd_Payment_Due_Date__c
                });
            }
    
            if (show.s7e__X3rd_Payment__c != null && show.s7e__X3rd_Payment_Due_Date__c != null) {
                paymentSchedule.add(new Map<String, Object>{
                    'label' => '3rd Installment',
                    'percent' => show.s7e__X3rd_Payment__c,
                    'dueDate' => show.s7e__X3rd_Payment_Due_Date__c
                });
            }
    
            String memo = '';
            Decimal lastPercent = 0;
    
            // Build memo text
            for (Map<String, Object> payment : paymentSchedule) {
                Decimal percent = (Decimal) payment.get('percent');
                Date dueDate = (Date) payment.get('dueDate');
                String label = (String) payment.get('label');
    
                if (percent == null || dueDate == null) {
                    continue;
                }
    
                Decimal amount = ((percent - lastPercent) * totalAmount) / 100;
    
                if (todayDate >= dueDate) {
                    memo += label + ' of ' + percent.setScale(2) + '%. Due on Receipt: $' + amount.setScale(2) + '<br/>\n';
                } else {
                    memo += label + ', ' + percent.setScale(2) + '% Due by ' + dueDate.format() + '. Amount: $' + amount.setScale(2) + '<br/>\n';
                }
    
                lastPercent = percent;
            }
    		system.debug('>> SO Memo >>'+memo);
            return memo;
    
        } catch (Exception e) {
            System.debug('>> generateMemoForSalesOrder >> ERROR >> ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
    }
    
    // Process sales order lines first
    public class PostSalesOrderLinesQueueable implements Queueable {
        private Set<Id> itemIds;
        private Set<Id> sponsorItemIds;
        private Map<Id, s7e__Item__c> newItemsMap;
        private Map<Id, s7e__Item__c> oldItemsMap;
        private Map<Id, String> recordTypeMap;
        private Map<Id, s7e__Show__c> showMap;
        private Set<Id> salesOrderIds = new Set<Id>();
        private Map<Id, SObject> sOIdToShowMap = new Map<Id, SObject>();
        private Map<Id, Boolean> salesOrderPostedMap = new Map<Id, Boolean>();
        private Map<Id, DataWrapper> itemToDataWrapperMap = new Map<Id, DataWrapper>();
    
        // Constructor
        public PostSalesOrderLinesQueueable(
            Set<Id> itemIds,
            Set<Id> SponsorItemIds,
            Map<Id, s7e__Item__c> newItemsMap,
            Map<Id, s7e__Item__c> oldItemsMap,
            Map<Id, String> recordTypeMap,
            Map<Id, s7e__Show__c> showMap
        ) {
            this.itemIds = itemIds;
            this.sponsorItemIds = SponsorItemIds;
            this.newItemsMap = newItemsMap;
            this.oldItemsMap = oldItemsMap;
            this.recordTypeMap = recordTypeMap;
            this.showMap = showMap;
            
            Set<Id> allItemIds = new Set<Id>();
            if(itemIds != null){
                allItemIds.addAll(itemIds);
            }
            if(sponsorItemIds != null){
                allItemIds.addAll(sponsorItemIds);
            }

            // Process data to extract sales order information
            this.itemToDataWrapperMap = generateItemFontevaDataWrapper(allItemIds, newItemsMap, oldItemsMap, recordTypeMap);
    
            if (itemToDataWrapperMap != null && !itemToDataWrapperMap.isEmpty()) {
                for (Id itemId : allItemIds) {
                    if (itemToDataWrapperMap.containsKey(itemId)) {
                        DataWrapper wrapper = itemToDataWrapperMap.get(itemId);
    
                        if (wrapper != null && wrapper.salesOrder != null && wrapper.showRecord != null) {
                            Object soIdObj = wrapper.salesOrder.get('Id');
                           
                            if (soIdObj != null) {
                                String salesOrderId = String.valueOf(soIdObj);
    
                                if (!String.isBlank(salesOrderId)) {
                                    // Only add if not already present
                                    if (!this.salesOrderIds.contains(salesOrderId)) {
                                        this.salesOrderIds.add(salesOrderId);
                                    }
    
                                    if (!this.salesOrderPostedMap.containsKey(salesOrderId)) {
                                        this.salesOrderPostedMap.put(salesOrderId, wrapper.isSalesOrderPosted);
                                    }
    
                                    if (!this.sOIdToShowMap.containsKey(salesOrderId)) {
                                        this.sOIdToShowMap.put(salesOrderId, wrapper.showRecord);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    
        // Execute method - now processes sales order lines first
        public void execute(QueueableContext context) {
            try {
                handlePostSalesOrderLines(salesOrderIds, sOIdToShowMap, salesOrderPostedMap);
            } catch (Exception e) {
                logError('>> PostSalesOrderLinesQueueable >> ERROR >> ' + e.getMessage() + '\n' + e.getStackTraceString());
                throw new AuraHandledException('>> PostSalesOrderLinesQueueable >> ERROR >> ' + e.getMessage());
            } finally {
                //handlePostSalesOrders(salesOrderIds, sOIdToShowMap, salesOrderPostedMap);
            }
        }
    }
    
    // Process sales order lines
    private static void handlePostSalesOrderLines(Set<Id> salesOrderIds, Map<Id, SObject> showMap, Map<Id, Boolean> salesOrderPostedMap) {
        if (salesOrderIds != null && !salesOrderIds.isEmpty()) {
            // Query line items
            String query = 'SELECT Id, Name, OrderApi__Sales_Order__c, OrderApi__Is_Posted__c, OrderApi__Line_Description__c, OrderApi__Entity__c, ' +
                           'OrderApi__Is_Line_Posted__c, OrderApi__Item__c, OrderApi__Credit_Note__r.OrderApi__Is_Posted__c, OrderApi__Item__r.Name ' +
                           'FROM OrderApi__Sales_Order_Line__c ' +
                           'WHERE OrderApi__Sales_Order__c IN :salesOrderIds';
            
            List<OrderApi__Sales_Order_Line__c> salesOrderLines = Database.query(query);
    
            
            System.debug('>> handlePostSalesOrderLines >> Found ' + salesOrderLines.size() + ' SOL items');
            
            List<OrderApi__Sales_Order_Line__c> salesOrderLinesToUpdate = new List<OrderApi__Sales_Order_Line__c>();
            
            // Process line items
            for (OrderApi__Sales_Order_Line__c sol : salesOrderLines) {
                if (!sol.OrderApi__Is_Line_Posted__c) {
                    OrderApi__Sales_Order_Line__c solUpdate = new OrderApi__Sales_Order_Line__c();
                    solUpdate.Id = sol.Id;
                    solUpdate.OrderApi__Is_Line_Posted__c = true;
                    
                    salesOrderLinesToUpdate.add(solUpdate);
                }
            }

            // Save updates
            if (!salesOrderLinesToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(salesOrderLinesToUpdate, true);
                Integer successCount = 0;
    
                for (Database.SaveResult res : results) {
                    if (res.isSuccess()) {
                        successCount++;
                    } else {
                        logError('>> handlePostSalesOrderLines >> SOL Update Error >> ' + res.getErrors());
                    }
                }
    
                System.debug('>> handlePostSalesOrderLines >> Successfully updated ' + successCount + ' SOLs');
            } else {
                System.debug('>> handlePostSalesOrderLines >> No SOLs to update');
            }
            handlePostSalesOrders(salesOrderIds, showMap, salesOrderPostedMap);
        }
    }
    
    // Process sales orders
    private static void handlePostSalesOrders(Set<Id> salesOrderIds, Map<Id, SObject> showMap, Map<Id, Boolean> salesOrderPostedStatus) {
        // Query sales orders
        Map<Id, SObject> salesOrdersMap = new Map<Id, SObject>();
        for (SObject so : [
            SELECT Id, Name, OrderApi__Is_Closed__c, OrderApi__Payment_Terms__c, OrderApi__Balance_Due__c, 
                   OrderApi__Payment_Terms__r.OrderApi__Display_Message__c,
                   OrderApi__Is_Posted__c, OrderApi__Memo__c, OrderApi__Overall_Total__c
            FROM OrderApi__Sales_Order__c
            WHERE Id IN :salesOrderIds
        ]) {
            salesOrdersMap.put(so.Id, so);
            System.debug('>> handlePostSalesOrders >> Found SO >> ' + so.get('Name'));
        }
    
        List<SObject> salesOrdersToUpdate = new List<SObject>();
        
        // Prepare updates
        for (Id soId : salesOrderIds) {
            if (!salesOrdersMap.containsKey(soId)) {
                System.debug('>> handlePostSalesOrders >> SO not found >> ' + soId);
                continue;
            }
    
            SObject soUpdate = Schema.getGlobalDescribe()
                .get(PACKAGE_OBJECTS.get('SALES_ORDER'))
                .newSObject(soId);
            
            Decimal total = (Decimal) salesOrdersMap.get(soId).get('OrderApi__Balance_Due__c');
            SObject show = showMap.get(soId);
            String memo = generateMemoForSalesOrder(total, System.today(), show);
            
            if(salesOrderPostedStatus.get(soId)) {
                soUpdate.put('OrderApi__Memo__c', memo);
            } else {
                soUpdate.put('OrderApi__Is_Posted__c', true);
                soUpdate.put('OrderApi__Is_Closed__c', true);
                soUpdate.put('OrderApi__Memo__c', memo);
            }
            
            salesOrdersToUpdate.add(soUpdate);
        }
    
        // Save updates
        if (!salesOrdersToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(salesOrdersToUpdate, false);
            Integer successCount = 0;
    
            for (Database.SaveResult res : results) {
                if (res.isSuccess()) {
                    successCount++;
                } else {
                    logError('>> handlePostSalesOrders >> Update Error >> ' + res.getErrors());
                }
            }
    
            System.debug('>> handlePostSalesOrders >> Successfully updated ' + successCount + ' SOs');
        } else {
            System.debug('>> handlePostSalesOrders >> No SOs to update');
        }
    }
    
    @testVisible
    private static void handleAssign(Set<Id> assignItemIds, Map<Id, DataWrapper> itemToDataWrapperMap) {
        // Validate input parameters
        if (assignItemIds == null || assignItemIds.isEmpty() || itemToDataWrapperMap == null) {
            System.debug('>> handleAssign >> END : No action required: Empty input data');
            return;
        }
        
        try {
            // Collection maps for record tracking
            Map<Id, SObject> pendingLineItems = new Map<Id, SObject>();
            Map<Id, SObject> pendingCornerLineItems = new Map<Id, SObject>();
            Map<Id, Id> itemToSalesOrderMap = new Map<Id, Id>();
            Map<Id, Id> newOpportunitiesWithCorners = new Map<Id, Id>();
            Map<Id, Id> newOpportunitiesWithoutCorners = new Map<Id, Id>();
            Map<Id, SObject> SOIdShowMap = new Map<Id, SObject>();
            //List<s7e__Item__c> itemsToUpdate = new List<s7e__Item__c>();
            Map<Id, Decimal> salesOrderToTotalPriceMap = new Map<Id, Decimal>();
            Map<Id, SObject> pendingFeeLineItems = new Map<Id, SObject>();
            List<SObject> newSOLIToInsert = new List<SObject>();
            
            System.debug('>> handleAssign >> Processing ' + assignItemIds.size() + ' items for assignment');
            
            // Step 1: Process each item for assignment
            for (Id itemId : assignItemIds) {
                DataWrapper itemData = itemToDataWrapperMap.get(itemId);
                
                // Skip items with incomplete data
                if (itemData == null || itemData.item == null || itemData.account == null) {
                    System.debug('>> handleAssign >> Skipping item ' + itemId + ': Incomplete data');
                    continue;
                }
                
                // Determine the sales order to use
                Id salesOrderId = null;
                if (itemData.salesOrder != null) {
                    salesOrderId = (Id)itemData.salesOrder.get('Id');
                    System.debug('>> handleAssign >> Using existing sales order ' + salesOrderId + ' for item ' + itemId);
                } else if (itemData.SOIdOnOpportunity != null) {
                    salesOrderId = itemData.SOIdOnOpportunity;
                    System.debug('>> handleAssign >> Using opportunity\'s sales order ' + salesOrderId + ' for item ' + itemId);
                } else {
                    System.debug('>> handleAssign >> No sales order found for item ' + itemId + ' , hence creating one.');
                    SObject salesOrderRecord = createSalesOrderRecord(itemData);
                    try{
                        insert salesOrderRecord;
                        System.debug('>> handleAssign >> Sales order cerated successfully : '+salesOrderRecord.Id);
                        salesOrderId = salesOrderRecord.Id;
                        Opportunity opp = new Opportunity();
                        opp.Id = itemData.Opportunity;
                        opp.s7e__Ext_Sales_Order_ID__c = salesOrderId;
                        update opp;
                    } catch(Exception e){
                        system.debug('>> handleAssign >> Error creating sales order for item : '+itemId + ' EXCEPTION : '+e);
                    }
                }
                
                // Add to the appropriate maps
                itemToSalesOrderMap.put(itemId, salesOrderId);
                SOIdShowMap.put(salesOrderId, itemData.showRecord);
                
                // For sales orders, determine if the opportunity has corners
                boolean hasCorners = (itemData.numberOfOpenCorners != null && itemData.numberOfOpenCorners > 0 && itemData.item.get('scyc_Is_Flat_Rate__c')!=true);
                if (hasCorners && itemData.opportunity != null) {
                    newOpportunitiesWithCorners.put(itemData.opportunity, salesOrderId);
                } else if (itemData.opportunity != null) {
                    newOpportunitiesWithoutCorners.put(itemData.opportunity, salesOrderId);
                }
                
                // Create line items
                SObject mainLineItem = createMainLineItem(itemData, salesOrderId);
                Decimal mainSubtotal = calculateLineItemSubtotal(mainLineItem); // Processing Fee
                pendingLineItems.put(itemId, mainLineItem);
                
                Decimal totalPrice = mainSubtotal; // Processing Fee
                // Create corner line item if needed
                if (hasCorners && itemData.cornerItem != null) {
                    SObject cornerLineItem = createCornerLineItem(itemData, salesOrderId);
                    totalPrice += calculateLineItemSubtotal(cornerLineItem); // Processing Fee
                    pendingCornerLineItems.put(itemId, cornerLineItem);
                    System.debug('>> handleAssign >> Prepared corner line item for item ' + itemId + ' with ' + itemData.numberOfOpenCorners + ' corners');
                }
                
                itemData.totalLineItemPrice = totalPrice; // Processing Fee
    			salesOrderToTotalPriceMap.put(salesOrderId, totalPrice); // Processing Fee
                
                SObject feeLineItem = createProcessingFeeLineItem(itemData, salesOrderId);
                if (feeLineItem != null) {
                    pendingFeeLineItems.put(itemId, feeLineItem);
                    System.debug('>> handleAssign >> Prepared processing fee line item for item ' + itemId);
                }
                
            }
            
            // Step 2: Process Line Items
            if (!pendingLineItems.isEmpty() && (!pendingLineItems.isEmpty() || !pendingCornerLineItems.isEmpty() || !pendingFeeLineItems.isEmpty())) {
                System.debug('>> processNewSalesOrder >> Inserting ' + pendingLineItems.size() + ' main line items');
                newSOLIToInsert.addAll(pendingLineItems.values());
                if (!pendingCornerLineItems.isEmpty()) {
                    System.debug('>> processNewSalesOrder >> Inserting ' + pendingCornerLineItems.size() + ' corner line items');
                    newSOLIToInsert.addAll(pendingCornerLineItems.values());
                }
                if (!pendingFeeLineItems.isEmpty()) {
                    System.debug('>> processNewSalesOrder >> Inserting ' + pendingFeeLineItems.size() + ' prcessing fee line items');
                    newSOLIToInsert.addAll(pendingFeeLineItems.values());
                }
                List<Database.SaveResult> lineItemResults = Database.insert(newSOLIToInsert, false);
                List<s7e__Item__c> itemsToUpdate = new List<s7e__Item__c>();
                
                // Process results and prepare item updates
                Integer index = 0;
                for (Id itemId : pendingLineItems.keySet()) {
                    Database.SaveResult result = lineItemResults[index++];
                    
                    if (result.isSuccess()) {
                        Id lineItemId = result.getId();
                        itemsToUpdate.add(new s7e__Item__c(Id = itemId, s7e__Ext_Line_Item_ID__c = lineItemId));
                        System.debug('>> processNewSalesOrder >> Successfully created line item ' + lineItemId + ' for item ' + itemId);
                    } else {
                        List<String> errorMessages = new List<String>();
                        for (Database.Error err : result.getErrors()) {
                            errorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                        }
                        System.debug('>> processNewSalesOrder >> Failed to create line item for item ' + itemId + ': ' + String.join(errorMessages, '; '));
                    }
                }
                
                /*if (!pendingFeeLineItems.isEmpty()) {
                    System.debug('>> processNewSalesOrder >> Inserting ' + pendingFeeLineItems.size() + ' processing fee line items');
                    List<Database.SaveResult> lineItemResultsPf = Database.insert(pendingFeeLineItems.values(), false);
                    
                    // Process results and prepare item updates
                    Integer indexPf = 0;
                    for (Id itemId : pendingFeeLineItems.keySet()) {
                        Database.SaveResult result = lineItemResultsPf[indexPf++];
                        
                        if (result.isSuccess()) {
                            Id lineItemId = result.getId();
                            System.debug('>> processNewSalesOrder >> Successfully created Processing Fee line item ' + lineItemId + ' for item ' + itemId);
                        } else {
                            List<String> errorMessages = new List<String>();
                            for (Database.Error err : result.getErrors()) {
                                errorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                            }
                            System.debug('>> processNewSalesOrder >> Failed to create Processing Fee line item for item ' + itemId + ': ' + String.join(errorMessages, '; '));
                        }
                    }
                }*/
                
                // Step 8: update items with line item IDs
                if (!itemsToUpdate.isEmpty()) {
                    System.debug('>> processNewSalesOrder >> updating ' + itemsToUpdate.size() + ' items with line item IDs');
                    System.enqueueJob(new UpdateLineItemIdQueueable(itemsToUpdate));
                }
            }
            
        } catch (Exception e) {
            logError('>> handleAssign >> ERROR >> ' + e.getMessage() + '\nStack trace: ' + e.getStackTraceString());
        }
    }
    
    // Creates a new Sales Order SObject with fields populated from the data wrapper
    @testVisible
    private static SObject createSalesOrderRecord(DataWrapper itemData) {
        SObject salesOrder = Schema.getGlobalDescribe().get(PACKAGE_OBJECTS.get('SALES_ORDER')).newSObject();
        // Required fields
        salesOrder.put('OrderApi__Account__c', itemData.account);
        salesOrder.put('OrderApi__Business_Group__c', itemData.businessGroup);
        salesOrder.put('OrderApi__Schedule_Type__c', 'Simple Invoice');
        salesOrder.put('OrderApi__Posting_Entity__c', 'Invoice');
        salesOrder.put('OrderApi__Calculate_Billing_Details__c', true);
        salesOrder.put('OrderApi__Calculate_Shipping_Details__c', true);  
        if (itemData.opportunity != null) {
            salesOrder.put('Opportunity__c', itemData.opportunity);
        }
        if (itemData.contact != null) {
            salesOrder.put('OrderApi__Contact__c', itemData.contact);
        }
        return salesOrder;
    }
    
    // Creates a main line item for a sales order
    @testVisible
    private static SObject createMainLineItem(DataWrapper itemData, Id salesOrderId) {
        SObject lineItem = Schema.getGlobalDescribe().get(PACKAGE_OBJECTS.get('SALES_ORDER_LINE')).newSObject();
        // Required fields
        lineItem.put('OrderApi__Sales_Order__c', salesOrderId);
        lineItem.put('OrderApi__Item__c', itemData.item.get('Id'));
        //SH-1024 check memebership pricing before populating rate
        if((Boolean)itemData.showRecord.get('s7e__Enable_Membership_Pricing__c')){
            Decimal price=0;
            System.Callable callableSvc = new SubscriberCallableService();
			Map<String, Object> args = new Map<String, Object>{
                'accountId' => (String)itemData.account,
                'itemId'    =>  itemData.newItemRecord.s7e__Ex_ProductId__c,
                'quantity'  => (Integer)itemData.quantity
            };
            price = (Decimal) callableSvc.call('getPrice', args);
            lineItem.put('OrderApi__Sale_Price__c', price);
        } else {
        	lineItem.put('OrderApi__Sale_Price__c', itemData.item.get('OrderApi__Price__c'));    
        }
        //lineItem.put('OrderApi__Sale_Price__c', itemData.item.get('OrderApi__Price__c'));
        //SH-1204 Check if item has flat rate
        //lineItem.put('OrderApi__Quantity__c', itemData.quantity);
        if (itemData.item.get('scyc_Is_Flat_Rate__c') == true) {
            lineItem.put('OrderApi__Quantity__c', 1);
        } else {
            lineItem.put('OrderApi__Quantity__c', itemData.quantity);
        }
        //
        lineItem.put('OrderApi__Account__c', itemData.account);
        lineItem.put('OrderApi__Entity__c', 'Account');
        lineItem.put('OrderApi__Line_Description__c', itemData.BoothDescription);
        if (itemData.salesOrder != null && itemData.isSalesOrderPosted) {
            lineItem.put('OrderApi__Is_Adjustment__c', true);
            lineItem.put('OrderApi__Is_Line_Posted__c', true);
        }
        if (itemData.contact != null) {
            lineItem.put('OrderApi__Contact__c', itemData.contact);
        }
        if (itemData.itemClass != null && itemData.itemClass.get('Id') != null) {
            lineItem.put('OrderApi__Item_Class__c', itemData.itemClass.get('Id'));
        }
        Decimal price = (Decimal)lineItem.get('OrderApi__Sale_Price__c') != null ? (Decimal)lineItem.get('OrderApi__Sale_Price__c') : 0;
        Decimal quantity = (Decimal)lineItem.get('OrderApi__Quantity__c') != null ? (Decimal)lineItem.get('OrderApi__Quantity__c') : 0;
       Decimal totalFeeAmount= price * quantity;
         // Populating Overall Total on SOLI
        lineItem.put('OrderApi__Overall_Total__c',totalFeeAmount);
        // Populating Balance Due on SOLI
        lineItem.put('OrderApi__Balance_Due__c',totalFeeAmount);
        return lineItem;
    }
    
    // Creates a corner line item for a sales order
    @testVisible
    private static SObject createCornerLineItem(DataWrapper itemData, Id salesOrderId) {
        SObject cornerLineItem = Schema.getGlobalDescribe().get(PACKAGE_OBJECTS.get('SALES_ORDER_LINE')).newSObject();
        // Required fields
        cornerLineItem.put('OrderApi__Sales_Order__c', salesOrderId);
        cornerLineItem.put('OrderApi__Item__c', itemData.cornerItem.get('Id'));
        cornerLineItem.put('OrderApi__Sale_Price__c', itemData.cornerItem.get('OrderApi__Price__c'));
        cornerLineItem.put('OrderApi__Quantity__c', itemData.numberOfOpenCorners);
        cornerLineItem.put('OrderApi__Account__c', itemData.account);
        cornerLineItem.put('OrderApi__Entity__c', 'Account');
        if (itemData.contact != null) {
            cornerLineItem.put('OrderApi__Contact__c', itemData.contact);
        }
        if (itemData.salesOrder != null && itemData.isSalesOrderPosted) {
            cornerLineItem.put('OrderApi__Is_Adjustment__c', true);
            cornerLineItem.put('OrderApi__Is_Line_Posted__c', true);
        }
        if (itemData.cornerItem.get('OrderApi__Item_Class__c') != null) {
            cornerLineItem.put('OrderApi__Item_Class__c', itemData.cornerItem.get('OrderApi__Item_Class__c'));
        }
        Decimal price = (Decimal)cornerLineItem.get('OrderApi__Sale_Price__c') != null ? (Decimal)cornerLineItem.get('OrderApi__Sale_Price__c') : 0;
        Decimal quantity = (Decimal)cornerLineItem.get('OrderApi__Quantity__c') != null ? (Decimal)cornerLineItem.get('OrderApi__Quantity__c') : 0;
       Decimal totalFeeAmount= price * quantity;
         // Populating Overall Total on SOLI
        cornerLineItem.put('OrderApi__Overall_Total__c',totalFeeAmount);
        // Populating Balance Due on SOLI
        cornerLineItem.put('OrderApi__Balance_Due__c',totalFeeAmount);
        
        return cornerLineItem;
    }
    
    // Creates a processing fee line item for a sales order
    @testVisible
    private static SObject createProcessingFeeLineItem(DataWrapper itemData, Id salesOrderId) {
        if (itemData == null || itemData.processingFeeItem == null || itemData.totalLineItemPrice == null || 
            itemData.showRecord == null || itemData.processingFeePercentage == null) {
            System.debug('>> createProcessingFeeLineItem >> Missing required data for processing fee calculation');
            return null;
        }
        
        // Add this check:
        Boolean addProcessingFee = false;
        try {
            addProcessingFee = (Boolean)itemData.showRecord.get('scyc_Add_Processing_Fee__c');
        } catch (Exception e) {
            System.debug('>> createProcessingFeeLineItem >> Error accessing scyc_Add_Processing_Fee__c: ' + e.getMessage());
            return null;
        }
        
        if (!addProcessingFee) {
            System.debug('>> createProcessingFeeLineItem >> Processing fee not enabled for show');
            return null;
        }
        
        SObject feeLineItem = Schema.getGlobalDescribe().get(PACKAGE_OBJECTS.get('SALES_ORDER_LINE')).newSObject();
        
        // Calculate the total fee amount
        Decimal totalFeeAmount = itemData.totalLineItemPrice * itemData.processingFeePercentage;
        
        System.debug('>> createProcessingFeeLineItem >> BEFORE RECORD CREATION:');
        System.debug('   totalLineItemPrice: ' + itemData.totalLineItemPrice);
        System.debug('   processingFeePercentage: ' + itemData.processingFeePercentage);
        System.debug('   calculated totalFeeAmount: ' + totalFeeAmount);
        System.debug('   processingFeeItem base price: ' + itemData.processingFeeItem.get('OrderApi__Price__c'));
        
        // CRITICAL FIX: Set the calculated total as the unit price with quantity 1
        // This ensures the line total equals our calculated fee amount
        feeLineItem.put('OrderApi__Sales_Order__c', salesOrderId);
        feeLineItem.put('OrderApi__Item__c', itemData.processingFeeItem.get('Id'));
        //feeLineItem.put('OrderApi__Sale_Price__c', totalFeeAmount); // Use calculated total, not base price
        feeLineItem.put('OrderApi__Sale_Price__c', itemData.processingFeePercentage);
        //feeLineItem.put('OrderApi__Quantity__c', 1);
        //SH-1204
        if(itemData.item.get('scyc_Is_Flat_Rate__c') == true){
            Decimal price=0;
            System.Callable callableSvc = new SubscriberCallableService();
			Map<String, Object> args = new Map<String, Object>{
                'accountId' => (String)itemData.account,
                'itemId'    =>  itemData.newItemRecord.s7e__Ex_ProductId__c,
                'quantity'  => (Integer)itemData.quantity
            };
            price = (Decimal) callableSvc.call('getPrice', args);
           	feeLineItem.put('OrderApi__Quantity__c', price); 
        } else {
 	       feeLineItem.put('OrderApi__Quantity__c', itemData.totalLineItemPrice);
        }
        //feeLineItem.put('OrderApi__Quantity__c', itemData.totalLineItemPrice);
        //feeLineItem.put('OrderApi__Quantity__c', lineItemQuantity);
        //feeLineItem.put('OrderApi__Quantity__c', quantity);
        feeLineItem.put('OrderApi__Account__c', itemData.account);
        feeLineItem.put('OrderApi__Entity__c', 'Account');
        feeLineItem.put('OrderApi__Line_Description__c', 'Processing Fee (' + (itemData.processingFeePercentage * 100).setScale(1) + '%) for ' + itemData.showRecord.get('Name'));
        
        // Populating Overall Total on SOLI
        feeLineItem.put('OrderApi__Overall_Total__c',totalFeeAmount);
        // Populating Balance Due on SOLI
        feeLineItem.put('OrderApi__Balance_Due__c',totalFeeAmount);
        
        // IMPORTANT: Try setting this to prevent Fonteva from recalculating the price
        feeLineItem.put('OrderApi__Is_Line_Posted__c', false); // Change this from true to false initially
        
        // Optional: If Fonteva has a field to override price calculation, use it
        // feeLineItem.put('OrderApi__Override_Price__c', true); // Check if this field exists
        
        //Adjustment checkbox for booth move operations
        if (itemData.salesOrder != null && itemData.isSalesOrderPosted) {
            feeLineItem.put('OrderApi__Is_Adjustment__c', true);
            feeLineItem.put('OrderApi__Is_Line_Posted__c', true);
        }
        
        if (itemData.contact != null) {
            feeLineItem.put('OrderApi__Contact__c', itemData.contact);
        }
        if (itemData.processingFeeItem.get('OrderApi__Item_Class__c') != null) {
            feeLineItem.put('OrderApi__Item_Class__c', itemData.processingFeeItem.get('OrderApi__Item_Class__c'));
        }
        
        System.debug('>> createProcessingFeeLineItem >> RECORD TO BE INSERTED:');
        System.debug('   OrderApi__Sale_Price__c: ' + feeLineItem.get('OrderApi__Sale_Price__c'));
        System.debug('   OrderApi__Quantity__c: ' + feeLineItem.get('OrderApi__Quantity__c'));
        
        return feeLineItem;
    }
    
    // Queueable class to asynchronously update Item__c records with their Line Item IDs
    public class UpdateLineItemIdQueueable implements Queueable {
        private final List<s7e__Item__c> itemsToUpdate;
        
        // Constructor to initialize the queueable job with items to update
        public UpdateLineItemIdQueueable(List<s7e__Item__c> items) {
            this.itemsToUpdate = items;
        }
        
        // Executes the queueable job to update the Item__c records
        public void execute(QueueableContext context) {
            System.debug('>> UpdateItemLineItemsQueueable >> START: Executing queueable job for ' + (itemsToUpdate != null ? itemsToUpdate.size() : 0) + ' items');
            try {
                if (itemsToUpdate != null && !itemsToUpdate.isEmpty()) {
                    System.debug('>> UpdateItemLineItemsQueueable >> Updating ' + itemsToUpdate.size() + ' items');
                    List<Database.SaveResult> results = Database.update(itemsToUpdate, false);
                    
                    // Log success/failure for each record update
                    Integer successCount = 0;
                    for (Database.SaveResult result : results) {
                        if (result.isSuccess()) {
                            successCount++;
                        } else {
                            logError('>> UpdateItemLineItemsQueueable >> ERROR >> Failed to update item: ' + result.getErrors());
                        }
                    }
                    
                    System.debug('>> UpdateItemLineItemsQueueable >> Successfully updated ' + successCount + ' of ' + results.size() + ' items');
                } else {
                    System.debug('>> UpdateItemLineItemsQueueable >> No items to update');
                }
            } catch (Exception e) {
                logError('>> ERROR >> : ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
        
    }
    
    @testVisible
    private static void handleVacate(Set<Id> vacateItemIds, Map<Id, DataWrapper> itemToDataWrapperMap) {
        if (vacateItemIds == null || vacateItemIds.isEmpty() || itemToDataWrapperMap == null) {
            System.debug('>> handleVacate >> END : No action required: Empty input data');
            return;
        }
       
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> lineItemIds = new Set<Id>();
            List<s7e__Item__c> itemsToUpdate = new List<s7e__Item__c>();
            Map<Id, List<SObject>> salesOrderToLineItemsMap = new Map<Id, List<SObject>>();
            Map<Id, Boolean> salesOrderIsPostedMap = new Map<Id, Boolean>();
            Map<Id, Id> lineItemToSalesOrderMap = new Map<Id, Id>();
            Set<Id> affectedSalesOrderIds = new Set<Id>();
            
            // NEW: Cancellation fee lines
            List<SObject> cancellationFeeLineItemsToInsert = new List<SObject>();
           
            System.debug('>> handleVacate >> Processing ' + vacateItemIds.size() + ' items for vacation');
           
            // Step 1: Gather main line item IDs
            for (Id itemId : vacateItemIds) {
                DataWrapper itemData = itemToDataWrapperMap.get(itemId);
                if (itemData?.oldItemRecord == null) continue;
               
                Object extId = itemData.oldItemRecord.get('s7e__Ext_Line_Item_ID__c');
                if (extId != null && String.isNotBlank(String.valueOf(extId))) {
                    lineItemIds.add(String.valueOf(extId));
                }
            }
    
            // Step 2: Fetch main line items
            Map<Id, SObject> existingLineItems = new Map<Id, SObject>();
            if (!lineItemIds.isEmpty()) {
                String query = 'SELECT Id, OrderApi__Line_Description__c, OrderApi__Sales_Order__c, OrderApi__Item__c, OrderApi__Item_Class__c, OrderApi__Is_Posted__c, OrderApi__Entity__c, OrderApi__Account__c, OrderApi__Contact__c, OrderApi__Sale_Price__c, ' +
                              'OrderApi__Quantity__c, OrderApi__Subtotal__c FROM ' +
                              PACKAGE_OBJECTS.get('SALES_ORDER_LINE') + ' WHERE Id IN :lineItemIds';
    
                for (SObject rec : Database.query(query)) {
                    Id lineId = rec.Id;
                    Id soId = (Id)rec.get('OrderApi__Sales_Order__c');
                    existingLineItems.put(lineId, rec);
                    lineItemToSalesOrderMap.put(lineId, soId);
                    affectedSalesOrderIds.add(soId);
                    salesOrderIsPostedMap.put(soId, (Boolean)rec.get('OrderApi__Is_Posted__c'));
                }
            }
           
            // Step 3: Corner lines
            Map<Id, SObject> cornerLineItemsMap = new Map<Id, SObject>();
            Map<Id, Id> lineItemToCornerLineItemMap = new Map<Id, Id>();
            if (!affectedSalesOrderIds.isEmpty()) {
                for (SObject cl : Database.query(
                    'SELECT Id, OrderApi__Line_Description__c, OrderApi__Subtotal__c, OrderApi__Sales_Order__c, OrderApi__Entity__c, OrderApi__Account__c, OrderApi__Is_Posted__c, OrderApi__Contact__c, OrderApi__Quantity__c, OrderApi__Sale_Price__c, OrderApi__Item__c, OrderApi__Item_Class__c ' +
                                      'FROM ' + PACKAGE_OBJECTS.get('SALES_ORDER_LINE') + ' ' +
                                      'WHERE OrderApi__Sales_Order__c IN :affectedSalesOrderIds ' +
                                      'AND OrderApi__Item__r.OrderApi__Item_Class__r.Name = \'Exhibit Space\' ' +
                    'AND OrderApi__Item__r.Name LIKE \'%Corner%\''))
                {
                    cornerLineItemsMap.put(cl.Id, cl);
                    // Simple matching logic – adjust if needed
                    for (Id itemId : vacateItemIds) {
                        DataWrapper dw = itemToDataWrapperMap.get(itemId);
                        if (dw?.oldItemRecord == null) continue;
                        Id mainId = (Id)dw.oldItemRecord.get('s7e__Ext_Line_Item_ID__c');
                        if (mainId != null && !lineItemToCornerLineItemMap.containsKey(mainId) &&
                            dw.oldItemRecord.get('s7e__No_of_Open_Corners__c') != null &&
                            cl.get('OrderApi__Quantity__c') == (Decimal)dw.oldItemRecord.get('s7e__No_of_Open_Corners__c')) {
                            lineItemToCornerLineItemMap.put(mainId, cl.Id);
                            break;
                        }
                    }
                }
            }
           
            // Step 3.5: Processing fee lines
            Map<Id, SObject> procesingFeeLineItemsMap = new Map<Id, SObject>();
            Map<Id, Id> lineItemToProcesingFeeLineItemMap = new Map<Id, Id>();
            if (!affectedSalesOrderIds.isEmpty()) {
                for (SObject pf : Database.query(
                    'SELECT Id, OrderApi__Sales_Order__c, OrderApi__Subtotal__c, OrderApi__Item__c, OrderApi__Item_Class__c ' +
                                      'FROM ' + PACKAGE_OBJECTS.get('SALES_ORDER_LINE') + ' ' +
                                      'WHERE OrderApi__Sales_Order__c IN :affectedSalesOrderIds ' +
                                      'AND OrderApi__Item__r.OrderApi__Item_Class__r.Name = \'Fees\' ' +
                    'AND OrderApi__Item__r.Name LIKE \'%Processing Fee%\''))
                {
                    procesingFeeLineItemsMap.put(pf.Id, pf);
                    for (Id itemId : vacateItemIds) {
                        DataWrapper dw = itemToDataWrapperMap.get(itemId);
                        if (dw?.oldItemRecord == null || dw?.showRecord == null) continue;
                        Id mainId = (Id)dw.oldItemRecord.get('s7e__Ext_Line_Item_ID__c');
                        if (mainId != null && !lineItemToProcesingFeeLineItemMap.containsKey(mainId) &&
                            (Boolean)dw.showRecord.get('scyc_Add_Processing_Fee__c') == true &&
                            (Decimal)dw.salesOrder.get('OrderApi__Amount_Paid__c') <= 0) {
                            lineItemToProcesingFeeLineItemMap.put(mainId, pf.Id);
                            break;
                        }
                    }
                }
            }
    
            // Collections for adjustments
            Map<Id, SObject> creditNotesToCreate = new Map<Id, SObject>();
            Map<Id, Id> salesOrderToCreditNoteMap = new Map<Id, Id>();
            List<SObject> allAdjustmentLines = new List<SObject>();
            List<SObject> lineItemsToDelete = new List<SObject>();
           
            // Main processing loop
            for (Id itemId : vacateItemIds) {
                DataWrapper itemData = itemToDataWrapperMap.get(itemId);
                if (itemData?.oldItemRecord == null || itemData?.salesOrder == null) continue;
               
                s7e__Item__c item = itemData.oldItemRecord;
                SObject salesOrder = itemData.salesOrder;
                Id salesOrderId = salesOrder.Id;
                Boolean isSalesOrderPosted = (Boolean)salesOrder.get('OrderApi__Is_Posted__c');
                Decimal amountPaid = (Decimal)salesOrder.get('OrderApi__Amount_Paid__c');
                Decimal cancellationPercent = (Decimal)itemData.showRecord.get('s7e__Current_Cancellation_Per__c');
                Boolean includeCancellationFee = (Boolean)itemData.newItemRecord.get('s7e__Include_Cancellation_Fee__c');
    
                // === CANCELLATION FEE – CORRECT CALCULATION ===
                if (includeCancellationFee && cancellationPercent > 0 && itemData.cancelFeeItem != null) {
                    Decimal totalCancellableAmount = 0.0;
                
                    // Main line
                    if (String.isNotBlank(item.s7e__Ext_Line_Item_ID__c)) {
                        SObject mainLine = existingLineItems.get(item.s7e__Ext_Line_Item_ID__c);
                        if (mainLine != null) {
                            Decimal p = (Decimal)mainLine.get('OrderApi__Sale_Price__c');
                            Decimal q = (Decimal)mainLine.get('OrderApi__Quantity__c');
                            if (p != null && q != null) totalCancellableAmount += p * q;
                        }
                    }
                
                    // Corner line
                    if (lineItemToCornerLineItemMap.containsKey(item.s7e__Ext_Line_Item_ID__c)) {
                        SObject corner = cornerLineItemsMap.get(lineItemToCornerLineItemMap.get(item.s7e__Ext_Line_Item_ID__c));
                        if (corner != null) {
                            Decimal p = (Decimal)corner.get('OrderApi__Sale_Price__c');
                            Decimal q = (Decimal)corner.get('OrderApi__Quantity__c');
                            if (p != null && q != null) totalCancellableAmount += p * q;
                            }
                        }
    
                    if (totalCancellableAmount > 0) {
                        Decimal fee = (totalCancellableAmount * cancellationPercent / 100).setScale(2, RoundingMode.HALF_UP);
                
                        SObject feeLine = Schema.getGlobalDescribe().get(PACKAGE_OBJECTS.get('SALES_ORDER_LINE')).newSObject();
                        feeLine.put('OrderApi__Sales_Order__c', salesOrderId);
                        feeLine.put('OrderApi__Item__c', itemData.cancelFeeItem.get('Id'));
                        feeLine.put('OrderApi__Sale_Price__c', fee);
                        feeLine.put('OrderApi__Quantity__c', 1);
                        feeLine.put('OrderApi__Price_Override__c', true);
                        feeLine.put('OrderApi__Account__c', itemData.account);
                        feeLine.put('OrderApi__Entity__c', 'Account');
                        feeLine.put('OrderApi__Line_Description__c',
                            'Cancellation Fee (' + cancellationPercent.setScale(1) + '% of $' + totalCancellableAmount.setScale(2) + ') - ' +
                            (item.s7e__Booth_Number__c != null ? 'Booth ' + item.s7e__Booth_Number__c : 'Sponsorship Vacated'));
                
                        if (isSalesOrderPosted) {
                            feeLine.put('OrderApi__Is_Adjustment__c', true);
                            feeLine.put('OrderApi__Is_Line_Posted__c', true);
                        }
                        if (itemData.contact != null) feeLine.put('OrderApi__Contact__c', itemData.contact);
                        if (itemData.cancelFeeItem.get('OrderApi__Item_Class__c') != null)
                            feeLine.put('OrderApi__Item_Class__c', itemData.cancelFeeItem.get('OrderApi__Item_Class__c'));
    
                        feeLine.put('OrderApi__Overall_Total__c', fee);
                        feeLine.put('OrderApi__Balance_Due__c', fee);
                
                        cancellationFeeLineItemsToInsert.add(feeLine);
                    }
                }
                // === END CANCELLATION FEE ===
    
                // === NEGATIVE ADJUSTMENTS & DELETES ===
                if (String.isNotBlank(item.s7e__Ext_Line_Item_ID__c)) {
                    SObject mainLine = existingLineItems.get(item.s7e__Ext_Line_Item_ID__c);
                    if (mainLine != null && (Decimal)mainLine.get('OrderApi__Quantity__c') > 0) {
                        if (isSalesOrderPosted) {
                            processNegativeAdjustmentLine(0, (Decimal)mainLine.get('OrderApi__Quantity__c'), mainLine, itemData,
                                    creditNotesToCreate, salesOrderToCreditNoteMap, allAdjustmentLines);
                               
                            // Corner negative adjustment
                                if (lineItemToCornerLineItemMap.containsKey(item.s7e__Ext_Line_Item_ID__c)) {
                                SObject corner = cornerLineItemsMap.get(lineItemToCornerLineItemMap.get(item.s7e__Ext_Line_Item_ID__c));
                                if (corner != null) {
                                    processNegativeAdjustmentLine(0, (Decimal)corner.get('OrderApi__Quantity__c'), corner, itemData,
                                            creditNotesToCreate, salesOrderToCreditNoteMap, allAdjustmentLines);
                                    }
                                }
    
                            // PROCESSING FEE: NO NEGATIVE LINE EVER
                                if (lineItemToProcesingFeeLineItemMap.containsKey(item.s7e__Ext_Line_Item_ID__c)) {
                                SObject feeLine = procesingFeeLineItemsMap.get(lineItemToProcesingFeeLineItemMap.get(item.s7e__Ext_Line_Item_ID__c));
                                if (feeLine != null) {
                                        if (isSalesOrderPosted) {
                                        System.debug('>> Keeping processing fee (posted SO): ' + feeLine.Id);
                                        } else {
                                        lineItemsToDelete.add(feeLine);
                                        }
                                    }
                                }
                            } else {
                            lineItemsToDelete.add(mainLine);
                                if (lineItemToCornerLineItemMap.containsKey(item.s7e__Ext_Line_Item_ID__c)) {
                                    lineItemsToDelete.add(cornerLineItemsMap.get(lineItemToCornerLineItemMap.get(item.s7e__Ext_Line_Item_ID__c)));
                                }
                            // Also delete processing fee if unposted
                            if (lineItemToProcesingFeeLineItemMap.containsKey(item.s7e__Ext_Line_Item_ID__c)) {
                                SObject feeLine = procesingFeeLineItemsMap.get(lineItemToProcesingFeeLineItemMap.get(item.s7e__Ext_Line_Item_ID__c));
                                if (feeLine != null) lineItemsToDelete.add(feeLine);
                            }
                        }
                    }
                }
               
                itemsToUpdate.add(new s7e__Item__c(
                    Id = itemId,
                    s7e__Ext_Line_Item_ID__c = null,
                    s7e__Include_Cancellation_Fee__c = false
                ));
            }
    
            // Insert cancellation fee lines
            if (!cancellationFeeLineItemsToInsert.isEmpty()) {
                insert cancellationFeeLineItemsToInsert;
            }
    
            // Delete unposted lines
            if (!lineItemsToDelete.isEmpty()) {
                //delete lineItemsToDelete;
            }
           
            // Step 6: Insert credit notes
            if (!creditNotesToCreate.isEmpty()) {
                List<Database.SaveResult> creditNoteResults = Database.insert(creditNotesToCreate.values(), false);
                for (Integer i = 0; i < creditNoteResults.size(); i++) {
                    if (creditNoteResults[i].isSuccess()) {
                        Id salesOrderId = new List<Id>(creditNotesToCreate.keySet())[i];
                        salesOrderToCreditNoteMap.put(salesOrderId, creditNoteResults[i].getId());
                    } else {
                        String errors = '';
                        for (Database.Error err : creditNoteResults[i].getErrors()) {
                            errors += err.getMessage() + '; ';
                        }
                        logError('>> handleVacate >> Failed to create credit note: ' + errors);
                    }
                }
            }
           
            // Step 7: Update adjustment lines with credit note IDs
            for (SObject adjLine : allAdjustmentLines) {
                Id salesOrderId = (Id)adjLine.get('OrderApi__Sales_Order__c');
                if (salesOrderToCreditNoteMap.containsKey(salesOrderId)) {
                    adjLine.put('OrderApi__Credit_Note__c', salesOrderToCreditNoteMap.get(salesOrderId));
                }
            }
           
            // Step 8: Insert adjustment line items
            if (!allAdjustmentLines.isEmpty()) {
                List<Database.SaveResult> adjustmentResults = Database.insert(allAdjustmentLines, false);
                for (Integer i = 0; i < adjustmentResults.size(); i++) {
                    if (!adjustmentResults[i].isSuccess()) {
                        String errors = '';
                        for (Database.Error err : adjustmentResults[i].getErrors()) {
                            errors += err.getMessage() + '; ';
                        }
                        logError('>> handleVacate >> Failed to create adjustment line item: ' + errors);
                    }
                }
            }
           
            if (!itemsToUpdate.isEmpty()) {
                System.enqueueJob(new UpdateLineItemIdQueueable(itemsToUpdate));
            }
           
        } catch (Exception e) {
            Database.rollback(sp);
            logError('>> handleVacate >> ERROR >> ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Vacate failed: ' + e.getMessage());
        }
    }
    
    
    public static void processNegativeAdjustmentLine(Decimal newQuantity, Decimal oldQuantity, SObject oldLineItem, DataWrapper dw,
        Map<Id, SObject> creditNotesToCreate, Map<Id, Id> salesOrderToCreditNoteMap, List<SObject> allAdjustmentLines) {
        
        Decimal quantityDifference = newQuantity - oldQuantity;
        if (quantityDifference >= 0) return;
        
        Decimal absoluteDifference = oldQuantity;
        if (newQuantity > 0) {
            absoluteDifference = Math.abs(quantityDifference);
        }
        
        String salesOrderLineApiName = PACKAGE_OBJECTS.get('SALES_ORDER_LINE');
        String creditNoteApiName = PACKAGE_OBJECTS.get('CREDIT_NOTE');
        Id salesOrderId = (Id)oldLineItem.get('OrderApi__Sales_Order__c');
        
        Decimal originalUnitPrice = (Decimal)oldLineItem.get('OrderApi__Sale_Price__c');
        Decimal totalAdjustmentAmount = originalUnitPrice * absoluteDifference;
        
        try {
            // Create or update credit note
            SObject creditNote;
            if (!creditNotesToCreate.containsKey(salesOrderId)) {
                creditNote = Schema.getGlobalDescribe().get(creditNoteApiName).newSObject();
                creditNote.put('OrderApi__Sales_Order__c', salesOrderId);
                creditNote.put('OrderApi__Total__c', -1 * Math.abs(totalAdjustmentAmount));
                creditNote.put('OrderApi__Is_Posted__c', true);
                
                if (oldLineItem.get('OrderApi__Entity__c') != null) {
                    creditNote.put('OrderApi__Entity__c', oldLineItem.get('OrderApi__Entity__c'));
                }
                if (oldLineItem.get('OrderApi__Account__c') != null) {
                    creditNote.put('OrderApi__Account__c', oldLineItem.get('OrderApi__Account__c'));
                }
                if (oldLineItem.get('OrderApi__Contact__c') != null) {
                    creditNote.put('OrderApi__Contact__c', oldLineItem.get('OrderApi__Contact__c'));
                }
                
                creditNotesToCreate.put(salesOrderId, creditNote);
            } else {
                creditNote = creditNotesToCreate.get(salesOrderId);
                Decimal currentTotal = (Decimal)creditNote.get('OrderApi__Total__c');
                creditNote.put('OrderApi__Total__c', currentTotal - Math.abs(totalAdjustmentAmount));
            }
            
            // Create negative adjustment line
            SObject adjustmentLineItem = Schema.getGlobalDescribe().get(salesOrderLineApiName).newSObject();
            adjustmentLineItem.put('OrderApi__Sales_Order__c', salesOrderId);
            adjustmentLineItem.put('OrderApi__Item__c', oldLineItem.get('OrderApi__Item__c'));
            adjustmentLineItem.put('OrderApi__Quantity__c', absoluteDifference);
            adjustmentLineItem.put('OrderApi__Sale_Price__c', -1 * originalUnitPrice);
            adjustmentLineItem.put('OrderApi__Entity__c', oldLineItem.get('OrderApi__Entity__c'));
            adjustmentLineItem.put('OrderApi__Account__c', oldLineItem.get('OrderApi__Account__c'));
            adjustmentLineItem.put('OrderApi__Item_Class__c', oldLineItem.get('OrderApi__Item_Class__c'));
            adjustmentLineItem.put('OrderApi__Sales_Order_Line__c', oldLineItem.Id);
            adjustmentLineItem.put('OrderApi__Is_Adjustment__c', true);
            adjustmentLineItem.put('OrderApi__Line_Description__c', oldLineItem.get('OrderApi__Line_Description__c'));
            
            if (salesOrderToCreditNoteMap.containsKey(salesOrderId)) {
                adjustmentLineItem.put('OrderApi__Credit_Note__c', salesOrderToCreditNoteMap.get(salesOrderId));
            }
            if (oldLineItem.get('OrderApi__Contact__c') != null) {
                adjustmentLineItem.put('OrderApi__Contact__c', oldLineItem.get('OrderApi__Contact__c'));
            }
            
            allAdjustmentLines.add(adjustmentLineItem);
            System.debug('Created negative adjustment for line item: ' + oldLineItem.Id);
            
        } catch (Exception e) {
            logError('Exception in processNegativeAdjustmentLine: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    public static void processPositiveAdjustmentLine(Decimal newQuantity, Decimal oldQuantity, SObject oldLineItem, DataWrapper itemData, List<SObject> allAdjustmentLines) {
        Decimal quantityDifference = newQuantity - oldQuantity;
        if (quantityDifference <= 0) return;
        
        String salesOrderLineApiName = PACKAGE_OBJECTS.get('SALES_ORDER_LINE');
        
        SObject adjustmentLineItem = Schema.getGlobalDescribe().get(salesOrderLineApiName).newSObject();
        adjustmentLineItem.put('OrderApi__Sales_Order__c', oldLineItem.get('OrderApi__Sales_Order__c'));
        adjustmentLineItem.put('OrderApi__Item__c', oldLineItem.get('OrderApi__Item__c'));
        adjustmentLineItem.put('OrderApi__Quantity__c', quantityDifference);
        
        Decimal originalUnitPrice = (Decimal)oldLineItem.get('OrderApi__Sale_Price__c');
        adjustmentLineItem.put('OrderApi__Sale_Price__c', originalUnitPrice);
        
        adjustmentLineItem.put('OrderApi__Entity__c', oldLineItem.get('OrderApi__Entity__c'));
        adjustmentLineItem.put('OrderApi__Account__c', oldLineItem.get('OrderApi__Account__c'));
        adjustmentLineItem.put('OrderApi__Item_Class__c', oldLineItem.get('OrderApi__Item_Class__c'));
        adjustmentLineItem.put('OrderApi__Sales_Order_Line__c', oldLineItem.Id);
        adjustmentLineItem.put('OrderApi__Is_Adjustment__c', true);
        adjustmentLineItem.put('OrderApi__Line_Description__c', oldLineItem.get('OrderApi__Line_Description__c'));
        
        if (oldLineItem.get('OrderApi__Contact__c') != null) {
            adjustmentLineItem.put('OrderApi__Contact__c', oldLineItem.get('OrderApi__Contact__c'));
        }
        
        allAdjustmentLines.add(adjustmentLineItem);
        System.debug('Created positive adjustment for line: ' + oldLineItem.Id);
    }
    
    @testVisible
    private static void handleSponsor(Set<Id> sponsorItemIds, Map<Id, DataWrapper> itemToDataWrapperMap) {
        Savepoint sp = Database.setSavepoint();
        try {
            Map<Id, SObject> creditNotesToCreate = new Map<Id, SObject>();
            Map<Id, Id> salesOrderToCreditNoteMap = new Map<Id, Id>();
            List<SObject> allAdjustmentLines = new List<SObject>();
            Map<Id, SObject> newLineItemsMap = new Map<Id, SObject>();
            List<s7e__Item__c> itemsToUpdate = new List<s7e__Item__c>();
            Set<Id> salesOrderIds = new Set<Id>();
            Set<Id> lineItemIds = new Set<Id>();
            Map<Id, SObject> opportunityToNewSalesOrderMap = new Map<Id, SObject>();
            Map<Id, Id> opportunityToSalesOrderIdMap = new Map<Id, Id>();
            Map<Id, SObject> pendingFeeLineItems = new Map<Id, SObject>(); // Processing Fee

            System.debug('>> handleSponsor >> Processing ' + sponsorItemIds.size() + ' sponsor items');

            // Step 1: Determine Sales Orders
            for (Id itemId : sponsorItemIds) {
                DataWrapper itemData = itemToDataWrapperMap.get(itemId);
                if (itemData == null || itemData.opportunity == null || itemData.item == null || itemData.newItemRecord == null) {
                    logError('>> handleSponsor >> Skipping item ' + itemId + ': Missing required data');
                    continue;
                }

                Id opportunityId = itemData.opportunity;
                if (!opportunityToSalesOrderIdMap.containsKey(opportunityId) && !opportunityToNewSalesOrderMap.containsKey(opportunityId)) {
                    if (itemData.SOIdOnOpportunity != null) {
                        opportunityToSalesOrderIdMap.put(opportunityId, itemData.SOIdOnOpportunity);
                        salesOrderIds.add(itemData.SOIdOnOpportunity);
                    } else {
                        SObject newSalesOrder = createSalesOrderRecord(itemData);
                        opportunityToNewSalesOrderMap.put(opportunityId, newSalesOrder);
                    }
                }
                if (itemData.oldItemRecord != null && String.isNotBlank(itemData.oldItemRecord.s7e__Ext_Line_Item_ID__c)) {
                    lineItemIds.add(itemData.oldItemRecord.s7e__Ext_Line_Item_ID__c);
                }
                
            }

            // Step 1.5: Insert new Sales Orders
            if (!opportunityToNewSalesOrderMap.isEmpty()) {
                List<SObject> newSalesOrdersToInsert = opportunityToNewSalesOrderMap.values();
                List<Database.SaveResult> salesOrderResults = Database.insert(newSalesOrdersToInsert, false);
                List<Opportunity> oppsToUpdate = new List<Opportunity>();

                for (Id oppId : opportunityToNewSalesOrderMap.keySet()) {
                    SObject salesOrder = opportunityToNewSalesOrderMap.get(oppId);
                    Id newSalesOrderId = salesOrder.Id;
                    for (Database.SaveResult result : salesOrderResults) {
                        if (result.isSuccess() && result.getId() == newSalesOrderId) {
                            opportunityToSalesOrderIdMap.put(oppId, newSalesOrderId);
                            salesOrderIds.add(newSalesOrderId);
                            oppsToUpdate.add(new Opportunity(Id = oppId, s7e__Ext_Sales_Order_ID__c = newSalesOrderId));
                        } else if (!result.isSuccess()) {
                            logError('>> handleSponsor >> Failed to create sales order: ' + result.getErrors());
                        }
                    }
                }
                if (!oppsToUpdate.isEmpty()) {
                    List<Database.SaveResult> updateResults = Database.update(oppsToUpdate, false);
                    for (Database.SaveResult result : updateResults) {
                        if (!result.isSuccess()) {
                            logError('>> handleSponsor >> Failed to update opportunity: ' + result.getErrors());
                        }
                    }
                }
            }

            // Step 2: Fetch existing line items and sales order details
            Map<Id, SObject> existingLineItems = new Map<Id, SObject>();
            Map<Id, Boolean> salesOrderIsPostedMap = new Map<Id, Boolean>();
            if (!lineItemIds.isEmpty()) {
                String salesOrderLineApiName = PACKAGE_OBJECTS.get('SALES_ORDER_LINE');
                String query = 'SELECT Id, OrderApi__Contact__c, OrderApi__Sales_Order__c, OrderApi__Item__c, OrderApi__Line_Description__c, OrderApi__Item_Class__c, OrderApi__Account__c, OrderApi__Entity__c, OrderApi__Sale_Price__c, OrderApi__Is_Line_Posted__c, OrderApi__Quantity__c ' +
                              'FROM ' + salesOrderLineApiName + ' WHERE Id IN :lineItemIds';
                for (SObject rec : Database.query(query)) {
                    existingLineItems.put(rec.Id, rec);
                    salesOrderIsPostedMap.put((Id)rec.get('OrderApi__Sales_Order__c'), (Boolean)rec.get('OrderApi__Is_Line_Posted__c'));
                }
            }

            // Step 3: Process sponsor items
            for (Id itemId : sponsorItemIds) {
                DataWrapper itemData = itemToDataWrapperMap.get(itemId);
                if (itemData == null || itemData.newItemRecord == null) {
                    logError('>> handleSponsor >> Skipping item ' + itemId + ': Missing item data');
                    continue;
                }

                Decimal newQuantity = itemData.newQuantity != null ? itemData.newQuantity : 0;
                Decimal oldQuantity = itemData.oldQuantity != null ? itemData.oldQuantity : 0;
                String itemStatus = itemData.newItemRecord.s7e__Status__c;

                if (newQuantity < 0 || oldQuantity < 0) {
                    logError('>> handleSponsor >> Invalid quantity for item ' + itemId + ': newQuantity=' + newQuantity + ', oldQuantity=' + oldQuantity);
                    continue;
                }

                Id salesOrderId = opportunityToSalesOrderIdMap.get(itemData.opportunity);
                if (salesOrderId == null) {
                    logError('>> handleSponsor >> Skipping item ' + itemId + ': No sales order found');
                    continue;
                }

                //itemData.isSalesOrderPosted = salesOrderIsPostedMap.get(salesOrderId) != null ? 
                //                             salesOrderIsPostedMap.get(salesOrderId) : false;
				//SH-1227 fix for adjustment SOLIs
				itemData.isSalesOrderPosted = (itemData.salesOrder != null && itemData.salesOrder.get('OrderApi__Is_Posted__c') != null)
                            ? (Boolean) itemData.salesOrder.get('OrderApi__Is_Posted__c')
                            : false;
                
                
                // Case 1: Cancelled sponsorship
                if (itemStatus != null && (itemStatus == 'Canceled' || itemStatus == 'Cancelled')) {
                    if (itemData.oldItemRecord != null && String.isNotBlank(itemData.oldItemRecord.s7e__Ext_Line_Item_ID__c)) {
                        SObject lineItem = existingLineItems.get(itemData.oldItemRecord.s7e__Ext_Line_Item_ID__c);
                        if (lineItem != null && itemData.oldQuantity > 0) {
                            processNegativeAdjustmentLine(0, itemData.oldQuantity, lineItem, itemData,
                                creditNotesToCreate, salesOrderToCreditNoteMap, allAdjustmentLines);
                        }
                    }
                    itemsToUpdate.add(new s7e__Item__c(Id = itemId, s7e__Ext_Line_Item_ID__c = null));
                    continue;
                }

                // Case 2: Quantity changed
                if (newQuantity != oldQuantity && itemData.oldItemRecord != null && String.isNotBlank(itemData.oldItemRecord.s7e__Ext_Line_Item_ID__c)) {
                    SObject lineItem = existingLineItems.get(itemData.oldItemRecord.s7e__Ext_Line_Item_ID__c);
                    if (lineItem != null) {
                        if (newQuantity > oldQuantity) {
                            processPositiveAdjustmentLine(newQuantity, oldQuantity, lineItem, itemData, allAdjustmentLines);
                        } else {
                            processNegativeAdjustmentLine(newQuantity, oldQuantity, lineItem, itemData,
                                creditNotesToCreate, salesOrderToCreditNoteMap, allAdjustmentLines);
                        }
                    }
                }
                // Case 3: New line item
                else if (itemData.oldItemRecord == null || String.isBlank(itemData.oldItemRecord.s7e__Ext_Line_Item_ID__c)) {
                    SObject newLineItem = Schema.getGlobalDescribe().get(PACKAGE_OBJECTS.get('SALES_ORDER_LINE')).newSObject();
                    newLineItem.put('OrderApi__Sales_Order__c', salesOrderId);
                    newLineItem.put('OrderApi__Item__c', itemData.item.get('Id'));
                    newLineItem.put('OrderApi__Quantity__c', newQuantity);
                    //SH-1204 check membership pricing for processing fee
                    if((Boolean)itemData.showRecord.get('s7e__Enable_Membership_Pricing__c')){
                        Decimal price=0;
                        System.Callable callableSvc = new SubscriberCallableService();
                        Map<String, Object> args = new Map<String, Object>{
                            'accountId' => (String)itemData.account,
                            'itemId'    =>  itemData.newItemRecord.s7e__Ex_ProductId__c,
                            'quantity'  => (Integer)itemData.quantity
                        };
                        price = (Decimal) callableSvc.call('getPrice', args);
                        newLineItem.put('OrderApi__Sale_Price__c', price);
                    } else {
                        newLineItem.put('OrderApi__Sale_Price__c', itemData.item.get('OrderApi__Price__c'));    
                    }
                    //
                    //newLineItem.put('OrderApi__Sale_Price__c', itemData.item.get('OrderApi__Price__c'));
                    newLineItem.put('OrderApi__Entity__c', 'Account');
                    newLineItem.put('OrderApi__Account__c', itemData.account);
                    String itemName = (String)itemData.item.get('Name') != null ? (String)itemData.item.get('Name') : 'Unknown Sponsorship';
                    newLineItem.put('OrderApi__Line_Description__c', 'Sponsorship: ' + itemName);
                    newLineItem.put('OrderApi__Is_Adjustment__c', itemData.isSalesOrderPosted);
                    newLineItem.put('OrderApi__Is_Line_Posted__c', itemData.isSalesOrderPosted);
                    if (itemData.item.get('OrderApi__Item_Class__c') != null) {
                        newLineItem.put('OrderApi__Item_Class__c', itemData.item.get('OrderApi__Item_Class__c'));
                    }
                    if (itemData.contact != null) {
                        newLineItem.put('OrderApi__Contact__c', itemData.contact);
                    }
                    newLineItemsMap.put(itemId, newLineItem);
                }
                
                // Calculate subtotal for new line items
                if (newLineItemsMap.containsKey(itemId)) {
                    SObject newLineItem = newLineItemsMap.get(itemId);
                    itemData.totalLineItemPrice = calculateLineItemSubtotal(newLineItem);
                }
                
                // Create processing fee line item
                SObject feeLineItem = createProcessingFeeLineItem(itemData, salesOrderId);
                if (feeLineItem != null) {
                    pendingFeeLineItems.put(itemId, feeLineItem);
                    System.debug('>> handleSponsor >> Prepared processing fee line item for item ' + itemId);
                }
            }

            // Step 4: Insert credit notes
            if (!creditNotesToCreate.isEmpty()) {
                List<Database.SaveResult> creditNoteResults = Database.insert(creditNotesToCreate.values(), false);
                for (Integer i = 0; i < creditNoteResults.size(); i++) {
                    Database.SaveResult result = creditNoteResults[i];
                    Id salesOrderId = new List<Id>(creditNotesToCreate.keySet())[i];
                    if (result.isSuccess()) {
                        salesOrderToCreditNoteMap.put(salesOrderId, result.getId());
                    } else {
                        String errors = String.join(result.getErrors(), '; ');
                        logError('>> handleSponsor >> Failed to create credit note for sales order ' + salesOrderId + ': ' + errors);
                    }
                }
            }

            // Step 5: Update adjustment lines with credit note IDs
            for (SObject adjLine : allAdjustmentLines) {
                Id salesOrderId = (Id)adjLine.get('OrderApi__Sales_Order__c');
                if (salesOrderToCreditNoteMap.containsKey(salesOrderId)) {
                    adjLine.put('OrderApi__Credit_Note__c', salesOrderToCreditNoteMap.get(salesOrderId));
                }
            }

            // Step 6: Insert adjustment line items
            if (!allAdjustmentLines.isEmpty()) {
                List<Database.SaveResult> adjustmentResults = Database.insert(allAdjustmentLines, false);
                for (Database.SaveResult result : adjustmentResults) {
                    if (!result.isSuccess()) {
                        String errors = String.join(result.getErrors(), '; ');
                        logError('>> handleSponsor >> Failed to create adjustment line item: ' + errors);
                    }
                }
            }

            // Step 7: Insert new line items and update item references
            if (!newLineItemsMap.isEmpty()) {
                List<SObject> newLineItems = newLineItemsMap.values();
                List<Database.SaveResult> lineItemResults = Database.insert(newLineItems, false);
                for (Integer i = 0; i < lineItemResults.size(); i++) {
                    Database.SaveResult result = lineItemResults[i];
                    Id itemId = new List<Id>(newLineItemsMap.keySet())[i];
                    if (result.isSuccess()) {
                        Id newLineItemId = result.getId();
                        itemsToUpdate.add(new s7e__Item__c(
                            Id = itemId,
                            s7e__Ext_Line_Item_ID__c = newLineItemId
                        ));
                        System.debug('>> handleSponsor >> Inserted new line item: ' + newLineItemId + ' for Item ' + itemId);
                    } else {
                        String errors = String.join(result.getErrors(), '; ');
                        logError('>> handleSponsor >> Failed to create line item for Item ' + itemId + ': ' + errors);
                    }
                }
            }
            
            // In handleSponsor, around line 1080, fix the fee line item insertion:
            if (!pendingFeeLineItems.isEmpty()) {
                List<Database.SaveResult> feeLineItemResults = Database.insert(pendingFeeLineItems.values(), false);
                
                // Process results
                Integer index = 0;
                for (Id itemId : pendingFeeLineItems.keySet()) {
                    Database.SaveResult result = feeLineItemResults[index++];
                    if (result.isSuccess()) {
                        Id feeLineItemId = result.getId();
                        System.debug('>> handleSponsor >> Successfully created processing fee line item ' + feeLineItemId + ' for item ' + itemId);
                    } else {
                        List<String> errorMessages = new List<String>();
                        for (Database.Error err : result.getErrors()) {
                            errorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                        }
                        logError('>> handleSponsor >> Failed to create processing fee line item for item ' + itemId + ': ' + String.join(errorMessages, '; '));
                    }
                }
            }
            // Step 8: Update items
            if (!itemsToUpdate.isEmpty()) {
                System.enqueueJob(new UpdateLineItemIdQueueable(itemsToUpdate));
            }

        } catch (Exception e) {
            Database.rollback(sp);
            logError('>> handleSponsor >> ERROR for items ' + String.join(new List<Id>(sponsorItemIds), ', ') + ' >> ' + e.getMessage() + '\nStack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error processing sponsor items: ' + e.getMessage());
        }
    }
    
}