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
 *   Purpose         :   This test class is used to test all functionality of Batch
 *               
 *   Created By      :   
 *   
 *   Created Date    :   30/01/2019
 *   
 *   Revision Logs   :   V_1.0 - Created
 *                       
 **/
@IsTest(SeeAllData=false)
public class Test_Batch_UpdateRuleOnOLIWithBlank {

    /**
	 * This method is used to test batch class
	 **/
    @isTest 
    public static void validateAll() {
        
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();   
        
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', 
                                                                                           Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        //List to store the RevRecRules....
        List<RevRecRules__c> revRecRulesList = new List<RevRecRules__c>();
        
	    revRecRulesList.add(new RevRecRules__c(Name = 'Test', Active__c = true, Recognition_Type__c = 'Single Transaction'));
        revRecRulesList.add(new RevRecRules__c(Name = 'Test1', Active__c = true, Recognition_Type__c = 'Amortize Milestone'));
        revRecRulesList.add(new RevRecRules__c(Name = 'Test2', Active__c = true, Recognition_Type__c = 'Milestone'));
        
        if(revRecRulesList.size()>0){
        insert revRecRulesList;
        }
        
        System.debug('InsertedRevRecRules...###'+revRecRulesList);
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Testing0' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'Existing Customer - Upgrade'));
        opportunities.add(new Opportunity(Name = 'Testing1' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 2000, Type = 'Existing Customer - Upgrade'));
        opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 5000, Type = 'Existing Customer - Upgrade'));
        
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
        
        //PriceBookEntry List
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[2].Id, UnitPrice = 500, isActive = true));
        
        //Insert  pricebookEntries
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, Product2Id = products[2].Id,
                                                 PricebookEntryId = pricebookEntries[0].Id, Quantity = 1, UnitPrice = 1000,RevRecRule__c = revRecRulesList[0].Id));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, Product2Id = products[1].Id,
                                                 PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 2000,RevRecRule__c = revRecRulesList[1].Id));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id, Product2Id = products[2].Id,
                                                 PricebookEntryId = pricebookEntries[2].Id,Quantity = 1, UnitPrice = 5000,RevRecRule__c = revRecRulesList[2].Id));
        insert oppLineItems;
        
       //Test starts here...
        Test.startTest();
        
        List<OpportunityLineItem> oppLineItemsList = [SELECT Id, RevRecRule__c FROM OpportunityLineItem WHERE Id IN : oppLineItems ];
        System.debug('oppLineItemsList...###'+oppLineItemsList);
        
        List<RevRecRules__c> listOfRevRecRule  = [SELECT Id, Name FROM RevRecRules__c where Id =: oppLineItems[0].RevRecRule__c];
        delete listOfRevRecRule;
        System.assertEquals(1,listOfRevRecRule.size());
        
        List<RevRecRules__c> listOfRevRecRuleAfterDeletion = [SELECT Id, Name FROM RevRecRules__c];
        System.debug('UpdatedRevRecRules...###'+listOfRevRecRuleAfterDeletion);
        
        System.assertEquals('Test',listOfRevRecRule[0].Name);
        System.assertNotEquals('Test',listOfRevRecRuleAfterDeletion[0].Name);
        System.assertNotEquals('Test',listOfRevRecRuleAfterDeletion[1].Name);
        
        
        //Instance of Batch_UpdateOldRuleStartAndEndDate Batch class 
        Batch_UpdateRuleOnOLIWithBlank bc = new Batch_UpdateRuleOnOLIWithBlank();
        //Execute batch
        Database.ExecuteBatch(bc);
        
        //stop test
        test.stopTest();
        
        //System.assertEquals(null,oppLineItemsList[0].Id);
    }
}