/**
 * Routing Rule for Contact
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-11
 */

global class FS_ContactRoutingRule extends Framework.Domain {
    public FS_ContactRoutingRule(List<Contact> sObjectList) {
        super(sObjectList);
    }

    global class Constructor implements Framework.Domain.DomainConstructor  {
        global Framework.Domain construct(List<SObject> sObjectList) {
            return new FS_ContactRoutingRule(sObjectList);
        }
    }

    public override void beforeInsert() {
        Framework.Log.push(FS_ContactRoutingRule.class.getName(), 'beforeInsert');
        FS_ContactRoutingRuleService.beforeInsert((List<Contact>) records);
        Framework.Log.pop();
    }

    public override void afterInsert() {
        Framework.Log.push(FS_ContactRoutingRule.class.getName(), 'afterInsert');
        //FS_ContactRoutingRuleService.afterInsert((List<Contact>) records);
        Framework.Log.pop();
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap) {
        Framework.Log.push(FS_ContactRoutingRule.class.getName(), 'beforeUpdate');
        FS_ContactRoutingRuleService.beforeUpdate((List<Contact>) records, (Map<Id, Contact>) oldMap);
        Framework.Log.pop();
    }

    public override void afterUpdate(Map<Id, SObject> oldMap) {
        Framework.Log.push(FS_ContactRoutingRule.class.getName(), 'afterUpdate');
        FS_ContactRoutingRuleService.updateUserEmail((List<Contact>) records, (Map<Id,Contact>)oldMap);
        //FS_ContactRoutingRuleService.afterUpdate((List<Contact>) records, (Map<Id, Contact>) oldMap);
        Framework.Log.pop();
    }

}