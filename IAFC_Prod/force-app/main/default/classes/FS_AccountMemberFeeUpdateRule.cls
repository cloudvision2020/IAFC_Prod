global class FS_AccountMemberFeeUpdateRule extends Framework.Domain{
    public FS_AccountMemberFeeUpdateRule(List<OrderApi__Subscription__c> sObjectList) {
        super(sObjectList);
    }

    global class Constructor implements Framework.Domain.DomainConstructor  {
        global Framework.Domain construct(List<SObject> sObjectList) {
            return new FS_AccountMemberFeeUpdateRule (sObjectList); 
        }
    }
    
    public override void afterInsert() {
        Framework.Log.push(FS_AccountMemberFeeUpdateRule.class.getName(),'After Insert');
        FS_AccountMemberFeeUpdate.afterInsertingAccount((List<OrderApi__Subscription__c>) records);
        Framework.Log.pop();
    }
    
     public override void afterUpdate(Map<Id, SObject> oldMap){
        Framework.Log.push(FS_AccountMemberFeeUpdateRule.class.getName(), 'afterUpdate');
        FS_AccountMemberFeeUpdate.afterUpdatingAccount((List<OrderApi__Subscription__c>) records,
                (Map<Id, OrderApi__Subscription__c>) oldMap);
        Framework.Log.pop();
    }
}