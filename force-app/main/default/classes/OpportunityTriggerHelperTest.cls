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
private class OpportunityTriggerHelperTest {
    /**
    *	Description		:	This class is used to test the functionality of Opportunity Trigger.
    *
    *	Created Date	:	05/31/2016
    *
    *	Version			:	V_1.0
    *
    *	Revision Log	:	V_1.0 - Created
    *
    *	Coverage		:	100%
    **/
    
    //Test setup method
    @testSetup static void setup() {
        
        //Test data of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2, Offset_Type__c = 'Start', 
                                           Default_Rule__c = true, Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE)); 
        
        //Insert Rules							                                                            
        insert  revRecRules;
        
        //Test data of rule assignment
        List<Rule_Assignment__c> ruleAssignments = new List<Rule_Assignment__c>();
        ruleAssignments.add(new Rule_Assignment__c(Name = 'Test rule assignment', RevRecRule__c = revRecRules[0].Id, Active__c = true));
        
        //Insert rule Assignment
        insert ruleAssignments;
        
        //Test data of Rule Assignment Criteria
        List<Rule_Assignment_Criteria__c> ruleAssignCriteria = new List<Rule_Assignment_Criteria__c>();
        ruleAssignCriteria.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Additional_Search_Criteria__c='Test', 
                                                               Operator__c = 'IN', Rule_Assignment__c = ruleAssignments[0].Id));
        
        //Insert Rule Assignment Criteria			
        insert ruleAssignCriteria;
        
        //Test data of opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test 1', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 2', CloseDate = Date.Today().addDays(2), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 3', CloseDate = Date.Today().addDays(3), StageName = 'Open', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'UOpportunity', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        
        //Insert List of opportunity
        insert opportunities;
    }
    
    //Test method 
    static testMethod void myUnitTest() {
        
        //Test Start Here
        Test.startTest();
        
        //Query List of Rules
        List<RevRecRules__c> listOfRules = [Select Id from RevRecRules__c];
        
        //Assert
        System.assertEquals(1,listOfRules.size());
        
        //List of ruleAssignmet which inserted in test setup method
        List<Rule_Assignment__c> listOfRuleAssignment = [Select Id from Rule_Assignment__c];
        
        //Assert
        System.assertEquals(1,listOfRuleAssignment.size());
        
        //List of ruleAssignmet which inserted in test setup method
        List<Rule_Assignment_Criteria__c> listOfRuleAssCriteria = [Select Id from Rule_Assignment_Criteria__c];
        
        //Set of  opp ids
        Set<String> setOfOpportunityIds = new Set<String>();
        
        //List of opportunity query result
        List<Opportunity> listOfOpportunityInserted = [Select Id, Name from Opportunity ];
        
        //Assert
        System.assertEquals(4,listOfOpportunityInserted.size());
        
        //Query List of opportunity, which previously inserted
        listOfOpportunityInserted = [Select Id, REVvue_RevRecRule__c, REVvue_RuleAssignment__c from Opportunity order by Name];
        
        //Assert
        System.assertEquals(listOfRules[0].Id, listOfOpportunityInserted[0].REVvue_RevRecRule__c);
        System.assertEquals(listOfRuleAssignment[0].Id,listOfOpportunityInserted[0].REVvue_RuleAssignment__c);
        
        //Assert
        System.assertEquals(listOfRules[0].Id, listOfOpportunityInserted[1].REVvue_RevRecRule__c);
        System.assertEquals(listOfRuleAssignment[0].Id,listOfOpportunityInserted[1].REVvue_RuleAssignment__c);
        
        //Assert
        System.assertEquals(listOfRules[0].Id, listOfOpportunityInserted[2].REVvue_RevRecRule__c);
        System.assertEquals(listOfRuleAssignment[0].Id,listOfOpportunityInserted[2].REVvue_RuleAssignment__c);
        
        //Assert
        System.assertEquals(null, listOfOpportunityInserted[3].REVvue_RevRecRule__c);
        System.assertEquals(null,listOfOpportunityInserted[3].REVvue_RuleAssignment__c);
        
        List<Opportunity> oppToBeUpdated = new List<Opportunity>();
        oppToBeUpdated.add(new Opportunity(Id=listOfOpportunityInserted[2].Id, REVvue_RuleAssignment__c=null));
        update oppToBeUpdated;
        
        //Query List of opportunity, which previously inserted
        listOfOpportunityInserted = [Select Id, REVvue_RevRecRule__c, REVvue_RuleAssignment__c from Opportunity order by Name];
        
        System.assertEquals(null, listOfOpportunityInserted[2].REVvue_RuleAssignment__c);
        
        //Test Stop
        Test.stopTest();
        
    }
    
    /**
    *  This method is used to test the functionality of CalculateDateChange()
    **/
    @IsTest
    static void testCalculateDateChange() {
        Id pricebookId = Test.getStandardPricebookId();
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', 
                                                              Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period', 
                                                              Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize');
        insert  revRecDefaultRule;
        
        Account testAccount = new Account();
        testAccount.Name='Test Account' ;
        insert testAccount;
        
        //Test Opportunity
        List<Opportunity> opportynity = new List<Opportunity>();
        opportynity.add(new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', Type = 'New Customer',AccountId = testAccount.Id));
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        products.add(new Product2(Name = 'Test0',  IsActive = true, Product_Date__c = System.today()));
        insert products;
        System.assertEquals(true, products[0].IsActive);
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = RevRecDefaultRule.Id, ServiceDate = Date.Today().addDays(90)));
        
        insert oppLineItems;
        
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity[0].Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        
        // Create the contract
        Contract c = new Contract();
        c.AccountId = opportynity[0].accountId;
        c.ContractTerm = 12;
        c.StartDate = System.today();
        c.OwnerExpirationNotice = '30';
        c.Status = 'Draft'; 
        insert c;
        System.assertEquals('Draft', c.Status);
        
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();   
        revRecProductRules.add( new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                         Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                         Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                         Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                         Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                         Revenue_Recognition_Start_Date__c = 'CONTRACT:Contract End Date',Revenue_Recognition_End_Date__c = 'CONTRACT:Contract End Date'));  
        
        revRecProductRules.add( new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                         Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                         Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                         Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                         Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                         Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:AppRopozSLN__Start_Revenue_Date__c',Revenue_Recognition_End_Date__c = 'OPPORTUNITY:AppRopozSLN__Start_Revenue_Date__c'));
        
		insert revRecProductRules;
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                           RevRecProductRule__c =: revRecProductRules[0].Id];
        
        //Query through Schedule records
        List<RevRecOpportunityLineItemSchedule__c> schedules = [Select Id From RevRecOpportunityLineItemSchedule__c WHERE 
                                                                RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];  
        
        
        Test.startTest();
     
        //update opportynity
        opportynity[0].CloseDate = Date.Today().addDays(365);
        //opportynity[0].contractId = c.Id;
        update opportynity;
        
        // update revRecDefaultRule
        revRecDefaultRule.Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        update revRecDefaultRule;
        
        //update revRecLineItems
        revRecLineItems[0].ResidualAmount__c = 500;
        revRecLineItems[0].RevRecRule__c = revRecDefaultRule.Id;
        update revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;   
        update oppLineItems;
        
        // update revRecProductRules
        revRecProductRules[0].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        revRecProductRules[0].Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        update revRecProductRules;
        
        Test.stopTest();       
        
    } 
    
    /**
    *  This method is used to test the functionality of CalculateDateChange()
    **/
    @IsTest
    static void testCalculateDateChange1() {
       Id pricebookId = Test.getStandardPricebookId();
        
        List<RevRecRules__c> revRecDefaultRule = new List<RevRecRules__c>();
        revRecDefaultRule.add(new RevRecRules__c(initial_amount_type__c='Amount', Revenue_Recognition_End_Date__c='OPPORTUNITY PRODUCT:Date', Offset_Period__c=1, Offset_Type__c='Period',
                                           Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Name='Rule test', Recognition_Type__c='Amortize Milestone', 
                                           Revenue_Recognition_Start_Date__c='OPPORTUNITY PRODUCT:Date', Period_or_Exact_Days__c='exact', Divide_By__c='Prorate', 
                                           Description__c='Descr', residual_Amount__c=1.00, Default_Rule__c=false, initial_amount__c=1000.00));
        revRecDefaultRule.add(new RevRecRules__c(initial_amount_type__c='Amount', Revenue_Recognition_End_Date__c='PRODUCT:Product Date', Offset_Period__c=1, Offset_Type__c='Period',
                                           Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Name='Rule test', Recognition_Type__c='Amortize', 
                                           Revenue_Recognition_Start_Date__c='PRODUCT:Product Date', Period_or_Exact_Days__c='exact', Divide_By__c='Prorate', 
                                           Description__c='Descr', residual_Amount__c=1.00, Default_Rule__c=false, initial_amount__c=1000.00)); 
        revRecDefaultRule.add(new RevRecRules__c(initial_amount_type__c='Amount', Revenue_Recognition_End_Date__c='PRODUCT:Product Date', Offset_Period__c=1, Offset_Type__c='Period',
                                           Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Name='Rule test', Recognition_Type__c='Amortize', 
                                           Revenue_Recognition_Start_Date__c='PRODUCT:Product Date', Period_or_Exact_Days__c='exact', Divide_By__c='Prorate', 
                                           Description__c='Descr', residual_Amount__c=1.00, Default_Rule__c=false, initial_amount__c=1000.00)); 
        insert revRecDefaultRule;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        
        // Create the contract
        Contract c = new Contract();
        c.AccountId = acc.Id;
        c.ContractTerm = 12;
        c.StartDate = System.today();
        c.OwnerExpirationNotice = '30';
        c.Status = 'Draft'; 
        insert c;
        
        // Create the contract
        Contract contracts = new Contract();
        contracts.AccountId = acc.Id;
        contracts.ContractTerm = 6;
        contracts.StartDate = System.today();
     //	contracts.EndDate = Date.Today().addDays(365);
        contracts.OwnerExpirationNotice = '30';
        contracts.Status = 'Draft'; 
        insert contracts;
         
        //Test Opportunity
        List<Opportunity> opportynity = new List<Opportunity>();
        opportynity.add(new Opportunity (Name = 'Test', CloseDate = Date.Today(), 
                                         StageName = 'Closed Won', Type = 'New Customer', 
                                         AccountId = acc.Id, contractId = c.Id));
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        insert products;
        System.assertEquals(true, products[0].IsActive);
        
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry List
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 2000, isActive = true));
        
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = revRecDefaultRule[0].Id, ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = revRecDefaultRule[1].Id, ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = revRecDefaultRule[2].Id, ServiceDate = Date.Today().addDays(90))); 
        
        insert oppLineItems;
        System.assertEquals(1000, oppLineItems[1].UnitPrice);
        
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity[0].Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
                       
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                        Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                        Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                        Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                        Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                        Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate',
                                                        Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate'));
        
        revRecProductRules.add( new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                         Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                         Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                         Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                         Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                         Revenue_Recognition_Start_Date__c = 'PRODUCT:Product Date',
                                                         Revenue_Recognition_End_Date__c = 'PRODUCT:Product Date'));     
        
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                        Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                        Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                        Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                        Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                        Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate',
                                                        Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate'));
        
        revRecProductRules.add( new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                         Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                         Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                         Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                         Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                         Revenue_Recognition_Start_Date__c = 'CONTRACT:StartDate',
                                                         Revenue_Recognition_End_Date__c = 'CONTRACT:StartDate'));       
        
		insert revRecProductRules;
              
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                           RevRecProductRule__c =: revRecProductRules[0].Id];
        
        List<RevRecProductRuleMilestone__c> mileStones1  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                           RevRecProductRule__c =: revRecProductRules[1].Id];
        
        List<RevRecProductRuleMilestone__c> mileStones2  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                           RevRecProductRule__c =: revRecProductRules[2].Id];
                
        //Query through Schedule records
        List<RevRecOpportunityLineItemSchedule__c> schedules = [Select Id From RevRecOpportunityLineItemSchedule__c WHERE 
                                                                RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
        
        Test.startTest();
        
        //update opportynity
        opportynity[0].CloseDate = Date.Today().addDays(365);
        opportynity[0].contractId = contracts.Id;
        update opportynity;
        
        // update revRecDefaultRule
        revRecDefaultRule[0].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        update revRecDefaultRule; 
        
        //update revRecLineItems
        revRecLineItems[0].ResidualAmount__c = 500;
        update revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[0].ServiceDate = Date.Today().addDays(50);
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[0].Id; 
        oppLineItems[1].ServiceDate = Date.Today().addDays(74);
        oppLineItems[2].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[2].ServiceDate = Date.Today().addDays(63);
        update oppLineItems;
        
        // update revRecProductRules
        revRecProductRules[0].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        revRecProductRules[0].Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        
        revRecProductRules[1].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        revRecProductRules[1].Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        
     	revRecProductRules[2].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        revRecProductRules[2].Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate';
        
        revRecProductRules[3].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        revRecProductRules[3].Revenue_Recognition_End_Date__c = 'CONTRACT:Contract Start Date';
        
        update revRecProductRules; 
        
        Test.stopTest();       
    } 
}