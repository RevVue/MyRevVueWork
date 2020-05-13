@isTest(SeeAllData=false)
private class TestRevRecRuleController {
/**
 *	Description		:	Test class for RevRecRuleController.
 *
 *	Created By		:	Terry Lydon 
 *
 *	Created Date	:	07/11/2012 
 *
 *	Version			:	V_1.2
 *
 *	Revision Log	:	V_1.0 - Craeted - 07/11/2012 
 *						V_1.1 - Modified as per Blended revenue calcultion - 07/06/2015.
 *						V_1.2 - Modified as per Blended revenue split calcultion - 16/05/2016.
 *
 *	Coverage		:	84%
 *
**/
    static testMethod void testConstructor() {
    	
    	RevRecRules__c rule = new RevRecRules__c(Revenue_Recognition_End_Date__c='OPPORTUNITY PRODUCT:ServiceDate', initial_amount_type__c='Amount',    
            Offset_Period__c=1, Offset_Type__c='Period', Active__c=true, Residual_Amount_Type__c='Amount', initial_amount__c=1000.00,
            Name='Rule test', Recognition_Type__c='Amortize', Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate', Period__c='Monthly', 
            Period_or_Exact_Days__c='exact', Default_Rule__c=false, residual_Amount__c=1.00, Description__c='Descr', Divide_By__c='Prorate'); 
        insert rule;
        
        Pagereference thePage = Page.RevRecRule;
        Test.setCurrentPage(thePage);
        
        ApexPages.CurrentPage().getParameters().put('editRuleId', rule.Id);
        
        // Verify that AppSetting record is not null
        RevRecRuleController theController = new RevRecRuleController();
        System.assert(theController.getRevRecRules() != null);
        //System.assert(theController.getShowDetail() == false);      
    }
   
