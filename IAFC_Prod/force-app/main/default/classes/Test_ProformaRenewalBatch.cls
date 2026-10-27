@isTest
private class Test_ProformaRenewalBatch {

  @TestSetup
    private static void setup() {
    
        Account account = FS_TestUtils.createAccount('Test Account Name');
        insert account;

    
        Contact contact = FS_TestUtils.createContact('Test Contact', 'contact@test.com'); 
        contact.AccountId=account.Id;
        contact.Functional_Title__c='2-3 Crossed Bugle Chief Officer';
        contact.MailingCountryCode='US';
        //contact.Division__c = 'Estern';
        contact.MailingStateCode='MD';
        contact.Senior_Metro_Approved__c = true;
        contact.International_Metro_Approved__c = true;
        insert contact;
        contact = [SELECT Id, Name, Functional_Title__c, MailingCountryCode, MailingStateCode, Division__c FROM Contact WHERE Id=:contact.Id];
        System.debug('##--Contact: ' + contact);
        
        OrderApi__Business_Group__c businessGroup = FS_TestUtils.createBusinessGroup('International Society of Automation');
        insert businessGroup;

        OrderApi__Item_Class__c itemClass = FS_TestUtils.createItemClass('Divisions');
        itemClass.OrderApi__Is_Active__c=true;
        itemClass.OrderApi__Business_Group__c=businessGroup.Id;
        insert itemClass;

        OrderApi__Item_Class__c itemClassSection = FS_TestUtils.createItemClass('Sections');
        itemClassSection.OrderApi__Is_Active__c=true;
        itemClassSection.OrderApi__Business_Group__c=businessGroup.Id;
        insert itemClassSection;

        PagesApi__Community_Group__c communityGroup = new PagesApi__Community_Group__c(Name='Eastern');
        insert communityGroup;

        PagesApi__Community_Group__c commGrp = new PagesApi__Community_Group__c(Name='EVMS');
        commGrp.PagesApi__Type__c='Section';
        insert commGrp;
        
        PagesApi__Community_Group__c communityGroupMetro = new PagesApi__Community_Group__c(Name='Metro Chiefs');
        insert communityGroupMetro ;

        PagesApi__Community_Group_Member__c commGrpMemMetro = new PagesApi__Community_Group_Member__c();
        commGrpMemMetro.PagesApi__Contact__c= contact.Id;
        commGrpMemMetro.PagesApi__Community_Group__c=communityGroupMetro.Id;
        commGrpMemMetro.PagesApi__Is_Active__c = true;
        commGrpMemMetro.PagesApi__Role__c = 'Member';
        insert commGrpMemMetro;
        
        OrderApi__Item__c item = FS_TestUtils.createItem('Basic Membership', itemClass.Id);
        item.OrderApi__Business_Group__c=businessGroup.Id;
        item.FS_Item_Functional_Titles__c='Administrative Support';
        item.FS_Community_Group__c=communityGroup.Id;

        item.OrderApi__Is_Active__c= true;

        insert item;
        System.debug('##--Item: ' + Item);

        OrderApi__Item__c itemSection = FS_TestUtils.createItem('Section Membership', itemClassSection.Id);
        itemSection.OrderApi__Business_Group__c=businessGroup.Id;
        item.FS_Community_Group__c=commGrp.Id;
        itemSection.OrderApi__Is_Active__c=true;
        insert itemSection;
        
        OrderApi__Item__c itemMetro = FS_TestUtils.createItem('Metropolitan Fire Chiefs', itemClassSection.Id);
        itemMetro.OrderApi__Business_Group__c=businessGroup.Id;
        itemMetro.FS_Community_Group__c=communityGroupMetro.Id;
        itemMetro.OrderApi__Is_Active__c=true;
        insert itemMetro;

       
        Profile p = [SELECT Id FROM Profile WHERE Name='Fonteva Customer Community Login User'];

        User user = new User(Alias='standt', Email='test@example.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId=p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test@example.com', ContactId=contact.Id);
        insert user;

        PagesApi__Community_Group_Member__c commGrpMem = new PagesApi__Community_Group_Member__c();
        commGrpMem.PagesApi__Contact__c=contact.Id;
        commGrpMem.PagesApi__Community_Group__c=commGrp.Id;
        insert commGrpMem;
 

        // TODO: Create Sales Order that satisfies the batch condition
        OrderApi__Sales_Order__c objSalesOrder = FS_TestUtils.createSalesOrder(contact.Id, account.Id, 'Receipt', 'Closed');
        objSalesOrder.OrderApi__Schedule_Type__c='Simple Receipt';
        objSalesOrder.OrderApi__Posting_Status__c='Pending';
        objSalesOrder.OrderApi__Entity__c='Contact';
        insert objSalesOrder;
        
        //  TODO: Create Sales Order Items that satisfies the condition
        OrderApi__Sales_Order_Line__c objSalesLine = FS_TestUtils.createSalesOrderLine(item.Id, objSalesOrder.Id, contact.Id, account.Id);
        objSalesLine.OrderApi__Contact__c = contact.Id;
        objSalesLine.OrderApi__Is_Subscription__c=true;
        objSalesLine.OrderApi__Is_Renewal__c=true;
        insert objSalesLine;

    }  //  end of setup
  
  @isTest static void testBatchProcess() {
    // Implement test code
    Test.startTest();
    Database.executeBatch(new ProformaRenewalBatch());
    Test.stopTest();
    
    List<OrderApi__Sales_Order__c> lstOrder = [SELECT Id FROM OrderApi__Sales_Order__c];
    System.debug('##--Sales Order: ' + lstOrder);
    List<OrderApi__Sales_Order_Line__c> lstLines = [SELECT Id, Name FROM OrderApi__Sales_Order_Line__c WHERE OrderApi__Sales_Order__c=:lstOrder[0].Id];
    //System.assertEquals(true, lstLines.size() == 2);
	
  }  //  end of testBatchProcess
    @isTest
    static void testExecuteMethod() {
        Test.startTest();
        ProformaRenewalBatch scheduler = new ProformaRenewalBatch();
        scheduler.execute(null); 
        Test.stopTest();

        // Add assertions for the execute method if needed
    }
  
  
}  //  end of FS_ProformaRenewalBatchTest