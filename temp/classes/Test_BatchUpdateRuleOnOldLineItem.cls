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
  *    Description    :    This Test class check functionality Batch_UpdateRuleOnOldLineItem
  *  
  *    Created By     :    
  *
  *    Created Date   :    09/30/2014
  *
  *    Version        :    V1.0
  *
  *    Revisison Log  :    V1.0 - Created
  *
  *    Coverage       :     100%
**/   
@isTest(seeAllData = false)
private class Test_BatchUpdateRuleOnOldLineItem {
    
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
                products.add(new Product2(Name = 'Test0',  IsActive = true, AppRopozSLN__RevRecRule__c = revRecDefaultRule.Id));
                products.add(new Product2(Name = 'Test1',  IsActive = true, AppRopozSLN__RevRecRule__c = revRecDefaultRule.Id));
                products.add(new Product2(Name = 'Test2',  IsActive = true, AppRopozSLN__RevRecRule__c = revRecDefaultRule.Id));
                products.add(new Product2(Name = 'Test3',  IsActive = true, AppRopozSLN__RevRecRule__c = revRecDefaultRule.Id));
                products.add(new Product2(Name = 'Test4',  IsActive = true, AppRopozSLN__RevRecRule__c = revRecDefaultRule.Id));
                
        insert products;
        
         //Assert
        System.assertEquals(products.size() , 5);  
        
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
            revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0',
                                                                              AppRopozSLN__Opportunity__c = opportunities[0].Id,
                                                                              AppRopozSLN__ResidualAmount__c = 100,
                                                                              AppRopozSLN__DeferredRev__c = 1200,
                                                                              AppRopozSLN__RecognizedRev__c = 1000));
                                                                              
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
            
            oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id,
                                                     PricebookEntryId = pricebookEntries[2].Id,
                                                     Quantity = 1,
                                                     UnitPrice = 1000 ,Product2Id = products[0].Id ));                         
        insert oppLineItems;
        List<OpportunityLineItem> queryOLI = [SELECT Id, RevRecRule__c, product2.RevRecRule__c FROM OpportunityLineItem Where Id =: oppLineItems[0].id];
        queryOLI[0].RevRecRule__c = null;
        update queryOLI;
        System.assertEquals(null,queryOLI[0].RevRecRule__c);
        
        
        //Test starts here
        Test.startTest();
        
        Batch_UpdateRuleOnOldLineItem bc = new Batch_UpdateRuleOnOldLineItem();
        Database.executeBatch(bc, 10);
        
        //Test stop here
        Test.stopTest();                
     }

}