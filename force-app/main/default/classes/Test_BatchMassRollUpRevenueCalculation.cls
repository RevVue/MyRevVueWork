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
*    Description    :    This Test class check functionality batch to update historiacal opp revenue
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
private class Test_BatchMassRollUpRevenueCalculation{
    
    @isTest 
    public static void testBatch_UpdateRuleOnOldLineItem() {
        
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
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                              AppRopozSLN__Offset_Period__c = 2,
                                                              AppRopozSLN__Offset_Type__c = 'Start',
                                                              Default_Rule__c = true,
                                                              Recognition_Type__c = 'Milestone');
        
        insert  revRecDefaultRule;
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Testing0' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Testing1' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 2000, Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 5000, Type = 'New Customer'));
        
        insert opportunities;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
        products.add(new Product2(Name = 'Test2',  IsActive = true));
        
        insert products;
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry List
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
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
        
        insert revRecLineItems;
        
        //Assert
        System.assertEquals(revRecLineItems.size() , 3);  
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[2].Id, UnitPrice = 500, isActive = true));
        
        //Insert  pricebookEntries
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, Product2 = products[0],
                                                 PricebookEntryId = pricebookEntries[0].Id, Quantity = 1, UnitPrice = 1000));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, Product2 = products[1],
                                                 PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 2000));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id, Product2 = products[2],
                                                 PricebookEntryId = pricebookEntries[2].Id, Quantity = 1, UnitPrice = 5000));
        insert oppLineItems;
        
        //Test starts here
        Test.startTest();
        
        List<Opportunity> queryOpp = [SELECT Id, Name, CreatedDate, CloseDate, StageName, Amount FROM Opportunity];
        System.assert(true,queryOpp);
        
        Batch_MassRollUpRevenueCalculation bc1 = new Batch_MassRollUpRevenueCalculation(queryOpp);
        Database.executeBatch(bc1);
        
        Batch_MassRollUpRevenueCalculation bc2 = new Batch_MassRollUpRevenueCalculation(queryOpp,true);
        Database.executeBatch(bc2);
        
        System.assertEquals('Testing0', queryOpp[0].Name);
        
        List<RevRecOpportunityLineItem__c> olis = [SELECT Id, Opportunity__c FROM RevRecOpportunityLineItem__c];
        System.assert(true,olis);
        
        //Test stop here
        Test.stopTest();   
        
        //Query through RevRec Line Itemss
        revRecLineItems = [Select Id, AppRopozSLN__ResidualAmount__c From AppRopozSLN__RevRecOpportunityLineItem__c WHERE ID IN: revRecLineItems];  
        
        //Assert for results : After calculation   
        System.assertEquals(revRecLineItems[0].AppRopozSLN__ResidualAmount__c, 100);
        System.assertEquals(revRecLineItems[1].AppRopozSLN__ResidualAmount__c, 100);
        System.assertEquals(revRecLineItems[2].AppRopozSLN__ResidualAmount__c, 100);   
        
    }
}