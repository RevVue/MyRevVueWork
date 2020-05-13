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
@isTest(seeAllData=false)
private class Test_Batch_UpdateHistoricalProductMiles {
/**
  *    Description    :		This Test class check functionality batch to update historiacal Milestone_date_source__c
  *  
  *    Created By     :  	
  *
  *    Created Date   :		01/20/2015
  *
  *    Version        :		V1.0
  *
  *    Revisison Log  :		V1.0 - 01/20/2015 - Created
  *
  *    Coverage       :		100%
**/
	
	//Method to test functionality of Batch_UpdateHistoricalProductMilestones
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
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                                    AppRopozSLN__Offset_Period__c = 2,
                                                                    AppRopozSLN__Offset_Type__c = 'Start',
                                                                    Default_Rule__c = true,
                                                                    Recognition_Type__c = 'Milestone');
                                                                    
        insert  revRecDefaultRule;
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Testing' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'New Customer'));
        
        insert opportunities;
     
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true));
        products.add(new Product2(Name = 'Test2',  IsActive = true));
       
        insert products;
        
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
         List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[2].Id, UnitPrice = 500, isActive = true));
        
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 3000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[2].Id, UnitPrice = 600, isActive = true));
        
        //Insert  pricebookEntries
        insert pricebookEntries;
      
       //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, 
                  PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000));
         
         insert oppLineItems;
         
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0',
                     AppRopozSLN__Opportunity__c = opportunities[0].Id, AppRopozSLN__ResidualAmount__c = 100,
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
                                                                         AppRopozSLN__Milestone_Type__c = 'Amount'));
                                                                                                                                                   
        insert  revRecProductRules;
       
        
        //Insert MileStone
        List<AppRopozSLN__RevRecProductRuleMilestone__c> listMileStone = new List<AppRopozSLN__RevRecProductRuleMilestone__c>();
        listMileStone.add(new AppRopozSLN__RevRecProductRuleMilestone__c(AppRopozSLN__Milestone_Date__c = Date.Today(),
                                                                               AppRopozSLN__Milestone_Name__c = 'Test',
                                                                               AppRopozSLN__Milestone_Sequence__c = 1,
                                                                               AppRopozSLN__RevRecProductRule__c = revRecProductRules[0].Id,
                                                                               AppRopozSLN__Amount__c = 1000,
                                                                               AppRopozSLN__Percent__c = 10));
                                                                               
        listMileStone.add(new AppRopozSLN__RevRecProductRuleMilestone__c(AppRopozSLN__Milestone_Date__c = Date.Today(),
                                                                               AppRopozSLN__Milestone_Name__c = 'Test',
                                                                               AppRopozSLN__Milestone_Sequence__c = 1,
                                                                               AppRopozSLN__RevRecProductRule__c = revRecProductRules[0].Id,
                                                                               AppRopozSLN__Amount__c = 1000,
                                                                               AppRopozSLN__Percent__c = 10));
                
        insert listMileStone ;
        
        //Test starts here
        Test.startTest();
        
        Batch_UpdateHistoricalProductMilestones bc = new Batch_UpdateHistoricalProductMilestones();
        Database.executeBatch(bc, 10);
        
        //Test stop here
        Test.stopTest();
        
        //Assert for results
        listMileStone = [Select Milestone_Date_Source__c From RevRecProductRuleMilestone__c WHERE ID IN: listMileStone];      
        system.assertEquals(constants.MILESTONE_DATE_MANUAL , listMileStone[0].Milestone_Date_Source__c);
        system.assertEquals(constants.MILESTONE_DATE_MANUAL , listMileStone[1].Milestone_Date_Source__c);                  
    }
}