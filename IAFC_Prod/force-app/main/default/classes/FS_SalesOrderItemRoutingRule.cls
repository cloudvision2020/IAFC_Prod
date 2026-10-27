/**
 * Routing Rule for Sales Order Lint Item
 * @author Vishnu Pilli from fusionSpan
 * @date 2019-02-15
 */

global class FS_SalesOrderItemRoutingRule extends Framework.Domain {
	public FS_SalesOrderItemRoutingRule(List<OrderApi__Sales_Order_Line__c> sObjectList) {
        super(sObjectList);
    }

    global class Constructor implements Framework.Domain.DomainConstructor  {
        global Framework.Domain construct(List<SObject> sObjectList) {
            return new FS_SalesOrderItemRoutingRule(sObjectList);
        }
    }


    public override void afterInsert() {
        Framework.Log.push(FS_SalesOrderItemRoutingRule.class.getName(), 'afterInsert');
        //FS_SalesOrderItemRoutingRuleService.afterInsert((List<OrderApi__Sales_Order__c>) records);
        System.debug('##--Sales Order Line: After Create Routing rule');
        FS_SalesOrderItemRoutingRuleService.afterInsert((List<OrderApi__Sales_Order_Line__c>) records);

        Framework.Log.pop();
    }


    public override void afterUpdate(Map<Id, SObject> oldMap) {
        Framework.Log.push(FS_SalesOrderItemRoutingRule.class.getName(), 'afterUpdate');
        FS_SalesOrderItemRoutingRuleService.afterUpdate((List<OrderApi__Sales_Order_Line__c>) records, (Map<Id, OrderApi__Sales_Order_Line__c>) oldMap);
        Framework.Log.pop();
    }

    public override void afterDelete() {
        Framework.Log.push(FS_SalesOrderItemRoutingRule.class.getName(), 'afterDelete');
        FS_SalesOrderItemRoutingRuleService.afterDelete((List<OrderApi__Sales_Order_Line__c>) records);
        Framework.Log.pop();
    }

}	//	end of FS_SalesOrderItemRoutingRule