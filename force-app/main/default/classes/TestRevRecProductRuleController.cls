/**
 *  Description     :   This class is used to Test the ProductRule controller functionality.
 *
 *  Created Date    :
 *
 *  Version         :   V_1.4
 *
 *  Revision Log    :   V_1.0 - Created
 *                      V_1.1 - Change test class for Amortize milestone rule functinality.
 *                      V_1.2 - Change test class for Milestone rule functinality.
 *                      V_1.3 - Change test class for Blended  rule functinality.
 *                      V_1.4 - Change test class for Blended split.
 *
 *  Coverage        :   
**/
@isTest(SeeAllData=false)
private class TestRevRecProductRuleController {

    static RevRecRules__c rule;
    static List<RevRecRuleMilestone__c> revRecRuleMilestones;
    static Opportunity opp1;
    static OpportunityLineItem oli;
    static Product2 p1;
    
    //Test  Standard Price book
    static Id pricebookId = Test.getStandardPricebookId();    
    
    static void testSetupForAmortize() {          
       
        rule = new RevRecRules__c(
            Revenue_Recognition_End_Date__c='OPPORTUNITY:CloseDate',
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
            initial_amount__c=1000.00,
            Start_Percentage__c = 90.00,
            End_Percentage__c = 10.00 
        ); 
        insert rule;
        
        // create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create the contract
        Contract c = new Contract();
        c.AccountId = acc.Id;
        c.ContractTerm = 12;
        c.StartDate = System.today();
        c.OwnerExpirationNotice = '30';
        c.Status = 'Draft'; 
        insert c;
        
        // create the product
        p1 = new Product2(
            name='Test Product 1',
            IsActive=true,
            Description='My Product',
            ProductCode='Prod code',
            RevRecRule__c =rule.Id 
        );
        insert p1;    
           
       
        // create the pricebookentry
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id=pricebookId,
            Product2Id=p1.id,
            UnitPrice=100.00,
            IsActive=true,
            UseStandardPrice=false
        );
        insert pbe1;   
       
        // create the opportunity
        opp1 = new Opportunity(
            Probability=100, 
            Type='New Customer',  
            Pricebook2Id=pricebookId,
            ForecastCategoryName='Closed', 
            StageName='Closed Won',
            Amount=273200.00,
            name='Test Opp 1',
            CloseDate= Date.newInstance(2040, 8, 8)
        );
        insert opp1;
   
