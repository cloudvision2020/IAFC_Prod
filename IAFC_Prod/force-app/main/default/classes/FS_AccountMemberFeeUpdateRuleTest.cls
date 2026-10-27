@istest
public class FS_AccountMemberFeeUpdateRuleTest{ 
    @TestSetup
    private static void install() {
        Framework.Installer.install();
        PagesApi.PackageScripts.install(); 
        OrderApi.PackageScripts.install(); 
        EventApi.PackageScripts.install(); 
        
        Framework.RoutingRule[] rules = new List<Framework.RoutingRule>();
        Framework.RoutingRule accountMemberFeeUpdate = new Framework.RoutingRule();
        accountMemberFeeUpdate.apexClass = FS_ContactPerformaRoutingRule.class.getName();
        accountMemberFeeUpdate.namespace = '';
        accountMemberFeeUpdate.isEnabled = true;
        accountMemberFeeUpdate.sObjectName = 'OrderApi__Subscription__c'; 
        accountMemberFeeUpdate.executionOrder = 50;
        rules.add(accountMemberFeeUpdate); 
        Framework.Config.push(rules);  
    }
    
    @istest 
    static void testAccountMemberFee(){    
        //Inserting Account
        Account a=FS_TestUtils.createAccount('Testing');
        a.FS_Account_New_Member_Fee__c=true;
        insert a; 
        System.debug('===Account'+a.id);
        
        //Inserting Contact
        Contact c=FS_TestUtils.createContact('ltest','test@gmail.com'); 
        c.accountId=a.id;
        insert c;
        System.debug('==contact'+c.id);
               
        //Inserting Subscriptionplan
        OrderApi__Subscription_Plan__c oSubsPlan=FS_TestUtils.createSubsPlan('TestSubscription');
        oSubsPlan.OrderApi__Type__c='Termed';
        oSubsPlan.OrderApi__Initial_Term_Months__c=12; 
        oSubsPlan.OrderApi__Renewal_Term_Months__c=12;
        oSubsPlan.OrderApi__Is_Active__c=true; 
        insert oSubsPlan;
        System.debug('==Subscriptionplan'+oSubsPlan.id);  
        
        //Inserting Itemclass
        OrderApi__Item_Class__c oItemClass=FS_TestUtils.createItemClass('TestItemclass');
        insert oItemClass;
        System.debug('==Itemclass'+oItemClass.id);
        
        //Inserting BusinessGroup
         OrderApi__Business_Group__c obusinessGroup=FS_TestUtils.createBusinessGroup('TestBusiness');
         insert obusinessGroup;
         System.debug('==BusinessGroup'+obusinessGroup.id);
         
         //Inserting GLAccount
         OrderApi__GL_Account__c glAccount=new OrderApi__GL_Account__c();
         glAccount.name='TestGLAccount';
         glAccount.OrderApi__Business_Group__c=obusinessGroup.id;
         glAccount.GL_Code__c='12345-12345';
         insert glAccount;
         System.debug('==GLAccount'+glAccount.id); 
        
         //Inserting Item
         OrderApi__Item__c oItem=FS_TestUtils.createItem('Departmental Membership',oItemClass.id); 
         oItem.OrderApi__Business_Group__c=obusinessGroup.id;
         oItem.OrderApi__Income_Account__c=glAccount.id;
         oItem.OrderApi__Adjustment_Account__c=glAccount.id;
         oItem.OrderApi__Refund_Account__c=glAccount.id;
         insert oItem; 
         System.debug('==Item'+oItem.id);
         System.debug('*******'+oItem.name);
         
         //Inserting salesorder
         OrderApi__Sales_Order__c oSalesOrder=FS_TestUtils.createSalesOrder(c.id,a.id,'Receipt','Open');
         insert oSalesOrder;
         System.debug('==salesorder'+oSalesOrder.id);
         
         //Inserting salesorderLine
         OrderApi__Sales_Order_Line__c salesOrderLineObj=FS_TestUtils.createSalesOrderLine(oItem.id,oSalesOrder.id,c.id,a.id);
         insert salesOrderLineObj;
         System.debug('==salesorderLine'+salesOrderLineObj.id); 
         
      	//Inserting Subscription
        OrderApi__Subscription__c sub=FS_TestUtils.createSubscription(oItem.id,oSubsPlan.id,a.id,c.id,salesOrderLineObj.id);
        sub.OrderApi__Business_Group__c=obusinessGroup.id;
        sub.OrderApi__Is_Active__c=true; 
        insert sub;   
        OrderApi__Subscription__c subc=[select Subscription_Item_Name__c from OrderApi__Subscription__c where id=:sub.id limit 1];
        System.debug('=='+subc.Subscription_Item_Name__c); 
        if(subc.Subscription_Item_Name__c=='Departmental Membership'){
             a.FS_Account_New_Member_Fee__c=false;
        }else{
            if((subc.Subscription_Item_Name__c!='Departmental Membership' && sub.OrderApi__Is_Active__c==false) || Test.isRunningTest()	 ){
                a.FS_Account_New_Member_Fee__c=false;
            }
        }
        update a;
        System.debug('=='+a.FS_Account_New_Member_Fee__c); 
        System.debug('==Subscription'+sub.id);
        Map<id,OrderApi__Subscription__c> subscriptionList=new Map<id,OrderApi__Subscription__c>([select id from OrderApi__Subscription__c where id=:sub.id]);
        update subscriptionList.values();
        List<OrderApi__Subscription__c> afterUpdatingList=[select id,OrderApi__Is_Active__c,OrderApi__Account__r.FS_Account_New_Member_Fee__c from OrderApi__Subscription__c where id in:subscriptionList.keyset()];
        test.startTest();
        FS_AccountMemberFeeUpdate.afterInsertingAccount(afterUpdatingList);
        FS_AccountMemberFeeUpdate.afterUpdatingAccount(afterUpdatingList,subscriptionList);
        test.stopTest();
        
        FS_AccountMemberFeeUpdateRule FSSubscriptionRoutingRule = new FS_AccountMemberFeeUpdateRule(afterUpdatingList);
        FS_AccountMemberFeeUpdateRule.Constructor fscc = new FS_AccountMemberFeeUpdateRule.Constructor();
        fscc.construct(afterUpdatingList);
        FSSubscriptionRoutingRule.afterInsert();
        FSSubscriptionRoutingRule.afterUpdate(subscriptionList);    
    }
}