    static testMethod void testControllerActions() {
    	
        Pagereference thePage = Page.RevRecRule;
        Test.setCurrentPage(thePage);
         
        //Test start  here
        Test.startTest();
        
        RevRecRuleController theController = new RevRecRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();
        
        System.assertNotEquals(theController.getRecord(), null);
        
        List<RevRecRuleWrapper> RevRecRules = theController.getRevRecRules();
        RevRecRules__c rule = null;
        if (RevRecRules.size() != 0) {
            string id = RevRecRules[0].rule.Id;
            ApexPages.currentPage().getParameters().put('id', id);
            rule = theController.getRecord();
            
            System.assertEquals(theController.edit(), null);
            rule.Recognition_Type__c = 'Amortize';
            System.assertEquals(theController.ChangeRecognitionTypeOptions(), null);
        } else {
            System.assertEquals(theController.create(), null);  
            rule = theController.getRecord();
            System.assertEquals(rule.Recognition_Type__c, 'Single Transaction');            
        }
        
        theController.getRRPRRecord();
        theController.getAmortizeByOptions();
        theController.getMilestoneOptions();
        theController.ChangeMilestoneType();
        System.assertNotEquals(theController.getStartDateSelectOptions(), null);
        System.assertNotEquals(theController.getEndDateSelectOptions(), null);
        System.assertNotEquals(theController.getRecognitionTypeOptions(), null);
        System.assertNotEquals(theController.getDividedByOptions(), null);
        System.assertNotEquals(theController.getPeriodExactOptions(), null);

        System.assertEquals(theController.save(), null);    
        System.assertEquals(theController.cancel(), null);                      
        
        System.assertEquals(theController.create(), null);
        rule = theController.getRecord();
        System.assertEquals(rule.id, null);
        theController.save();
        theController.ChangeRecognitionTypeOptions();
        System.assertNotEquals(rule.id, null);
        System.assertEquals(theController.getShowSingleTransDetail(), true);
        
        theController.rule.Recognition_Type__c = 'Amortize';
        rule.Period__c = 'monthly';
        theController.ChangeRecognitionTypeOptions();
        
        //Code added as per to test EXACT days by percentage functionlaity
       // theController.onChangeExactDaysOptions();
        theController.rule.Divide_By__c = 'prorate';
        theController.onChangeDivideByOption();
        theController.rule.Divide_By__c = 'non prorate';
        theController.onChangeDivideByOption();
        
        System.assertEquals(theController.getShowAmortizeDetail(), true);
        System.assertEquals(theController.getShowDevideEvenlyDetail(), true);
        System.assertEquals(theController.getShowByPeriodOrExactDetail(), true);
        
        theController.rule.Period__c = 'weekly';
        theController.ChangeRecognitionPeriod();
        System.assertEquals(theController.getshowOffsetDetail() , true);
		
		theController.rule.Period__c = 'daily';  
        theController.ChangeRecognitionPeriod();
        System.assertEquals(theController.getshowOffsetDetail() , true);
		
        theController.rule.Period__c = 'quartly';
        theController.ChangeRecognitionPeriod();
        System.assertEquals(theController.getShowAmortizeDetail() , true);

        theController.rule.Period__c = 'yearly';
        theController.ChangeRecognitionPeriod();
        System.assertEquals(theController.getShowAmortizeDetail() , true);

        theController.rule.Recognition_Type__c = 'Milestone';
        
        thecontroller.overrideRule.Milestone_Type__c = 'amount';
        theController.getMilestoneTotal();
        
        thecontroller.overrideRule.Milestone_Type__c = 'qty';
        theController.getMilestoneTotal();
        
        thecontroller.overrideRule.Milestone_Type__c = 'ww';
        theController.getMilestoneTotal();
        
        theController.save();
        theController.ChangeRecognitionTypeOptions();
        System.assertEquals(theController.getShowMilestoneDetail() , true);
        theController.addMilestone();
        List<RevRecRuleMilestone__c> ruleMilestones = theController.getRevRecRulesMilestones();
        ruleMilestones[0].Percent__c = 50;
        theController.addMilestone();
        ruleMilestones[1].Percent__c = 50;        
        theController.removeMilestone();
        System.assertEquals(theController.deleteRule() , null);
        theController.saveMilesOnBlur();
       
        //Code added - 01/20/2015 - As per Milestone Date Source Requirement
        System.assertNotEquals(theController.getStartAndEndDateOptions(), null);
         
        //Code added - 11/8/2014 - As per Amortized Milestone Rule Requirements
        rule.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE;
        theController.ChangeRecognitionTypeOptions();
        System.assertEquals(theController.getShowAmortizedMilestoneDetail() , true);
        
        rule.Period__c = 'monthly';
        theController.ChangeRecognitionTypeOptions(); 
        System.assertEquals(theController.getShowDevideEvenlyDetail(), true);
        System.assertEquals(theController.getShowByPeriodOrExactDetail(), true);
        
        /******* ~~~~~~~~~~ Code added - 07/06/2015 - As per blended revenue recognition ~~~~~~~~~~~~ ******/
        /** ** ** START ** ** **/
       
        //Calling getter list of controller
        theController.getBlendedOptions();	
        theController.getShowBlendedRevenueDetail();
        theController.getEndDateSelectOptions();
        theController.getEndDateSelectOptions();
        rule.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE;
        theController.ChangeRecognitionTypeOptions();
      
        //Calling add method to add category
        theController.addCategory();
        
        //Creating categoryy record from instance
        theController.listCategoryWrap[0].category1.Name = 'Test - 1';
        theController.listCategoryWrap[0].category1.Category_Type__c = 'Percent';
        theController.listCategoryWrap[0].category1.Percent__c = 10;
        theController.listCategoryWrap[0].category1.Line_Item__c = '0';
        theController.listCategoryWrap[0].category1.Category_Start_Date__c = 'Opportunity:Close Date';
        theController.listCategoryWrap[0].category1.Category_End_Date__c = 'None';
        
        //Calling add method to add category
        theController.listCategoryWrap[0].isSelected = true;
        theController.addCategory();
        
        theController.listCategoryWrap[1].category1.Name = 'Test - 2';
        theController.listCategoryWrap[1].category1.Category_Type__c = 'Amount';
        theController.listCategoryWrap[1].category1.Amount__c = 1000;
        theController.listCategoryWrap[1].category1.Line_Item__c = '1';
        theController.listCategoryWrap[1].category1.Category_Start_Date__c = 'Opportunity:Close Date';
        theController.listCategoryWrap[1].category1.Category_End_Date__c = 'Product:Date';
        
        //Calling add method to add category
        theController.listCategoryWrap[1].isSelected = true;
        theController.addCategory();
        
        
        //Assert for results
        System.assertEquals(3, theController.listCategoryWrap[2].category1.Sequence__c);
        
        theController.addCategory();
        theController.removeCategory();
               
        theController.listCategoryWrap[2].category1.Name = 'Test - 3';
        theController.listCategoryWrap[2].category1.Category_Type__c = 'Qty';
        theController.listCategoryWrap[2].category1.Amount__c = 1;
        theController.listCategoryWrap[2].category1.Line_Item__c = '1';
        theController.listCategoryWrap[2].category1.Category_Start_Date__c = 'Opportunity:Close Date';
        theController.listCategoryWrap[2].category1.Category_End_Date__c = 'Product:Date';
        
        //Calling save method
        theController.save();
        
        //Query through Rule Category 
        List<RevRecRuleCategory__c> ruleCategories = [SELECT id , Recognition_Type__c From RevRecRuleCategory__c 
        												WHERE RevRecRule__c =: rule.Id ORDER BY Sequence__c];
        
        //Assert for results
        System.assertEquals(3, ruleCategories.size());
        System.assertEquals(constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, ruleCategories[0].Recognition_Type__c);
        System.assertEquals(constants.RULE_RECOGNITION_TYPE_AMORTIZE, ruleCategories[1].Recognition_Type__c);
        System.assertEquals(constants.RULE_RECOGNITION_TYPE_AMORTIZE, ruleCategories[2].Recognition_Type__c);
        
        //Remove category
        theController.listCategoryWrap[0].isSelected = false;
        theController.listCategoryWrap[1].isSelected = true;
        theController.listCategoryWrap[2].isSelected = false;
        theController.removeCategory();
        
        //Assert for results
        System.assertEquals(2,  theController.listCategoryWrap.size());
        
        //Save
        theController.save(); 
        
        //Query to get product categories
        ruleCategories = [SELECT id , Recognition_Type__c,Sequence__c From RevRecRuleCategory__c WHERE RevRecRule__c =: rule.Id ORDER BY Sequence__c];
        
        //Assert for results
        System.assertEquals(2, ruleCategories.size());
        System.assertEquals(constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, ruleCategories[0].Recognition_Type__c);
        System.assertEquals(constants.RULE_RECOGNITION_TYPE_AMORTIZE, ruleCategories[1].Recognition_Type__c);
        System.assertEquals(1, ruleCategories[0].Sequence__c);
        System.assertEquals(2, ruleCategories[1].Sequence__c);
        
        //Controller methods
        theController.edit();
        //theController.ChangeCategoryType();
        theController.toggleShowHideInActive();
        theController.toggleStartStopCronJob();
         
        //Test stops here
        Test.stopTest(); 
       /** ** ** END ** ** **/
    }
    
