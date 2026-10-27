/*
@desc
*Case-1* If Division on the Contact object  is changed after proforma generation and
does not match the Division Item on the Sales Order Line THEN Proforma Sync is TRUE on sales order
*Case-2* If Functional Title on the Contact object is changed after proforma generation and 
the proforma Sales Order Line that includes the Individual IAFC Dues Item class and 
does not correspond to the correct Functional Title THEN Proforma Sync is TRUE
*/

global without sharing class  FS_ContactPerformaRoutingRule extends Framework.Domain {
    public static boolean isAfterUpdateRun = true;
    public FS_ContactPerformaRoutingRule(List<Contact> sObjectList) {
        super(sObjectList);
    }
    
    global class Constructor implements Framework.Domain.DomainConstructor {
        public Framework.Domain construct(List<SObject> sObjectList) {
            return new FS_ContactPerformaRoutingRule(sObjectList);
        }
    }
    
    public override void afterUpdate(Map<Id, SObject> oldMap) {
        Framework.Log.push(FS_ContactPerformaRoutingRule.class.getName(), 'afterUpdate');
        if(isAfterUpdateRun){
            if(!test.isRunningTest()) isAfterUpdateRun = false;
            FS_ContactPerformaService.updatePerforma((List<Contact>) records, (Map<Id, contact>)oldMap );
        }
        Framework.Log.pop();
    }
}