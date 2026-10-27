@isTest
public class FS_TestUtils {
    public static Contact createContact(String lName, String emailId){
        Contact oContact = new Contact();
        oContact.lastName = lName;
        oContact.email = emailId;
        return oContact;
    }
    public static Account createAccount(String name){
        Account acc = new Account();
        acc.Name = name;
        return acc;
    }
    public static OrderApi__Item__c createItem(String name, Id oItemClassId){
        OrderApi__Item__c oItem = new OrderApi__Item__c();
        oItem.Name = name;
        oItem.OrderApi__Item_Class__c = oItemClassId;
        return oItem;
        
    }
    public static OrderApi__Item_Class__c createItemClass(String name){
        OrderApi__Item_Class__c oItemClass = new OrderApi__Item_Class__c ();
        oItemClass.Name = name;
        return oItemClass;
    }
    public static OrderApi__Subscription_Plan__c createSubsPlan(String name){
        OrderApi__Subscription_Plan__c oSubsPlan = new OrderApi__Subscription_Plan__c();
        oSubsPlan.Name= name;
        return oSubsPlan;
    }
    public static OrderApi__Subscription__c createSubscription(Id oItem,Id oSubsPlan, Id a, Id c, Id oSalesOrderLine){
        OrderApi__Subscription__c oSubscription = new OrderApi__Subscription__c();
        oSubscription.OrderApi__Subscription_Plan__c = oSubsPlan;
        oSubscription.OrderApi__Account__c = a;
        oSubscription.OrderApi__Contact__c = c;
        oSubscription.OrderApi__Item__c  = oItem; 
        oSubscription.OrderApi__Current_Term_End_Date__c = System.TODAY()+30;
        oSubscription.OrderApi__Current_Term_Start_Date__c =   System.TODAY()-5;
        
        oSubscription.OrderApi__Status__c = 'Active';       
        oSubscription.OrderApi__Is_Active__c = true;
        oSubscription.OrderApi__Sales_Order_Line__c = oSalesOrderLine;
        
        
        return oSubscription;
    }
    public static OrderApi__Sales_Order__c createSalesOrder(Id oContact, Id oAccount,String postingEntity, String status){
        OrderApi__Sales_Order__c oSalesOrder = new OrderApi__Sales_Order__c();
        oSalesOrder.OrderApi__Contact__c = oContact;
        oSalesOrder.OrderApi__Account__c = oAccount;
        oSalesOrder.OrderApi__Entity__c = 'Account';
        oSalesOrder.OrderApi__Posting_Entity__c = postingEntity; //Receipt
        oSalesOrder.OrderApi__Status__c = status; //Open
        return oSalesOrder;
    }
    public static OrderApi__Sales_Order_Line__c createSalesOrderLine(Id oItem, Id oSalesOrder, Id oContact, Id oAccount){
        OrderApi__Sales_Order_Line__c salesOrderLineObj = new OrderApi__Sales_Order_Line__c();
        salesOrderLineObj.OrderApi__Item__c  = oItem;
        salesOrderLineObj.OrderApi__Sales_Order__c = oSalesOrder;
        return salesOrderLineObj;
    }
    
    public static OrderApi__Business_Group__c createBusinessGroup(String name){
        OrderApi__Business_Group__c obusinessGroup = new OrderApi__Business_Group__c();
        oBusinessGroup.OrderApi__Type__c = 'test';
        oBusinessGroup.Name = name;
        return oBusinessGroup;
    }
}