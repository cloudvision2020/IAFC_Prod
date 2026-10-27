/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : MultiOrderInvoiceController
 * Author          : <YourName>
 * Created Date    : Jul 20, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Jul 20, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jul 20, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */ 


public without sharing class MultiOrderInvoiceController {

    // Item Class names used to identify Division / Sections / Membership lines — keep in sync
    // with OrderSummaryBuilderController's ITEM_CLASS_* constants.
    private static final String ITEM_CLASS_DIVISION = Label.Item_Class_Division;
    private static final String ITEM_CLASS_SECTIONS = Label.Item_Class_Sections;
    private static final String ITEM_CLASS_MEMBERSHIP = Label.Item_Class_Membership;

    public MultiInvoiceResult result { get; private set; }

    public MultiOrderInvoiceController() {
        String idsParam = ApexPages.currentPage().getParameters().get('ids');
        this.result = buildInvoices(idsParam);
    }

    public static MultiInvoiceResult buildInvoices(String idsParam) {
        MultiInvoiceResult out = new MultiInvoiceResult();
        out.groupRows = new List<GroupInvoiceRow>();
        out.standardRows = new List<StandardInvoiceRow>();
        if (String.isBlank(idsParam)) return out;

        List<String> orderedEncIds = new List<String>();
        Set<String> seen = new Set<String>();
        for (String raw : idsParam.split(',')) {
            String t = raw == null ? '' : raw.trim();
            t = t.replace(' ', '+');
            if (String.isNotBlank(t) && !seen.contains(t)) {
                orderedEncIds.add(t);
                seen.add(t);
            }
        }
        if (orderedEncIds.isEmpty()) return out;

        Map<String, OrderApi__Sales_Order__c> ordersByEnc =
            new Map<String, OrderApi__Sales_Order__c>();
        Set<Id> orderRecordIds = new Set<Id>();

        for (OrderApi__Sales_Order__c so : [
            SELECT Id, Name,
                   OrderApi__Encrypted_Id__c,
                   OrderApi__Due_Date__c,
                   OrderApi__Account__c,
                   OrderApi__Account__r.Name,
                   OrderApi__Account__r.OrderApi__Primary_Contact__r.Name,
                   OrderApi__Account__r.Has_Group_Membership__c,
                   OrderApi__Account__r.BillingStreet,
                   OrderApi__Account__r.BillingCity,
                   OrderApi__Account__r.BillingState,
                   OrderApi__Account__r.BillingPostalCode,
                   OrderApi__Account__r.BillingCountry
            FROM OrderApi__Sales_Order__c
            WHERE OrderApi__Encrypted_Id__c IN :seen
        ]) {
            ordersByEnc.put(so.OrderApi__Encrypted_Id__c, so);
            orderRecordIds.add(so.Id);
        }

        List<OrderApi__Sales_Order_Line__c> allLines = [
            SELECT Id, OrderApi__Sales_Order__c,
                   OrderApi__Line_Description__c,
                   OrderApi__Contact__c,
                   OrderApi__Contact__r.Name,
                   OrderApi__Contact__r.Membership_Type__c,
                   OrderApi__Contact__r.Sections__c,
                   OrderApi__Item_Name__c,
                   OrderApi__Item_Class__c,
                   OrderApi__Item_Class__r.Name,
                   OrderApi__Price_Rule__c,
                   OrderApi__Price_Rule__r.Name,
                   OrderApi__Activation_Date__c,
                   OrderApi__End_Date__c,
                   OrderApi__Sale_Price__c,
                   OrderApi__Quantity__c,
                   OrderApi__Overall_Total__c,
                   TermStartDate__c,
                   Term_End_Date__c
            FROM OrderApi__Sales_Order_Line__c
            WHERE OrderApi__Sales_Order__c IN :orderRecordIds
            AND OrderApi__Contact__c != null
            ORDER BY OrderApi__Contact__r.Name ASC
        ];

        Map<Id, List<OrderApi__Sales_Order_Line__c>> linesByOrder =
            new Map<Id, List<OrderApi__Sales_Order_Line__c>>();
        for (OrderApi__Sales_Order_Line__c line : allLines) {
            if (!linesByOrder.containsKey(line.OrderApi__Sales_Order__c)) {
                linesByOrder.put(line.OrderApi__Sales_Order__c,
                    new List<OrderApi__Sales_Order_Line__c>());
            }
            linesByOrder.get(line.OrderApi__Sales_Order__c).add(line);
        }

        Boolean headerSet = false;
        Boolean membershipTermSet = false;
        // group merge keyed by contact ACROSS all orders
        Map<Id, GroupInvoiceRow> groupByContact = new Map<Id, GroupInvoiceRow>();
        // tracks which Sales Order Names have contributed to each contact's merged row
        Map<Id, Set<String>> orderNumbersByContact = new Map<Id, Set<String>>();
        // tracks distinct Section item names per contact, across all selected orders
        Map<Id, Set<String>> sectionNamesByContact = new Map<Id, Set<String>>();
        // tracks distinct Membership item names per contact, across all selected orders
        Map<Id, Set<String>> membershipNamesByContact = new Map<Id, Set<String>>();

        for (String encId : orderedEncIds) {
            OrderApi__Sales_Order__c so = ordersByEnc.get(encId);
            if (so == null) continue;

            if (!headerSet && so.OrderApi__Account__r != null) {
                out.toName    = so.OrderApi__Account__r.Name;
                out.toStreet  = so.OrderApi__Account__r.BillingStreet;
                out.toCity    = so.OrderApi__Account__r.BillingCity;
                out.toState   = so.OrderApi__Account__r.BillingState;
                out.toZip     = so.OrderApi__Account__r.BillingPostalCode;
                out.toCountry = so.OrderApi__Account__r.BillingCountry;
                out.primaryContactName = (so.OrderApi__Account__r.OrderApi__Primary_Contact__r != null)
                    ? so.OrderApi__Account__r.OrderApi__Primary_Contact__r.Name
                    : null;
                out.isGroupMembership = so.OrderApi__Account__r.Has_Group_Membership__c == true;
                headerSet = true;
            }


            //Boolean isGroup = so.OrderApi__Account__r != null
              //  && so.OrderApi__Account__r.Has_Group_Membership__c == true;

            Boolean isGroup = true;

            List<OrderApi__Sales_Order_Line__c> lines = linesByOrder.containsKey(so.Id)
                ? linesByOrder.get(so.Id) : new List<OrderApi__Sales_Order_Line__c>();

            for (OrderApi__Sales_Order_Line__c line : lines) {
                Decimal lineCost = line.OrderApi__Sale_Price__c == null ? 0 : line.OrderApi__Sale_Price__c;

                String lineItemClassName = (line.OrderApi__Item_Class__r != null)
                    ? line.OrderApi__Item_Class__r.Name
                    : null;
                String lineDivision = (lineItemClassName == ITEM_CLASS_DIVISION
                        && line.OrderApi__Price_Rule__r != null)
                    ? line.OrderApi__Price_Rule__r.Name
                    : null;

                if (isGroup) {
                    Id cId = line.OrderApi__Contact__c;

                    if (!orderNumbersByContact.containsKey(cId)) {
                        orderNumbersByContact.put(cId, new Set<String>());
                    }
                    if (String.isNotBlank(so.Name)) {
                        orderNumbersByContact.get(cId).add(so.Name);
                    }

                    // Sections — derived from lines whose Item Class = 'Sections',
                    // NOT from Contact__r.Sections__c (that field was blank).
                    if (lineItemClassName == ITEM_CLASS_SECTIONS
                            && String.isNotBlank(line.OrderApi__Item_Name__c)) {
                        if (!sectionNamesByContact.containsKey(cId)) {
                            sectionNamesByContact.put(cId, new Set<String>());
                        }
                        sectionNamesByContact.get(cId).add(line.OrderApi__Item_Name__c);
                    }

                    // Membership Type — derived from lines whose Item Class =
                    // 'Individual IAFC Dues', NOT from Contact__r.Membership_Type__c
                    // (that field held a truncated value, e.g. "Full" instead of
                    // "Full Membership").
                    if (lineItemClassName == ITEM_CLASS_MEMBERSHIP
                            && String.isNotBlank(line.OrderApi__Item_Name__c)) {
                        if (!membershipNamesByContact.containsKey(cId)) {
                            membershipNamesByContact.put(cId, new Set<String>());
                        }
                        membershipNamesByContact.get(cId).add(line.OrderApi__Item_Name__c);

                        //new
                        if (!membershipTermSet
                            && line.TermStartDate__c != null
                            && line.Term_End_Date__c != null) {
                            out.membershipTermStart = line.TermStartDate__c;
                            out.membershipTermEnd   = line.Term_End_Date__c;
                            membershipTermSet = true;
                        }
                    }

                    if (groupByContact.containsKey(cId)) {
                        GroupInvoiceRow ex = groupByContact.get(cId);
                        ex.cost = (ex.cost == null ? 0 : ex.cost) + lineCost;
                        if (String.isBlank(ex.division) && lineDivision != null) {
                            ex.division = lineDivision;
                        }
                    } else {
                        GroupInvoiceRow row = new GroupInvoiceRow();
                        row.fullName = line.OrderApi__Contact__r.Name;
                        row.division = lineDivision;
                        row.cost = lineCost;
                        out.groupRows.add(row);
                        groupByContact.put(cId, row);
                    }
                    out.grandTotal += lineCost;
                } else {
                    StandardInvoiceRow row = new StandardInvoiceRow();
                    row.lineDescription = line.OrderApi__Line_Description__c;
                    row.contactName = line.OrderApi__Contact__r.Name;
                    row.itemName = line.OrderApi__Item_Name__c;
                    row.activationDate = line.OrderApi__Activation_Date__c;
                    row.endDate = line.OrderApi__End_Date__c;
                    row.salePrice = line.OrderApi__Sale_Price__c;
                    row.quantity = line.OrderApi__Quantity__c;
                    row.total = line.OrderApi__Overall_Total__c;
                    out.standardRows.add(row);
                    out.grandTotal += (line.OrderApi__Overall_Total__c == null ? 0 : line.OrderApi__Overall_Total__c);
                }
            }
        }

        // Finalize the comma-joined Sales Order #, Sections, and Membership Type
        // for each merged group row.
        for (Id cId : groupByContact.keySet()) {
            GroupInvoiceRow row = groupByContact.get(cId);

            Set<String> nums = orderNumbersByContact.get(cId);
            if (nums != null && !nums.isEmpty()) {
                row.orderNumber = String.join(new List<String>(nums), ', ');
            }

            Set<String> secs = sectionNamesByContact.get(cId);
            if (secs != null && !secs.isEmpty()) {
                row.sections = String.join(new List<String>(secs), ', ');
            }

            Set<String> memberships = membershipNamesByContact.get(cId);
            if (memberships != null && !memberships.isEmpty()) {
                row.membershipType = String.join(new List<String>(memberships), ', ');
            }
        }

        return out;
    }

    // ---- wrapper classes ----
    /*public class MultiInvoiceResult {
        public String toName { get; set; }
        public String toStreet { get; set; }
        public String toCity { get; set; }
        public String toState { get; set; }
        public String toZip { get; set; }
        public String toCountry { get; set; }
        public Boolean isGroupMembership { get; set; }
        public String primaryContactName { get; set; }
        public Decimal grandTotal { get; set; }
        public List<GroupInvoiceRow> groupRows { get; set; }
        public List<StandardInvoiceRow> standardRows { get; set; }
        public MultiInvoiceResult() { this.grandTotal = 0; this.isGroupMembership = false; }
    }*/
    public class MultiInvoiceResult {
    public String toName { get; set; }
    public String toStreet { get; set; }
    public String toCity { get; set; }
    public String toState { get; set; }
    public String toZip { get; set; }
    public String toCountry { get; set; }
    public Boolean isGroupMembership { get; set; }
    public String primaryContactName { get; set; }
    public Decimal grandTotal { get; set; }
    public List<GroupInvoiceRow> groupRows { get; set; }
    public List<StandardInvoiceRow> standardRows { get; set; }

    public Date membershipTermStart { get; set; }
    public Date membershipTermEnd { get; set; }

    public String getMembershipTermLabel() {
        if (membershipTermStart == null || membershipTermEnd == null) return null;
        return formatDate(membershipTermStart) + ' - ' + formatDate(membershipTermEnd);
    }

    private String formatDate(Date d) {
        return String.valueOf(d.month()) + '/' + String.valueOf(d.day()) + '/' + String.valueOf(d.year());
    }

    public MultiInvoiceResult() { this.grandTotal = 0; this.isGroupMembership = false; }
    }







    public class GroupInvoiceRow {
        public String orderNumber { get; set; }
        public String fullName { get; set; }
        public String membershipType { get; set; }
        public String division { get; set; }
        public String sections { get; set; }
        public Decimal cost { get; set; }
    }
    public class StandardInvoiceRow {
        public String lineDescription { get; set; }
        public String contactName { get; set; }
        public String itemName { get; set; }
        public Date activationDate { get; set; }
        public Date endDate { get; set; }
        public Decimal salePrice { get; set; }
        public Decimal quantity { get; set; }
        public Decimal total { get; set; }
    }
}