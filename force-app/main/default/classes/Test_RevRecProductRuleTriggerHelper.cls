/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*/
@isTest(seeAllData = false)
private class Test_RevRecProductRuleTriggerHelper {
    
    @isTest
    static void myUnitTest() {
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, AppRopozSLN__Offset_Period__c = 0,
                                                              AppRopozSLN__Offset_Type__c = 'Start', Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate',
                                                              Default_Rule__c = true, Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate',
                                                              Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                              Divide_By__c = 'Period',
                                                              Period_or_Exact_Days__c = 'period',
                                                              Period__c = 'Monthly');
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Clsoed Won');
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
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id,
                                                 Quantity = 1, UnitPrice = 1000, RevRecRule__c = revRecDefaultRule.Id, ServiceDate = Date.today().addMonths(5)));
        insert oppLineItems;
        
        oppLineItems[0].Overriden_Rule_Assignment_Id__c = '';
        update oppLineItems;
        
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0',
                                                                          AppRopozSLN__Opportunity__c = opportynity.Id, AppRopozSLN__ResidualAmount__c = 100,
                                                                          AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        
        //Product override rule
        List<AppRopozSLN__RevRecProductRule__c> revRecProductRules = new  List<AppRopozSLN__RevRecProductRule__c>();
        revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addMonths(5),
                                                                     AppRopozSLN__Residual_Amount__c = 4000,
                                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                                     AppRopozSLN__Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE ,
                                                                     AppRopozSLN__Milestone_Type__c = 'amount',
                                                                     AppRopozSLN__Start_Date__c = Date.Today(),
                                                                     Divide_By__c = 'Period',
                                                                     Period_or_Exact_Days__c = 'period',
                                                                     Period__c = 'Monthly'/*,
Amortize_By__c = 'amount'*/));
        
        try {
            insert revRecProductRules;
        } catch(Exception e) {
            system.assert(false, e.getMessage());
        }
        
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
        revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c(RevRecProductRule__c=revRecProductRules[0].id, Milestone_Sequence__c = 1, 
                                                                          Milestone_Name__c = 'test1', Percent__c=20, Milestone_Date__c = Date.today().addDays(-1)))  ;    
        revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c(RevRecProductRule__c=revRecProductRules[0].id, Milestone_Sequence__c = 2, 
                                                                          Milestone_Name__c = 'test2', Percent__c=20, Milestone_Date__c = Date.today().addDays(-5)))  ;    
        revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c(RevRecProductRule__c=revRecProductRules[0].id, Milestone_Sequence__c = 3, 
                                                                          Milestone_Name__c = 'test3', Percent__c=60, Milestone_Date__c = Date.today().addDays(-7)))  ;    
        insert(revRecProductRuleMilestones);
        
        List<RevRecProductRuleMilestone__c> productRuleMileStone = [Select Id, Name From RevRecProductRuleMilestone__c
                                                                    WHERE RevRecProductRule__c = :revRecProductRules[0].id];
        
        //Update Producct Rule
        revRecProductRules[0].Start_Date__c = Date.Today().addMonths(2);
        
        //Test start here
        Test.startTest();
        
        System.assertEquals(1, revRecProductRules.size());
        system.assert(productRuleMileStone.size() > 0);
        update revRecProductRules;
        
        //Aseert for result
        productRuleMileStone = [Select Id, Name From RevRecProductRuleMilestone__c
                                WHERE RevRecProductRule__c = :revRecProductRules[0].id];
        system.assertEquals(9, productRuleMileStone.size());
        
        //Test stop here
        Test.stopTest();
    }
    
    @isTest
    static void deleteRuleTypeFromOpportunityLIneItemTest(){
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                 Time_of_Month_Selection_Types_tr__c = '1',
                                                                 Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Offset_Period__c = 0,
                                                              Offset_Type__c = 'Start', Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate',
                                                              Default_Rule__c = true, Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate',
                                                              Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                              Divide_By__c = 'Period',
                                                              Period_or_Exact_Days__c = 'period',
                                                              Period__c = 'Monthly');
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Clsoed Won');
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
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0',
                                                             Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200,RecognizedRev__c = 1000));
        insert revRecLineItems; 
        
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addMonths(5),
                                                        Residual_Amount__c = 4000,
                                                        RevRecOpportunityLineItem__c = revRecLineItems[0].Id));
        try {
            insert revRecProductRules;
        } catch(Exception e) {
            system.assert(false, e.getMessage());
        }
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id,
                                                 Quantity = 1, UnitPrice = 1000,Overriden_Rule_Assignment_Id__c = revRecProductRules[0].Id,Overridden_Rule__c = revRecProductRules[0].Name, RevRecRule__c = revRecDefaultRule.Id,RevRecOpportunityLineItem__c = revRecProductRules[0].RevRecOpportunityLineItem__c, ServiceDate = Date.today().addMonths(5)));
        insert oppLineItems;
        
        //Query Opp. Line Item
        List<OpportunityLineItem> oppLineItemInserted = [Select Id, Overridden_Rule__c,Overriden_Rule_Assignment_Id__c,RevRecOpportunityLineItem__c from OpportunityLineItem Where Id IN : oppLineItems];
        
        oppLineItemInserted[0].Overriden_Rule_Assignment_Id__c = '';
        oppLineItemInserted[0].Overridden_Rule__c = '';
        
        update oppLineItemInserted;
        
        System.assertEquals('', oppLineItemInserted[0].Overridden_Rule__c);
        
    }
    
    //This method is to test the functionality of the RevRecProductRuleMilestoneTriggerHelper....
    @isTest
    static void testRevRecProdRuleMiles() {
        
        Map<id,RevRecProductRuleMilestone__c> oldmap = new Map<id,RevRecProductRuleMilestone__c>();

        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, AppRopozSLN__Offset_Period__c = 0,
                                                              AppRopozSLN__Offset_Type__c = 'Start', Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate',
                                                              Default_Rule__c = true, Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate',
                                                              Recognition_Type__c = 'Milestone',
                                                              Divide_By__c = 'Period',
                                                              Period_or_Exact_Days__c = 'period',
                                                              Period__c = 'Monthly');
        
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Clsoed Won');
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
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id,
                                                 Quantity = 1, UnitPrice = 1000, RevRecRule__c = revRecDefaultRule.Id, ServiceDate = Date.today().addMonths(5)));
        insert oppLineItems;
        
        
        
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0',
                                                                          AppRopozSLN__Opportunity__c = opportynity.Id, AppRopozSLN__ResidualAmount__c = 100,
                                                                          AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        
        //Product override rule
        List<AppRopozSLN__RevRecProductRule__c> revRecProductRules = new  List<AppRopozSLN__RevRecProductRule__c>();
        revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addMonths(5),
                                                                     AppRopozSLN__Residual_Amount__c = 4000,
                                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                                     AppRopozSLN__Recognition_Type__c = 'Milestone' ,
                                                                     AppRopozSLN__Milestone_Type__c = 'amount',
                                                                     AppRopozSLN__Start_Date__c = Date.Today(),
                                                                     Divide_By__c = 'Period',
                                                                     Period_or_Exact_Days__c = 'period',
                                                                     Period__c = 'Monthly'));
        
        try {
            insert revRecProductRules;
        } catch(Exception e) {
            system.assert(false, e.getMessage());
        }
        
        RevRecProductRuleMilestone__c rrPRMiles = new RevRecProductRuleMilestone__c(RevRecProductRule__c=revRecProductRules[0].id, Milestone_Sequence__c = 1, 
                                                                                    Milestone_Name__c = 'testing', Actual_Amount__c =900.00, Actual_Qty__c=1, Percent__c=20, Milestone_Date__c = Date.today().addDays(-1));
        insert rrPRMiles;
        oldmap.put(rrPRMiles.id,rrPRMiles);
        
        List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
        revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c(RevRecProductRule__c=revRecProductRules[0].id, Milestone_Sequence__c = 1, 
                                                                          Milestone_Name__c = 'test1', Actual_Amount__c =100.00, Actual_Qty__c=2, Percent__c=20, Milestone_Date__c = Date.today().addDays(-1)))  ;   
        revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c(RevRecProductRule__c=revRecProductRules[0].id, Milestone_Sequence__c = 2, 
                                                                          Milestone_Name__c = 'test2', Percent__c=20, Milestone_Date__c = Date.today().addDays(-5)))  ;    
        revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c(RevRecProductRule__c=revRecProductRules[0].id, Milestone_Sequence__c = 3, 
                                                                          Milestone_Name__c = 'test3', Percent__c=60, Milestone_Date__c = Date.today().addDays(-7)))  ;    
        insert(revRecProductRuleMilestones);
        
        List<RevRecProductRuleMilestone__c> productRuleMileStone = [Select Id, Name From RevRecProductRuleMilestone__c
                                                                    WHERE RevRecProductRule__c = :revRecProductRules[0].id];
        
        //Update Producct Rule
        revRecProductRules[0].Start_Date__c = Date.Today().addMonths(2);
        
        
        
        System.assertEquals(1, revRecProductRules.size());
        system.assert(productRuleMileStone.size() > 0);
        update revRecProductRules;
        
        //Test start here
        Test.startTest();
        
        //Aseert for result
        productRuleMileStone = [Select Id, Milestone_Name__c, Actual_Amount__c From RevRecProductRuleMilestone__c
                                WHERE RevRecProductRule__c = :revRecProductRules[0].id];
        productRuleMileStone[0].Actual_Amount__c = 500.00;
        update productRuleMileStone;
        Boolean isUpdateCheckBox = false;
        try{
            //Code here
            RevRecProductRuleMilestoneTriggerHelper.setOverriddenRuleManualUpdateCheckBoxValue(productRuleMileStone,oldmap);
        }catch(Exception e){
            //Handle exception here
        }
        //Test stop here
        Test.stopTest();
    }
}