    /**
     *	@description	:	This method is used to test the functionality of "Allocate" button added on Blende Rule Screen to create templates
     *						for blended rules.
     **/
     static testMethod void testAllocationFunctionality() {
     	
     	//Test start  here
        Test.startTest();
        
     	//Pagereferecne
     	Pagereference thePage = Page.RevRecRule;
        Test.setCurrentPage(thePage);
        
     	//Controller initilization
     	RevRecRuleController controller = new RevRecRuleController();
        String currentPageUrl = ApexPages.currentPage().getUrl();        
        List<RevRecRuleWrapper> RevRecRules = controller.getRevRecRules();
        //string id = RevRecRules[0].rule.Id;
        //ApexPages.currentPage().getParameters().put('id', id);
        RevRecRules__c rule = controller.getRecord();
     	
     	//Calling getter list of controller
        controller.getBlendedOptions();	
        controller.getShowBlendedRevenueDetail();
        controller.getEndDateSelectOptions();
        controller.getEndDateSelectOptions();
        rule.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE;
        controller.ChangeRecognitionTypeOptions();
      
        //Calling add method to add category
        controller.addCategory();
        
        //Creating categoryy record from instance
        controller.listCategoryWrap[0].category1.Name = 'Test - 1';
        controller.listCategoryWrap[0].category1.Category_Type__c = 'Percent';
        controller.listCategoryWrap[0].category1.Percent__c = 10;
        controller.listCategoryWrap[0].category1.Line_Item__c = '0';
        controller.listCategoryWrap[0].category1.Category_Start_Date__c = 'Opportunity:Close Date';
        controller.listCategoryWrap[0].category1.Category_End_Date__c = 'None';
        
        //Split categories
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;
        controller.categoryToBeSplit = '1';
        controller.doSplitCategories();
        
        //Assert for results
        System.assertEquals(1, controller.listSplitCategoryWrap.size());
        
        //Add after 1st row
        controller.listSplitCategoryWrap[0].isSelected = true;
        controller.addCategoryForSplit();
        
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
        
        //Remove 2nd row
        controller.listSplitCategoryWrap[1].isSelected = true;
        controller.removeCategoryForSplit();
        
        //Assert for results
        System.assertEquals(1, controller.listSplitCategoryWrap.size());
        
        //Add and remove at the end
        controller.addCategoryForSplit();
        controller.removeCategoryForSplit();
        controller.addCategoryForSplit();
       
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
                
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_CHILD;
        controller.categoryToBeSplit = '1';
        controller.categoryParentId = controller.listSplitCategoryWrap[0].category1.RevRecRuleSplitCategory__c;
        controller.doSplitCategories();
        
        //Assert for results
        System.assertEquals(1, controller.listSplitCategoryWrap.size());
                
        //Cancel
        controller.saveSplits();
        
        //Split categories
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_PARENT;
        controller.categoryToBeSplit = '1';
        controller.doSplitCategories();
        
        controller.typeOfCategoryScreen = constants.SPLIT_SCREEN_TYPE_CHILD;
        controller.categoryToBeSplit = '1';
        controller.categoryParentId = controller.listSplitCategoryWrap[0].category1.RevRecRuleSplitCategory__c;
        controller.doSplitCategories();
        controller.addCategoryForSplit();
        
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
        
         //Cancel
        controller.saveSplits();
        
        //Assert for results
        System.assertEquals(2, controller.listSplitCategoryWrap.size());
        
        //Cancel
        controller.cancel();
        controller.init();
        
        controller.save();
                
        //list of rules
        RevRecRules = controller.getRevRecRules();
        String id = RevRecRules[0].rule.Id;
        ApexPages.currentPage().getParameters().put('id', id);
        rule = controller.getRecord();
        
        //Re-initilize controller
        controller = new RevRecRuleController();
        controller.inIt();
        
        controller.defaults();
         
         RevRecRuleWrapper wrap = new RevRecRuleWrapper();
         wrap.categoryValueTypes = new List<String>{'test','testing'};
             wrap.revenueRecogStartDates = new List<String>{'System.today()'};
             wrap.revenueRecogEndDates = new List<String>{'System.today.addDays(2)'};
        //Test stops here
        Test.stopTest();
     }
}