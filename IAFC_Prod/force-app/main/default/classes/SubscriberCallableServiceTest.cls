@IsTest
private class SubscriberCallableServiceTest {

    @IsTest
    static void testGetPrice_Success() {
        // 1. Setup Test Data
        String accId = '001xx000003DGp0AAG';
        String itemId = '01txx000003DGp0AAG';
        Integer qty = 5;

        // Note: If FDService relies on database records, insert them here.
        // If FDService is a mockable service, you'd configure the mock now.

        SubscriberCallableService service = new SubscriberCallableService();

        Test.startTest();
        // 2. Test the direct method
        Decimal result = service.getPrice(accId, itemId, qty);
        Test.stopTest();

        // 3. Verify results 
        // We assert against 0 here assuming no FDService logic is hit, 
        // or replace with expected value if FDService is functional in tests.
        Assert.areNotEqual(null, result, 'The price should not be null.');
    }

    @IsTest
    static void testCallableEntryPoint() {
        // 1. Setup Arguments
        SubscriberCallableService service = new SubscriberCallableService();
        Map<String, Object> args = new Map<String, Object>{
            'accountId' => '001xx000003DGp0AAG',
            'itemId' => '01txx000003DGp0AAG',
            'quantity' => 10
        };

        Test.startTest();
        // 2. Execute via the Callable interface
        Object result = service.call('getPrice', args);
        
        // 3. Execute with an invalid action
        Object invalidResult = service.call('nonExistentMethod', args);
        Test.stopTest();

        // 4. Assertions
        Assert.isTrue(result instanceof Decimal, 'Result should be a Decimal');
        Assert.isNull(invalidResult, 'Invalid action should return null');
    }
}