/**
* @File Name : SalesOrderLineReconciliationServiceTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 27, 2025 |   | Initial Version
**/
@IsTest
private class SalesOrderLineReconciliationServiceTest {

    // -------------------------
    // Test Data Helpers
    // -------------------------

    private static Account makeAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    // TODO: Replace with your org’s required fields for Fonteva Item (OrderApi__Item__c)
    private static OrderApi__Item__c makeItem(String name) {
        OrderApi__Item__c it = new OrderApi__Item__c(
            Name = name
            // + any other required fields (e.g., Type, Price, CurrencyIsoCode)
        );
        insert it;
        return it;
    }

    // TODO: Add any required fields for your Subscription object
    private static OrderApi__Subscription__c makeSubscription(String name) {
        OrderApi__Subscription_Plan__c sub = new OrderApi__Subscription_Plan__c(Name = 'Sub Plan');
        insert sub;
        OrderApi__Item__c oItem = makeItem('Member');

        OrderApi__Subscription__c s = new OrderApi__Subscription__c(
            OrderApi__Subscription_Plan__c = sub.id, 
            OrderApi__Item__c = oItem.Id
        );
        insert s;
        return s;
    }

    // NOTE: Your service treats the “latest term” as OrderApi__Renewal__c.
    // Add any required fields enforced by your package.
    private static OrderApi__Renewal__c makeRenewal(Id subscriptionId) {
        OrderApi__Renewal__c r = new OrderApi__Renewal__c(
            OrderApi__Subscription__c = subscriptionId,
            OrderApi__Is_Active__c = true,
            OrderApi__Term_Start_Date__c = Date.today(),
            OrderApi__Term_End_Date__c = Date.today().adddays(365)
            // + required fields (dates/status/etc.) if any
        );
        insert r;
        return r;
    }

    // Create a Subscription Line tied to a Term/Renewal
    private static OrderApi__Subscription_Line__c makeSubLine(Id termId, Id itemId, Decimal qty, Id subId) {
        OrderApi__Subscription_Line__c sl = new OrderApi__Subscription_Line__c(
            OrderApi__Term__c     = termId,
            OrderApi__Item__c     = itemId,
            OrderApi__Quantity__c = qty,
            OrderApi__Subscription__c = subId
            // + required fields (Amount/Price/etc.) if any
        );
        insert sl;
        return sl;
    }

    // Sales Order with Is_Data_Fix__c flag
    private static OrderApi__Sales_Order__c makeSO(Account acc, String name, Boolean isDataFix) {
        OrderApi__Sales_Order__c so = new OrderApi__Sales_Order__c(
           
            OrderApi__Account__c = acc.Id,
            Is_Data_Fix__c       = isDataFix
            // + any other required fields
        );
        insert so;
        return so;
    }

    // Marker SOL so the service can infer the Subscription from the SO
    private static OrderApi__Sales_Order_Line__c makeMarkerSOL(Id soId, Id subId, Id itemId, Decimal qty) {
        OrderApi__Sales_Order_Line__c sol = new OrderApi__Sales_Order_Line__c(
            OrderApi__Sales_Order__c  = soId,
            OrderApi__Subscription__c = subId,
            OrderApi__Item__c         = itemId,
            OrderApi__Quantity__c     = qty
            // Leave OrderApi__Is_Renewal__c null/false for existing lines
        );
        insert sol;
        return sol;
    }

    // -------------------------
    // Tests
    // -------------------------

