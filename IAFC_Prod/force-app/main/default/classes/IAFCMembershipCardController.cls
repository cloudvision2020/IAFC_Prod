/**
 * IAFCMembershipCardController
 * Controller for IAFC Membership Card displaying Contact and OrderApi Subscription details
 * Uses ONLY OrderApi standard fields - no custom fields required
 */
public with sharing class IAFCMembershipCardController {
    
    // Properties
    public Contact member { get; set; }
    public OrderApi__Subscription__c subscription { get; set; }
    public Boolean hasSubscription { get; set; }
    public String membershipStatus { get; set; }
    public List<String> activeSectionsList { get; set; }
    
    // Constructor
    public IAFCMembershipCardController() {
    
            Id currentUserId = UserInfo.getUserId();
        
        User u = [
            SELECT Id, ContactId, AccountId
            FROM User
            WHERE Id = :currentUserId
            LIMIT 1
        ];
        
        Id contactId = u.ContactId;

       // String contactId = ApexPages.currentPage().getParameters().get('id');
        hasSubscription = false;
        activeSectionsList = new List<String>();
        
        if (String.isNotBlank(contactId)) {
            loadMembershipData(contactId);
        } else {
            member = new Contact();
            subscription = new OrderApi__Subscription__c();
        }
    }
    
    /**
     * Load membership data from Contact and OrderApi Subscription
     */
    private void loadMembershipData(String contactId) {
        try {
            // Query Contact details
                member = [SELECT Id,
                        FirstName,
                        LastName,
                        Name,
                        Membership_Expiration__c,
                        Rejoin_Date__c,
                        iMIS_Legacy_Id__c,
                        Active_Sections__c,
                        Division__c,
                        Email,
                        Phone
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1];

            
            // Parse active sections
            parseActiveSections();
            
            // Query most recent active OrderApi Subscription for this Contact
            // Using ONLY standard OrderApi fields
            List<OrderApi__Subscription__c> subscriptions = [SELECT Id,
                                                          Name,
                                                          OrderApi__Contact__c,
                                                          OrderApi__Activated_Date__c,
                                                          OrderApi__Current_Term_End_Date__c,
                                                          OrderApi__Current_Term_Start_Date__c
                                                   FROM OrderApi__Subscription__c
                                                   WHERE OrderApi__Contact__c = :contactId
                                                   ORDER BY OrderApi__Activated_Date__c DESC NULLS LAST
                                                   LIMIT 1];
            
            if (!subscriptions.isEmpty()) {
                subscription = subscriptions[0];
                hasSubscription = true;
            } else {
                subscription = new OrderApi__Subscription__c();
                hasSubscription = false;
            }
            
            // Calculate membership status
            calculateMembershipStatus();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Error loading membership data: ' + e.getMessage()
            ));
        }
    }
    
    /**
     * Parse active sections from multi-select picklist or text field
     */
    private void parseActiveSections() {
        activeSectionsList = new List<String>();
        
        if (String.isNotBlank(member.Active_Sections__c)) {
            // Handle both semicolon and comma separators
            if (member.Active_Sections__c.contains(';')) {
                activeSectionsList = member.Active_Sections__c.split(';');
            } else if (member.Active_Sections__c.contains(',')) {
                activeSectionsList = member.Active_Sections__c.split(',');
            } else {
                activeSectionsList.add(member.Active_Sections__c);
            }
            
            // Trim whitespace from each section
            List<String> trimmedList = new List<String>();
            for (String section : activeSectionsList) {
                if (String.isNotBlank(section)) {
                    trimmedList.add(section.trim());
                }
            }
            activeSectionsList = trimmedList;
        }
    }
    
    /**
     * Calculate membership status based on expiration and subscription dates
     */
    private void calculateMembershipStatus() {
        Date expirationDate = null;
        
        // Check OrderApi current term end date first
        if (hasSubscription && subscription.OrderApi__Current_Term_End_Date__c != null) {
            expirationDate = subscription.OrderApi__Current_Term_End_Date__c;
        }
        // Fall back to contact membership expiration
        else if (member.Membership_Expiration__c != null) {
            expirationDate = member.Membership_Expiration__c;
        }
        
        if (expirationDate != null) {
            if (expirationDate >= Date.today()) {
                membershipStatus = 'ACTIVE';
            } else {
                membershipStatus = 'EXPIRED';
            }
        } else {
            membershipStatus = 'UNKNOWN';
        }
    }
    
    /**
     * Get membership expiration date (prioritize subscription over contact)
     */
   /* public String getMembershipExpiration() {
        if (hasSubscription && subscription.OrderApi__Current_Term_End_Date__c != null) {
            return subscription.OrderApi__Current_Term_End_Date__c.format();
        } else if (member.Membership_Expiration__c != null) {
            return member.Membership_Expiration__c.format();
        }
        return 'N/A';
    }*/
    public String getMembershipExpiration() {
        if (member.Membership_Expiration__c != null) {
            return member.Membership_Expiration__c.format();
        }
        return 'N/A';
    }

    
    /**
     * Get formatted activated date
     */
    public String getFormattedActivatedDate() {
        if (hasSubscription && subscription.OrderApi__Activated_Date__c != null) {
            return subscription.OrderApi__Activated_Date__c.format();
        }
        return 'N/A';
    }
    
    /**
     * Get formatted expired date (using term end date)
     */
    public String getFormattedExpiredDate() {
        if (hasSubscription && subscription.OrderApi__Current_Term_End_Date__c != null) {
            return subscription.OrderApi__Current_Term_End_Date__c.format();
        }
        return 'N/A';
    }
    
    /**
     * Get formatted paid through date (using term end date)
     */
    public String getFormattedPaidThroughDate() {
        if (hasSubscription && subscription.OrderApi__Current_Term_End_Date__c != null) {
            return subscription.OrderApi__Current_Term_End_Date__c.format();
        }
        return 'N/A';
    }
    
    /**
     * Get CSS class for status badge
     */
    public String getStatusBadgeClass() {
        if (membershipStatus == 'ACTIVE') {
            return 'status-badge status-active';
        } else if (membershipStatus == 'EXPIRED') {
            return 'status-badge status-expired';
        }
        return 'status-badge status-unknown';
    }
    
    /**
     * Check if membership is active
     */
    public Boolean getIsActive() {
        return membershipStatus == 'ACTIVE';
    }
    
    /**
     * Check if membership is expired
     */
    public Boolean getIsExpired() {
        return membershipStatus == 'EXPIRED';
    }
    
    /**
     * Get member since date (from subscription activated date)
     */
    /*public String getMemberSince() {
        if (hasSubscription && subscription.OrderApi__Activated_Date__c != null) {
            return subscription.OrderApi__Activated_Date__c.format();
        }
        return 'N/A';
    }*/
    public String getMemberSince() {
    if (member.Rejoin_Date__c != null) {
        return member.Rejoin_Date__c.format();
    }
    return 'N/A';
   }

    
    /**
     * Get full member name
     */
    public String getMemberName() {
        if (String.isNotBlank(member.FirstName) && String.isNotBlank(member.LastName)) {
            return member.FirstName + ' ' + member.LastName;
        } else if (String.isNotBlank(member.Name)) {
            return member.Name;
        }
        return 'Member Name';
    }
    
    /**
     * Check if contact has active sections
     */
    public Boolean getHasActiveSections() {
        return !activeSectionsList.isEmpty();
    }
    
    /**
     * Get formatted division text
     */
    public String getFormattedDivision() {
        if (String.isNotBlank(member.Division__c)) {
            return member.Division__c;
        }
        return 'N/A';
    }
    
    /**
     * Get formatted iMIS Legacy ID
     */
    public String getFormattedLegacyId() {
        if (String.isNotBlank(member.iMIS_Legacy_Id__c)) {
            return member.iMIS_Legacy_Id__c;
        }
        return 'N/A';
    }
}