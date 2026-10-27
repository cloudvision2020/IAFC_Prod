/**
 * Routing Rule for Subscription
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-12
 */

global class FS_SubscriptionRoutingRule extends Framework.Domain {
    public FS_SubscriptionRoutingRule(List<OrderApi__Subscription__c> sObjectList) {
        super(sObjectList);
    }

    global class Constructor implements Framework.Domain.DomainConstructor  {
        global Framework.Domain construct(List<SObject> sObjectList) {
            return new FS_SubscriptionRoutingRule(sObjectList);
        }
    }

//    public override void beforeInsert() {
//        Framework.Log.push(FS_SubscriptionRoutingRule.class.getName(), 'beforeInsert');
//        Framework.Log.pop();
//    }

    public override void afterInsert() {
        Framework.Log.push(FS_SubscriptionRoutingRule.class.getName(), 'afterInsert');
        FS_SubscriptionRoutingRuleService.afterInsert((List<OrderApi__Subscription__c>) records);
        Framework.Log.pop();
    }

//    public override void beforeUpdate(Map<Id, SObject> oldMap) {
//        Framework.Log.push(FS_SubscriptionRoutingRule.class.getName(), 'beforeUpdate');
//        Framework.Log.pop();
//    }

    public override void afterUpdate(Map<Id, SObject> oldMap) {
        Framework.Log.push(FS_SubscriptionRoutingRule.class.getName(), 'afterUpdate');
        FS_SubscriptionRoutingRuleService.afterUpdate((List<OrderApi__Subscription__c>) records,
                (Map<Id, OrderApi__Subscription__c>) oldMap);
        Framework.Log.pop();
    }
}