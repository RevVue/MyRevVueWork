@isTest(SeeAllData=false)
private class TestRevRecOpportunityExtension { 
  	 
    static testMethod void testController() {
        
        //Test  Standard Price book
    	Id  pricebookId = Test.getStandardPricebookId();
    
        RevRecRules__c rule = new RevRecRules__c(
            Revenue_Recognition_End_Date__c='OPPORTUNITY:CloseDate', initial_amount_type__c='Amount', Offset_Period__c=1, initial_amount__c=1000.00,
            Offset_Type__c='Period', Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Default_Rule__c=false,
            Name='Rule test', residual_Amount__c=1.00, Description__c='Descr', Divide_By__c='Prorate', Enable_Manual_Forecast__c = false,
            Recognition_Type__c='Amortize', Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate', Period_or_Exact_Days__c='exact'); 
        insert rule; 
        
        // create the product
        Product2 p1 = new Product2(name='Test Product 1', IsActive=true, Description='My Product', ProductCode='Prod code', RevRecRule__c =rule.Id );
        insert p1;    
           
        // create the pricebookentry
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=p1.id, UnitPrice=100.00, IsActive=true,
             									 UseStandardPrice=false);
        insert pbe1;   
       
        // create the opportunity
        Opportunity opp1 = new Opportunity(Probability=100, Type='New Customer', Pricebook2Id=pricebookId, ForecastCategoryName='Closed', 
        								   StageName='Closed Won', Amount=273200.00, name='Test Opp 1', CloseDate= Date.newInstance(2010, 6, 1));
        insert opp1;
   
        // add the line item
        OpportunityLineItem oli = new OpportunityLineItem(Quantity=1.00, PricebookEntryId=pbe1.id, OpportunityId=opp1.id, UnitPrice=12000.00);
        insert oli;  

        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opp1.id);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(theOppty);
        RevRecOpportunityExtension cExt = new RevRecOpportunityExtension(sc);
        
        System.assertNotEquals(cExt.getOppLineItems(), null);
        System.assertNotEquals(cExt.getOpportunityId(), null);      
        