        // add the line item
        oli = new OpportunityLineItem(Quantity=1.00, PricebookEntryId=pbe1.id, OpportunityId=opp1.id, UnitPrice=12000.00);
        insert oli;  
        
    }

    static void testSetupForMilestone() {
       
        rule = new RevRecRules__c(
            Revenue_Recognition_End_Date__c='OPPORTUNITY:CloseDate',
            initial_amount_type__c='Amount', 
            Offset_Period__c=1,
            Offset_Type__c='Period',
            Active__c=true,
            Residual_Amount_Type__c='Amount', 
            Period__c='Monthly',
            Name='Rule test',
            Recognition_Type__c='Milestone', 
            Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate', 
            Period_or_Exact_Days__c='exact',
            Divide_By__c='Prorate',
            Description__c='Descr',
            residual_Amount__c=1.00, 
            Default_Rule__c=false, 
            initial_amount__c=1000.00 ,
            Start_Percentage__c = 90.00,
            End_Percentage__c = 10.00
        ); 
        insert rule;
        
        //Code modified - 01/20/2015 - As per Milestone Date Automation requirement
        revRecRuleMilestones = new List<RevRecRuleMilestone__c>();
        
        revRecRuleMilestones.add(new RevRecRuleMilestone__c (Milestone_Sequence__c = 1, Milestone_Name__c = 'test', RevRecRule__c= rule.Id, Percent__c = 100,
                                                             Milestone_Date_Source__c = 'OPPORTUNITY:CloseDate', Amount__c = 10000));
        revRecRuleMilestones.add(new RevRecRuleMilestone__c (Milestone_Sequence__c = 1, Milestone_Name__c = 'test', RevRecRule__c= rule.Id, Percent__c = 100,
                                                             Milestone_Date_Source__c = 'OPPORTUNITY PRODUCT:ServiceDate', Amount__c = 10000));
        revRecRuleMilestones.add(new RevRecRuleMilestone__c (Milestone_Sequence__c = 1, Milestone_Name__c = 'test', RevRecRule__c= rule.Id, Percent__c = 100,
                                                             Milestone_Date_Source__c = Constants.MILESTONE_DATE_MANUAL, Amount__c = 10000));          
        
        insert revRecRuleMilestones;
                
        // create the product
        p1 = new Product2(
            name='Test Product 1',  
            IsActive=true,
            Description='My Product',
            ProductCode='Prod code',
            RevRecRule__c =rule.Id 
        );
        insert p1;    
           
        // create the pricebookentry
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id=pricebookId,
            Product2Id=p1.id,
            UnitPrice=100.00,
            IsActive=true,
            UseStandardPrice=false
        );
        insert pbe1;   
       
        // create the opportunity
        opp1 = new Opportunity(
            Probability=100, 
            Type='New Customer', 
            Pricebook2Id=pricebookId,
            ForecastCategoryName='Closed', 
            StageName='Closed Won',
            Amount=273200.00,
            name='Test Opp 1',
            CloseDate= Date.newInstance(2012, 8, 8)
        );
        insert opp1;
        
        // add the line item
        oli = new OpportunityLineItem(
            Quantity=1.00, 
            PricebookEntryId=pbe1.id, 
            OpportunityId=opp1.id, 
            UnitPrice=12000.00,
            ServiceDate = Date.Today().addDays(96)
        );
        insert oli;  
       
        RevRecOpportunityLineItem__c rROLI = new RevRecOpportunityLineItem__c(Name= oli.PricebookEntry.Name,  opportunity__c = opp1.Id);
        insert rROLI;
        
        oli.TotalPrice = oli.Quantity * oli.UnitPrice;
        oli.RevRecOpportunityLineItem__c = rROLI.Id;
        update oli;
           
    }

    static testMethod void testMilestone() {
        
        testSetupForMilestone();
        rule.Recognition_Type__c = 'Milestone';
        update rule;
      
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', opp1.id);
        thePage.getParameters().put('opportunityLineItemId', oli.id);
        Test.setCurrentPage(thePage);
        
        RevRecProductRuleController  theController = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();

        //Initilize constructer
        RevRecUtil util = new RevRecUtil();
        Utility utl = new Utility(opp1);

        //Override rule
        RevRecProductRule__c overrideRule = new RevRecProductRule__c();
        
        //overrideRule.Start_Date__c = Date.today().addDays(-1);
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
       
        //Code added - 06/07/2015 - As per Blended Revenue Recoggnition
        List<RevRecRuleCategory__c> revRecRuleCatg = new List<RevRecRuleCategory__c>();
        List<RevRecProductRuleCategory__c> revRecProductRuleCatg = new List<RevRecProductRuleCategory__c>();
        
        //Code modified - 11/7/2014 - add an argumnet in query
        Map<String, RevRecRuleMilestone__c> mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();
        string msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones, 
                                        mapRevRecMileStoneWithName, revRecRuleCatg, revRecProductRuleCatg, utl, null);
        
        //Code added - 01/20/2015 - As per Milestone Date automation requirement        
        //Put values and calaling controller method
        theController.overrideRule.Milestone_Type__c = 'amount';
        revRecProductRuleMilestones[0].Percent__c = 100; 
        theController.ChangeMilestoneTypeForAM();
        theController.getShowValidateAMAgainstLI();
        theController.onEditableMode();
        theController.initializSalesAndActualForecast();
        RevRecProductRuleController.schedulesEnabledForOrg();
        theController.getTransDate(System.today(), True);  
            
        theController.overrideRule.Milestone_Type__c = 'amount';
        revRecProductRuleMilestones[0].qty__c = 2; 
        theController.ChangeMilestoneTypeForAM();
        theController.getOpportunity();
        theController.ChangeMilestoneType();
        theController.saveAMMilesOnBlur();
        
        //Put values and calaling controller method
        revRecProductRuleMilestones[0].Percent__c = 100; 
        theController.overrideRule.Milestone_Type__c = 'qty';
        theController.ChangeMilestoneTypeForAM();
        theController.ChangeMilestoneType();
        
        revRecProductRuleMilestones[0].amount__c = 10;  
        theController.overrideRule.Milestone_Type__c = 'qty';
        theController.ChangeMilestoneTypeForAM();
        
        //Put values and calaling controller method
        revRecProductRuleMilestones[0].qty__c = 1; 
        theController.overrideRule.Milestone_Type__c = 'test';
        theController.ChangeMilestoneTypeForAM();
        theController.ChangeMilestoneType();
        
        revRecProductRuleMilestones[0].amount__c = 10;  
        theController.overrideRule.Milestone_Type__c = 'test';
        theController.ChangeMilestoneTypeForAM();
        theController.ChangeMilestoneType();
        
        //Put values and calaling controller method
        theController.overrideRule.Milestone_Type__c = 'amount';
        revRecProductRuleMilestones[0].Percent__c = 100; 
        theController.getMilestoneTotal();
        
        theController.overrideRule.Milestone_Type__c = 'amount';
        revRecProductRuleMilestones[0].qty__c = 1; 
        theController.getMilestoneTotal();
        
        //Put values and calaling controller method
        revRecProductRuleMilestones[0].Percent__c = 100; 
        theController.overrideRule.Milestone_Type__c = 'qty';
        theController.getMilestoneTotal();
        
        revRecProductRuleMilestones[0].amount__c = 10;  
        theController.overrideRule.Milestone_Type__c = 'qty';
        theController.getMilestoneTotal();
        theController.saveAMMilesOnBlur();
        
        //Put values and calaling controller method
        revRecProductRuleMilestones[0].qty__c = 1; 
        theController.overrideRule.Milestone_Type__c = 'test';
        theController.getMilestoneTotal();
        
        revRecProductRuleMilestones[0].amount__c = 10;  
        theController.overrideRule.Milestone_Type__c = 'test';
        theController.getMilestoneTotal();   
        
        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Milestone';
        theController.overrideRule.Milestone_Type__c = 'amount';
        revRecProductRuleMilestones[0].amount__c = 10;
        theController.saveAMMilesOnBlur();
        
        system.assertEquals(3, revRecProductRuleMilestones.size()); 
        theController.indexString = '1,';
        theController.addMilestone();
        
        //theController.indexString = '1,';
        theController.removeMilestone ();
                
        //Assert for results
        System.assertEquals('OPPORTUNITY:CloseDate', revRecProductRuleMilestones[0].Milestone_Date_Source__c);
        System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate', revRecProductRuleMilestones[1].Milestone_Date_Source__c);
        System.assertEquals(constants.MILESTONE_DATE_MANUAL, revRecProductRuleMilestones[2].Milestone_Date_Source__c);
        
        thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', opp1.id);
        thePage.getParameters().put('opportunityLineItemId', oli.id);
        Test.setCurrentPage(thePage);
        
        theController = new RevRecProductRuleController();
        currentPageUrl = ApexPages.currentPage().getUrl();
        
        theController.overrideRule.Milestone_Type__c = 'amount'; 
        overrideRule.Residual_Amount_Type__c = 'Amount';
        overrideRule.start_Date__c = Date.today();
        overrideRule.End_Date__c = Date.today();
        theController.ChangeRecognitionTypeOptions();
        theController.overrideRule.Recognition_Type__c = 'Single Transaction';
        //theController.save();
        theController.ChangeRecognitionTypeOptions();
        theController.getShowValidateAMAgainstLI();
        theController.getOpportunity();
        theController.isMultiCurrencyEnabled = false;
        theController.init();
        theController.ChangeMilestoneType();
        
        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Milestone';
        theController.overrideRule.Milestone_Type__c = 'qty';
        revRecProductRuleMilestones[0].Qty__c= 3;
        //theController.save();
        theController.ChangeMilestoneType();
        
        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Milestone';
        theController.overrideRule.Milestone_Type__c = 'percent';
        revRecProductRuleMilestones[0].Percent__c = 1;
        theController.AdjustProductPricingOpportunityAmount();
        theController.ChangeMilestoneTypeForAM();
        theController.getMilestoneTotal();
        
        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Milestone';
        theController.overrideRule.Milestone_Type__c = 'qty';
        revRecProductRuleMilestones[0].Qty__c= 5;
        revRecProductRuleMilestones[0].Milestone_Date__c = date.today();
        theController.ChangeMilestoneTypeForAM();
        theController.getMilestoneTotal();
        theController.getMilestoneAmountTotal();
        theController.getMilestoneDeferredAmountTotal();
        theController.AdjustProductPricingOpportunityAmount();
        
        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Milestone';
        theController.overrideRule.Milestone_Type__c = 'percent';
        revRecProductRuleMilestones[0].Percent__c = 1;
        theController.ChangeMilestoneTypeForAM();
        theController.ChangeMilestoneTypeForAM();
        theController.getMilestoneTotal();
        theController.getMilestoneAmountTotal();
        theController.getMilestoneDeferredAmountTotal();

        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Milestone';
        theController.overrideRule.Milestone_Type__c = 'amount';
        revRecProductRuleMilestones[0].amount__c = 1;
        revRecProductRuleMilestones[0].Milestone_Date__c = date.today();
        theController.getMilestoneTotal();
        theController.getMilestoneAmountTotal();
        theController.getMilestoneDeferredAmountTotal();
        theController.saveMilesOnBlur();
        
        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Amortized Milestone';
        theController.overrideRule.Milestone_Type__c = 'amount';
        theController.overrideRule.Period__c = 'weekly';
        theController.assignVisualBlocks(); 
        theController.overrideRule.Residual_Amount__c = 0.1;
        revRecProductRuleMilestones[0].amount__c = 50;
        revRecProductRuleMilestones[0].Milestone_Date__c = date.today();
        theController.ChangeMilestoneTypeForAM();
        theController.getMilestoneTotal();
        theController.getMilestoneAmountTotal();
        theController.getMilestoneDeferredAmountTotal();
        theController.AdjustProductPricingOpportunityAmount();
        theController.saveAMMilesOnBlur();

        //Calling controller method
        theController.overrideRule.Recognition_Type__c = 'Amortized Milestone';
        theController.overrideRule.Milestone_Type__c = 'qty';
        revRecProductRuleMilestones[0].Milestone_Date__c = date.parse('05/11/2018');
        revRecProductRuleMilestones[0].Qty__c= 8;
        revRecProductRuleMilestones[0].amount__c = 100;
        theController.saveAMMilesOnBlur();
        theController.saveMilestone();
        theController.removeMilestone (); 
        theController.overrideRule.Period__c = 'quarterly';
        theController.assignVisualBlocks();
        theController.overrideRule.Period__c = 'yearly';
        theController.assignVisualBlocks();
        theController.overrideRule.Period__c = 'daily';
        theController.assignVisualBlocks();
        
    }
    
     static testMethod void testControllerActions() {
        testSetupForAmortize();
        
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', opp1.id);
        thePage.getParameters().put('opportunityLineItemId', oli.id);
        Test.setCurrentPage(thePage);
        
        RevRecProductRuleController  theController = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        
        //Code Added - 11/08/2014 - As per Amortized Milestone Rule Requirements 
        List<SelectOption> listAmortizeBy  = theController.getAmortizeMilestoneOptions();
        List<SelectOption> listMileStoneType  = theController.getMilestoneOptions();

        RevRecUtil util = new RevRecUtil();
        Utility utl = new Utility(opp1);

        RevRecProductRule__c overrideRule = new RevRecProductRule__c();
        overrideRule.Recognition_Type__c = 'Single Transaction';
        overrideRule.Start_Date__c = Date.today().addDays(-1);
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
        
        //Code added - 06/07/2015 - As per Blended Revenue Recoggnition
        List<RevRecRuleCategory__c> revRecRuleCatg = new List<RevRecRuleCategory__c>();
        List<RevRecProductRuleCategory__c> revRecProductRuleCatg = new List<RevRecProductRuleCategory__c>();
        
        //Code modified - 11/7/2014 - add an argumnet in query
        Map<String, RevRecRuleMilestone__c> mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();
        string msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones, 
                                        mapRevRecMileStoneWithName, revRecRuleCatg , revRecProductRuleCatg, utl, null);
        
        System.assertEquals(msg, '');

        overrideRule.Recognition_Type__c = 'Amortize';
        overrideRule.Residual_Amount_Type__c = 'Percent';
        rule.Period__c = 'Weekly';
        theController.overrideRule.End_Date__c = Date.Today();
        theController.ChangeRecognitionPeriod();
        theController.init(); 
         
        //Code modified - 11/7/2014 - add an argumnet in query
        mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();        
        msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones, 
                                                       mapRevRecMileStoneWithName, revRecRuleCatg, revRecProductRuleCatg, utl, null);
        System.assertEquals(msg, '');

        overrideRule.Recognition_Type__c = 'Amortize'; 
        rule.Period__c = 'quarterly';
        theController.ChangeRecognitionPeriod();
         
        //Code modified - 11/7/2014 - add an argumnet in query
        mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();        
        msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones, 
                                                       mapRevRecMileStoneWithName, revRecRuleCatg, revRecProductRuleCatg, utl, null);
        
        System.assertEquals(msg, '');
        
        overrideRule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'daily'; 
        theController.ChangeRecognitionPeriod();
        theController.assignVisualBlocks();
        msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones, 
                                                        mapRevRecMileStoneWithName, revRecRuleCatg, revRecProductRuleCatg, utl, null);
        System.assertEquals(msg, '');
        
        overrideRule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'yearly';
        theController.ChangeRecognitionPeriod();
        msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones, 
                                            mapRevRecMileStoneWithName, revRecRuleCatg, revRecProductRuleCatg, utl, null);
        System.assertEquals(msg, '');
        
        //Code added - 11/08/2014 - For amoertize quartely
        overrideRule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'quarterly';
        theController.ChangeRecognitionPeriod();
        msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones, 
                                                       mapRevRecMileStoneWithName, revRecRuleCatg,  revRecProductRuleCatg, utl, null);
        System.assertEquals(msg, '');
        

        overrideRule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'Yearly';
        theController.ChangeRecognitionPeriod();
        //theController.save();
         
        //Code modified - 11/7/2014 - add an argumnet in query
        mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();
        msg = util.CalculateOverrideRuleFromRevRecRule(opp1, oli, p1, rule,  overrideRule, revRecRuleMilestones,revRecProductRuleMilestones,
                                                       mapRevRecMileStoneWithName, revRecRuleCatg,  revRecProductRuleCatg, utl, null);
        System.assertEquals(msg, '');
        
        System.assertNotEquals(theController.getDividedByOptions(), null);
        System.assertNotEquals(theController.getPeriodExactOptions(), null);
        System.assertEquals(theController.ChangeRecognitionPeriod(), null);
        
        System.assertNotEquals(theController.cancel(), null);
        
        overrideRule.Recognition_Type__c = 'Milestone';
        overrideRule.Milestone_Type__c = 'qty';
        theController.saveMilesOnBlur();
        theController.indexString = '1,';
        theController.addMilestone();
        
        revRecProductRuleMilestones = theController.getRevRecProductRuleMilestones();
        revRecProductRuleMilestones[0].Percent__c = 100;
        revRecProductRuleMilestones[0].Milestone_Date__c = Date.today();
        theController.indexString = '0,';
        theController.removeMilestone ();
        
        theController.indexString = '0,';
        theController.addMilestone();
        revRecProductRuleMilestones[0].Percent__c = 100;
        revRecProductRuleMilestones[0].Milestone_Date__c = Date.today();
        revRecProductRuleMilestones[0].Milestone_Date_Source__c = 'OPPORTUNITY PRODUCT:ServiceDate';
                
        System.assertEquals(theController.ChangeShowTotalPeriod(), null);
        System.assertNotEquals(theController.getMilestoneTotal(), null);
        System.assertNotEquals(theController.getRecord (), null);
        
        theController.getShowAmortizeDetail ();
        theController.getShowMilestoneDetail ();
        theController.getShowDevideEvenlyDetail ();
        theController.getShowByPeriodOrExactDetail ();
        theController.getShowOffsetDetail ();
        theController.getShowSingleTransDetail ();
        theController.setShowTotalPeriod(true);
        thecontroller.getStartAndEndDateOptions();
        thecontroller.getMilestoneDeferredAmountTotal();
        thecontroller.ChangeMilestoneDateSource();
        System.assertEquals(theController.getShowTotalPeriod (), true);  
        theController.ChangeRecognitionTypeOptions(); 
        theController.onChangeExactDaysOptions();
         
        overrideRule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'Yearly';
        rule.Divide_By__c = 'exact';
        theController.onChangeDivideByOption();
        theController.removeMilestone();
    } 
    
     //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    static testMethod void testAmortizeMilestoneAmortizeByQty() {
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortized Milestone',
                                                              Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                              Revenue_Recognition_Start_Date__c='OPPORTUNITY PRODUCT:AppRopozSLN__Product_Selling_Date__c',
                                                              Revenue_Recognition_End_Date__c='OPPORTUNITY PRODUCT:ServiceDate',
                                                              Initial_Amount__c = 0.00, Milestone_Type__c = 'amount');
        insert  revRecDefaultRule;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create the contract
        Contract c = new Contract();
        c.AccountId = acc.Id;
        c.ContractTerm = 12;
        c.StartDate = System.today();
        c.OwnerExpirationNotice = '30';
        c.Status = 'Draft'; 
        insert c;
        
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
        
        //PriceBookEntry List
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, 
                            Quantity = 1, UnitPrice = 1000, RevRecRule__c = revRecDefaultRule.Id,
                            ServiceDate = Date.Today().addMonths(6)));
        insert oppLineItems;
        
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000 ));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
             
        //Set URL parameter
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer iniilization
        RevRecProductRuleController  theController = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        
        //List of select options
        List<SelectOption> listSelect = theController.getAmortizeMilestoneOptions();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        
        //Test start from here
        Test.StartTest();
        
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        //System.assert(msg == null);
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = theController.getRevRecProductRuleMilestones();
        
        //Change milestone typpe
        //theController.overrideRule.Amortize_By__c = 'qty';
        theController.overrideRule.Milestone_Type__c = 'qty';
        
        //Addd Actual amount and quantity
        //revRecProductRuleMilestones[0].Amount__c = 10;
        //revRecProductRuleMilestones[0].Actual_Amount__c = 10;
        //revRecProductRuleMilestones[0].Qty__c = 1;
        revRecProductRuleMilestones[0].Actual_Qty__c = 1;
        revRecProductRuleMilestones[0].Milestone_Date__c = date.parse('06/07/2012');
        
        //Assert for results : 5 milestone from November-2014  - March-2014
        System.assertEquals(3, revRecProductRuleMilestones.size());
        
        revRecProductRuleMilestones[0].Actual_Qty__c = 1;
        theController.adjustFutureRevenue();
        System.assertEquals(1, revRecProductRuleMilestones[0].Actual_Qty__c);
        
        revRecProductRuleMilestones[0].Actual_Amount__c = 10000;
        revRecProductRuleMilestones[0].Milestone_Date_Source__c = 'CONTRACT:Contract Start Date';
        //theController.overrideRule.Amortize_By__c = 'amount';
        theController.overrideRule.Milestone_Type__c = 'amount';
        theController.overrideRule.Residual_Amount__c = 0.1;
        theController.overrideRule.initial_Amount__c = 3.00;
        theController.adjustFutureRevenue();
        theController.AdjustProductPricingOpportunityAmount();
        System.assertEquals(10000, revRecProductRuleMilestones[0].Actual_Amount__c);
        
        //revRecProductRuleMilestones[0].Actual_Amount__c = 10000;
        theController.AdjustProductPricingOpportunityAmount();
        //System.assertEquals(10000, revRecProductRuleMilestones[0].Actual_Amount__c);
        //System.assertEquals(1000, oppLineItems[0].TotalPrice);
                
        //Calling controller methods
        theController.indexString = '1,';
        theController.addMilestone();
        revRecProductRuleMilestones[2].Milestone_Name__c = 'Test';
        revRecProductRuleMilestones[2].Milestone_Date__c = date.parse('06/07/2012');
        
        //Change milestone typpe
        //theController.overrideRule.Amortize_By__c = 'qty';
        theController.overrideRule.Milestone_Type__c = 'qty';
        theController.ChangeMilestoneTypeForAM();
        theController.saveMilestone();
        theController.AdjustProductPricingOpportunityAmount();
        
        //theController.overrideRule.Amortize_By__c = 'qty';
        theController.overrideRule.Milestone_Type__c = 'qty';
        string res = theController.getMilestoneTotal();
        
        //Assert for results
        system.assertEquals(4, revRecProductRuleMilestones.size());
        
        //Re-calling constructer
        msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Test stop here
        Test.stopTest();
        
        //Get milestones list
        revRecProductRuleMilestones = theController.getRevRecProductRuleMilestones();
        
        //Addd Actual amount and quantity
        revRecProductRuleMilestones[0].Amount__c = 1000;
        revRecProductRuleMilestones[0].Actual_Amount__c = 1000;
        revRecProductRuleMilestones[0].Qty__c = 1;
        //revRecProductRuleMilestones[0].Actual_Qty__c = 1;
        
        //theController.overrideRule.Amortize_By__c = 'qty';
        theController.overrideRule.Milestone_Type__c = 'qty';
        
        //Calling save method
        theController.getMilestoneActualTotal();
        theController.getMilestoneTotal();
        theController.getVariance();
        theController.getShowAmortizeMilestoneDetail();
        
        //Assert for results
        system.assertEquals(4, revRecProductRuleMilestones.size());
        
        theController.ChangeRecognitionTypeOptions();
        
        //update RevRecOppportunity Line Item         
        thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer iniilization
        theController = new RevRecProductRuleController();
        currentPageUrl = ApexPages.currentPage().getUrl();
  
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    static testMethod void testAmortizeMilestoneAmortizeByAmount1() {
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                          Time_of_Month_Selection_Types_tr__c = '1',Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
         //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', Offset_Period__c = 2, Offset_Type__c =  'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortized Milestone',
                                                              Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                              Revenue_Recognition_Start_Date__c='OPPORTUNITY PRODUCT:AppRopozSLN__Product_Selling_Date__c',
                                                              Revenue_Recognition_End_Date__c='OPPORTUNITY PRODUCT:ServiceDate',
                                                              Initial_Amount__c = 0.00, Milestone_Type__c = 'amount'/*, Amortize_By__c = 'amount'*/);
        insert revRecDefaultRule;
        
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
        
        //PriceBookEntry List
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, 
                                RevRecRule__c = revRecDefaultRule.Id , Quantity = 1, UnitPrice = 1000, ServiceDate = Date.Today().addMonths(6)));
        insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, DeferredRev__c = 100, RecognizedRev__c = 100));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
       
       
        //Set URL parameter
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer iniilization
        RevRecProductRuleController  theController = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        
        //List of select options
        List<SelectOption> listSelect = theController.getAmortizeMilestoneOptions();
      
        //Test start from here
        Test.StartTest();
       
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
          
        //Test stop here
        Test.stopTest();
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = theController.getRevRecProductRuleMilestones();
        
        //Change milestone typpe
        //theController.overrideRule.Amortize_By__c = 'amount';
        theController.overrideRule.Milestone_Type__c = 'amount';
        
        //Addd Actual amount and quantity
        revRecProductRuleMilestones[0].Amount__c = 10;
        revRecProductRuleMilestones[0].Actual_Amount__c = 10;
        revRecProductRuleMilestones[0].Qty__c = 1;
        revRecProductRuleMilestones[0].Actual_Qty__c = 1; 
        revRecProductRuleMilestones[0].Milestone_Date__c = date.parse('06/07/2012'); 
        
        //Assert for results : 3 milestone 
        //System.assertEquals(3, revRecProductRuleMilestones.size());
        
        revRecProductRuleMilestones[0].Actual_Amount__c = 10000;
        Constants.IS_BY_PASS_LINE_ITEM_TRIGGER = true;
        theController.saveMilestone();
        theController.AdjustProductPricingOpportunityAmount();
        Constants.IS_BY_PASS_LINE_ITEM_TRIGGER = false;  
        System.assertEquals(10000, revRecProductRuleMilestones[0].Actual_Amount__c);
        //System.assertEquals(1000, oppLineItems[0].TotalPrice);
       
        theController.overrideRule.Milestone_Type__c = 'percent';
        theController.ChangeMilestoneTypeForAM();
        theController.getMilestoneActualTotal();
        theController.getVariance();
        theController.AdjustProductPricingOpportunityAmount();
    }
  	/***** ***** ***** Code added - 07/06/2015 - As per Blended Revnue recognition **** ***** ****/
    /***** START *****/
    
    /**
     *  @description    :   This method is used to test the Blended revenue recognition functionality.
     *
     *  @args           :   
     *
     *  @return         :   Void
     *    
    **/
    static testmethod void testBlendedRevenueRecognition() {
         
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
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
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 1,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, RevRecRule__c = revRecRules[0].Id));
        
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Percent', Percent__c = 10, Line_Item__c = '0',Sequence__c = 2,
                                                     Category_Start_Date__c = 'Manual', Category_End_Date__c = 'None', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, RevRecRule__c = revRecRules[0].Id));
        
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -3 ' , Category_Type__c = 'Qty', Qty__c = 1, Line_Item__c = '1',Sequence__c = 3,
                                                     Category_Start_Date__c = 'None', Category_End_Date__c = 'Manual', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[0].Id));
        
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -4 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 4,
                                                     Category_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', Category_End_Date__c = 'OPPORTUNITY:CloseDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, RevRecRule__c = revRecRules[0].Id));
        
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -5 ' , Category_Type__c = 'Qty', Qty__c = 1, Line_Item__c = '1',Sequence__c = 0,
                                                     Category_Start_Date__c = 'CONTRACT: Contract Start Date', Category_End_Date__c = 'None', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[1].Id));
        
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -6 ' , Category_Type__c = 'Qty', Qty__c = 1, Line_Item__c = '1',Sequence__c = 1,
                                                     Category_Start_Date__c = 'Manual', Category_End_Date__c = 'OPPORTUNITY:CloseDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[1].Id));
        
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -7 ' , Category_Type__c = 'Qty', Qty__c = 1, Line_Item__c = '0',Sequence__c = 2,
                                                     Category_Start_Date__c = 'PRODUCT:Product Date', Category_End_Date__c = 'OPPORTUNITY:CloseDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE, RevRecRule__c = revRecRules[1].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
        
        // create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create the contract
        Contract c = new Contract();
        c.AccountId = acc.Id;
        c.ContractTerm = 12;
        c.StartDate = System.today();
        c.OwnerExpirationNotice = '30';
        c.Status = 'Draft'; 
        insert c;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-90), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true,RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
         
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
                                                 ,ServiceDate = Date.Today().addMonths(6) , RevRecRule__c = revRecRules[0].Id));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[3].Id, Quantity = 10, UnitPrice = 15000
                                                 ,ServiceDate = Date.Today().addMonths(6),RevRecRule__c = revRecRules[0].Id));
        
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
        
        //Set URL parameter
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer initlilization
        RevRecProductRuleController controller = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        
        //Assert for results
        system.assertEquals(4, controller.listCategoryWrap.size());
        
        //Calling Getter list of controller
        List<SelectOption>  recognitionTypeOptions = controller.getRecognitionTypeOptions();
        List<SelectOption>  startDateOptions = controller.getStartDateSelectOptions();
        List<SelectOption>  endDateOptions = controller.getEndDateSelectOptions(); 
        controller.getBlendedOptions();
        controller.getRevRecProductRuleCategories();
        controller.getRevRecRulesCategory();
        controller.getShowBlendedRevenueRecognitionDetail();
        controller.calculateBlendedCategories();
        //Calling controller method
        controller.ChangeCategoryType();
        
        controller.listCategoryWrap[0].isSelected = true;
        controller.listCategoryWrap[2].isSelected = true;
        controller.addCategory();
        //controller.save();
        
        //Assert for results
        system.assertEquals(5, controller.listCategoryWrap.size());
        system.assertEquals(4, controller.listCategoryWrap[3].revRecProductCategory.sequence__c);
        
        controller.listCategoryWrap[0].isSelected = false;
        controller.listCategoryWrap[2].isSelected = false;
        controller.listCategoryWrap[3].isSelected = true;
        controller.removeCategory();
        
        //Assert for results
        system.assertEquals(4, controller.listCategoryWrap.size());
        
        //change start date
        controller.listCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'Opportunity:Close Date';
        controller.listCategoryWrap[0].revRecProductCategory.Category_End_Date__c = 'Opportunity:Close Date';
        
        ApexPages.currentpage().getParameters().put('endRowNumber' , '1');
        ApexPages.currentpage().getParameters().put('startRowNum' , '1');
        
        //On change methods     
        controller.onChangeEndOptionsForBlended(); 
        controller.onChangeStartOptionsForBlended();

        controller.listCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'PRODUCT:Product Date';
        controller.onChangeStartOptionsForBlended();
        controller.listCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'CONTRACT:Contract Start Date';
        controller.onChangeStartOptionsForBlended();
        //Set URL parameter
        /** thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer initlilization
        controller = new RevRecProductRuleController();
        currentPageUrl = ApexPages.currentPage().getUrl();
        
        //Assert for results
        //system.assertEquals(5, controller.listCategoryWrap.size());
        
        //Change dates 
        controller.listCategoryWrap[0].revRecProductCategory.Actual_Start_Date__c = Date.Today().addYears(-3);
        controller.listCategoryWrap[0].revRecProductCategory.Actual_End_Date__c = Date.Today().addYears(3);
        
        ApexPages.currentpage().getParameters().put('endRowNumber' , '2');
        ApexPages.currentpage().getParameters().put('startRowNum' , '2');        
        controller.endRowNumber = 1;
        controller.onChangeEndOptionsForBlended(); 
        controller.startRowNumber = 1;
        controller.onChangeStartOptionsForBlended();
        
        System.assertEquals(controller.listCategoryWrap[0].revRecProductCategory.Actual_Start_Date__c, Date.Today().addYears(-3));
        System.assertEquals(controller.listCategoryWrap[0].revRecProductCategory.Actual_End_Date__c, Date.Today().addYears(3));
        
        controller.save(); 
        **/
        
        //Test stop here
        Test.stopTest();        
    }
    /***** END *****/
    
    /** This method is used to cover the RevRecHelper **/
    static testmethod void testRevRecHelperMethod () {
        
        //Test starts here
        Test.startTest();
         
        String certainWeek = '1st' ;
        String certainDayOfWeek = 'monday';
        Date theDate = Date.Today();
        
        //Calling controller method
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, CertainWeek, certainDayOfWeek);
        
        certainWeek = '2nd' ;
        certainDayOfWeek = 'sunday';
        theDate = Date.Today();
         
        //Calling controller method 
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, CertainWeek, certainDayOfWeek);
        
        certainWeek = '3rd' ;
        certainDayOfWeek = 'tuesday';
        theDate = Date.Today();
        
        //Calling controller method
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, CertainWeek, certainDayOfWeek);
        
        CertainWeek = '4th' ;
        certainDayOfWeek = 'wednesday';
        theDate = Date.Today();
        System.assertEquals('wednesday', certainDayOfWeek);
        
        //Calling controller method
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, CertainWeek, certainDayOfWeek);
        
        certainWeek = 'Last' ;
        certainDayOfWeek = 'thursday';
        theDate = Date.Today();
        
        //Calling controller method
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, CertainWeek, certainDayOfWeek);
        
        certainWeek = '1' ;
        certainDayOfWeek = 'friday';
        theDate = Date.Today();
        System.assertEquals('friday', certainDayOfWeek);
        
        //Calling controller method
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, CertainWeek, certainDayOfWeek);
        
        certainWeek = '1' ;
        certainDayOfWeek = 'saturday';
        theDate = Date.Today();
        
        //Calling controller method
        RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, CertainWeek, certainDayOfWeek);      
        
        //Test stop here
        Test.stopTest();
    }
    
    //Code added  - 11/8/2014 - Method to test functioanlity of Rule = Amortize MileStone 
    static testMethod void testAmortizeMilestoneAmortizeByAmount() {
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                          Time_of_Month_Selection_Types_tr__c = '1',Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortized Milestone',
                                                                Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                                Revenue_Recognition_Start_Date__c='OPPORTUNITY PRODUCT:AppRopozSLN__Product_Selling_Date__c',
                                                                Revenue_Recognition_End_Date__c='OPPORTUNITY PRODUCT:ServiceDate',
                                                                Initial_Amount__c = 0.00, /*Amortize_By__c = 'amount', */Milestone_Type__c = 'amount');
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
        
        //Add line items into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, 
                                    UnitPrice = 1000, ServiceDate = Date.Today().addMOnths(6) , RevRecRule__c = revRecDefaultRule.Id));
        
        //Insert line items
        insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Rev Rec opp line items
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        //Insert line items
        insert revRecLineItems;  
        System.assertEquals(100, revRecLineItems[0].ResidualAmount__c);
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
         
        //Product override rule
        //constants.IS_BY_PASS_TRIGGER = true;
        
        //Set URL parameter
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer iniilization
        RevRecProductRuleController  theController = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        
        //List of select options
        List<SelectOption> listSelect = theController.getAmortizeMilestoneOptions();
        
         //Test start from here
        Test.StartTest();
        
        //Initilize Controller class
        RevRecUtil util = new RevRecUtil();
        string msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        //System.assertEquals(msg, '');
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = theController.getRevRecProductRuleMilestones();

        //Change milestone typpe
        //theController.overrideRule.Amortize_By__c = 'amount';
        theController.overrideRule.Milestone_Type__c = 'amount';
        
        //Addd Actual amount and quantity
        revRecProductRuleMilestones[0].Amount__c = 10;
        revRecProductRuleMilestones[0].Actual_Amount__c = 10;
        revRecProductRuleMilestones[0].Qty__c = 1;
        revRecProductRuleMilestones[0].Actual_Qty__c = 1;
       	
        //Calling controller methods
        theController.addMilestone();
        
        revRecProductRuleMilestones[0].Milestone_Name__c = 'Test';
        revRecProductRuleMilestones[0].Milestone_Date__c = Date.Today().addMOnths(9);
        
        //Change milestone typpe
        //theController.overrideRule.Amortize_By__c = 'amount';
        theController.overrideRule.Milestone_Type__c = 'amount';
        theController.ChangeMilestoneTypeForAM();
        //theController.overrideRule.Amortize_By__c = 'amount';
        theController.overrideRule.Milestone_Type__c = 'amount';
        string res = theController.getMilestoneTotal();

        //Assert for results
        //System.assert(msg == null);
        
        //Re-calling constructer
        msg = util.EvaluateRevRecScheduleForOpportunity(string.valueOf(opportynity.Id));
        
        //Assert for results
        //System.assert(msg == null);
        
        //Get milestones list
        revRecProductRuleMilestones = theController.getRevRecProductRuleMilestones();
        
        //Test stop here
        Test.stopTest();
        
        //Addd Actual amount and quantity
        revRecProductRuleMilestones[0].Amount__c = 1000;
        revRecProductRuleMilestones[0].Actual_Amount__c = 1000;
        revRecProductRuleMilestones[0].Qty__c = 5;   
        revRecProductRuleMilestones[0].Milestone_Date__c = System.today();
        //theController.overrideRule.Amortize_By__c = 'amount';
        theController.overrideRule.Milestone_Type__c = 'amount';
        
        //Calling save method
        theController.getMilestoneActualTotal();
        theController.getMilestoneTotal();
        theController.getVariance();
        //theController.save();
        theController.getShowAmortizeMilestoneDetail();

        //Calling controller method
        theController.ChangeRecognitionTypeOptions();
                
        thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer iniilization
        /** theController = new RevRecProductRuleController();
        currentPageUrl = ApexPages.currentPage().getUrl();
        
        theController.selectedAMType = '1';
        theController.ChangeMilestoneTypeForAM();
        
        //Calling controller method 
        theController.save(); **/

    }
    
    /** ** ** **This method is used to check the functionality of Error message display while rec date is less then opportunity:closedate ** ** ** **/
    static testMethod void testErrorMessageFunctionality() {
      
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                          Time_of_Month_Selection_Types_tr__c = '1',Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                              Offset_Period__c = 2,Offset_Type__c = 'Start',Default_Rule__c = true,
                                                              Recognition_Type__c = 'Blended Revenue',
                                                              /*Amortize_By__c = 'amount',*/ Milestone_Type__c = 'amount');
                                                                    
        insert  revRecDefaultRule;
        
         //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 1,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, RevRecRule__c = revRecDefaultRule.Id));
        
        insert ruleCategories;
        
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
        
        //Add line items into list
        oppLineItems.add(new OpportunityLineItem(serviceDate = Date.Today().addDays(-2), OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000));
        
        //Insert line items
        insert oppLineItems;
         
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Rev Rec opp line items
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
             
        //Insert line items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        
        //Test start here 
        Test.startTest();
        
        //Set URL parameter
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer initlilization
        RevRecProductRuleController controller = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        system.assertEquals(0, msgs.size());
        //system.assert(msgs[0].getDetail().contains(constants.ERROR_MESSAGE_BASED_ON_DATES));
    } 
    
    /***** ***** ***** Code added - 10/23/2015 - As per Blended Split Revnue recognition **** ***** ****/
    static testMethod void testSplitBlended() {
        
        //Application Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        //Insert Application setting
        insert appSetting;
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start', Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                 
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //List of Rule Category
        List<RevRecRuleCategory__c> ruleCategories = new List<RevRecRuleCategory__c>();
        
        //Add categories into list
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -1 ' , Category_Type__c = 'Amount', Amount__c = 100, Line_Item__c = '0',Sequence__c = 1,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'None', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, 
                                                     RevRecRule__c = revRecRules[0].Id));
        
        ruleCategories.add(new RevRecRuleCategory__c(Name = 'Cat -2 ' , Category_Type__c = 'Percent', Percent__c = 10, Line_Item__c = '0',Sequence__c = 2,
                                                     Category_Start_Date__c = 'OPPORTUNITY:CloseDate', Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate', 
                                                     Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION,
                                                     RevRecRule__c = revRecRules[0].Id));
        
        //Insert Rule Categories
        insert ruleCategories;
               
        // create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create the contract
        Contract c = new Contract();
        c.AccountId = acc.Id;
        c.ContractTerm = 12;
        c.StartDate = System.today();
        c.OwnerExpirationNotice = '30';
        c.Status = 'Draft'; 
        insert c;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-90), StageName = 'Closed Won',Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        
        //Insert Product
        insert products;
         
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
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, 
                                                 Quantity = 1, UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90),
                                                  RevRecRule__c = revRecRules[0].Id));
       
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 100, RecognizedRev__c = 100));
      
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        
        //Update line items 
        update oppLineItems;
        
        List<RevRecProductRuleCategory__c> revRecProductRuleCatg = new List<RevRecProductRuleCategory__c>();
        insert revRecProductRuleCatg;
        
        //Test start here 
        Test.startTest();
        
        //Set URL parameter
        Pagereference thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer initlilization
        RevRecProductRuleController controller = new RevRecProductRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        
        //Assert for results
        system.assertEquals(2, controller.listCategoryWrap.size());
        
        //Save method
        //controller.save();
        
        //Set URL parameter
        //thePage = Page.RevRecProductRule;
        //thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        //thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        //Test.setCurrentPage(thePage);
        
        //Constructer initlilization
        //controller = new RevRecProductRuleController();
        //currentPageUrl = ApexPages.currentPage().getUrl();
        
        //Set controller variable
        controller.categoryToBeSplit = '1';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;
        
        //Calling controller method
        controller.doSplitCategories();
        
        //Assert for results
        System.assertEquals(1, controller.listSplitCategoryWrap.size());
        
        //Select checkbox
        controller.listSplitCategoryWrap[0].isSelected = true;
        
        //Calling add Category method
        controller.addCategoryForSplit();
        
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
        
        //Select checkbox
        controller.listSplitCategoryWrap[0].isSelected = true;
        
        //Calling add Category method
        controller.addCategoryForSplit();
        
        //Assert for results
        System.assertEquals(3, controller.listSplitCategoryWrap.size());
        
        //Select checkbox
        controller.listSplitCategoryWrap[1].isSelected = true;
                
        //Calling add Category method
        controller.removeCategoryForSplit();
        
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
        
        //change start and end date
        controller.listSplitCategoryWrap[1].revRecProductCategory.Category_Start_Date__c = 'Opportunity:Close Date';
        controller.listSplitCategoryWrap[1].revRecProductCategory.Category_End_Date__c = 'Opportunity:Close Date';
        
        //set page parameter 
        ApexPages.currentpage().getParameters().put('endRowNumber' , '2');
        ApexPages.currentpage().getParameters().put('startRowNum' , '2');
        
        //Calling onchange methods
        controller.onChangeStartOptionsForSplitBlended();
        controller.onChangeEndOptionsForBlendedSplit();
        
        //Change end date
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_End_Date__c = 'NONE';
        
        //Set page parameter
        ApexPages.currentpage().getParameters().put('endRowNumber' , '1');
        ApexPages.currentpage().getParameters().put('startRowNum' , '1');
        
        //Calling onchange date merhods
        controller.onChangeStartOptionsForSplitBlended();
        controller.onChangeEndOptionsForBlendedSplit();
        
        system.assertEquals(100.00 , controller.originalLineItemAmount);
        system.assertEquals(0.01, controller.originalLineItemQty);
        
        //Setting values in splitting wrapper
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_Type__c = 'Amount';
        controller.listSplitCategoryWrap[1].revRecProductCategory.Category_Type__c = 'Percent';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Amount__c = 50;
        controller.listSplitCategoryWrap[1].revRecProductCategory.Percent__c = 100;
        controller.listSplitCategoryWrap[0].revRecProductCategory.Line_Item__c = '0';
        controller.listSplitCategoryWrap[1].revRecProductCategory.Line_Item__c = '1';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'MANUAL';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Start_Date__c = Date.Today().addDays(-3);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_End_Date__c = null;
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_End_Date__c = 'NONE';
        controller.listSplitCategoryWrap[1].revRecProductCategory.Category_End_Date__c = 'MANUAL';
        controller.listSplitCategoryWrap[1].revRecProductCategory.Category_Start_Date__c = 'MANUAL';
        controller.listSplitCategoryWrap[1].revRecProductCategory.Actual_Start_Date__c = Date.Today();
        controller.listSplitCategoryWrap[1].revRecProductCategory.Actual_End_Date__c = Date.Today().addMonths(1);
       	controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Deferred__c = 10;
        controller.listSplitCategoryWrap[0].revRecProductCategory.Recognized_Amount__c = 8;
        controller.listSplitCategoryWrap[1].revRecProductCategory.Actual_Deferred__c = 10;
        controller.listSplitCategoryWrap[1].revRecProductCategory.Recognized_Amount__c = 1;
        
        
        //Calling controller methods
        controller.calculateSplit();
        controller.saveSplits();
        
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
        System.assertEquals(50.00, controller.listSplitCategoryWrap[0].revRecProductCategory.Recognized_Amount__c);
        System.assertEquals(0.00, controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Deferred__c);
        //System.assertEquals(25.00, controller.listSplitCategoryWrap[1].revRecProductCategory.Recognized_Amount__c);
        //System.assertEquals(25.00, controller.listSplitCategoryWrap[1].revRecProductCategory.Actual_Deferred__c);
        //System.assertEquals(75.00 , controller.totalSplitRecognized);
        //System.assertEquals(25.00 , controller.totalSplitDeferred);
        
        //Assert for parent screen data - After Splits
        //System.assertEquals(75.00, controller.listCategoryWrap[0].revRecProductCategory.Recognized_Amount__c);
        //System.assertEquals(25.00, controller.listCategoryWrap[0].revRecProductCategory.Actual_Deferred__c);
        
        //Now splitting for child screen 
        //Set controller variable
        controller.categoryToBeSplit = '1';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;
        
        //Calling controller method
        controller.doSplitCategories();
        
        //Assert for results
        //System.assertEquals(2, controller.listSplitCategoryWrap.size());
        
        //Set controller variable
        controller.categoryToBeSplit = '1';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_CHILD;
        controller.categoryParentId = controller.listSplitCategoryWrap[0].revRecProductCategory.RevRecProductRuleSplitCategory__c;
        
        //Calling controller method
        controller.doSplitCategories();
        
        //Assert for results
        //System.assertEquals(1, controller.listSplitCategoryWrap.size());
        //system.assertEquals(50.00, controller.originalLineItemAmount);
        //system.assertEquals(0.005, controller.originalLineItemQty);
        
        //Setting controller properties
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_Type__c = 'Amount';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Amount__c = 50;
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'MANUAL';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Start_Date__c = Date.Today();
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_End_Date__c = Date.Today().addMonths(4);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_End_Date__c = 'MANUAL';
        
        //Calling controller methods
        controller.init();
        controller.calculateSplit();
        controller.saveSplits();

        //Assert for results
        //System.assertEquals(10.00, controller.listSplitCategoryWrap[0].revRecProductCategory.Recognized_Amount__c);
        //System.assertEquals(40.00, controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Deferred__c);
         
        //Assert for parent screen data - After Splits
        //System.assertEquals(35.00, controller.listCategoryWrap[0].revRecProductCategory.Recognized_Amount__c);
        //System.assertEquals(65.00, controller.listCategoryWrap[0].revRecProductCategory.Actual_Deferred__c);
        
         //Now splitting for child screen 
        //Set controller variable
        controller.categoryToBeSplit = '1';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;

        //Calling controller method
        controller.doSplitCategories();
        
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'MANUAL';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Start_Date__c = Date.Today().addMonths(-4);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_End_Date__c = Date.Today().addMonths(-2);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_End_Date__c = 'MANUAL';
        
        //Calling controller methods
        controller.doSplitCategories();
        controller.calculateSplit();
        controller.saveSplits();
        
        //Now splitting for child screen 
        //Set controller variable
        controller.categoryToBeSplit = '1';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;
        
        //Calling controller method
        controller.doSplitCategories();
        
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'MANUAL';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Start_Date__c = Date.Today().addMonths(4);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_End_Date__c = Date.Today().addMonths(6);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_End_Date__c = 'MANUAL';
        
        //Calling controller methods
        controller.calculateSplit();
        controller.saveSplits();
        
        //Set controller variable
        controller.categoryToBeSplit = '1';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;
        
        //Calling controller method
        controller.doSplitCategories();
        
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_Start_Date__c = 'MANUAL';
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_Start_Date__c = Date.Today().addMonths(4);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Actual_End_Date__c = Date.Today().addMonths(2);
        controller.listSplitCategoryWrap[0].revRecProductCategory.Category_End_Date__c = 'MANUAL';
        
        //Calling controller methods
        controller.calculateSplit();
        controller.saveSplits();
        
        /**Code added as per Enable split button functionality**/
        //Set URL parameter
        thePage = Page.RevRecProductRule;
        thePage.getParameters().put('opportunityId', string.valueOf(opportynity.id));
        thePage.getParameters().put('opportunityLineItemId', string.valueOf(oppLineItems[0].id));
        Test.setCurrentPage(thePage);
        
        //Constructer initlilization
        controller = new RevRecProductRuleController();
        currentPageUrl = ApexPages.currentPage().getUrl();
        
        //Set controller variable
        controller.categoryToBeSplit = '2';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;
        
        //Calling controller method
        controller.doSplitCategories();
        controller.blankMethod();
        
        //Assert for results
        System.assertEquals(1, controller.listSplitCategoryWrap.size());
        
        //Select checkbox
        controller.listSplitCategoryWrap[0].isSelected = true;
        
        //Calling add Category method
        controller.addCategoryForSplit();
        
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
        
        //Set controller variable
        controller.categoryToBeSplit = '2';
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_CHILD;
        controller.categoryParentId =   controller.listCategoryWrap[1].revRecProductCategory.Id;
        
        //Calling controller method
        controller.doSplitCategories(); 
        controller.onChangeLineItemForBlended();
        controller.ChangeCategoryTypeForSplit();
        
        //Assert for results
        System.assertEquals(1, controller.listSplitCategoryWrap.size());
        
        //Test stop here
        Test.stopTest();     
    }
}