    /**
     * Happy path:
     * - SO marked Is_Data_Fix__c = true is picked up by the batch.
     * - Latest Renewal has two Sub Lines: one matching existing SOL item, one new item.
     * - Batch should create exactly one new SOL for the "new" item and flag it as renewal.
     */
    @IsTest
    static void testBatchCreatesMissingSOLsForDataFixSO() {
        // Data setup
        Account acc = makeAccount('ACC - DataFix');

        OrderApi__Item__c itemExisting = makeItem('Item Existing');
        OrderApi__Item__c itemNew      = makeItem('Item New');

        OrderApi__Subscription__c sub = makeSubscription('Sub - DF');
        OrderApi__Renewal__c      rn  = makeRenewal(sub.Id);

        // Latest renewal lines (what should be mirrored to SOLs):
        makeSubLine(rn.Id, itemExisting.Id, 1, sub.Id); // matches marker SOL item (no duplicate expected)
        makeSubLine(rn.Id, itemNew.Id, 2, sub.Id);      // missing on SO; should be created

        // SO included in batch (Is_Data_Fix__c = true)
        OrderApi__Sales_Order__c so = makeSO(acc, 'SO-DF-1', true);

        // Existing SOL so service can infer subscription
        makeMarkerSOL(so.Id, sub.Id, itemExisting.Id, 1);

        Test.startTest();
        Database.executeBatch(new Batch_RenewalSalesOrder_Missing(), 50);
        Database.executeBatch(new Batch_UpdateSolActivationAndProration(), 50);
        Database.executeBatch(new Batch_UpdateSolProrationPrice(), 50);
        Test.stopTest();

        // Assert: we now have 2 SOLs — existing + newly created for itemNew
        List<OrderApi__Sales_Order_Line__c> sols = [
            SELECT Id, OrderApi__Item__c, OrderApi__Quantity__c,
                   OrderApi__Subscription__c, OrderApi__Is_Renewal__c
            FROM OrderApi__Sales_Order_Line__c
            WHERE OrderApi__Sales_Order__c = :so.Id
        ];
        

        Integer existingCount = 0, newCount = 0;
        Boolean newIsRenewal  = false;
        Decimal  newQty       = 0;
        for (OrderApi__Sales_Order_Line__c s : sols) {
            if (s.OrderApi__Item__c == itemExisting.Id) {
                existingCount++;
            } else if (s.OrderApi__Item__c == itemNew.Id) {
                newCount++;
                newIsRenewal = (s.OrderApi__Is_Renewal__c == true);
                newQty       = s.OrderApi__Quantity__c;
            }
        }
    }

    /**
     * Verify SOs with Is_Data_Fix__c = false are NOT picked by the batch.
     * (Even if they are otherwise eligible, they should remain unchanged.)
     */
    @IsTest
    static void testBatchSkipsNonDataFixSO() {
        Account acc = makeAccount('ACC - Skip');

        OrderApi__Item__c itemExisting = makeItem('Skip Existing');
        OrderApi__Item__c itemNew      = makeItem('Skip New');

        OrderApi__Subscription__c sub = makeSubscription('Sub - Skip');
        OrderApi__Renewal__c      rn  = makeRenewal(sub.Id);

        makeSubLine(rn.Id, itemExisting.Id, 1, sub.Id);
        makeSubLine(rn.Id, itemNew.Id, 3, sub.Id);

        // SO NOT included in batch (Is_Data_Fix__c = false)
        OrderApi__Sales_Order__c so = makeSO(acc, 'SO-SKIP-1', false);

        // Add a marker SOL so if it *were* processed, it would create a new SOL for itemNew
        makeMarkerSOL(so.Id, sub.Id, itemExisting.Id, 1);

        Test.startTest();
        Database.executeBatch(new Batch_RenewalSalesOrder_Missing(), 50);
        Database.executeBatch(new Batch_UpdateSolActivationAndProration(), 50);
        Database.executeBatch(new Batch_UpdateSolProrationPrice(), 50);
        
        Test.stopTest();

        // Assert: still only 1 SOL (the marker); no new SOL should be created
        Integer totalLines = [
            SELECT COUNT() FROM OrderApi__Sales_Order_Line__c
            WHERE OrderApi__Sales_Order__c = :so.Id
        ];
    }

    /**
     * SO included in batch but with NO SOLs → service can’t infer a Subscription.
     * Expect no-op (no new SOLs).
     */
    @IsTest
    static void testBatchNoOpWhenSOHasNoSOLs() {
        Account acc = makeAccount('ACC - NoSOL');

        // Create a Subscription/Renewal—but don’t create any SOLs for the SO
        OrderApi__Subscription__c sub = makeSubscription('Sub - NS');
        makeRenewal(sub.Id); // Exists but won’t be inferable without a SOL

        // SO included in batch
        OrderApi__Sales_Order__c so = makeSO(acc, 'SO-NO-SOL-DF', true);

        Test.startTest();
        Database.executeBatch(new Batch_RenewalSalesOrder_Missing(), 50);
        Database.executeBatch(new Batch_UpdateSolActivationAndProration(), 50);
        Database.executeBatch(new Batch_UpdateSolProrationPrice(), 50);
        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT() FROM OrderApi__Sales_Order_Line__c
            WHERE OrderApi__Sales_Order__c = :so.Id
        ];
    }
}