/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : OrderSummaryBuilderController
 * Author          : <YourName>
 * Created Date    : Aug 26, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Aug 26, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Aug 26, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */


public without sharing class OrderSummaryBuilderController {

    // Item Class names that classify a Sales Order Line for column purposes.

    private static final String ITEM_CLASS_MEMBERSHIP = Label.Item_Class_Membership;
    private static final String ITEM_CLASS_DIVISION = Label.Item_Class_Division;
    private static final String ITEM_CLASS_SECTIONS = Label.Item_Class_Sections;

    @AuraEnabled(cacheable=true)
    public static OrderSummaryResponse getOrderSummary(
        Id accountId,
        Id businessGroupId,
        Boolean openOnly
    ) {
        OrderSummaryResponse response = new OrderSummaryResponse();
        response.rows = new List<OrderRow>();
        response.businessGroups = new List<BusinessGroupOption>();
        response.pastDueTotal = 0;
        response.upcomingTotal = 0;
        response.openTotal = 0;

        if (accountId == null) {
            return response;
        }

        String soql =
            'SELECT Id, Name, ' +
            '       OrderApi__Encrypted_Id__c, ' +
            '       OrderApi__Due_Date__c, ' +
            '       OrderApi__Balance_Due__c, ' +
            '       OrderApi__Business_Group__c, ' +
            '       OrderApi__Business_Group__r.Name ' +
            'FROM OrderApi__Sales_Order__c ' +
            'WHERE OrderApi__Account__c = :accountId ' +
            '  AND OrderApi__Entity__c = \'Account\' ' +
            '  AND OrderApi__Is_Proforma__c = true ' +
            '  AND OrderApi__Posting_Entity__c = \'Receipt\' ' +
            '  AND OrderApi__Schedule_Type__c = \'Simple Receipt\' ' +
            '  AND OrderApi__Status__c = \'Closed\' ' +
            '  AND Id IN ( ' +
            '        SELECT OrderApi__Sales_Order__c ' +
            '        FROM OrderApi__Sales_Order_Line__c ' +
            '        WHERE OrderApi__Sales_Order_Line__c = null ' +
            '          AND OrderApi__Item__r.OrderApi__Is_Subscription__c = true ' +
            '  ) ' +
            '  AND Id IN ( ' +
            '        SELECT OrderApi__Sales_Order__c ' +
            '        FROM OrderApi__Sales_Order_Line__c ' +
            '        WHERE OrderApi__Contact__r.Has_Group_Membership__c = true ' +
            '  ) ';

        if (businessGroupId != null) {
            soql += ' AND OrderApi__Business_Group__c = :businessGroupId ';
        }
        if (openOnly == true) {
            soql += ' AND OrderApi__Sales_Order_Status__c IN (\'Draft\',\'Overdue\',\'Unpaid\') ';
            soql += ' AND OrderApi__Balance_Due__c > 0 ';
        }
        soql += ' ORDER BY OrderApi__Due_Date__c ASC, Name ASC ';

        List<OrderApi__Sales_Order__c> orders = Database.query(soql);

        Set<Id> orderIds = new Set<Id>();
        for (OrderApi__Sales_Order__c o : orders) {
            orderIds.add(o.Id);
        }

        // ---- One query for all lines; categorize by Item Class for column values ----
        Map<Id, Decimal> costByOrder = new Map<Id, Decimal>();
        Map<Id, String> fullNameByOrder = new Map<Id, String>();
        Map<Id, String> membershipTypeByOrder = new Map<Id, String>();
        Map<Id, String> divisionByOrder = new Map<Id, String>();
        Map<Id, List<String>> sectionNamesByOrder = new Map<Id, List<String>>();

        if (!orderIds.isEmpty()) {
            for (OrderApi__Sales_Order_Line__c line : [
                SELECT Id,
                       OrderApi__Sales_Order__c,
                       OrderApi__Sale_Price__c,
                       Contact_Name__c,
                       OrderApi__Price_Rule__c,
                       OrderApi__Price_Rule__r.Name,
                       OrderApi__Item_Name__c,
                       OrderApi__Item_Class__c,
                       OrderApi__Item_Class__r.Name
                FROM OrderApi__Sales_Order_Line__c
                WHERE OrderApi__Sales_Order__c IN :orderIds
            ]) {
                Id ordId = line.OrderApi__Sales_Order__c;

                // Cost = sum of Sale Price across ALL lines on the order
                Decimal price = (line.OrderApi__Sale_Price__c == null) ? 0 : line.OrderApi__Sale_Price__c;
                costByOrder.put(ordId, (costByOrder.containsKey(ordId) ? costByOrder.get(ordId) : 0) + price);

                // Full Name — take the first non-blank contact name found on any line for this order
                if (!fullNameByOrder.containsKey(ordId) && String.isNotBlank(line.Contact_Name__c)) {
                    fullNameByOrder.put(ordId, line.Contact_Name__c);
                }

                String itemClassName = (line.OrderApi__Item_Class__r != null)
                    ? line.OrderApi__Item_Class__r.Name
                    : null;

                if (itemClassName == ITEM_CLASS_MEMBERSHIP) {
                    if (!membershipTypeByOrder.containsKey(ordId)) {
                        membershipTypeByOrder.put(ordId, line.OrderApi__Item_Name__c);
                    }
                } else if (itemClassName == ITEM_CLASS_DIVISION) {
                    if (!divisionByOrder.containsKey(ordId) && line.OrderApi__Price_Rule__r != null) {
                        divisionByOrder.put(ordId, line.OrderApi__Price_Rule__r.Name);
                    }
                } else if (itemClassName == ITEM_CLASS_SECTIONS) {
                    if (!sectionNamesByOrder.containsKey(ordId)) {
                        sectionNamesByOrder.put(ordId, new List<String>());
                    }
                    String itemName = line.OrderApi__Item_Name__c;
                    if (itemName != null && !sectionNamesByOrder.get(ordId).contains(itemName)) {
                        sectionNamesByOrder.get(ordId).add(itemName);
                    }
                }
            }
        }

        Date today = Date.today();
        Map<Id, BusinessGroupOption> bgMap = new Map<Id, BusinessGroupOption>();

        for (OrderApi__Sales_Order__c o : orders) {
            OrderRow row = new OrderRow();
            row.id = o.Id;
            row.encryptedId = o.OrderApi__Encrypted_Id__c;
            row.orderNumber = o.Name;
            row.dueDate = o.OrderApi__Due_Date__c;
            row.balanceDue = o.OrderApi__Balance_Due__c == null ? 0 : o.OrderApi__Balance_Due__c;
            row.businessGroupId = o.OrderApi__Business_Group__c;
            row.businessGroupName = o.OrderApi__Business_Group__r != null
                ? o.OrderApi__Business_Group__r.Name : '';

            row.fullName = fullNameByOrder.get(o.Id);
            row.membershipType = membershipTypeByOrder.get(o.Id);
            row.division = divisionByOrder.get(o.Id);
            row.sections = sectionNamesByOrder.containsKey(o.Id)
                ? String.join(sectionNamesByOrder.get(o.Id), ', ')
                : '';
            row.cost = costByOrder.containsKey(o.Id) ? costByOrder.get(o.Id) : 0;

            row.isPastDue = (o.OrderApi__Due_Date__c != null
                             && o.OrderApi__Due_Date__c < today
                             && row.balanceDue > 0);

            response.rows.add(row);

            // Card totals — only unpaid balances count
            if (row.balanceDue > 0) {
                response.openTotal += row.balanceDue;
                if (row.isPastDue) {
                    response.pastDueTotal += row.balanceDue;
                } else {
                    response.upcomingTotal += row.balanceDue;
                }
            }

            // Distinct business groups for the dropdown
            if (o.OrderApi__Business_Group__c != null
                && !bgMap.containsKey(o.OrderApi__Business_Group__c)) {
                BusinessGroupOption opt = new BusinessGroupOption();
                opt.value = o.OrderApi__Business_Group__c;
                opt.label = row.businessGroupName;
                bgMap.put(o.OrderApi__Business_Group__c, opt);
            }
        }

        response.businessGroups = bgMap.values();
        return response;
    }

    // ---- Wrappers ----
    public class OrderSummaryResponse {
        @AuraEnabled public Decimal pastDueTotal { get; set; }
        @AuraEnabled public Decimal upcomingTotal { get; set; }
        @AuraEnabled public Decimal openTotal { get; set; }
        @AuraEnabled public List<OrderRow> rows { get; set; }
        @AuraEnabled public List<BusinessGroupOption> businessGroups { get; set; }
    }

    public class OrderRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String encryptedId { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public String fullName { get; set; }
        @AuraEnabled public String membershipType { get; set; }
        @AuraEnabled public String division { get; set; }
        @AuraEnabled public String sections { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public Date dueDate { get; set; }
        @AuraEnabled public Decimal balanceDue { get; set; }
        @AuraEnabled public Id businessGroupId { get; set; }
        @AuraEnabled public String businessGroupName { get; set; }
        @AuraEnabled public Boolean isPastDue { get; set; }
    }

    public class BusinessGroupOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }
}