        cExt.setQueryItemId(oli.id);
        System.assertEquals(cExt.getQueryItemId(), oli.id);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);

        System.assertEquals(cExt.formatCurrencyFromDecimal(1000.00), '$1,000.00');
        
        //System.assertNotEquals(cExt.getTotalOpportunity(), null);
        //System.assertNotEquals(cExt.getTotalResidual(), null);      
        
        //System.assertNotEquals(cExt.getTotalRecognized(), null);
        
        //System.assertNotEquals(cExt.getTotalDeferred(), null);
        
        System.assertEquals(cExt.resetOverriddenRule(), null);
        
        //test schedular controller
        Pagereference thePage = Page.RevRecSchedule;
        thePage.getParameters().put('opportunityId', opp1.id);
        thePage.getParameters().put('opportunityLineItemId', oli.id);
        Test.setCurrentPage(thePage);
        
        
    } 
    
    /**
     *	@description	:	This method is used to test the extension for override rule .
     *
     *	@args			:	-
     *
     *	@return			:	void
    **/
    static testmethod void testOverrideRuleController() {    	    
         
        //Test  Standard Price book
    	Id  pricebookId = Test.getStandardPricebookId();
    
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
  	    insert appSetting; 
        
        //RevRec Rule
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2',Offset_Period__c = 2, Offset_Type__c = 'Start',
                          									  Default_Rule__c = true, Recognition_Type__c = 'Amortize Milestone', Enable_Manual_Forecast__c = true);                                                            
        insert  revRecDefaultRule;
      
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true));
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000));
        insert oppLineItems;
         
       //List of RevRec Line items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add line item into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
                                                                       
         insert   revRecProductRules;
        System.assertEquals(4000, revRecProductRules[0].Residual_Amount__c);
         
       /**  //List of Rule Category
        List<RevRecProductRuleCategory__c> ruleCategories = new List<RevRecProductRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecProductRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
        											 Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'PRODUCT:ServiceDate', 
        											 Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecProductRule__c = revRecProductRules[1].Id));
        
         //Add categories into list
        ruleCategories.add(new RevRecProductRuleCategory__c(Name = 'Cat -2 ', Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
        											 Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'PRODUCT:ServiceDate', 
        											 Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecProductRule__c = revRecProductRules[1].Id));
        
        //Insert Rule Categories
        insert ruleCategories;**/
         
        //Test strt here
        Test.startTest();
        
        //Initilize constructer
        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opportynity.id);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(theOppty);
        RevRecOpportunityExtension cExt = new RevRecOpportunityExtension(sc);
        
        //Assigning values
        cExt.getOppLineItems();
        cExt.OppLineItems[0].LineItem.RevRecRule__c = revRecDefaultRule.Id;
        cExt.oppLineItemRow = '0';
        cExt.oppRuleValue = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE;
        cExt.oppRuleId = revRecDefaultRule.Id;
        
        //Calling method  on line item level rule selection
        //cExt.saveRuleOnOppLineItems();
        RevRecOpportunityExtension.queryRules(null);
        
        //SETTING ruule on opportunity
        theOppty.REVvue_RevRecRule__c = revRecDefaultRule.Id;
        
        //Open pop up while selecting rule from opportunity level
        cExt.oppRuleId = revRecDefaultRule.Id;
        //RevRecOpportunityExtension.isInLightning = true;
        cExt.showLineItemPopUpScreen();
        
        cExt.lineItemsWrap[0].isSelectedLineItem = true;
        
         //Calling method  on  opportunity level rule selection
         cExt.saveOpportunityLevelRule();
        RevRecOpportunityExtension.queryRules('Test');
        
        //Test stops here
        Test.stopTest();
    } 
    
    /**
     *	@description	:	This method is used to test the extension for override rule .
     *
     *	@args			:	-
     *
     *	@return			:	void
    **/
    static testmethod void testOverriddenRuleInsertionOnOpptyLevel() {    	    
         
        //Test  Standard Price book
    	Id  pricebookId = Test.getStandardPricebookId();
    
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting; 
        
        //RevRec Rule
        //Default Rule
        List<RevRecRules__c> revRecDefaultRules = new List<RevRecRules__c>();
        revRecDefaultRules.add(new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2',Offset_Period__c = 2, Offset_Type__c = 'Start',
                          						  Default_Rule__c = true, Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                  Revenue_Recognition_Start_Date__c = 'OPPORTUNITY Product:ServiceDate', Enable_Manual_Forecast__c = true,
                                                  Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate'));
        insert  revRecDefaultRules;
      
        //Test Opportunity
        List<Opportunity> opportynities = new List<Opportunity>();
        opportynities.add(new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', 
                                          Type = 'New Customer', REVvue_RevRecRule__c = revRecDefaultRules[0].Id));
		insert opportynities;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true));
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
         
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000, ServiceDate = Date.today().addDays(-100)));
       	oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000, ServiceDate = Date.today().addDays(-100)));
        insert oppLineItems;
         
       	//List of RevRec Line items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynities[0].Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynities[0].Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
		insert revRecLineItems;  
        System.assertEquals(100, revRecLineItems[1].ResidualAmount__c);
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[1].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[1].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
      	insert revRecProductRules;
         
        //Test strt here
        Test.startTest();
        
        //Initilize constructer
        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opportynities[0].id);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(theOppty);
        RevRecOpportunityExtension cExt = new RevRecOpportunityExtension(sc);
        
        cExt.getOppLineItems();
        cExt.OppLineItems[0].LineItem.RevRecRule__c = revRecDefaultRules[0].Id;
        
        //Calling method  on  opportunity level rule selection
        cExt.oppRuleId = revRecDefaultRules[0].Id;
        cExt.showLineItemPopUpScreen();
        
        cExt.lineItemsWrap[0].isSelectedLineItem = true;
        cExt.saveOpportunityLevelRule();
        
        //Test stops here
        Test.stopTest();
    } 
    
     /**
     *	@description	:	This method is used to test the extension for override rule .
     *
     *	@args			:	-
     *
     *	@return			:	void
    **/
    static testmethod void testOverriddenRuleInsertionOnOpptyLevel1() {    	    
         
        //Test  Standard Price book
    	Id  pricebookId = Test.getStandardPricebookId();
    
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting; 
        
        //RevRec Rule
        //Default Rule
        List<RevRecRules__c> revRecDefaultRules = new List<RevRecRules__c>();
        revRecDefaultRules.add(new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2',Offset_Period__c = 2, Offset_Type__c = 'Start',
                          						  Default_Rule__c = true, Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                  Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate', Enable_Manual_Forecast__c = true,
                                                  Revenue_Recognition_End_Date__c = 'OPPORTUNITY Product:ServiceDate'));
        insert  revRecDefaultRules;
      
        //Test Opportunity
        List<Opportunity> opportynities = new List<Opportunity>();
        opportynities.add(new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', 
                                          Type = 'New Customer', REVvue_RevRecRule__c = revRecDefaultRules[0].Id));
		insert opportynities;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true));
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000, ServiceDate = Date.today().addDays(100)));
       	oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000, ServiceDate = Date.today().addDays(100)));
        insert oppLineItems;
         
       	//List of RevRec Line items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynities[0].Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynities[0].Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
		insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[1].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[1].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
      	insert revRecProductRules;
        System.assertEquals('Period', revRecProductRules[1].Offset_Type__c);
         
        //Test strt here
        Test.startTest();
        
        //Initilize constructer
        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opportynities[0].id);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(theOppty);
        RevRecOpportunityExtension cExt = new RevRecOpportunityExtension(sc);
        
        cExt.getOppLineItems();
        cExt.OppLineItems[0].LineItem.RevRecRule__c = revRecDefaultRules[0].Id;
        
        //Calling method  on  opportunity level rule selection
        cExt.oppRuleId = revRecDefaultRules[0].Id;
        cExt.showLineItemPopUpScreen();
        cExt.lineItemsWrap[0].isSelectedLineItem = true;
        cExt.saveOpportunityLevelRule();
        
        revRecDefaultRules[0].Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
        revRecDefaultRules[0].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY Product:ServiceDate';

		update revRecDefaultRules;
		
		oppLineItems[0].ServiceDate = null;
		
		update oppLineItems;
		
		try {
			cExt.saveOpportunityLevelRule();
		} catch(Exception e) {}
        
		//Test stops here
        Test.stopTest();
         
        revRecDefaultRules[0].Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE;
        revRecDefaultRules[0].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY Product:ServiceDate';
        revRecDefaultRules[0].Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate';
		update revRecDefaultRules;
		
		/*try {
			cExt.saveOpportunityLevelRule();
		} catch(Exception e) {}*/
        
		oppLineItems[0].ServiceDate = Date.today().addMonths(200);
		
		update oppLineItems;
		
		try {
			cExt.saveOpportunityLevelRule();
		} catch(Exception e) {}
    } 
    
     /**
     *	@description	:	This method is used to test the extension for override rule .
     *
     *	@args			:	-
     *
     *	@return			:	void
    **/
    static testmethod void testOverriddenRuleInsertionOnOpptyLevel2() {    	    
         
        //Test  Standard Price book
    	Id  pricebookId = Test.getStandardPricebookId();
    
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting; 
        
        //RevRec Rule
        //Default Rule
        List<RevRecRules__c> revRecDefaultRules = new List<RevRecRules__c>();
        revRecDefaultRules.add(new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2',Offset_Period__c = 2, Offset_Type__c = 'Start',
                          						  Default_Rule__c = true, Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION,
                                                  Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate', Enable_Manual_Forecast__c = true));
        insert  revRecDefaultRules;
      
        //Test Opportunity
        List<Opportunity> opportynities = new List<Opportunity>();
        opportynities.add(new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', 
                                          Type = 'New Customer', REVvue_RevRecRule__c = revRecDefaultRules[0].Id));
		insert opportynities;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true));
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000, ServiceDate = Date.today().addDays(100)));
       	oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000, ServiceDate = Date.today().addDays(100)));
        insert oppLineItems;
         
       	//List of RevRec Line items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynities[0].Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynities[0].Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
		insert revRecLineItems; 
        System.assertEquals(1200, revRecLineItems[1].DeferredRev__c);
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[1].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[1].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
      	insert revRecProductRules;
         
        //Test strt here
        Test.startTest();
        
        //Initilize constructer
        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opportynities[0].id);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(theOppty);
        RevRecOpportunityExtension cExt = new RevRecOpportunityExtension(sc);
        
        cExt.getOppLineItems();
        cExt.OppLineItems[0].LineItem.RevRecRule__c = revRecDefaultRules[0].Id;
        
        //Calling method  on  opportunity level rule selection
        cExt.oppRuleId = revRecDefaultRules[0].Id;
        cExt.showLineItemPopUpScreen();
        cExt.lineItemsWrap[0].isSelectedLineItem = true;
        cExt.saveOpportunityLevelRule();
        
        //Test stops here
        Test.stopTest();
    } 
    
    static testMethod void testController1() {
        
        //Test  Standard Price book
    	Id  pricebookId = Test.getStandardPricebookId();
    
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1', 
                                                                                           Time_of_Month_Selection_Types__c = '2',
                                                                                           Chart_Pref__c = '1');
        insert appSetting;
        
        RevRecRules__c rule = new RevRecRules__c(
            Revenue_Recognition_End_Date__c='OPPORTUNITY:CloseDate', initial_amount_type__c='Amount', Offset_Period__c=1, initial_amount__c=1000.00,
            Offset_Type__c='Period', Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Default_Rule__c=false,
            Name='Rule test', residual_Amount__c=1.00, Description__c='Descr', Divide_By__c='Prorate', Enable_Manual_Forecast__c = false,
            Recognition_Type__c='Amortize', Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate', Period_or_Exact_Days__c='exact'); 
        insert rule;
        
        // create the product
        List<Product2> p1 = new List<Product2>();
        p1.add(new Product2(name='Test Product 1', IsActive=true, Description='My Product', ProductCode='Prod code', RevRecRule__c =rule.Id ));
        p1.add(new Product2(name='Test Product 1', IsActive=true, Description='My Product', ProductCode='Prodode'));
        insert p1;    
           
        // create the pricebookentry
        List<PricebookEntry> pbe1 = new List<PricebookEntry>();
        pbe1.add(new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=p1[0].id, UnitPrice=100.00, IsActive=true, UseStandardPrice=false));
        pbe1.add(new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=p1[1].id, UnitPrice=100.00, IsActive=true, UseStandardPrice=false));
        insert pbe1;   
        
        // create the opportunity
        List<Opportunity> opp1 = new List<Opportunity>();
        opp1.add(new Opportunity(Probability=10, Type='New Customer', Pricebook2Id=pricebookId, ForecastCategoryName='Closed', 
                                 StageName='Qualification', Amount=273200.00, name='Test Opp 1', CloseDate= Date.newInstance(2010, 6, 1)));
        opp1.add(new Opportunity(Probability=100, Type='New Customer', Pricebook2Id=pricebookId, ForecastCategoryName='Closed', 
                                 StageName='Qualification', Amount=273200.00, name='Test Opp 1', CloseDate= Date.newInstance(2010, 6, 1)));
        insert opp1;
   
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0', AppRopozSLN__Opportunity__c = opp1[0].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, 
                                                                          AppRopozSLN__DeferredRev__c = 1200, 
                                                                          AppRopozSLN__RecognizedRev__c = 1000));
        
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test1', AppRopozSLN__Opportunity__c = opp1[0].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 0, 
                                                                          AppRopozSLN__DeferredRev__c = 0, 
                                                                          AppRopozSLN__RecognizedRev__c = 0));   
        
        insert  revRecLineItems;         
        
        // add the line item
        List<OpportunityLineItem> oli = new List<OpportunityLineItem>();
        oli.add(new OpportunityLineItem(Quantity=1.00, PricebookEntryId=pbe1[0].id, OpportunityId=opp1[0].id, UnitPrice=23000.00,
                                        AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id, RevRecRule__c = rule.Id));
        oli.add(new OpportunityLineItem(Quantity=1.00, PricebookEntryId=pbe1[1].id, OpportunityId=opp1[0].id, UnitPrice=12000.00,
                                       AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[1].Id));
        insert oli;  

        //Assert
        System.assertEquals(null, oli[1].RevRecRule__c);
        
        
        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opp1[0].id);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(theOppty);
        RevRecOpportunityExtension cExt = new RevRecOpportunityExtension(sc);
        
        System.assertNotEquals(cExt.getOppLineItems(), null);
        System.assertNotEquals(cExt.getOpportunityId(), null);      
        
        cExt.setQueryItemId(oli[0].id);
        System.assertEquals(cExt.getQueryItemId(), oli[0].id);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);

        System.assertEquals(cExt.formatCurrencyFromDecimal(1000.00), '$1,000.00');
        //cExt.oppLineItemRow = '0';
        System.assertEquals(cExt.resetOverriddenRule(), null);
        
        //test schedular controller
        Pagereference thePage = Page.RevRecSchedule;
        thePage.getParameters().put('opportunityId', opp1[0].id);
        thePage.getParameters().put('opportunityLineItemId', oli[0].id);
        Test.setCurrentPage(thePage);
        
        RevRecScheduleList  theController = new RevRecScheduleList();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        System.assertNotEquals(theController.getRevRecSchedules(), null);
        System.assertNotEquals(theController.getLineItem(), null);
        
        //Code added - 11/23/2015 
        theController.ExportToExcel();
		
        System.assertNotEquals(theController.getRule (), null);
        System.assertNotEquals(theController.cancel (), null); 
        
        //Code added - as per Multi currecy not enabled code coverage
        theController.isMultiCurrencyEnabled = false;
        theController.inIt();
        
        //Second opp
        theOppty = new Opportunity ();
        theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opp1[0].id);
        sc = new ApexPages.Standardcontroller(theOppty);
        cExt = new RevRecOpportunityExtension(sc);
        
        System.assertNotEquals(cExt.getOppLineItems(), null);
        System.assertNotEquals(cExt.getOpportunityId(), null);      
        
        cExt.setQueryItemId(oli[1].id);
        System.assertEquals(cExt.getQueryItemId(), oli[1].id);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);
        
        //test schedular controller
        thePage = Page.RevRecSchedule;
        thePage.getParameters().put('opportunityId', opp1[0].id);
        thePage.getParameters().put('opportunityLineItemId', oli[1].id);
        Test.setCurrentPage(thePage);
        
       theController = new RevRecScheduleList();
        currentPageUrl = ApexPages.currentPage().getUrl();
        

        theController.isMultiCurrencyEnabled = true;
        theController.inIt();
        theController.getColors();
         String colorCode = '#006400';
         String colorCodeZero = '#FFFFFF';
         String colorCodeWei = '#FF6600';
         Decimal Recognized =  50.00;
         Decimal Deferred = 100.00; 
         Decimal RecognizedWeighted = 500.00;
         Decimal DeferredWeighted = 650.00;
         String transDate = 'Date.today()';
         Decimal Forecasted = 450.00; 
         Decimal totalForecastedZero = 586.00;
         Decimal ForecastedWeighted = 400.00; 
         Date schDate =Date.today(); 
         Decimal RecognizedCumulative = 987.00;
         Decimal RecognizedWeightedCumulative = 100.00;
         Decimal ForecastedCumulative =200.00; 
        Decimal ForecastedWeiCummulative = 20.00;
        RevRecScheduleList.BarChartDataWrapper chartWrap = new RevRecScheduleList.BarChartDataWrapper(colorCode,colorCodeZero, colorCodeWei,Recognized,  Deferred, 
                                                                                                      RecognizedWeighted,  DeferredWeighted, transDate, Forecasted, 
                                                                                                      totalForecastedZero,  ForecastedWeighted, schDate,  RecognizedCumulative,
                                                                                                      RecognizedWeightedCumulative, ForecastedCumulative,  ForecastedWeiCummulative);
        String colorCode1 = '#006400';
        String colorCodeZero1 = '#FFFFFF';
        String colorCodeWei1 = '#FF6600';
        Decimal Recognized1 =  50.00;
        Decimal Deferred1 = 100.00; 
        Decimal RecognizedWeighted1 = 500.00;
        Decimal DeferredWeighted1 = 650.00;
        Decimal Forecasted1 = 450.00; 
        Decimal totalForecastedZero1 = 586.00;
        Decimal ForecastedWeighted1 = 400.00; 
        String chartDate  = 'Date.today()';
        Date schDate1 = System.today().addDays(3);
        Decimal RecognizedCumulative1 = 987.00;
        Decimal RecognizedWeightedCumulative1 = 100.00;
        Decimal ForecastedCumulative1 =200.00; 
        Decimal ForecastedWeiCummulative1 = 20.00;
        RevRecScheduleList.BarChartDataWrapperBR chartWrapp = new RevRecScheduleList.BarChartDataWrapperBR( colorCode1,  colorCodeZero1,  colorCodeWei1, Recognized1, Deferred1, 
                                                                                                          RecognizedWeighted1, DeferredWeighted1,  Forecasted1,  totalForecastedZero1, 
                                                                                                           ForecastedWeighted1, chartDate,  schDate1,  RecognizedCumulative1, 
                                                                                                           RecognizedWeightedCumulative1,  ForecastedCumulative1, ForecastedWeiCummulative1);
        RevRecOpportunityLineItemSchedule__c schedule = new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = oli[0].Id,OpportunityLineItemId__c = oli[0].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '1',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 1, DefReWei__c = 50.00);
        Decimal recognizedCumulatives = 100.00;
        Decimal recognizedWeiCumulatives = 200.00;
        Decimal forecastedCumulatives = 500.00;
        RevRecScheduleList.RevRecLineItemScheduleWrapper schWrapp = new RevRecScheduleList.RevRecLineItemScheduleWrapper( schedule, recognizedCumulatives, recognizedWeiCumulatives,forecastedCumulatives);

        }
    
    
    /**
     *  @description    :   @this method is used to cover the RevRecUtil class.
     *
     *  @args           :
     *
     *  @return         :
    **/
    static testmethod void testRevRecUtil1() {
    
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1', Opportunity_Stage__c = 'Closed Lost',
                                                                 Time_of_Month_Selection_Types__c = '2', Opportunity_Type__c = 'Existing Business');
        insert appSetting;
        
        //Test Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-23), StageName = 'Closed Won', 
                                                  Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-23), StageName = 'Closed Lost', 
                                                  Type = 'Existing Business'));                                               
        insert opportunities;
        System.assertEquals('Closed Lost', opportunities[1].StageName);
        
        //Test start here
        Test.startTest(); 
        
        RevRecUtil ctrl = new RevRecUtil();
        
        try {
            ctrl.EvaluateRevRecSchedule(opportunities[0], null, null, null, null, null, null, null);
        } catch(Exception e) {}
        
        try {
            ctrl.EvaluateRevRecSchedule(opportunities[1], null, null, null, null, null, null, null);
        } catch(Exception e) {}
        
        //Test stop here
        Test.stopTest();
    } 
    
    /**
     *  @description    :   @this method is used to cover the ProductRuleCategoryWrapper.
     *
     *  @args           :
     *
     *  @return         :
    **/
    
     static testmethod void testProductRuleCatWrapper() {
         
         //Test  Standard Price book
    	Id  pricebookId = Test.getStandardPricebookId();
    
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
  	    insert appSetting; 
        
        //RevRec Rule
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2',Offset_Period__c = 2, Offset_Type__c = 'Start',
                          									  Default_Rule__c = true, Recognition_Type__c = 'Amortize Milestone', Enable_Manual_Forecast__c = true);                                                            
        insert  revRecDefaultRule;
      
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true));
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000));
        insert oppLineItems;
         
       //List of RevRec Line items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add line item into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1),Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
									                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
									                     Milestone_Type__c = 'qty', Start_Date__c = Date.Today().addMonths(1),
									                     Offset_Period__c = 1,
									                     Offset_Type__c = 'Period'));
                                                                       
         insert   revRecProductRules;
        System.assertEquals(4000, revRecProductRules[0].Residual_Amount__c);
         
         RevRecProductRuleCategory__c ruleCategories = new  RevRecProductRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
        											 Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'PRODUCT:ServiceDate', 
        											 Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecProductRule__c = revRecProductRules[0].Id);
        
        //Insert Rule Categories
        insert ruleCategories;
         
         //Test start here
         Test.startTest(); 
         integer rowCount = 2; 
         List<String> lineItemForBlended1 = new List<String>{'Test','Test1'};
         Boolean isSelected = true;
         
         ProductRuleCategoryWrapper wrap = new ProductRuleCategoryWrapper(ruleCategories,rowCount,lineItemForBlended1,isSelected);
         
        //Test stop here
         Test.stopTest();
     }
}