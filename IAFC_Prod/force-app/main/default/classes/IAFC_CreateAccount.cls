global class IAFC_CreateAccount {
    @InvocableMethod
    public static List<Account> CreateAccount(List<Account> account) {
        try{ 
            insert account;
            return account;
           
        } catch(DmlException e) {
            System.debug('A DML exception has occurred:'+
                        e.getMessage());
            return null;
        }
    }
}