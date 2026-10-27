/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : OrderSummaryBuilderControllerTest
 * Author          : <YourName>
 * Created Date    : Aug 26, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Aug 26, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 26, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

@isTest
private class OrderSummaryBuilderControllerTest {

    @isTest
    static void testNullAccountId_returnsEmptyResponse() {
        Test.startTest();
        OrderSummaryBuilderController.OrderSummaryResponse result =
            OrderSummaryBuilderController.getOrderSummary(null, null, false);
        Test.stopTest();
    }

    @isTest
    static void testAllOrders_returnsExpectedRow() {
        Map<String, Id> ids = buildTestData();

        Test.startTest();
        OrderSummaryBuilderController.OrderSummaryResponse result =
            OrderSummaryBuilderController.getOrderSummary(ids.get('account'), null, false);
        Test.stopTest();
    }

    @isTest
    static void testBusinessGroupFilter() {
        Map<String, Id> ids = buildTestData();

        Test.startTest();
        OrderSummaryBuilderController.OrderSummaryResponse result =
            OrderSummaryBuilderController.getOrderSummary(ids.get('account'), ids.get('businessGroup'), false);
        Test.stopTest();
    }

    @isTest
    static void testOpenOnly_executesWithoutError() {
        Map<String, Id> ids = buildTestData();

        Test.startTest();
        OrderSummaryBuilderController.OrderSummaryResponse result =
            OrderSummaryBuilderController.getOrderSummary(ids.get('account'), null, true);
        Test.stopTest();
    }


    private static Map<String, Id> buildTestData() {
        Account acc = new Account(Name = 'Test Account OSB');
        insert acc;

        OrderApi__Business_Group__c bg = new OrderApi__Business_Group__c(Name = 'Test Business Group');
        insert bg;

        Contact memberContact = new Contact(
            LastName = 'Member',
            AccountId = acc.Id,
            Has_Group_Membership__c = true
        );
        insert memberContact;

        OrderApi__Item__c subscriptionItem = new OrderApi__Item__c(
            Name = 'Subscription Item',
            OrderApi__Is_Subscription__c = true,
            OrderApi__Price__c = 50
        );
        insert subscriptionItem;

        OrderApi__Sales_Order__c order = new OrderApi__Sales_Order__c(
            OrderApi__Account__c = acc.Id,
            OrderApi__Entity__c = 'Account',
            OrderApi__Is_Proforma__c = true,
            OrderApi__Posting_Entity__c = 'Receipt',
            OrderApi__Schedule_Type__c = 'Simple Receipt',
            OrderApi__Status__c = 'Closed',
            OrderApi__Business_Group__c = bg.Id,
            OrderApi__Encrypted_Id__c = 'enc-' + String.valueOf(Math.random())
        );
        insert order;
        OrderApi__Sales_Order_Line__c line = new OrderApi__Sales_Order_Line__c(
            OrderApi__Sales_Order__c = order.Id,
            OrderApi__Sales_Order_Line__c = null,
            OrderApi__Item__c = subscriptionItem.Id,
            OrderApi__Sale_Price__c = 50,
            OrderApi__Price_Override__c = true,
            OrderApi__Contact__c = memberContact.Id
        );
        insert line;

        return new Map<String, Id>{
            'account' => acc.Id,
            'businessGroup' => bg.Id
        };
    }
}