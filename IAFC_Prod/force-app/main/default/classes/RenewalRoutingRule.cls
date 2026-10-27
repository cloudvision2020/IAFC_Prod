global class RenewalRoutingRule extends Framework.Domain {
    public RenewalRoutingRule(List<OrderApi__Renewal__c> sObjectList) {
        super(sObjectList);
    }

    global class Constructor implements Framework.Domain.DomainConstructor  {
        global Framework.Domain construct(List<SObject> sObjectList) {
            return new RenewalRoutingRule(sObjectList);
        }
    }
    public override void afterInsert() {
        Framework.Log.push(RenewalRoutingRule.class.getName(), 'afterInsert');
        RenewalRoutingRuleService.afterInsert((List<OrderApi__Renewal__c>) records);
        Framework.Log.pop();
    }
    public override void afterUpdate(Map<Id, SObject> oldMap) {
        Framework.Log.push(RenewalRoutingRule.class.getName(), 'afterUpdate');
        RenewalRoutingRuleService.afterUpdate((List<OrderApi__Renewal__c>) records,
                (Map<Id, OrderApi__Renewal__c>) oldMap);
        Framework.Log.pop();
    }
}