/**
 * Routing Rule for Community Group Member
 * @author Jiawei Zhou from fusionSpan
 * @date 2018-12-18
 */

global class FS_CommunityGroupMemberRoutingRule extends Framework.Domain {

    public FS_CommunityGroupMemberRoutingRule(List<PagesApi__Community_Group_Member__c> sObjectList) {
        super(sObjectList);
    }

    global class Constructor implements Framework.Domain.DomainConstructor  {
        global Framework.Domain construct(List<SObject> sObjectList) {
            return new FS_CommunityGroupMemberRoutingRule(sObjectList);
        }
    }

//    public override void beforeInsert() {
//        Framework.Log.push(FS_CommunityGroupMemberRoutingRule.class.getName(), 'beforeInsert');
//        //FS_CommunityGroupMemberRoutingRuleServic.beforeInsert((List<PagesApi__Community_Group_Member__c>) records);
//        Framework.Log.pop();
//    }

    public override void afterInsert() {
        Framework.Log.push(FS_CommunityGroupMemberRoutingRule.class.getName(), 'afterInsert');
        FS_CommunityGroupMemberRoutingRuleServic.afterInsert((List<PagesApi__Community_Group_Member__c>) records);
        Framework.Log.pop();
    }

//    public override void beforeUpdate(Map<Id, SObject> oldMap) {
//        Framework.Log.push(FS_CommunityGroupMemberRoutingRule.class.getName(), 'beforeUpdate');
//        //FS_CommunityGroupMemberRoutingRuleServic.beforeUpdate((List<PagesApi__Community_Group_Member__c>) records, (Map<Id, PagesApi__Community_Group_Member__c>) oldMap);
//        Framework.Log.pop();
//    }

    public override void afterUpdate(Map<Id, SObject> oldMap){
        Framework.Log.push(FS_CommunityGroupMemberRoutingRule.class.getName(), 'afterUpdate');
        FS_CommunityGroupMemberRoutingRuleServic.afterUpdate((List<PagesApi__Community_Group_Member__c>) records,
                (Map<Id, PagesApi__Community_Group_Member__c>) oldMap);
        Framework.Log.pop();
    }

    public override void afterDelete(){
        Framework.Log.push(FS_CommunityGroupMemberRoutingRule.class.getName(), 'afterDelete');
        FS_CommunityGroupMemberRoutingRuleServic.afterDelete((List<PagesApi__Community_Group_Member__c>) records);
        Framework.Log.pop();
    }
}