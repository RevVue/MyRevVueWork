@isTest(SeeAllData=false)
private class TestRevRecUtils { 
    
    static RevRecRules__c rule;
    static RevRecOpportunityExtension cExt;
    static Opportunity opp1;
    
    static void testSetup() {
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        rule = new RevRecRules__c(
            Revenue_Recognition_End_Date__c='OPPORTUNITY PRODUCT:ServiceDate',  
            initial_amount_type__c='Amount',    
            Offset_Period__c=1,
            Offset_Type__c='Period',
            Active__c=true,
            Residual_Amount_Type__c='Amount', 
            Period__c='Monthly',
            Name='Rule test',
            Recognition_Type__c='Amortize', 
            Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate',  
            Period_or_Exact_Days__c='exact',
            Divide_By__c='Prorate',
            Description__c='Descr',
            residual_Amount__c=1.00, 
            Default_Rule__c=false, 
            initial_amount__c=1000.00 
        ); 
        insert rule;
               
        // create the product
        Product2 p1 = new Product2(
            name='Test Product 1',
            IsActive=true,
            Description='My Product',
            ProductCode='Prod code',
            RevRecRule__c =rule.Id 
        );
        insert p1;    
           
       
        // create the pricebookentry
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=p1.id, UnitPrice=100.00, IsActive=true, UseStandardPrice=false);
        insert pbe1;   
       
        // create the opportunity
        opp1 = new Opportunity(Probability=100, Type='New Customer', Pricebook2Id= pricebookId, ForecastCategoryName='Closed', 
                               StageName='Closed Won', Amount=273200.00, name='Test Opp 1', CloseDate= Date.newInstance(2010, 6, 1));
        insert opp1;
   
