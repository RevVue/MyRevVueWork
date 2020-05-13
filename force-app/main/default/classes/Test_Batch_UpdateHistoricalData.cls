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
private class Test_Batch_UpdateHistoricalData {
    /**
*    Description    :       This Test class check functionality batch to update historiacal External_OpportunityLineItemId__c
*  
*    Created By     :    
*
*    Created Date   :       12/19/2014
*
*    Version        :       V1.0
*
*    Revisison Log  :       V1.0 - 12/19/2014 - Created
*
*    Coverage       :       100%
**/   
    static testMethod void myUnitTest() {
        
        
        //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1', Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                              AppRopozSLN__Offset_Period__c = 2, AppRopozSLN__Offset_Type__c = 'Start', Default_Rule__c = true,
                                                              Recognition_Type__c = 'Amortize');
        
        insert  revRecDefaultRule;
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Testing' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'Existing Customer - Upgrade'));
        opportunities.add(new Opportunity(Name = 'Testing1' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'New Customer'));
        insert opportunities;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true));
        
        insert products;
        System.assertEquals(true, products[1].IsActive);
        
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0', AppRopozSLN__Opportunity__c = opportunities[0].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));
        
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test1', AppRopozSLN__Opportunity__c = opportunities[1].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));   
        
        insert  revRecLineItems; 
        System.assertEquals(2, revRecLineItems.size());                           
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 4000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 7000, isActive = true));
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[0].Id,
                                                 Quantity = 1, UnitPrice = 1000, AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id, 
                                                 RevRecRule__c = revRecDefaultRule.Id));
        
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[1].Id,
                                                 Quantity = 1, UnitPrice = 1000, AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[1].Id, 
                                                 RevRecRule__c = revRecDefaultRule.Id));
        
        insert oppLineItems;
        
        List<RevRecOpportunityLineItemSchedule__c> RevRecOpportunityLineItemSchedules = new List<RevRecOpportunityLineItemSchedule__c>();
        
        RevRecUtil util = new RevRecUtil();
        util.EvaluateRevRecScheduleForOpportunity(opportunities[0].Id);
        
        
        RevRecOpportunityLineItemSchedule__c revRecLineItem = new RevRecOpportunityLineItemSchedule__c();
        revRecLineItem.External_OpportunityLineItemId__c = 'Testing';
        revRecLineItem.OpportunityLineItemId__c = oppLineItems[0].Id; 
        revRecLineItem.RevRecOpportunityLineItem__c =revRecLineItems[0].Id;
        RevRecOpportunityLineItemSchedules.add(revRecLineItem);
        //insert revRecLineItem; 
        
        util.EvaluateRevRecScheduleForOpportunity(opportunities[1].Id);
        
        RevRecOpportunityLineItemSchedule__c revRecLineItem1 = new RevRecOpportunityLineItemSchedule__c();
        revRecLineItem1.External_OpportunityLineItemId__c = null ;
        revRecLineItem1.OpportunityLineItemId__c = oppLineItems[0].Id; 
        revRecLineItem1.RevRecOpportunityLineItem__c =revRecLineItems[0].Id;
        RevRecOpportunityLineItemSchedules.add(revRecLineItem1);
        
        if(RevRecOpportunityLineItemSchedules.size()>0){
            insert RevRecOpportunityLineItemSchedules; 
        }
        
        //Test start here
        Test.startTest();
        
        List<RevRecOpportunityLineItemSchedule__c> schedules = new List<RevRecOpportunityLineItemSchedule__c>();    
        for(RevRecOpportunityLineItemSchedule__c schdl : [SELECT Id, External_OpportunityLineItemId__c FROM RevRecOpportunityLineItemSchedule__c]){
            System.debug('blank External Id -->'+schdl);
            schdl.External_OpportunityLineItemId__c = '';
            schedules.add(schdl);
        }
        
        if(schedules.size()>0){
            update schedules;
            System.debug('schedulesFieldBlanck-->'+schedules);
        }
        
        //Batch initilization and calling batch
        Batch_UpdateHistoricalData  bc = new Batch_UpdateHistoricalData();
        Database.executeBatch(bc);
        
        //Test stop here
        Test.stopTest();
    }
}