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
 *	Description		:	This class is used to test the functionality of Trigger_Product.
 *
 *	Created Date	:
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0-Created
 *
 *	Coverage		:	100%
**/
@isTest(SeeAllData=false)
private class ProductTriggerHelperTest {
	
	/**
	 *	@description	:	This method is used to test product rule assignment trigger.
	**/
    static testMethod void testAssignRulesOnProducts() {
    	
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();   
        
        //RevRec Rule
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        revRecRules.add(new RevRecRules__c(Name = 'Test-1', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                           Default_Rule__c = true, Recognition_Type__c = 'Amortize'));
        revRecRules.add(new RevRecRules__c(Name = 'Test-2', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                           Default_Rule__c = true, Recognition_Type__c = 'Single Transaction'));
        
                                                     
        insert  revRecRules;
        
    	//Rule
    	List<Rule_Assignment__c> ruleAssg = new List<Rule_Assignment__c>();
    	
    	//Add rules into list
    	ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -1' , Selected_Familys__c = 'Hardware,Software,Tax',
    										Product_Family__c = 'Hardware,Software,Tax' , Active__c = true, RevRecRule__c = revRecRules[0].Id,
    										Is_Family_Assignment__c = true));
    	
    	ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -2' , Selected_Familys__c = 'MFG',
    										Product_Family__c = 'MFG' ,Active__c = true, RevRecRule__c = revRecRules[1].Id
    										, Is_Family_Assignment__c = true));
    										
    	insert ruleAssg;
    	
    	//Rule Assignment criterais 
    	List<Rule_Assignment_Criteria__c> ruleAsgCriterias = new List<Rule_Assignment_Criteria__c>();
    	ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
    							Product_Family__c = 'Hardware,Software,Tax',Rule_Assignment__c = ruleAssg[0].Id));
    	
    	ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
    							Product_Family__c = 'MFG',Rule_Assignment__c = ruleAssg[1].Id));
    	
    	insert ruleAsgCriterias;
    	
    	//List of Rule Assignment criteria
    	List<Product2> products = new List<Product2>();
    	products.add(new Product2(Name = '1Test 1' ));
    	products.add(new Product2(Name = '2Test 2' , Family = 'Tax'));
    	
    	//Test starts here 
    	Test.startTest();
    	
    	insert products;

    	//Assert for results
    	products = [Select Id , Name , RevRecRule__c, Family From Product2 Where ID IN : products ORDER BY NAME ASC];
    	System.assertEquals(2, products.size());
    	System.assertEquals(null, products[0].RevRecRule__c);
    	System.assertEquals(revRecRules[0].Id, products[1].RevRecRule__c);
    	
        //Test pricebookentry data 
        List<PricebookEntry> pricebookEntries1 = new List<PricebookEntry>();
        pricebookEntries1.add(new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=products[0].id, UnitPrice=100.00, IsActive=true, UseStandardPrice=false));
        pricebookEntries1.add(new PricebookEntry(Pricebook2Id=pricebookId, Product2Id=products[1].id, UnitPrice=100.00, IsActive=true, UseStandardPrice=false));
        insert pricebookEntries1; 
        
        //Test opportunity data
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Probability=100, Type='New Customer', Pricebook2Id=pricebookId, Amount=273200.00, ForecastCategoryName='Closed', name='Test Opp 1',
                                          StageName='Closed Won', CloseDate= Date.newInstance(2010, 6, 1)));
        opportunities.add(new Opportunity(Probability=100, Type='New Customer', Pricebook2Id=pricebookId, Amount=273200.00, ForecastCategoryName='Closed', name='Test Opp 1',
                                          StageName='Closed Won', CloseDate= Date.newInstance(2010, 6, 1), REVvue_RevRecRule__c = revRecRules[0].Id));    
        insert opportunities;
   
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        opportunitiesToUpdate.add(new Opportunity(Id = opportunities[0].Id, REVvue_RuleAssignment__c = ruleAssg[0].Id));
        update opportunitiesToUpdate;
        
        List<RevRecOpportunityLineItem__c> rROLI = new List<RevRecOpportunityLineItem__c>();
        rROLI.add(new RevRecOpportunityLineItem__c(Name= pricebookEntries1[0].Name,  opportunity__c = opportunities[0].id));
        rROLI.add(new RevRecOpportunityLineItem__c(Name= pricebookEntries1[1].Name,  opportunity__c = opportunities[1].id));
        insert rROLI;
        
        //Test opportunity line item data
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, OpportunityId=opportunities[0].id, PricebookEntryId=pricebookEntries1[0].id, UnitPrice=12000.00, RevRecOpportunityLineItem__c = rROLI[0].Id));                         
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, OpportunityId=opportunities[1].id, PricebookEntryId=pricebookEntries1[1].id, UnitPrice=1000.00, RevRecOpportunityLineItem__c = rROLI[1].Id));
        insert opportunityLineItems;
        
        products[0].RevRecRule__c =revRecRules[0].Id;
        update products[0];
        
        products = [Select Id , Name , RevRecRule__c, Family From Product2 Where ID IN : products ORDER BY NAME ASC];
    	System.assertEquals(2, products.size());
    	System.assertEquals(revRecRules[0].Id, products[0].RevRecRule__c);
        
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add(new RevRecProductRule__c(Start_Date__c = Date.Today(), 
                                                        End_Date__c = Date.Today().addMonths(5),
                                                        Residual_Amount__c = 4000,
                                                        Offset_Period__c = 12,
                                                        Offset_Type__c = 'Start',
                                                        Divide_By__c = 'Period',
                                                        Period_or_Exact_Days__c = 'period',
                                                        RevRecOpportunityLineItem__c = rROLI[0].Id,
                                                        Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                        Milestone_Type__c = 'Amount',
                                                        Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:AppRopozSLN__Start_Revenue_Date__c',
                                                        Revenue_Recognition_End_Date__c = 'OPPORTUNITY:AppRopozSLN__End_Revenue_Date__c'));
        revRecProductRules.add(new RevRecProductRule__c(Start_Date__c = Date.Today(), 
                                                        End_Date__c = Date.Today(),
                                                        Residual_Amount__c = 50,
                                                        Residual_Amount_Type__c = 'Percent',
                                                        Offset_Period__c = 12,
                                                        Offset_Type__c = 'Period',
                                                        Divide_By__c = 'Period',
                                                        Period_or_Exact_Days__c = 'period',
                                                        RevRecOpportunityLineItem__c = rROLI[1].Id,
                                                        Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                        Milestone_Type__c = 'Amount'));
        insert revRecProductRules;
        
        List<Product2> prodToBeUpdated = new List<Product2>();
        prodToBeUpdated.add(new Product2(Id=products[0].Id, RevRecRule__c =revRecRules[1].Id));
        update prodToBeUpdated;
        
    	//Test stop here 
    	Test.stopTest();
    }
}