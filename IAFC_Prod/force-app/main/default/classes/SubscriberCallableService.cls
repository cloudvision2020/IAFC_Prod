// This class is created in the subscriber's org.
// It must be declared as 'global' to be callable from the managed package.
// It implements the Callable interface to provide a standard entry point.
Global class SubscriberCallableService implements System.Callable {

    // This is the public method that returns an integer.
    // It's the method the managed package will call.
    public Decimal getPrice(String accountId, String itemId, Integer quantity) {
       // The FDService.ItemPriceRule and FDService.ItemPriceService
        // classes must exist in the subscriber's org.
        FDService.ItemPriceRule itemRule = FDService.ItemPriceRule.getInstance();
        itemRule.account = accountId;
        itemRule.item = itemId;
        itemRule.quantity = quantity;

        List<FDService.ItemPriceRule> priceRules = new List<FDService.ItemPriceRule> {itemRule};
        List<FDService.ItemPriceRule> updatedRules = FDService.ItemPriceService.getInstance().getPrice(priceRules);

        // Assuming the first element and price are always available.
        if (!updatedRules.isEmpty() && updatedRules[0].priceRule.price != null) {
            return (Decimal)updatedRules[0].priceRule.price;
        }

        // Return a default value if the price is not found.
        return 0;
    }

    // The required call method from the Callable interface.
    // This method routes the dynamic call to the actual business logic.
    public Object call(String action, Map<String, Object> args) {
        
        // Use a switch statement to dispatch the call to the appropriate method
        switch on action {
            when 'getPrice' {
                // Extract the arguments from the map
               
                String accountId = (String)args.get('accountId');
                 String itemId = (String)args.get('itemId');
                Integer quantity = (Integer)args.get('quantity');

                // Call the actual method with the extracted arguments and return its result.
                return this.getPrice( accountId,itemId, quantity);
            }
            when else {
                // Return null or throw an exception if the action is not supported.
                return null;
            }
        }
    }
}