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
 *	Description		:	This class is used to test the functionality of Batch_RunRuleAssignments.
 *
 *	Created Date	:	05/13/2016
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0 - Created
 *
 *	Coverage		:	100%
**/
@isTest(seeAllData=false)
private class Batch_RunRuleAssignmentsTest { 

    static testMethod void myUnitTest() {
    	
    	//List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
         
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //Standard Price Book Id
        Id pricebookId = Test.getStandardPricebookId();
        
        //List of opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        
        //Add opportunities into list
        opportunities.add(new Opportunity(Name = 'Test 1', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 2', CloseDate = Date.Today().addDays(2), StageName = 'Closed Won', Type = 'New Customer'));
        insert opportunities;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true,  Family='Hardware'));
        products.add(new Product2(Name = 'Test1',  IsActive = true,  Family='Software'));
        products.add(new Product2(Name = 'Test2',  IsActive = true,  Family='Hardware'));
        
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
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[2].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[2].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, 
        										 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
     	oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[3].Id, Quantity = 10, 
        										 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[3].Id, Quantity = 10, 
        										 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[5].Id, Quantity = 10, 
        										 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        
        //Insert Opp Line items
        Constants.IS_BY_PASS_LINE_ITEM_TRIGGER = true;
        insert oppLineItems;
        Constants.IS_BY_PASS_LINE_ITEM_TRIGGER = false;
        
        //Test start here 
        Test.startTest();
        
        //Executing batch
        Batch_RunRuleAssignments bc = new Batch_RunRuleAssignments(new Set<String>{opportunities[0].Id}, new Set<String>{products[0].Id}, new Set<String> {'Hardware'},
        									'NOT IN' , 'NOT IN', 'IN', Id.valueof(revRecRules[0].Id) , null); 
        Database.executeBatch(bc, 10);
        
        //Test stop here 
        Test.stopTest();
        
        //Asset for results
        oppLineItems = [Select Id , RevRecRule__c FROM OpportunityLineItem where ID IN :oppLineItems AND RevRecRule__c != null] ;
        System.assertEquals(2, oppLineItems.size());
        System.assertEquals( revRecRules[0].Id, oppLineItems[0].RevRecRule__c);
        
    }
}