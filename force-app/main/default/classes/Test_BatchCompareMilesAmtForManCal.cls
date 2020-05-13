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
/**
  *    Description    :    This Test class check functionality Batch_CompareMilesAmountForManualCal
  *  
  *    Created By     :    
  *
  *    Created Date   :    04/30/2020
  *
  *    Version        :    V1.0
  *
  *    Revisison Log  :    V1.0 - Created
  *
  *    Coverage       :     100%
**/   
@isTest(seeAllData = false)
private class Test_BatchCompareMilesAmtForManCal {
    static testMethod void myUnitTest() {
        
        //Dummy test data 
        
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', 
                                                                                           Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', 
                                                                    AppRopozSLN__Offset_Period__c = 2,Period_or_Exact_Days__c = 'period',
                                                                    AppRopozSLN__Offset_Type__c = 'Start',
                                                                    Default_Rule__c = true,Period__c = 'Monthly',
                                                                    Recognition_Type__c = 'Amortize');
                                                                    
        insert  revRecDefaultRule;
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
            opportunities.add(new Opportunity(Name = 'Testing' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'New Customer', REVvue_ExecMassCalc__c = true));
            opportunities.add(new Opportunity(Name = 'Testing1' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_ExecMassCalc__c = false));
            opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_ExecMassCalc__c = true));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_ExecMassCalc__c = true));
            
            insert opportunities;
            
        //Assert
        System.assertEquals(opportunities.size() , 5); 
        
        Set<Id> opportunityIds = new Set<Id>();
        opportunityIds.add(opportunities[0].Id);
        opportunityIds.add(opportunities[1].Id);
        opportunityIds.add(opportunities[2].Id);
        
         //Job Record
        AppRopozSLN__RevRecJob__c recJob = new AppRopozSLN__RevRecJob__c(AppRopozSLN__OpportunityID__c = string.valueOf(opportunities[1].Id), AppRopozSLN__description__c = 'Test');                                                
        insert recJob;

        //List of Product
        List<Product2> products = new List<Product2>();
                products.add(new Product2(Name = 'Test0',  IsActive = true));
                products.add(new Product2(Name = 'Test1',  IsActive = true));
                products.add(new Product2(Name = 'Test2',  IsActive = true));
                products.add(new Product2(Name = 'Test3',  IsActive = true));
                products.add(new Product2(Name = 'Test4',  IsActive = true));
                
        insert products;
        
         //Assert
        System.assertEquals(products.size() , 5);  
        
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
            revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0',
                                                                              AppRopozSLN__Opportunity__c = opportunities[0].Id,
                                                                              AppRopozSLN__ResidualAmount__c = 100,
                                                                              AppRopozSLN__DeferredRev__c = 1200,
                                                                              AppRopozSLN__RecognizedRev__c = 1000, AppRopozSLN__TotalRev__c = null));
                                                                              
            revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test1',
                                                                              AppRopozSLN__Opportunity__c = opportunities[1].Id,
                                                                              AppRopozSLN__ResidualAmount__c = 100,
                                                                              AppRopozSLN__DeferredRev__c = 1200,
                                                                              AppRopozSLN__RecognizedRev__c = 1000));   
            
            revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test2',
                                                                              AppRopozSLN__Opportunity__c = opportunities[2].Id,
                                                                              AppRopozSLN__ResidualAmount__c = 100,
                                                                              AppRopozSLN__DeferredRev__c = 1200,
                                                                              AppRopozSLN__RecognizedRev__c = 1000));
                                                                              
            revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test3',
                                                                              AppRopozSLN__Opportunity__c = opportunities[3].Id,
                                                                              AppRopozSLN__ResidualAmount__c = 100,
                                                                              AppRopozSLN__DeferredRev__c = 1200,
                                                                              AppRopozSLN__RecognizedRev__c = 1000));
                                                                              
            revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test4',
                                                                              AppRopozSLN__Opportunity__c = opportunities[4].Id,
                                                                              AppRopozSLN__ResidualAmount__c = 100,
                                                                              AppRopozSLN__DeferredRev__c = 1200,
                                                                              AppRopozSLN__RecognizedRev__c = 1000));                                                                                                                                                                                                                                                                                                                                                     
        insert revRecLineItems;
        
        //Assert
        System.assertEquals(revRecLineItems.size() , 5);   
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[2].Id, UnitPrice = 500, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[3].Id, UnitPrice = 800, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[4].Id, UnitPrice = 20000, isActive = true));
        //Insert  pricebookEntries
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
            oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, 
                                                     PricebookEntryId = pricebookEntries[0].Id,
                                                     Quantity = 1, 
                                                     UnitPrice = 1000,
                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id, 
                                                     RevRecRule__c = revRecDefaultRule.Id));
                                                     
            oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, 
                                                     PricebookEntryId = pricebookEntries[1].Id,
                                                     Quantity = 1,
                                                     UnitPrice = 1000,
                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[1].Id, 
                                                     RevRecRule__c = revRecDefaultRule.Id));
                                                      
            oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id,
                                                     PricebookEntryId = pricebookEntries[2].Id,
                                                     Quantity = 1,
                                                     UnitPrice = 1000,
                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[2].Id, 
                                                     RevRecRule__c = revRecDefaultRule.Id));                         
        insert oppLineItems;
               
        //Product override rule
        List<AppRopozSLN__RevRecProductRule__c> revRecProductRules = new  List<AppRopozSLN__RevRecProductRule__c>();
            revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addMonths(1),
                                                                         AppRopozSLN__Residual_Amount__c = 3000,
                                                                         AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                                         AppRopozSLN__Recognition_Type__c = 'Single Transaction'));
                                                                         
            revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addDays(10),
                                                                         AppRopozSLN__Residual_Amount__c = 3000,
                                                                         AppRopozSLN__Initial_Amount_Type__c = 'Percent',
                                                                         AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[1].Id,
                                                                         AppRopozSLN__Recognition_Type__c = 'Amortized Milestone',
                                                                         AppRopozSLN__offset_type__c = 'Period',
                                                                         AppRopozSLN__Offset_Period__c = 2,
                                                                         AppRopozSLN__Start_Date__c = Date.Today().addDays(4)));                                                             
                                                                         
            revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addMonths(5),
                                                                         AppRopozSLN__Residual_Amount__c = 4000,
                                                                         AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[2].Id,
                                                                         AppRopozSLN__Recognition_Type__c = 'Milestone' ,
                                                                         AppRopozSLN__Milestone_Type__c = 'amount'));
                                                                         //AppRopozSLN__Start_Date__c = Date.Today().addMonths(1)));
                                                                         
        insert  revRecProductRules;
        
        
        //Assert
        System.assertEquals(revRecProductRules.size() , 3);    
        
        //Insert MileStone
        List<AppRopozSLN__RevRecProductRuleMilestone__c> listMileStone = new List<AppRopozSLN__RevRecProductRuleMilestone__c>();
        listMileStone.add(new AppRopozSLN__RevRecProductRuleMilestone__c(AppRopozSLN__Milestone_Date__c = Date.Today(),
                                                                               AppRopozSLN__Milestone_Name__c = 'Test',
                                                                               AppRopozSLN__Milestone_Sequence__c = 1,
                                                                         	   AppRopozSLN__Actual_Amount__c = 1000,
                                                                               AppRopozSLN__RevRecProductRule__c = revRecProductRules[1].Id,
                                                                               AppRopozSLN__Amount__c = 1000,
                                                                               AppRopozSLN__Percent__c = 10));
              
        insert listMileStone ;
        
        //Test starts here
        Test.startTest();
        
        Batch_CompareMilesAmountForManualCal bc = new Batch_CompareMilesAmountForManualCal();
        Database.executeBatch(bc, 10);
        
        //Test stop here
        Test.stopTest();                
                                     
        //Assert for results
        //Query through RevRec Line Itemss
        revRecLineItems = [Select Id, AppRopozSLN__ResidualAmount__c From AppRopozSLN__RevRecOpportunityLineItem__c WHERE ID IN: revRecLineItems];  
        
        //Assert for results : After calculation   
        System.assertEquals(revRecLineItems[0].AppRopozSLN__ResidualAmount__c, 100);
        System.assertEquals(revRecLineItems[1].AppRopozSLN__ResidualAmount__c, 100);
        System.assertEquals(revRecLineItems[2].AppRopozSLN__ResidualAmount__c, 100);   
        
        //Query thriugh RevRec Line item schedule
        List<AppRopozSLN__RevRecOpportunityLineItemSchedule__c>  listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                                                 AppRopozSLN__RecognizedRev__c,
                                                                                                 AppRopozSLN__RecognizedRevTotal__c, 
                                                                                                 AppRopozSLN__ResidualAmountTotal__c,
                                                                                                 AppRopozSLN__OriginalDate__c,
                                                                                                 AppRopozSLN__DeferredRev__c FROM
                                                                                                 AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                            WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
        
        //Assert for results
        system.assertEquals(listRevRecLineItemSch.size(), 0);
        
        listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                    AppRopozSLN__RecognizedRev__c,
                                                                    AppRopozSLN__RecognizedRevTotal__c, 
                                                                    AppRopozSLN__ResidualAmountTotal__c,
                                                                    AppRopozSLN__OriginalDate__c,
                                                                    AppRopozSLN__DeferredRev__c FROM
                                                                    AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                    WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[1].Id];
        
        //Assert for results
      //system.assertEquals(listRevRecLineItemSch.size(), 3);
        
       listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                    AppRopozSLN__RecognizedRev__c,
                                                                    AppRopozSLN__RecognizedRevTotal__c, 
                                                                    AppRopozSLN__ResidualAmountTotal__c,
                                                                    AppRopozSLN__OriginalDate__c,
                                                                    AppRopozSLN__DeferredRev__c FROM
                                                                    AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                    WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[2].Id];
                                                                    
        //Assert for results
        //System.assertEquals(listRevRecLineItemSch.size(), 13);
        
    }
}