        // add the line item
        OpportunityLineItem oli = new OpportunityLineItem(Quantity=1.00, PricebookEntryId=pbe1.id, OpportunityId=opp1.id, 
                                                          UnitPrice=12000.00, ServiceDate=Date.newInstance(2012, 8, 30));
        insert oli;  

        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp1);
        cExt = new RevRecOpportunityExtension(sc);
        cExt.setQueryItemId(oli.id);
    }

    static testMethod void testOverridRule() {
        
        testSetup();
        
       //App Setting Data
        RevRecAppSetting__c theSetting = new RevRecAppSetting__c(Name = 'AppSetting', Time_of_Month_Selection_Types__c = '1',
                                                                 Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1');             
        insert theSetting;

        Utility u = new Utility(opp1);
        RevRecUtil util = new RevRecUtil();
        string lineItemId = cExt.getQueryItemId();
        OpportunityLineItem lineItem = [SELECT Id,Quantity,UnitPrice, TotalPrice, PricebookEntry.Name, RevRecOpportunityLineItem__r.Id          
                        FROM OpportunityLineItem WHERE Id = :lineItemId];
        
        opp1.CloseDate = Date.Today();
        update opp1;
        
        RevRecProductRule__c overrideRule = new RevRecProductRule__c();
        overrideRule.Recognition_Type__c = 'Single Transaction';
        overrideRule.Name = '[overridden] Test ST';
        overrideRule.Start_Date__c = Date.today().addDays(1);
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
        
        List<RevRecOpportunityLineItemSchedule__c> newSchedules = new  List<RevRecOpportunityLineItemSchedule__c>();
        OpportunityStage theStage = [select Id, Description, MasterLabel FROM  OpportunityStage WHERE MasterLabel = 'Closed Won' LIMIT 1];
        
        RevRecOpportunityLineItem__c revRecLineItem =  new RevRecOpportunityLineItem__c(name='test', opportunity__c = opp1.Id, OpportunityLineItemId__c = lineItemId);
        insert(revRecLineItem);
        
        lineItem.RevRecOpportunityLineItem__c = revRecLineItem.id;
        lineItem.RevRecRule__c = rule.id;
        revRecLineItem.ProductName__c = 'test';
        revRecLineItem.OpportunityLineItemId__c = lineItem.Id;
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);

        List<RevRecOpportunityLineItem__c> revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
            
        List<RevRecProductRule__c> overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
            
        Map<id, List<RevRecProductRuleMilestone__c>> revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);
        
        Map<Id, List<RevRecProductRuleCategory__c>> mapLineItemWithProductCategory = new Map<Id, List<RevRecProductRuleCategory__c>>();
        string msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        //System.assert(msg == null);
        
        overrideRule.Residual_Amount_Type__c = 'Percent';
        overrideRule.Residual_Amount__c = 5;
        overrideRule.offset_type__c = 'Period';
        overrideRule.Offset_Period__c = 1;
        overrideRule.Initial_Amount__c =100;
        overrideRule.Initial_Amount_Type__c = 'Amount';
        overrideRule.offset_type__c = 'Period';
        overrideRule.Total_Period__c = 4;
        overrideRule.Recognition_Type__c = 'Amortize';
        overrideRule.Period__c = 'Weekly';
        overrideRule.End_Date__c = Date.today().addMonths(100);
        
        oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);

        revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
            
        overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
            
        revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);
        
        msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        //System.assertEquals(msg, '');

        overrideRule.Recognition_Type__c = 'Amortize';
        overrideRule.Period__c = 'Yearly';
        oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);

        revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
            
        overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
        
        revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);

        msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        //System.assertEquals(msg, '');
            
        overrideRule.Recognition_Type__c = 'Amortize';
        overrideRule.Period__c = 'Quarterly';
        oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);

        revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
        
        overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
        
        revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);
           
        msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        //System.assertEquals(msg, '');
        
        overrideRule.Recognition_Type__c = 'Amortize';
        overrideRule.Period__c = 'Daily';
        oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);

        revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
            
        overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
        
        revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);
            
        msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        //System.assertEquals(msg, '');

        overrideRule.Recognition_Type__c = 'Amortize';
        overrideRule.Period__c = 'Monthly';
        overrideRule.Divide_By__c = 'noProrate';
        overrideRule.Milestone_Type__c = 'amount';
        oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);

        revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
            
        overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
        
        revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);
            
        msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        //System.assertEquals(msg, '');

        overrideRule.Recognition_Type__c = 'Milestone';
        overrideRule.Milestone_Type__c = 'amount';
        overrideRule.RevRecOpportunityLineItem__c = revRecLineItem.id;
        insert(overrideRule);
        
        revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c(RevRecProductRule__c=overrideRule.id, Milestone_Sequence__c = 1, Milestone_Name__c = 'test', Percent__c=100, Milestone_Date__c = Date.today().addDays(-1)))  ;    
        insert(revRecProductRuleMilestones);
        oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);   

        revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
             
        overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
            
        revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);
            
        msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        //System.assert(msg == '');
        
        overrideRule.Recognition_Type__c = 'Single Transaction';
        overrideRule.Start_Date__c = null;
        
        oliList = new List<OpportunityLineItem>();
        oliList.add(lineItem);

        revRecOliList = new List<RevRecOpportunityLineItem__c>();
        revRecOliList.add(revRecLineItem);
            
        overrideRuleList = new List<RevRecProductRule__c>();
        overrideRuleList.add(overrideRule);
          
        revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
        revRecProductRuleMilestonesMap.put(lineItem.id, revRecProductRuleMilestones);
        
        msg = util.EvaluateRevRecSchedule(opp1, oliList, revRecOliList, newSchedules, theStage, overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
        System.assert(msg != null);
             
        //Added - 11/7/2014
        //Assert for result
        List<RevRecProductRuleMilestone__c> productMileStones = [Select Id, Name, MileStone_Name__c From RevRecProductRuleMilestone__c
                                                                 WHERE RevRecProductRule__c IN: overrideRuleList];
        
        System.assertEquals(1, productMileStones.size());
        
        Pagereference thePage = Page.RevRecOpportunitySchedules;
        thePage.getParameters().put('opportunityId', opp1.id);
        Test.setCurrentPage(thePage);
        
        RevRecScheduleSetController theController = new RevRecScheduleSetController();
        System.assertNotEquals(theController.getSchedules(), null);
        System.assertNotEquals(theController.cancel(), null);
        
        revRecOliList = [Select Allocated__c, Remaining_Amount__c, Remaining_Percentage__c, Remaining_Qty__c
                           FROM RevRecOpportunityLineItem__c];
        
        //Assert for result
        //System.assertEquals(revRecOliList[0].Allocated__c, 100.00);
        //System.assertEquals(revRecOliList[0].Remaining_Amount__c, 1.00);
        //System.assertEquals(revRecOliList[0].Remaining_Percentage__c, 0.01);
        //System.assertEquals(revRecOliList[0].Remaining_Qty__c, 0);
    }
    
    static testMethod void testEndOfMonth() {
    
        testSetup();
        
        //App Setting Data
        RevRecAppSetting__c theSetting = new RevRecAppSetting__c(Name = 'AppSetting', Time_of_Month_Selection_Types__c = '1',
                      Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1');
        insert theSetting;
                        
        rule.Recognition_Type__c = 'Single Transaction';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);
        
        rule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'Monthly';
        rule.Divide_By__c = 'noProrate';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       
        
        rule.Period__c = 'Weekly';
        rule.Residual_Amount_Type__c = 'Percent';
        rule.offset_type__c = 'Period';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       


        rule.Period__c = 'Yearly';
        rule.offset_type__c = 'Period';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       

        rule.Period__c = 'Quarterly';
        rule.offset_type__c = 'Period';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null); 
        
        rule.Period__c = 'Daily';
        update(rule);
       // System.assertEquals(cExt.ReCalculateTheLineItem(), null);
    }
 
     static testMethod void testCertainDayOfMonth() {
        testSetup();
        
        //App Setting Data
        RevRecAppSetting__c theSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                      Certain_date_of_month__c = '15', Time_of_Month_Selection_Types_tr__c = '1',
                      Time_of_Month_Selection_Types__c = '2');
                      
        insert theSetting;

        rule.Recognition_Type__c = 'Single Transaction';
        rule.offset_type__c = 'Start';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);
        
        rule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'Monthly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       
        
        rule.Period__c = 'Weekly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       


        rule.Period__c = 'Yearly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       

        rule.Period__c = 'Quarterly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null); 

        rule.Period__c = 'daily';
        update(rule);
       // System.assertEquals(cExt.ReCalculateTheLineItem(), null); 
    }
    
     static testMethod void testCertainWeekDayOfMonth() {
        testSetup();
        
        //App Setting Data
        RevRecAppSetting__c theSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                      Certain_date_of_month__c = '15', Time_of_Month_Selection_Types_tr__c = '1',
                      Time_of_Month_Selection_Types__c = '3');
                      
        insert theSetting;
 
        rule.Recognition_Type__c = 'Single Transaction';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);
        
        theSetting.Certain_weekday__c = '1st';
        theSetting.Certain_weekday_day__c='Sunday';
        update(theSetting);  
                
        rule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'Monthly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       
        
        theSetting.Certain_weekday_day__c='Monday';
        update(theSetting);  
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       

        theSetting.Certain_weekday_day__c='Tuesday';
        update(theSetting);  
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       

        theSetting.Certain_weekday__c = '3rd';
        theSetting.Certain_weekday_day__c='Wednesday';
        update(theSetting);         

        rule.Period__c = 'Weekly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       


        theSetting.Certain_weekday__c = 'last';
        theSetting.Certain_weekday_day__c='Friday';
        update(theSetting);         
        rule.Period__c = 'Yearly';
        update(rule);
   //     System.assertEquals(cExt.ReCalculateTheLineItem(), null);       

        theSetting.Certain_weekday__c = 'last';
        theSetting.Certain_weekday_day__c='Saturday';
        update(theSetting);         
        rule.Period__c = 'Quarterly';
        update(rule);
        //System.assertEquals(cExt.ReCalculateTheLineItem(), null); 

    }
    
     static testMethod void testLastWorkingDayOfMonth() {
        
        testSetup();
                
        //App Setting Data
        RevRecAppSetting__c theSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                      Certain_date_of_month__c = '15', Time_of_Month_Selection_Types_tr__c = '1',
                      Time_of_Month_Selection_Types__c = '5');            
        insert theSetting;
       
        rule.Recognition_Type__c = 'Single Transaction';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);
        
        rule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'Monthly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       
        
        rule.Period__c = 'Weekly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       

        rule.Period__c = 'Yearly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null);       

        rule.Period__c = 'Quarterly';
        update(rule);
        System.assertEquals(cExt.ReCalculateTheLineItem(), null); 
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //Where END date year - start date year == 0
    static testMethod void testAmortizeMilestoneAmortizeByAmount1() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2', Is_Closed_Date_Validation__c = true);
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period',  Period_or_Exact_Days__c = 'period',
                                                              Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize', Period__c = 'Monthly');
                                                                    
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                                                Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                                                 PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = revRecDefaultRule.Id));
         
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, 
                                                              DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addMonths(1), Residual_Amount__c = 4000, 
                                                        RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                        Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                        Milestone_Type__c = 'amount', Start_Date__c = Date.Today().addDays(1),
                                                       /* Amortize_By__c = 'Amount',*/Divide_By__c = 'Period', Period__c = 'Monthly' , 
                                                        Period_or_Exact_Days__c = 'period'));                                                            
        insert revRecProductRules;
      
        //Test strt here
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Query through milestones records
        List<RevRecProductRuleMileStone__c> mileStones = [Select Id From RevRecProductRuleMileStone__c WHERE 
                                                RevRecProductRule__c =: revRecProductRules[0].Id];
        
        //Assert for results :  2    milestone from November-2014  - December-2014
        //System.assertEquals(1, mileStones.size());
            
        //Query through Schedule records
        List<RevRecOpportunityLineItemSchedule__c> schedules = [Select Id From RevRecOpportunityLineItemSchedule__c WHERE 
                                                RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
        
        //Assert for results :  2 Schedule  
        System.assertEquals(1, schedules.size());
               
        //Assert for results
        System.assert(msg == null);
        
        //Test stop  here
        Test.stopTest();
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //for End date year - start date year > 1
    static testMethod void testAmortizeMilestoneAmortizeByAmount2() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                          Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                          Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', 
                                                              Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period', 
                                                              Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize');
                                                                                                        
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                                      Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                    RevRecRule__c = revRecDefaultRule.Id));
                       
        insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add( new RevRecProductRule__c(  End_Date__c = Date.Today().addYears(5), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                           Milestone_Type__c = 'amount', Start_Date__c = Date.Today().addMonths(1),
                                                           /*Amortize_By__c = 'Amount', */Offset_Period__c = 1,
                                                           Offset_Type__c = 'Start',Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'));                                                         
        insert revRecProductRules;
      
        //Test strt here
        Test.startTest();
        
        //Initilize Constructer
        RevRecUtil util = new RevRecUtil();
        
        //Calling controller method
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                            RevRecProductRule__c =: revRecProductRules[0].ID];
        
        //Assert for results :  60   milestone 
        System.assertEquals(59, mileStones.size());
        
        //Query through Schedule records
        List<RevRecOpportunityLineItemSchedule__c> schedules = [Select Id From RevRecOpportunityLineItemSchedule__c WHERE 
                                                RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
        
        //Assert for results :  61 Schedule  
        System.assertEquals(59, schedules.size());
        
        //Assert for results
        System.assert(msg == null);
        
        //Test stop here
        Test.stopTest();
        
   }
       
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone
    //End date year -start date year ==1
    static testMethod void testAmortizeMilestoneAmortizeByAmount3() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                  Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                  Time_of_Month_Selection_Types__c = '2');
                  
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', Period__c = 'Monthly' , 
                                                              Period_or_Exact_Days__c = 'period', 
                                                              Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize');
                                                                    
        insert  revRecDefaultRule;
      
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                                                  Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry List
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                                                 PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, 
                                                 UnitPrice = 1000 , RevRecRule__c = revRecDefaultRule.Id));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                              DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Offset_Type__c = 'Period',
                     Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id, Milestone_Type__c = 'qty', 
                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,/* Amortize_By__c = 'qty',*/Offset_Period__c = 1,
                     Start_Date__c = Date.Today().addMonths(1), Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'));                                                          
        insert revRecProductRules;
        
        //Test strt here
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        
        //Calling conntroller method
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones = [Select id From RevRecProductRuleMilestone__c WHERE 
                                                            RevRecProductRule__c =: revRecProductRules[0].ID];
        
        //Assert for results :  12   milestone from December-2014  - November-2015
        System.assertEquals(12, mileStones.size());
        
        //Assert for results
        System.assert(msg == null);
       
        //Test stop here
        Test.stopTest(); 
    }
               
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //For default rule = Enddate year - start date year > 1
    static testMethod void testAmortizeMilestoneAmortizeByAmount4() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                      Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                      Time_of_Month_Selection_Types__c = '2');
                      
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                       Offset_Period__c = 2, 
                       Offset_Type__c = 'Start',
                       Default_Rule__c = true,
                        Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                       /*Amortize_By__c =  'Amount',*/ Milestone_Type__c =  'amount',
                       Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate',
                       Revenue_Recognition_Start_Date__c  = 'OPPORTUNITY:CloseDate');
                                                                    
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                    Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
       insert products;
         
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                                                     PricebookEntryId = pricebookEntries[1].Id,
                                                     Quantity = 1, 
                                                     UnitPrice = 1000));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                     Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                     DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        
        //Test strt here
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Test stop here
        Test.stopTest();
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Default Rule = Amortize MileStone 
    //For default rule = Enddate year - start date year = 1
    static testMethod void testAmortizeMilestoneAmortizeByAmount5() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                                           Certain_date_of_month__c = '28',
                                                                                           Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                                    Offset_Period__c = 2,
                                                                    Offset_Type__c = 'Start',
                                                                    Default_Rule__c = true,
                                                                    Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                                    /*Amortize_By__c =  'amount',*/ Milestone_Type__c =  'amount',
                                                                    Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate',
                                                                    Revenue_Recognition_Start_Date__c  = 'OPPORTUNITY:CloseDate');
                                                                    
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                    Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
        insert products;
         
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                                                     PricebookEntryId = pricebookEntries[1].Id,
                                                     Quantity = 1, 
                                                     UnitPrice = 1000));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                     Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                     DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
      
        //Test strt here
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Test stop here
        Test.stopTest();
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //For default rule = Enddate year - start date year = 0
    static testMethod void testAmortizeMilestoneAmortizeByAmount6() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                                           Certain_date_of_month__c = '28',
                                                                                           Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                                    Offset_Period__c = 2,
                                                                    Offset_Type__c = 'Start',
                                                                    Default_Rule__c = true,
                                                                    Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                                   /* Amortize_By__c =  'qty', */ Milestone_Type__c =  'qty',
                                                                    Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate',
                                                                    Revenue_Recognition_Start_Date__c  = 'OPPORTUNITY:CloseDate');
                                                                    
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                    Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
        insert products;
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                                                     PricebookEntryId = pricebookEntries[1].Id,
                                                     Quantity = 1, 
                                                     UnitPrice = 1000));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                     Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                     DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        
        //Test strt here
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        
        //Calling controler
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Test strt here
        Test.stopTest();
    }
    
    //Code added  - 11/10/2014 - Method to test functioanlity of Rule = Amortize MileStone
    //For Override rule -> End date is less than start date
    static testMethod void testAmortizeMilestoneAmortizeByAmount7() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                 Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '3',
                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
      
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                                                Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                      PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                     Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                     DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addMonths(1),
                                  Residual_Amount__c = 4000, 
                                  RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                  Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                  Milestone_Type__c = 'amount', Start_Date__c = Date.Today().addMonths(5)/*,
                                  Amortize_By__c = 'amount'*/));
                                                                         
        insert   revRecProductRules;
        
        //Test strt here
        Test.startTest();
        
        //Initilize Constructer
        RevRecUtil util = new RevRecUtil();
        
        //Calling controller method 
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
      
        //Query through Product milestone
        List<RevRecProductRuleMilestone__c> mileStones = [Select Id From RevRecProductRuleMilestone__c WHERE 
                                        RevRecProductRule__c =: revRecProductRules[0].ID];
        
        //End date less than Start date
        //Assert for results :  0 milestone : 
        System.assertEquals(0, mileStones.size());
        
        //Test strt here
        Test.stopTest();
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //For override Rule -> start date null 
    static testMethod void testAmortizeMilestoneAmortizeByAmount8() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                                           Certain_date_of_month__c = '28',
                                                                                           Time_of_Month_Selection_Types_tr__c = '2',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
      
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                                                Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                             PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                     Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                     DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(5),
                               Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                               Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                               Milestone_Type__c = 'amount'/*,                                                                         
                               Amortize_By__c = 'Amount'*/));
                                                                         
                                                                   
        insert   revRecProductRules;
        
        //Test strt here
        Test.startTest();
        
        //Initilize Constructer
        RevRecUtil util = new RevRecUtil();
        
        //Calling controller
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg != null);
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                            RevRecProductRule__c =: revRecProductRules[0].ID];
        
        //Assert for results :  60   milestone 
        System.assertEquals(0, mileStones.size());      
        
        //Test stop here
        Test.stopTest();
          
   }
   
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //Default rule -> start date is null
    static testMethod void testAmortizeMilestoneAmortizeByAmount9() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                                           Certain_date_of_month__c = '28',
                                                                                           Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                                    Offset_Period__c = 2,
                                                                    Offset_Type__c = 'Start',
                                                                    Default_Rule__c = true,
                                                                    Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                                    Milestone_Type__c =  'qty',
                                                                    Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate',
                                                                    Revenue_Recognition_Start_Date__c  = 'OPPORTUNITY:CloseDate');
                                                                    
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                    Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
        insert products;
        System.assertEquals(true, products[0].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                                                     PricebookEntryId = pricebookEntries[1].Id,
                                                     Quantity = 1, 
                                                     UnitPrice = 1000));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                     Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                     DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        insert revRecLineItems;  
        System.assertEquals(1, revRecLineItems.size());
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
      
        //Test start here
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        
        //Calling controller method
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //for End date year - start date year > 1 ; Start and Ensd date month same
    static testMethod void testAmortizeMilestoneAmortizeByAmount10() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'
                                                              , Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize');
        
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
       
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                    RevRecRule__c = revRecDefaultRule.Id));
                       
        insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add( new RevRecProductRule__c(  End_Date__c = Date.Today().addYears(5), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                           Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                           /*Amortize_By__c = 'Amount',*/ Offset_Period__c = 1,
                                                           Offset_Type__c = 'Start',Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'));
                                                                         
        insert   revRecProductRules;
      
        //Test strt here
        Test.startTest();
        
        //Initilize Constructer
        RevRecUtil util = new RevRecUtil();
        
        //Calling controller method
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                            RevRecProductRule__c =: revRecProductRules[0].ID];
        
        //Assert for results :  60   milestone 
        System.assertEquals(60, mileStones.size());
        
        //Query through Schedule records
        List<RevRecOpportunityLineItemSchedule__c> schedules = [Select Id From RevRecOpportunityLineItemSchedule__c WHERE 
                                                RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
            
        //Assert for results :  61 Schedule  
        System.assertEquals(60, schedules.size());
        
        //Assert for results
        System.assert(msg == null);    
        
        //Test stop here
        Test.stopTest();
   }
   
   //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    //for End date year - start date year = 1; Start and Ensd date month same
    static testMethod void testAmortizeMilestoneAmortizeByAmount12() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'
                                                             , Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize');
        
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
       
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = RevRecDefaultRule.Id));
                       
        insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add( new RevRecProductRule__c(  End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                           Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                           Offset_Period__c = 1,
                                                           Offset_Type__c = 'Start',Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'));
                                                                         
        insert   revRecProductRules;
      
        //Test strt here
        Test.startTest();
        
        //Initilize Constructer
        RevRecUtil util = new RevRecUtil();
        
        //Calling controller method
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        System.assert(msg == null);
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                            RevRecProductRule__c =: revRecProductRules[0].ID];
        
        //Assert for results :  13   milestone 
        System.assertEquals(12, mileStones.size());
        
        //Query through Schedule records
        List<RevRecOpportunityLineItemSchedule__c> schedules = [Select Id From RevRecOpportunityLineItemSchedule__c WHERE 
                                                RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
        
        //Assert for results :  13 Schedule  

        System.assertEquals(12, schedules.size());
        
        //Assert for results
        System.assert(msg == null);
        
        //Test stop here
        Test.stopTest();
   } 
    
    //Method tto test functionality of revrec helper class
    static testMethod void testRevRecHelper() {
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                    Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
        System.assertEquals(true, products[0].IsActive);
        
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, 
                                                     PricebookEntryId = pricebookEntries[1].Id,
                                                     Quantity = 1, 
                                                     UnitPrice = 1000));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                     Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                     DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        insert revRecLineItems;  
        System.assertEquals(1, revRecLineItems.size());
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        
        //Set of OppIds
        Set<Id> oppIds = new Set<Id>();
        oppIds.add(opportynity.Id);
        
        //Set of oppLineItems
        Set<Id> oppLis = new set<Id>();
        
        //Lopp through li's and populate set of id
        for(OpportunityLineItem li : oppLineItems) {
            oppLis.add(li.Id);
        }
        
        //Test start here
        Test.startTest();
        
        List<Opportunity> opps = [Select Id FROM Opportunity WHERE Id IN: oppIds];
        Id oppId = Id.valueOf(opps[0].Id);
        
        //Calling controller method
        RevRecHelper.GetOpportunityWithAllFieldsByIdSet(oppIds);
        RevRecHelper.GetOpportunityWithAllFieldsById(oppId);
        RevRecHelper.GetLineItemListWithAllFieldsByOpportunityIdSet(oppIds);
        RevRecHelper.GetLineItemListWithAllFeilds(oppId);
        RevRecHelper.GetLineItemWithAllFeilds(oppLineItems[0].Id);
        RevRecHelper.GetProduct2WithAllFeilds(products[0].Id);
        Date dt = System.today();
        String certnWeek1 = '1st';
        String certnWeek2 = '2nd';
        String certnWeek3 = '3rd';
        String certnWeek4 = '4th';
        String certnWeek5 = 'Last';
        String certnDayOfWeek1 = 'Sunday';
        String certnDayOfWeek2 = 'Monday';
        String certnDayOfWeek3 = 'Tuesday';
        String certnDayOfWeek4 = 'Wednesday';
        String certnDayOfWeek5 = 'Thrusday';
        String certnDayOfWeek6 = 'Friday';
        String certnDayOfWeek7 = 'Saturday';
        
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(dt, certnWeek1, certnDayOfWeek1);
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(dt, certnWeek2, certnDayOfWeek2);
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(dt, certnWeek3, certnDayOfWeek3);
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(dt, certnWeek4, certnDayOfWeek4);
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(dt, certnWeek5, certnDayOfWeek5);
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(dt, certnWeek5, certnDayOfWeek6);
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(dt, certnWeek4, certnDayOfWeek7);
        RevRecHelper.HasUserLevelAccessForREVview();
        Date sDt = System.today();
        Date eDt = System.today().addDays(30);
        RevRecHelper.TotalMonthDifference(sDt,eDt);
        
        //Test stops here
        Test.stopTest();
    }
    
    //Code added  - 04/08/2015 - Method to test functioanlity of Rule = Milestone
    //Default rule - Recornized Revenue automation functionality
    /*static testMethod void testMileStoneRecognizedReveAutomation() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
         
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                              Offset_Period__c = 2,
                                                              Offset_Type__c = 'Start',
                                                              Default_Rule__c = true,
                                                              Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_MILESTONE,
                                                              Milestone_Type__c = 'percent');
                                                                    
        insert  revRecDefaultRule;
        
        //List of RevRecMilestones
        List<RevRecRuleMilestone__c> revRecRuleMiles = new List<RevRecRuleMilestone__c>();
        revRecRuleMiles.add(new RevRecRuleMilestone__c(Percent__c = 10, RevRecRule__c = revRecDefaultRule.Id, 
                                                       Milestone_Date_Source__c = 'OPPORTUNITY:CloseDate'));
                                                       
        revRecRuleMiles.add(new RevRecRuleMilestone__c(Percent__c = 10, RevRecRule__c = revRecDefaultRule.Id, 
                                                       Milestone_Date_Source__c = 'OPPORTUNITY PRODUCT:ServiceDate'));
        
        //Insert milestones
        insert revRecRuleMiles;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-15), StageName = 'Closed Won',
                                                  Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
        insert products;
        System.assertEquals(true , products[0].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id,
                                                 Quantity = 1, UnitPrice = 1000 , RevRecRule__c = revRecDefaultRule.Id));
         insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id));
             
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
      
        //Test start here
        //Test.startTest();
        
        //Initilizing Standard controller and consstructer
       // ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opportynity);
        /*RevRecOpportunityExtension controller = new RevRecOpportunityExtension(sc);
        
        //Calling controller method
        controller.ReCalculateAll();
        
        //Query through RevRecLine Items
        List<RevRecOpportunityLineItem__c> revLines = [Select Id, RecognizedRev__c, DeferredRev__c 
                                    From RevRecOpportunityLineItem__c Where Id IN : revRecLineItems];
        
        //Asset for results
        //system.assertEquals(100, revLines[0].RecognizedRev__c);
        //system.assertEquals(900, revLines[0].DeferredRev__c);
        system.assertEquals(0, revLines[0].RecognizedRev__c);
        system.assertEquals(1000, revLines[0].DeferredRev__c);*/
       
        //RevRecUtil.checkMCEnabled();
                
        //Test stop here
        //Test.stopTest();
    //}   
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality1() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-3), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
        
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(8000, pricebookEntries[1].UnitPrice);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(90)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
       //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    
   /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality2() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'None', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'None', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
         
        //Insert Product
        insert  products;
        System.assertEquals(true, products[0].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(90)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        System.assertEquals(100, revRecLineItems[0].ResidualAmount__c);
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
         
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Calling controller method
        //controller.ReCalculateAll();
                        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality3() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(90)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        System.assertEquals(100, revRecLineItems[0].ResidualAmount__c);
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
       //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality4() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addMonths(-4), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(8000, pricebookEntries[1].UnitPrice);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(90)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality5() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(90)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
   /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality6() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
         //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addMonths(1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addYears(1)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
   /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality7() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
         //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addMonths(1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addYears(3)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
     /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality8() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-3), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(-1)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
     /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality9() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().adddays(-1)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality10() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
         //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addYears(1)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality11() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
         //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addYears(3)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality12() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
         //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ', Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addYears(3)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality13() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
         //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addYears(-1), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(2)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items      
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testBlendedFunctionality15() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-23), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(-10)));
        
         //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(-10)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[1].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
       //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();        
    }
    /**
     *  @description    :   This method is used to test the blended revenue functionality
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    static testMethod void testLineItemDeleteFunctionality() {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 0,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-23), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(-10)));
        
         //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(-10)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[1].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        delete  oppLineItems[0];
        
        //Test stop here
        Test.stopTest();        
    }
    
    /**
     *  @description    :   @this method is used to cover the RevRecUtil class.
     *
     *  @args           :
     *
     *  @return         :
    **/
    static testmethod void testRevRecUtil () {
        
        //Test  Standard Price book
        Id pricebookId = Test.getStandardPricebookId();
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                                                                 Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2',
                                                                 Opportunity_Stage__c = 'Closd Lost',
                                                                 Opportunity_Type__c = 'Existing Business');
        insert appSetting;
              
        //List of RevRecRule
        List<RevRecRules__c> revRecRules = new   List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-23), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        System.assertEquals(true, pricebookEntries[1].IsActive);
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(-10)));
        
         //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
                                                    ,ServiceDate = Date.Today().addDays(-10)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[1].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        delete  oppLineItems[0];
        
        //Test stop here
        Test.stopTest();
        
    }
}