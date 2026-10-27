public without sharing class FS_JoinProcess_VerifyProfile_Controller {
    public class MyPickListInfo {
        public String validFor;
    }

    @AuraEnabled
    public static Map<String, Object> getJSONCountriesAndStates() {
        Map<String, List<Map<String, String>>> controllingInfo = new Map<String, List<Map<String, String>>>();
        List<Map<String, String>> countriesInfo = new List<Map<String, String>>();

        countriesInfo.add(new Map<String, String>{'value' => 'US', 'label' => 'United States'});
        countriesInfo.add(new Map<String, String>{'value' => 'CA', 'label' => 'Canada'});

        Schema.DescribeFieldResult controllingFieldInfo = User.countrycode.getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = User.statecode.getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

        for (Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getValue(), new List<Map<String, String>>());
            if (!currControllingValue.getValue().equals('US') && !currControllingValue.getValue().equals('CA')) {
                countriesInfo.add(new Map<String, String>{'value' => currControllingValue.getValue(), 'label' => currControllingValue.getLabel()});
            }
        }

        for (Schema.PicklistEntry currDependentValue : dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;

            Map<String, String> temp = new Map<String, String>();
            temp.put('label', currDependentValue.getLabel());
            temp.put('value', currDependentValue.getValue());

            for (Integer curr : hexString.getChars()) {
                Integer val = 0;
                if (curr >= 65) {
                    val = curr - 65 + 10;
                } else {
                    val = curr - 48;
                }

                if ((val & 8) == 8) {
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(temp);
                }
                if ((val & 4) == 4) {
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(temp);
                }
                if ((val & 2) == 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(temp);
                }
                if ((val & 1) == 1) {
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(temp);
                }

                baseCount += 4;
            }
        }
        Map<String, Object> result = new Map<String, Object>();
        result.put('countriesInfo', countriesInfo);
        result.put('statesInfo', controllingInfo);
        return result;
    }

    @AuraEnabled
    public static List<Map<String, String>> getPreferredEmailTypeOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        List<String> emailTypes = System.Label.FS_JoinProcess_Email_Type.split(', ');

        for (String type : emailTypes) {
            options.add(new Map<String, String>{'label' => type, 'value' => type});
        }

        return options;
    }

    @AuraEnabled
    public static List<Map<String, String>> getPreferredPhoneTypeOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        List<String> phoneTypes = System.Label.FS_JoinProcess_Phone_Type.split(', ');

        for (String type : phoneTypes) {
            options.add(new Map<String, String>{'label' => type, 'value' => type});
        }

        return options;
    }

    @AuraEnabled
    public static List<Map<String, String>> getJobFunctionOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Contact.Functional_Title__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {
            options.add(new Map<String, String>{'label' => f.getLabel(), 'value' => f.getValue()});
        }

        return options;
    }

    @AuraEnabled
    public static Map<String, Object> getContact(Id userId, Id salesOrderId) {
        Map<String, Object> result = new Map<String, Object>();
        List<Id> relatedAccountIds = new List<Id>();
        Id contactId = [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
 /* Prosenjit - IAFC-39
 Fetched  Membership_Expiration__c in contact to populate it in join renew page */ 
        Contact contact = [SELECT Id, FirstName, MiddleName, LastName, Title, Suffix, Membership_Expiration__c, MailingStreet, MailingCity, MailingStateCode,
 /* Prosenjit - End of IAFC-39 changes */
                                    MailingCountryCode, MailingPostalCode, OrderApi__Preferred_Email_Type__c, OrderApi__Preferred_Phone_Type__c,
                                    OrderApi__Work_Email__c, OrderApi__Other_Email__c, OrderApi__Work_Phone__c, MobilePhone, OtherPhone,
                                    Functional_Title__c, New_Mem_Fee__c, Division__c, AccountId, Account.Name, Account.FS_Account_Division__c,
                                    Account.Population_Served_Size__c, Account.OrderApi__Outstanding_Credits__c, Account.Organization_Type__c,
                                    (SELECT Id FROM OrderApi__Subscriptions__r WHERE OrderApi__Status__c = 'Active'), 
                                    (SELECT Id FROM OrderApi__Sales_Orders__r WHERE OrderApi__Status__c = 'Open' OR (OrderApi__Status__c = 'Closed' 
                                                                                AND OrderApi__Posting_Status__c = 'Pending') ORDER BY LastModifiedDate DESC) 
                             FROM Contact WHERE Id = :contactId];

        // Determine eligible sales order ((open OR (closed AND pending))) AND has membership item sales order line)
        Id eligibleSalesOrderId = null;
        if (salesOrderId == null) {
            List<Id> itemIds = new List<Id>();
            for (OrderApi__Item__c tempItem : [SELECT Id, Name, FS_Item_Functional_Titles__c, (SELECT Id FROM
                    OrderApi__Subscription_Plan_Items__r ORDER BY OrderApi__Subscription_Plan__r.Name ASC) FROM OrderApi__Item__c WHERE OrderApi__Is_Active__c = TRUE]) {
                if (tempItem.FS_Item_Functional_Titles__c != null && tempItem.FS_Item_Functional_Titles__c.split(';').contains(contact.Functional_Title__c)
                        && tempItem.OrderApi__Subscription_Plan_Items__r.size() > 0) {
                    itemIds.add(tempItem.Id);
                }
            }
            List<Id> salesOrderIds = new List<Id>();
            for (OrderApi__Sales_Order__c tempSalesOrder : contact.OrderApi__Sales_Orders__r) {
                salesOrderIds.add(tempSalesOrder.Id);
            }

            for (OrderApi__Sales_Order__c tempSalesOrder : [SELECT Id, (SELECT Id, OrderApi__Item__r.Id FROM OrderApi__Sales_Order_Lines__r WHERE OrderApi__Item__r.Id IN :itemIds) FROM OrderApi__Sales_Order__c WHERE Id IN :salesOrderIds ORDER BY LastModifiedDate DESC]) {
                if (tempSalesOrder.OrderApi__Sales_Order_Lines__r.size() == 1) {
                    eligibleSalesOrderId = tempSalesOrder.Id;
                    break;
                }
            }
        }

        // Determine eligible sales order

        if (String.isBlank(contact.OrderApi__Preferred_Email_Type__c)
                || contact.OrderApi__Preferred_Email_Type__c != 'Work'
                || contact.OrderApi__Preferred_Email_Type__c != 'Other') {
            contact.OrderApi__Preferred_Email_Type__c = 'Work';
        }
        if (String.isBlank(contact.OrderApi__Preferred_Phone_Type__c)
                || contact.OrderApi__Preferred_Email_Type__c != 'Work'
                || contact.OrderApi__Preferred_Email_Type__c != 'Mobile') {
            contact.OrderApi__Preferred_Phone_Type__c = 'Work';
        }
        for (AccountContactRelation tempAccountContactRelation : [SELECT AccountId FROM AccountContactRelation WHERE ContactId = :contactId]) {
            relatedAccountIds.add(tempAccountContactRelation.AccountId);
        }
        result.put('Related Account Ids', relatedAccountIds);
        result.put('Contact', contact);
        result.put('Sales Order', null);
        if (salesOrderId == null) {
            if (eligibleSalesOrderId != null) {
                result.put(
                        'Sales Order',
                        [SELECT Id, (SELECT Id, OrderApi__Total__c, OrderApi__Item__c, OrderApi__Item__r.Name, OrderApi__Item__r.OrderApi__Price__c, OrderApi__Item__r.OrderApi__Description__c, OrderApi__Item__r.OrderApi__Item_Class__r.Name, OrderApi__Item__r.OrderApi__Image_Path__c, OrderApi__Item_Class__r.Name, OrderApi__Subscription_Plan__c, OrderApi__Subscription_Plan__r.Name FROM OrderApi__Sales_Order_Lines__r) FROM OrderApi__Sales_Order__c WHERE Id = :eligibleSalesOrderId][0]
                );
            }
        } else {
            OrderApi__Sales_Order__c salesOrder = [SELECT Id, OrderApi__Contact__c, (SELECT Id, OrderApi__Total__c, OrderApi__Item__c, OrderApi__Item__r.Name, OrderApi__Item__r.OrderApi__Price__c, OrderApi__Item__r.OrderApi__Description__c, OrderApi__Item__r.OrderApi__Item_Class__r.Name, OrderApi__Item__r.OrderApi__Image_Path__c, OrderApi__Item_Class__r.Name, OrderApi__Subscription_Plan__c, OrderApi__Subscription_Plan__r.Name FROM OrderApi__Sales_Order_Lines__r) FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId][0];
            if (salesOrder.OrderApi__Contact__c != contactId) {
                result.put('Error', 'User not correct');
            } else {
                result.put('Sales Order', salesOrder);
            }
        }
        return result;
    }

    @AuraEnabled
    public static Map<String, Object> updateContact(Contact currentContact, Id membershipItemId, Id membershipItemSalesOrderLineId,
            Id divisionItemId, Id divisionItemSalesOrderLineId, Id salesOrderId, Boolean isDepartmentalMembershipJoin,
            Boolean onlyShowVerifyMyProfilePage) {
        Map<String, Object> result = new Map<String, Object>();
        //try {
            update currentContact;
            if (onlyShowVerifyMyProfilePage) {
                result.put('Contact', currentContact);
                return result;
            }
            /* 
                Vishnu: In case of Departmental Membership, need to check if the Account already has an existing membership, 
                        in which case we should show error Message
            */
            if (isDepartmentalMembershipJoin) {
                Account objAcc = [SELECT Id, Name, 
                                        (SELECT Id FROM OrderApi__Subscriptions__r WHERE OrderApi__Status__c = 'Active'
                                                                                     AND OrderApi__Item__r.Name = 'Departmental Membership')
                                    FROM Account
                                   WHERE Id = :currentContact.AccountId];
                if (objAcc.OrderApi__Subscriptions__r != null && objAcc.OrderApi__Subscriptions__r.size() > 0) {
                    result.put('Show Error Message', true);
                    return result;
                }
            } else {
                Contact tempContact = [SELECT Id, (SELECT Id FROM OrderApi__Subscriptions__r WHERE OrderApi__Status__c = 'Active'),
                        (SELECT Id FROM OrderApi__Sales_Orders__r WHERE OrderApi__Status__c = 'Open' OR (OrderApi__Status__c = 'Closed'
                        AND OrderApi__Posting_Status__c = 'Pending')) FROM Contact WHERE Id = :currentContact.Id];
                Map<Id, OrderApi__Sales_Order__c> tempSalesOrdersByIds = new Map<Id, OrderApi__Sales_Order__c>([SELECT Id FROM OrderApi__Sales_Order__c WHERE OrderApi__Contact__c = :currentContact.Id AND (OrderApi__Status__c = 'Open' OR (OrderApi__Status__c = 'Closed' AND OrderApi__Posting_Status__c = 'Pending'))]);
                List<OrderApi__Sales_Order_Line__c> tempSalesOrderLinesRenewal = [SELECT Id FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Is_Renewal__c = TRUE AND OrderApi__Sales_Order__c IN :tempSalesOrdersByIds.keySet()];
                if (tempContact.OrderApi__Subscriptions__r != null && tempContact.OrderApi__Subscriptions__r.size() > 0
                       && tempSalesOrderLinesRenewal.isEmpty()) {
                    result.put('Show Error Message', true);
                    return result;
                }
            }

            currentContact = [SELECT Id, FirstName, MiddleName, LastName, Title, Suffix, MailingStreet, MailingCity, MailingStateCode,
                    MailingCountryCode, MailingPostalCode, OrderApi__Preferred_Email_Type__c, OrderApi__Preferred_Phone_Type__c,
                    OrderApi__Work_Email__c, OrderApi__Other_Email__c, OrderApi__Work_Phone__c, MobilePhone, OtherPhone,
                    Functional_Title__c, New_Mem_Fee__c, Division__c, AccountId, Account.Name FROM Contact WHERE Id = :currentContact.Id][0];
            result.put('Contact', currentContact);
            
            system.debug('> >> ' + salesOrderId );
            if (salesOrderId != null) {
               /* Boolean deleteMembershipItemSalesOrderLine = membershipItemSalesOrderLineId != null;
                Boolean deleteDivisionSalesOrderLine = divisionItemSalesOrderLineId != null;
                String divisionItemName = currentContact.Division__c + ' Division Dues';
                if(isDepartmentalMembershipJoin){
                    Contact objCon = [SELECT Id, Account.FS_Account_Division__c FROM Contact WHERE Id=:currentContact.Id];
                    divisionItemName = objCon.Account.FS_Account_Division__c + ' Division Dues';
                }
                Id correctDivisionItemId = null;

                for (OrderApi__Item__c tempItem : [
                        SELECT Id, Name, FS_Item_Functional_Titles__c, OrderApi__Image_Path__c, (
                                SELECT Id,
                                        OrderApi__Subscription_Plan__r.Name, OrderApi__Subscription_Plan__r.Id
                                FROM
                                        OrderApi__Subscription_Plan_Items__r
                                ORDER BY OrderApi__Subscription_Plan__r.Name ASC
                        )
                        FROM OrderApi__Item__c
                        WHERE ((FS_Item_Functional_Titles__c
                                != NULL) OR (OrderApi__Item_Class__r.Name = 'Divisions' AND Name = :divisionItemName)) AND OrderApi__Is_Active__c = TRUE
                ]) {
                    if (tempItem.FS_Item_Functional_Titles__c != null && tempItem.FS_Item_Functional_Titles__c.split(';').contains(currentContact.Functional_Title__c)
                            && tempItem.OrderApi__Subscription_Plan_Items__r.size() > 0) {
                        if (tempItem.Id == membershipItemId) {
                            deleteMembershipItemSalesOrderLine = false;
                        }
                    }
                    if (tempItem.Name == divisionItemName) {
                        if (tempItem.Id == divisionItemId) {
                            deleteDivisionSalesOrderLine = false;
                        } else {
                            correctDivisionItemId = tempItem.Id;
                        }
                    }
                }
                if (deleteMembershipItemSalesOrderLine) {*/
                    // To Store the Subscription Id
                    List<OrderApi__Sales_Order_Line__c> lstSOL = [Select Id, OrderApi__Subscription__c  from OrderApi__Sales_Order_Line__c where Id=:membershipItemSalesOrderLineId];
                    if(lstSOL.size() > 0){
                        OrderApi__Sales_Order__c so = new OrderApi__Sales_Order__c();
                        so.Temp_Sub_Id__c =lstSOL[0].OrderApi__Subscription__c;
                        so.Id = salesOrderId;
                        Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', true);
                        update so;
                        Framework.Dispatcher.disableTriggerInContext.put('OrderApi__Sales_Order__c', false);
                    }
                    
                    
                   /* Database.delete(membershipItemSalesOrderLineId);
                }
                if (deleteDivisionSalesOrderLine) {
                    Database.delete(divisionItemSalesOrderLineId);
                    OrderApi__Sales_Order_Line__c newDivisionItemSalesOrderLine = new OrderApi__Sales_Order_Line__c(
                            OrderApi__Sales_Order__c = salesOrderId,
                            OrderApi__Item__c = correctDivisionItemId
                    );
                    insert newDivisionItemSalesOrderLine;
                }*/
                result.put('Sales Order', [SELECT Id, (SELECT Id, OrderApi__Total__c, OrderApi__Item__c, OrderApi__Item__r.Name, OrderApi__Item__r.OrderApi__Price__c, OrderApi__Item__r.OrderApi__Description__c, OrderApi__Item__r.OrderApi__Item_Class__r.Name, OrderApi__Item__r.OrderApi__Image_Path__c, OrderApi__Item_Class__r.Name, OrderApi__Subscription_Plan__c, OrderApi__Subscription_Plan__r.Name FROM OrderApi__Sales_Order_Lines__r) FROM OrderApi__Sales_Order__c WHERE Id = :salesOrderId][0]);
            } else {
                result.put('Sales Order', null);
            }
            return result;
       /* } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            if (e.getMessage().contains('duplicate value') && e.getMessage().containsIgnoreCase('email')) {
                result.put('Exception', 'UniqueEmail');
            } else {
                result.put('Exception', e.getMessage());
            }
            return result;
        }*/
    }

    @AuraEnabled
    public static Map<String, Object> insertAccount(Account accountRecord, Contact currentContact) {
        Map<String, Object> result = new Map<String, Object>();
        System.debug(accountRecord);

        accountRecord.OwnerId = Label.FS_AdministratorId;
        Database.SaveResult sr = Database.insert(accountRecord);

        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = accountRecord.Id;
        acr.ContactId = currentContact.Id;
        acr.FS_Is_Primary__c = true;

        Database.SaveResult sr1 = Database.insert(acr);

        result.put('Status', sr.isSuccess() && sr1.isSuccess());
        currentContact = [SELECT Id, FirstName, MiddleName, LastName, Title, Suffix, MailingStreet, MailingCity, MailingStateCode,
                MailingCountryCode, MailingPostalCode, OrderApi__Preferred_Email_Type__c, OrderApi__Preferred_Phone_Type__c,
                OrderApi__Work_Email__c, OrderApi__Other_Email__c, OrderApi__Work_Phone__c, MobilePhone, OtherPhone,
                Functional_Title__c, New_Mem_Fee__c, Division__c, AccountId, Account.Name, Account.FS_Account_Division__c,
                Account.Population_Served_Size__c, Account.OrderApi__Outstanding_Credits__c, Account.Organization_Type__c,
        (SELECT Id FROM OrderApi__Subscriptions__r WHERE OrderApi__Status__c = 'Active'),
        (SELECT Id FROM OrderApi__Sales_Orders__r WHERE OrderApi__Status__c = 'Open' OR (OrderApi__Status__c = 'Closed'
        AND OrderApi__Posting_Status__c = 'Pending') ORDER BY LastModifiedDate DESC)
        FROM Contact WHERE Id = :currentContact.Id];
        result.put('Contact', currentContact);

        return result;
    }

    @AuraEnabled
    public static Map<String, String> getPopulationPicklistValues( ) {

        Map<String, String> picklistValuesMap = new Map<String,String>();

        Schema.DescribeFieldResult fieldResult = Account.Population_Served_Size__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry pickListVal : picklistEntries){
            if(picklistVal.isActive()) {
                picklistValuesMap.put(picklistVal.getValue(), picklistVal.getLabel());

            }
        }

        return picklistValuesMap;
    }
}