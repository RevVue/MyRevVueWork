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
 *   Created Date    :   22/09/2019
 *   
 *   Revision Logs   :   V_1.0 - Created
 *                       
 **/
@IsTest(SeeAllData=false)
public class Batch_UpdateOLIWithRulFromProductTest {

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
        System.assertEquals(true, products[1].IsActive);
        
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
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, Product2Id = products[0].Id,
                                                 PricebookEntryId = pricebookEntries[0].Id, Quantity = 1, UnitPrice = 1000));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, Product2Id = products[1].Id,
                                                 PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 2000));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id, Product2Id = products[2].Id,
                                                 PricebookEntryId = pricebookEntries[2].Id, Quantity = 1, UnitPrice = 5000));
        insert oppLineItems;

        System.debug('@@@ oppLineItems' +oppLineItems);
        System.assertEquals(2000, oppLineItems[1].UnitPrice);
        
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportunities[0].Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportunities[0].Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
		
		//Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add( new RevRecProductRule__c(  End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                           Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),Offset_Period__c = 1,
                                                           Offset_Type__c = 'Start', Revenue_Recognition_Start_Date__c = 'PRODUCT:Product_Date__c',
                                                           Revenue_Recognition_End_Date__c = 'PRODUCT:Product_Date__c'));
                                                                         
        insert   revRecProductRules;
        System.assertEquals(4000, revRecProductRules[0].Residual_Amount__c);
        
        Set<Id> setProductIds = new Set<Id>{products[0].Id, products[1].Id};
        List<Product2> newProducts = new List<Product2>();
        newProducts.addAll(products);
        Map<Id, Product2> mapOldProduct = new Map<Id, Product2>();
        mapOldProduct.put(products[0].Id, products[0]);
        mapOldProduct.put(products[1].Id, products[1]);
            
        Test.startTest();
        
        System.debug('@@@ setProductIds' +setProductIds);
        //Instance of Batch_UpdateOldRuleStartAndEndDate Batch class 
        Batch_UpdateOLIWithRulFromProduct bc = new Batch_UpdateOLIWithRulFromProduct(setProductIds,newProducts,mapOldProduct);
    
        //Execute batch
        Database.ExecuteBatch(bc, 10);
        test.stopTest();
    }
}