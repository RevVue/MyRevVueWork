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
public class Batch_PopulateRuleOnLineItemsTest {
/**
 *  Purpose              :   Test class for Batch_CreateChecklistTasksForOpportunites batch.
 * 
 *  Created by           :   Bill Feeheley
 * 
 *  Created Date         :   04/20/2016
 * 
 *  Version              :   V_1.0
 *
 *  Revision Log         :   V_1.0 - Created
 * 
 *  Code Coverage        :   20%
**/
    
    /** 
     *  Description  :   
    **/
    static testMethod void testCase1() {
        
       //Get standard pricbook Id to insert new price booke entery
       Id pricebookId = Test.getStandardPricebookId();   
       
       //Test RevRecRule data
       List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
       revRecRules.add(new RevRecRules__c(initial_amount_type__c='Amount', 
                                          Revenue_Recognition_End_Date__c='PRODUCT:ServiceDate', 
                                          Offset_Period__c=1, Offset_Type__c='Period',
            							  Active__c=true, Residual_Amount_Type__c='Amount', 
            							  Period__c='Monthly', Name='Rule test',
            							  Recognition_Type__c='Amortize', 
                                          Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate', 
            							  Period_or_Exact_Days__c='exact',
            							  Divide_By__c='Prorate', Description__c='Descr',
            							  residual_Amount__c=1.00, Default_Rule__c=false, 
            							  initial_amount__c=1000.00)); 
        insert revRecRules;
               
        //Test product data
        List<Product2> products = new List<Product2>();
        products.add(new Product2(name='Test Product 1', IsActive=true, 
                                  Description='Product', ProductCode='Prod code')); 
        insert products;    
       
        //Test pricebookentry data
        List<PricebookEntry> pricebookEntries1 = new List<PricebookEntry>();
        pricebookEntries1.add(new PricebookEntry(Pricebook2Id=pricebookId, 
                                                 Product2Id=products[0].id, 
                                                 UnitPrice=100.00, IsActive=true, 
                                                 UseStandardPrice=false));
        insert pricebookEntries1;   
       
        //Test opportunity data
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Probability=100, Type='New Customer', 
                                          Pricebook2Id=pricebookId, Amount=273200.00,
                						  ForecastCategoryName='Closed', name='Opp 1',
            							  StageName='Closed Won', 
                                          CloseDate= Date.newInstance(2010, 6, 1)));    
        insert opportunities;
   
        //Test opportunity line item data
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, 
                                                         OpportunityId=opportunities[0].id,
                                                         PricebookEntryId=pricebookEntries1[0].id, 
                                                         UnitPrice=12000.00));
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, 
                                                         OpportunityId=opportunities[0].id,
                                                         PricebookEntryId=pricebookEntries1[0].id, 
                                                         UnitPrice=1000.00)); 
        insert opportunityLineItems; 
        
        //Test start
        Test.startTest();
        
        //Batch initlization and execute batch
        Batch_PopulateRuleOnLineItems batchPopulateRuleOnLineItems = new Batch_PopulateRuleOnLineItems();
        Database.executeBatch(batchPopulateRuleOnLineItems,10);
        
        //Test stop
        Test.stopTest();
        
        //Assert for result
        opportunityLineItems = [Select Id, AppRopozSLN__RevRecOpportunityLineItem__c 
                                from OpportunityLineItem where Id =: opportunityLineItems[0].Id];
        System.assert(opportunityLineItems[0].AppRopozSLN__RevRecOpportunityLineItem__c != null);
    }
}