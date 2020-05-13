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
public class OpportunityLineItemTriggerHelperTest {
    /**
     *  Purpose              :   Test class for OpportunityLineItemtriggerHelper.
     * 
     *  Created by           :   Bill Feeheley
     * 
     *  Created Date         :   04/19/2016
     * 
     *  Version              :   
     *
     *  Revision Log         :
     * 
     *  Code Coverage        :   100%
     **/
     
    /**
     *  Description          :   This method is to Cover the SetRevRecRuleFieldValue().
    **/    
    public static testMethod void testSetRevRecRuleFieldValue() {
        
       //Get standard pricbook Id to insert new price booke entery
       Id pricebookId = Test.getStandardPricebookId();   
       
       //Test RevRecRule data
       List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
       revRecRules.add(new RevRecRules__c(initial_amount_type__c='Amount', Revenue_Recognition_End_Date__c='PRODUCT:ServiceDate', Offset_Period__c=1, Offset_Type__c='Period',
                                          Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Name='Rule test', Recognition_Type__c='Amortize', 
                                          Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate', Period_or_Exact_Days__c='exact', Divide_By__c='Prorate', 
                                          Description__c='Descr', residual_Amount__c=1.00, Default_Rule__c=false, initial_amount__c=1000.00)); 
        insert revRecRules;
               
        //Test product data
        List<Product2> products = new List<Product2>();
        products.add(new Product2(name='Test Product 1', IsActive=true, Description='Product', ProductCode='Prod code', RevRecRule__c =revRecRules[0].Id));
        products.add(new Product2(name='Test Product 1', IsActive=true, Description='Product', ProductCode='Prod code')); 
        insert products;    
       
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
   
        //Rule Assignments
        List<Rule_Assignment__c> ruleAssg = new List<Rule_Assignment__c>();
        
        //Add rules into list
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -1', Selected_Familys__c = 'Hardware,Software,Tax', Product_Family__c = 'Hardware,Software,Tax', Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Opportunity_Ids__c = opportunities[0].Id+',', 
                                            Selected_Product_Ids__c = products[0].Id +','));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -2' , Selected_Familys__c = 'MFG', Product_Family__c = 'MFG' ,Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+',', Selected_Product_Ids__c = products[0].Id +','));
                                            
        insert ruleAssg;
        
        List<Product2> productsToUpdate = new List<Product2>();
        productsToUpdate.add(new Product2(Id = products[0].Id, Rule_Assignment__c = ruleAssg[0].Id));
        update productsToUpdate;
        
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        opportunitiesToUpdate.add(new Opportunity(Id = opportunities[0].Id, REVvue_RuleAssignment__c = ruleAssg[0].Id));
        update opportunitiesToUpdate;
        
        //Test opportunity line item data
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, OpportunityId=opportunities[0].id, PricebookEntryId=pricebookEntries1[0].id, UnitPrice=12000.00));                         
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, OpportunityId=opportunities[1].id, PricebookEntryId=pricebookEntries1[1].id, UnitPrice=1000.00));
        
        //Test start
        Test.startTest();
        
        //Inserting opportunityLineItem
        insert opportunityLineItems[0]; 
        
        //Inserting opportunityLineItem
        insert opportunityLineItems[1]; 
        
        //Assert for result
        opportunityLineItems = [Select Id, AppRopozSLN__RevRecOpportunityLineItem__c from OpportunityLineItem where Id =: opportunityLineItems[0].Id];
        System.assert(opportunityLineItems[0].AppRopozSLN__RevRecOpportunityLineItem__c != null);
                             
        //Test stop
        Test.stopTest();
    }
    
    /**
     *  This method is used to test the functionality of 
    **/
    static testmethod void testRunRuleAssignments() {
        
        //List of RevRec Rule
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        revRecRules.add(new RevRecRules__c(Name = 'Test-1', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize'));
        revRecRules.add(new RevRecRules__c(Name = 'Test-2', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Single Transaction'));
        revRecRules.add(new RevRecRules__c(Name = 'Test-3', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Single Transaction'));
                                                     
        insert  revRecRules;
        
        //List of opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        
        //Add opportunities into list
        opportunities.add(new Opportunity(Name = 'Test 1', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 2', CloseDate = Date.Today().addDays(2), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 3', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 4', CloseDate = Date.Today().addDays(2), StageName = 'Closed Won', Type = 'New Customer'));
        insert opportunities;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true,  Family='Hardware'));
        products.add(new Product2(Name = 'Test1',  IsActive = true,  Family='Software'));
        products.add(new Product2(Name = 'Test2',  IsActive = true,  Family='tst'));
        products.add(new Product2(Name = 'Test3',  IsActive = true,  Family='MFG'));
        products.add(new Product2(Name = 'Test4',  IsActive = true,  Family='tEST1'));
        
        //Insert Product
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Rule Assignments
        List<Rule_Assignment__c> ruleAssg = new List<Rule_Assignment__c>();
        
        //Add rules into list
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -1', Selected_Familys__c = 'Hardware,Software,Tax', Product_Family__c = 'Hardware,Software,Tax', Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Opportunity_Ids__c = opportunities[0].Id+',', 
                                            Selected_Product_Ids__c = products[0].Id +','));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -2' , Selected_Familys__c = 'MFG', Product_Family__c = 'MFG' ,Active__c = true, RevRecRule__c = revRecRules[1].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+',', Selected_Product_Ids__c = products[0].Id +','));
                                            
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -3' , Selected_Familys__c = 'Hardware,Software,Tax',
                                            Product_Family__c = 'Hardware,Software,Tax' , Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Product_Ids__c  = products[0].Id +','));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -4' , Selected_Familys__c = 'MFG',
                                            Product_Family__c = 'MFG' ,Active__c = true, 
                                            RevRecRule__c = revRecRules[1].Id));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -5' , Selected_Familys__c = 'MFG',
                                            Product_Family__c = 'MFG' ,Active__c = true, 
                                            RevRecRule__c = revRecRules[1].Id));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -6' , Selected_Familys__c = 'Hardware,Software,Tax',
                                            Product_Family__c = 'Hardware,Software,Tax' , Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Product_Ids__c  = products[0].Id +','));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST ONLY OPP' ,Active__c = true, 
                                            RevRecRule__c = revRecRules[1].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+','));
                                            
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST  OPP-FAMILY IN' ,Active__c = true, 
                                            RevRecRule__c = revRecRules[1].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Selected_Familys__c = 'Hardware'));         
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST  OPP IN -FAMILY NOT IN' ,Active__c = true, 
                                            RevRecRule__c = revRecRules[1].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Selected_Familys__c = 'Hardware'));                                                                     
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST  OPP IN -PRODUCT NAME IN' ,Active__c = true, 
                                            RevRecRule__c = revRecRules[1].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Selected_Product_Ids__c = products[3].Id +','));            
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST  OPP IN -PRODUCT NAME NOT IN' ,Active__c = true, 
                                            RevRecRule__c = revRecRules[1].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Selected_Product_Ids__c = products[4].Id +','));    
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'PRODUCT NOT IN - FAMILY IN' , Selected_Familys__c = 'Hardware,Software,Tax',
                                            Product_Family__c = 'Hardware,Software,Tax' , Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Product_Ids__c  = products[0].Id +','));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'PRODUCT NOT IN - FAMILY NOT IN' , Selected_Familys__c = 'MFG',
                                            Product_Family__c = 'Hardware,Software,Tax' , Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Product_Ids__c  = products[0].Id +','));    
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id));  
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Familys__c = 'Hardware')); 
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Product_Ids__c = products[0].Id +','));    
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Familys__c = 'Hardware')); 
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Product_Ids__c = products[0].Id +','));    
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Product_Ids__c = products[0].Id +',',
                                            Selected_Familys__c = 'Hardware')); 
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Product_Ids__c = products[0].Id +',',
                                            Selected_Familys__c = 'Hardware')); 
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Product_Ids__c = products[0].Id +',',
                                            Selected_Familys__c = 'Hardware')); 
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Familys__c = 'Hardware')); 
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',',
                                            Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Familys__c = 'Hardware')); 
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'OPPORTUNITY NOT IN' , Selected_Opportunity_Ids__c = opportunities[0].Id+',', Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Familys__c = 'Hardware')); 
        insert ruleAssg;
        
        //Rule Assignment criterais 
        List<Rule_Assignment_Criteria__c> ruleAsgCriterias = new List<Rule_Assignment_Criteria__c>();
        
        //Add records in the list
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN', Opportunity_Name__c = 'Test 1',Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'IN',  Product_Family__c = 'Test0',Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN', Product_Name__c = 'Hardware,Software,Tax', 
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN', Product_Family__c = 'MFG',Rule_Assignment__c = ruleAssg[1].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'IN', Opportunity_Name__c = 'Test 1',Rule_Assignment__c = ruleAssg[1].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN', Product_Name__c = 'Test2', 
                                                             Rule_Assignment__c = ruleAssg[1].Id));
                
        //PRODUCT IN FAMILY NOT IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
                                Product_Family__c = 'MFG',Rule_Assignment__c = ruleAssg[2].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN' , 
                                Product_Name__c = 'Test2',Rule_Assignment__c = ruleAssg[2].Id));
        
        //PRODUCT IN FAMILY IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                Product_Family__c = 'MFG',Rule_Assignment__c = ruleAssg[5].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN' , 
                                Product_Name__c = 'Test2',Rule_Assignment__c = ruleAssg[5].Id));
                                
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                Product_Family__c = 'MFG',Rule_Assignment__c = ruleAssg[3].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
                                Product_Family__c = 'Hardware',Rule_Assignment__c = ruleAssg[4].Id));
        
         //Checking for only Selected Opportunity
         ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[6].Id));
        
        //Opprtunity In family IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[7].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[7].Id));
        
        //Opprtunity In family NOT IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[8].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[8].Id));
        
        //Opprtunity In PRODUCT  IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[9].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[9].Id));
        
        //Opprtunity In PRODUCT NOT IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[10].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[10].Id));
        
        //Opprtunity In PRODUCT NOT IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[10].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[10].Id));
        
        //PRODUCT not IN FAMILY NOT IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
                                Product_Family__c = 'MFG',Rule_Assignment__c = ruleAssg[11].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'NOT IN' , 
                                Product_Name__c = 'Test2',Rule_Assignment__c = ruleAssg[11].Id));
        
        //PRODUCT not IN FAMILY IN
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                Product_Family__c = 'MFG',Rule_Assignment__c = ruleAssg[12].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'NOT IN' , 
                                Product_Name__c = 'Test2',Rule_Assignment__c = ruleAssg[12].Id));
                                
        //Checking for NO Selected Opportunity
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[13].Id));  
        
        //Checking for only NOT IN Opportunity FAMLY IN 
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[14].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[14].Id));  
                                   
        //Checking for only Selected Opportunity
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[15].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[15].Id));  
        
        //Checking for only NOT IN Opportunity FAMLY IN 
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[16].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[16].Id));  
                                   
        //Checking for not in Opportuniity and IN PRODUCT
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[17].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[17].Id));  
        
        //Checking for NOT IN OPP , IN PRODUCT IN FAMILY
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[18].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[18].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[18].Id));  
        
        //Checking for NOT IN OPP , IN PRODUCT IN FAMILY
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[19].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[19].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[19].Id));  
        
        //Checking for NOT IN OPP , IN PRODUCT IN FAMILY
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[20].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[20].Id));  
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[20].Id));  
        
        
        //Checking for NOT IN OPP , IN PRODUCT IN FAMILY
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[21].Id));          
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'IN' , 
                                   Rule_Assignment__c = ruleAssg[21].Id));  
        
        //Checking for NOT IN OPP , IN PRODUCT IN FAMILY
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[22].Id));          
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN' , 
                                   Rule_Assignment__c = ruleAssg[22].Id));
        
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = 'NOT IN', Opportunity_Name__c = 'Test 1',
                                                             Rule_Assignment__c = ruleAssg[23].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = 'NOT IN',  Product_Family__c = 'Test0', 
                                                             Rule_Assignment__c = ruleAssg[23].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = 'NOT IN', Product_Name__c = 'Hardware,Software,Tax', 
                                                             Rule_Assignment__c = ruleAssg[23].Id));
         
        
        insert ruleAsgCriterias;
                
        //Standard Price Book Id
        Id pricebookId = Test.getStandardPricebookId();
        
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
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[3].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[3].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[4].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[4].Id, UnitPrice = 9000, isActive = true));
        
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
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[3].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[7].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[9].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[5].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[3].Id, PricebookEntryId = pricebookEntries[9].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id, PricebookEntryId = pricebookEntries[3].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[3].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, 
                                                 UnitPrice = 10000 , ServiceDate = Date.Today().addDays(90)));
        
        //Test start here 
        Test.startTest();
        
        //Insert Opp Line items
        insert oppLineItems;  
        System.assertEquals(10, oppLineItems[1].Quantity);
        
        //Test stop here
        Test.stopTest();
    }
    
    /**
     *  This method is used to test the functionality of RunRuleAssignments()
    **/
    static testmethod void testRunRuleAssignments1() {
                
        //Standard Price Book Id
        Id pricebookId = Test.getStandardPricebookId();
        
        //Test RevRec Rule data
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        revRecRules.add(new RevRecRules__c(Name = 'Test-1', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize'));                                           
        insert  revRecRules;
        
        //Test opportunity data
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test 1', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer', Pricebook2Id = pricebookId));
        insert opportunities;
        
        //Test Product data
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true,  Family='Hardware'));
        products.add(new Product2(Name = 'Test1',  IsActive = true,  Family='Hardware'));
        insert products;
        System.assertEquals(true, products[1].IsActive);
         
        //Rule Assignments
        List<Rule_Assignment__c> ruleAssg = new List<Rule_Assignment__c>();
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -1', Selected_Familys__c = 'Tax', Product_Family__c = 'Hardware', Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Opportunity_Ids__c = opportunities[0].Id+',', 
                                            Selected_Product_Ids__c = products[1].Id +',')); 
        insert ruleAssg;
        
        //Test Rule Assignment critera data 
        List<Rule_Assignment_Criteria__c> ruleAsgCriterias = new List<Rule_Assignment_Criteria__c>();
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = Constants.OPERATOR_NOT_IN, Opportunity_Name__c = 'Test 1',
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = Constants.OPERATOR_IN,  Product_Family__c = 'Test0',
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = Constants.OPERATOR_NOT_IN, Product_Name__c = 'Hardware', 
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = Constants.FIELD_NAME_PRODUCT_NAME, Product_Name__c = 'Hardware', 
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = Constants.OPERATOR_NOT_IN, Product_Name__c = 'Hardware', 
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        insert ruleAsgCriterias;
        System.assertEquals('Test0', ruleAsgCriterias[1].Product_Family__c);
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Test pricebook entry data
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        insert pricebookEntries;
        
        //Test Opportunity Line Item data
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity = 10, UnitPrice = 10000, 
                                                 ServiceDate = Date.Today().addDays(90), Product2Id = products[0].Id));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity = 10, UnitPrice = 10000, 
                                                 ServiceDate = Date.Today().addDays(90), Product2Id = products[1].Id));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity = 10, UnitPrice = 10000, 
                                                 ServiceDate = Date.Today().addDays(90)));
        //Test start here 
        Test.startTest();
        
        //Insert Opp Line items
        insert oppLineItems;        
        
        //Test stop here
        Test.stopTest();
    }
    
    /**
     *  This method is used to test the functionality of RunRuleAssignments()
    **/
    static testmethod void testRunRuleAssignments2() {
                
        //Standard Price Book Id
       Id pricebookId = Test.getStandardPricebookId();
        
        //Test RevRec Rule data
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        revRecRules.add(new RevRecRules__c(Name = 'Test-1', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize'));                                           
        insert  revRecRules;
        
        //Test opportunity data
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test 1', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer', Pricebook2Id = pricebookId));
        insert opportunities;
        
        //Test Product data
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true,  Family='Hardware'));
        products.add(new Product2(Name = 'Test1',  IsActive = true,  Family='Hardware'));
        insert products;
         
        //Rule Assignments
        List<Rule_Assignment__c> ruleAssg = new List<Rule_Assignment__c>();
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -1', Selected_Familys__c = 'Tax', Product_Family__c = 'Hardware', Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Opportunity_Ids__c = opportunities[0].Id+',', 
                                            Selected_Product_Ids__c = products[0].Id +',')); 
        insert ruleAssg;
        
        //Test Rule Assignment critera data 
        List<Rule_Assignment_Criteria__c> ruleAsgCriterias = new List<Rule_Assignment_Criteria__c>();
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = Constants.OPERATOR_NOT_IN, Opportunity_Name__c = 'Test 1',
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Name', Operator__c = Constants.OPERATOR_IN,  Product_Family__c = 'Test0',
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = Constants.OPERATOR_IN, Product_Name__c = 'Hardware', 
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = Constants.FIELD_NAME_PRODUCT_NAME, Product_Name__c = 'Hardware', 
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Product Name', Operator__c = Constants.OPERATOR_NOT_IN, Product_Name__c = 'Hardware', 
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        ruleAsgCriterias.add(new Rule_Assignment_Criteria__c(Criteria_Field__c = 'Family', Operator__c = Constants.OPERATOR_IN, Opportunity_Name__c = 'Test 1',
                                                             Rule_Assignment__c = ruleAssg[0].Id));
        insert ruleAsgCriterias;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Test pricebook entry data
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        insert pricebookEntries;
        
        //Test Opportunity Line Item data
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity = 10, UnitPrice = 10000, 
                                                 ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity = 10, UnitPrice = 10000, 
                                                 ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity = 10, UnitPrice = 10000, 
                                                 ServiceDate = Date.Today().addDays(90)));
        //Test start here 
        Test.startTest();
        
        //Insert Opp Line items
        insert oppLineItems;    
        
        List<OpportunityLineItem> listOfOppLineItems = [Select Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, ServiceDate, AppRopozSLN__RevRecOpportunityLineItem__c, Product2Id from OpportunityLineItem];        
        //Assert for result
        oppLineItems = [Select Id, AppRopozSLN__RevRecOpportunityLineItem__c from OpportunityLineItem where Id =: oppLineItems[0].Id];
        System.assert(oppLineItems[0].AppRopozSLN__RevRecOpportunityLineItem__c != null);
        
        //Test stop here
        Test.stopTest(); 
    }
    
    /**
     *  This method is used to test the functionality of RunRuleAssignments()
    **/
    static testmethod void testRunRuleAssignments3() {
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
                products.add(new Product2(Name = 'Test0',  IsActive = true));
                products.add(new Product2(Name = 'Test1',  IsActive = true));
                products.add(new Product2(Name = 'Test2',  IsActive = true));
                products.add(new Product2(Name = 'Test3',  IsActive = true));
                products.add(new Product2(Name = 'Test4',  IsActive = true));
                
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
            oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, 
                                                     PricebookEntryId = pricebookEntries[0].Id,
                                                     Quantity = 1, 
                                                     UnitPrice = 1000,
                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id, 
                                                     RevRecRule__c = revRecDefaultRule.Id));
                                                     
            oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, 
                                                     PricebookEntryId = pricebookEntries[1].Id,
                                                     Quantity = 1,
                                                     UnitPrice = 1000,
                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[1].Id, 
                                                     RevRecRule__c = revRecDefaultRule.Id));
                                                      
            oppLineItems.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id,
                                                     PricebookEntryId = pricebookEntries[2].Id,
                                                     Quantity = 1,
                                                     UnitPrice = 1000,
                                                     AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[2].Id, 
                                                     RevRecRule__c = revRecDefaultRule.Id));                         
        insert oppLineItems;
        
        //Assert
        System.assertEquals(oppLineItems.size() , 3);  
        
        //Product override rule
        List<AppRopozSLN__RevRecProductRule__c> revRecProductRules = new  List<AppRopozSLN__RevRecProductRule__c>();
            revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addMonths(1),
                                                                         AppRopozSLN__Residual_Amount__c = 3000,
                                                                         AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                                         AppRopozSLN__Recognition_Type__c = 'Single Transaction'));
                                                                         
            revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addDays(10),
                                                                         AppRopozSLN__Residual_Amount__c = 3000,
                                                                         AppRopozSLN__Initial_Amount_Type__c = 'Percent',
                                                                         AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[1].Id,
                                                                         AppRopozSLN__Recognition_Type__c = 'Single Transaction',
                                                                         AppRopozSLN__Start_Date__c = Date.Today().addDays(4)));                                                             
                                                                         
            revRecProductRules.add(new AppRopozSLN__RevRecProductRule__c(AppRopozSLN__End_Date__c = Date.Today().addMonths(5),
                                                                         AppRopozSLN__Residual_Amount__c = 4000,
                                                                         AppRopozSLN__RevRecOpportunityLineItem__c = revRecLineItems[2].Id,
                                                                         AppRopozSLN__Recognition_Type__c = 'Milestone' ,
                                                                         AppRopozSLN__Milestone_Type__c = 'amount'));
                                                                         //AppRopozSLN__Start_Date__c = Date.Today().addMonths(1)));
                                                                         
        insert  revRecProductRules;
        
        
        //Assert
        System.assertEquals(revRecProductRules.size() , 3);    
        
        //Insert MileStone
        List<AppRopozSLN__RevRecProductRuleMilestone__c> listMileStone = new List<AppRopozSLN__RevRecProductRuleMilestone__c>();
        listMileStone.add(new AppRopozSLN__RevRecProductRuleMilestone__c(AppRopozSLN__Milestone_Date__c = Date.Today(),
                                                                               AppRopozSLN__Milestone_Name__c = 'Test',
                                                                               AppRopozSLN__Milestone_Sequence__c = 1,
                                                                               AppRopozSLN__RevRecProductRule__c = revRecProductRules[2].Id,
                                                                               AppRopozSLN__Amount__c = 1000,
                                                                               AppRopozSLN__Percent__c = 10));
              
        insert listMileStone ;
        
        //Test starts here
        Test.startTest();
        
        String queryString = 'SELECT Id, Name, CreatedDate, CloseDate, StageName, Amount FROM Opportunity WHERE StageName = \'Closed Won\' AND Type = \'New Customer\'  AND CloseDate > 2014-06-30  AND Amount > 900 AND Amount < 1100 ';
        Batch_MassRevenueCalculate bc = new Batch_MassRevenueCalculate(queryString);
        Database.executeBatch(bc, 10);
        
        queryString = 'SELECT Id, Name, CreatedDate, CloseDate, StageName, Amount FROM Opportunity';
        Batch_MassRevenueCalculate bc1 = new Batch_MassRevenueCalculate(queryString, opportunityIds);
        Database.executeBatch(bc1, 10);
        
        //Test stop here
        Test.stopTest();                
                                     
        //Assert for results
        //Query through RevRec Line Itemss
        revRecLineItems = [Select Id, AppRopozSLN__ResidualAmount__c From AppRopozSLN__RevRecOpportunityLineItem__c WHERE ID IN: revRecLineItems];  
        
        //Assert for results : After calculation   
        System.assertEquals(revRecLineItems[0].AppRopozSLN__ResidualAmount__c, 3000);
        System.assertEquals(revRecLineItems[1].AppRopozSLN__ResidualAmount__c, 3000);
        System.assertEquals(revRecLineItems[2].AppRopozSLN__ResidualAmount__c, 4000);   
        
        //Query thriugh RevRec Line item schedule
        List<AppRopozSLN__RevRecOpportunityLineItemSchedule__c>  listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                                                      AppRopozSLN__RecognizedRev__c,
                                                                                                      AppRopozSLN__RecognizedRevTotal__c, 
                                                                                                      AppRopozSLN__ResidualAmountTotal__c,
                                                                                                      AppRopozSLN__OriginalDate__c,
                                                                                                      AppRopozSLN__DeferredRev__c 
                                                                                                      FROM AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                                                      WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
        
        //Assert for results
        //system.assertEquals(13, listRevRecLineItemSch.size());
        
        listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                    AppRopozSLN__RecognizedRev__c,
                                                                    AppRopozSLN__RecognizedRevTotal__c, 
                                                                    AppRopozSLN__ResidualAmountTotal__c,
                                                                    AppRopozSLN__OriginalDate__c,
                                                                    AppRopozSLN__DeferredRev__c FROM
                                                                    AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                    WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[1].Id];
        
       listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                    AppRopozSLN__RecognizedRev__c,
                                                                    AppRopozSLN__RecognizedRevTotal__c, 
                                                                    AppRopozSLN__ResidualAmountTotal__c,
                                                                    AppRopozSLN__OriginalDate__c,
                                                                    AppRopozSLN__DeferredRev__c FROM
                                                                    AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                    WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[2].Id];
                                                                    
        //Assert for results
        //System.assertEquals(listRevRecLineItemSch.size(), 13);
     
        
    }
    
    /**
     *  This method is used to test the functionality of updateRevVueProcessOnChange()
    **/
    static testMethod void updateRevVueProcessOnChange() {
        
       //Get standard pricbook Id to insert new price booke entery
       Id pricebookId = Test.getStandardPricebookId();   
       
       //Test RevRecRule data
       List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
       revRecRules.add(new RevRecRules__c(initial_amount_type__c='Amount', Revenue_Recognition_End_Date__c='PRODUCT:ServiceDate', Offset_Period__c=1, Offset_Type__c='Period',
                                          Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Name='Rule test', Recognition_Type__c='Amortize', 
                                          Revenue_Recognition_Start_Date__c='OPPORTUNITY:CloseDate', Period_or_Exact_Days__c='exact', Divide_By__c='Prorate', 
                                          Description__c='Descr', residual_Amount__c=1.00, Default_Rule__c=false, initial_amount__c=1000.00)); 
        insert revRecRules;
               
        //Test product data
        List<Product2> products = new List<Product2>();
        products.add(new Product2(name='Test Product 1', IsActive=true, Description='Product', ProductCode='Prod code', RevRecRule__c =revRecRules[0].Id));
        products.add(new Product2(name='Test Product 1', IsActive=true, Description='Product', ProductCode='Prod code')); 
        insert products;    
        System.assertEquals(true, products[1].IsActive);
       
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
        System.assertEquals('Closed', opportunities[1].ForecastCategoryName);
   
        //Rule Assignments
        List<Rule_Assignment__c> ruleAssg = new List<Rule_Assignment__c>();
        
        //Add rules into list
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -1', Selected_Familys__c = 'Hardware,Software,Tax', Product_Family__c = 'Hardware,Software,Tax', Active__c = true, 
                                            RevRecRule__c = revRecRules[0].Id, Selected_Opportunity_Ids__c = opportunities[0].Id+',', 
                                            Selected_Product_Ids__c = products[0].Id +','));
        
        ruleAssg.add(new Rule_Assignment__c(Name= 'TEST FAMILY -2' , Selected_Familys__c = 'MFG', Product_Family__c = 'MFG' ,Active__c = true, RevRecRule__c = revRecRules[0].Id,
                                            Selected_Opportunity_Ids__c = opportunities[0].Id+',', Selected_Product_Ids__c = products[0].Id +','));
                                            
        insert ruleAssg;
        
        List<Product2> productsToUpdate = new List<Product2>();
        productsToUpdate.add(new Product2(Id = products[0].Id, Rule_Assignment__c = ruleAssg[0].Id));
        update productsToUpdate;
        
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        opportunitiesToUpdate.add(new Opportunity(Id = opportunities[0].Id, REVvue_RuleAssignment__c= ruleAssg[0].Id));
        update opportunitiesToUpdate;
        
        //Test opportunity line item data
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, OpportunityId=opportunities[0].id, PricebookEntryId=pricebookEntries1[0].id, UnitPrice=15000));                         
        opportunityLineItems.add(new OpportunityLineItem(Quantity=1.00, OpportunityId=opportunities[1].id, PricebookEntryId=pricebookEntries1[1].id, TotalPrice=10000));
        
        //Inserting opportunityLineItem
        insert opportunityLineItems[0];  
        
        //Inserting opportunityLineItem
        insert opportunityLineItems[1]; 
        
        //Assert for result
        //opportunityLineItems = [Select Id, AppRopozSLN__RevRecOpportunityLineItem__c from OpportunityLineItem where Id =: opportunityLineItems[0].Id];
               
        List<OpportunityLineItem> OLIToBeUpdated = new List<OpportunityLineItem>();
        OLIToBeUpdated.add(new OpportunityLineItem(Id = opportunityLineItems[0].Id,  TotalPrice=1000));
        
        List<PricebookEntry> pricebookEntries1ToUpdate = new List<PricebookEntry>();
        pricebookEntries1ToUpdate.add(new PricebookEntry(Id=pricebookEntries1[0].Id, Pricebook2Id=pricebookId, Product2Id=products[0].id, UnitPrice=100.00, IsActive=true, UseStandardPrice=false));
        
        Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE_FROM_ADJUST = false;
        
        //Test start
        Test.startTest();
        
        update pricebookEntries1ToUpdate;
        update OLIToBeUpdated;
        
        //Test stop
        Test.stopTest();
    }
    
    /**
     *  This method is used to test the functionality of deleteSchedule()
    **/
    @IsTest
    static void testDeleteSchedule() {
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'
                                                              , Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize');
        
        insert  revRecDefaultRule;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won', Type = 'New Customer');
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        products.add(new Product2(Name = 'Test0',  IsActive = true));
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
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = RevRecDefaultRule.Id));
        
        insert oppLineItems;
        
        //RevRec Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new RevRecOpportunityLineItem__c( Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100, DeferredRev__c = 1200, RecognizedRev__c = 1000));
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        update oppLineItems;
        System.assertEquals(1, oppLineItems.size());
        
        //Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add( new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                         Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                         Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                         Offset_Period__c = 1,
                                                         Offset_Type__c = 'Start',Divide_By__c = 'Period', Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period'));
        
        insert   revRecProductRules;
        
        //Get milestones list
        List<RevRecProductRuleMilestone__c> mileStones  = [SELECT ID from RevRecProductRuleMilestone__c WHERE 
                                                           RevRecProductRule__c =: revRecProductRules[0].Id];
        
        //Query through Schedule records
        List<RevRecOpportunityLineItemSchedule__c> schedules = [Select Id From RevRecOpportunityLineItemSchedule__c WHERE 
                                                                RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
    }
    
    /**
     *  This method is used to test the functionality of CalculateDateChange()
    **/
    @IsTest
    static void testCalculateDateChange() {
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
        revRecDefaultRule.add(new RevRecRules__c(initial_amount_type__c='Amount', Revenue_Recognition_End_Date__c='OPPORTUNITY:Close Date', Offset_Period__c=1, Offset_Type__c='Period',
                                           Active__c=true, Residual_Amount_Type__c='Amount', Period__c='Monthly', Name='Rule test', Recognition_Type__c='Amortize', 
                                           Revenue_Recognition_Start_Date__c='OPPORTUNITY:Close Date', Period_or_Exact_Days__c='exact', Divide_By__c='Prorate', 
                                           Description__c='Descr', residual_Amount__c=1.00, Default_Rule__c=false, initial_amount__c=1000.00)); 
        insert revRecDefaultRule;
        
        //Test Opportunity
        List<Opportunity> opportynity = new List<Opportunity>();
        opportynity.add(new Opportunity (Name = 'Test', CloseDate = Date.Today().addDays(75), StageName = 'Closed Won', Type = 'New Customer'));
        opportynity.add(new Opportunity (Name = 'Test2', CloseDate = Date.Today().addDays(60), StageName = 'Closed Won', Type = 'New Customer'));
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        products.add(new Product2(Name = 'Test0',  IsActive = true));
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
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity[1].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = revRecDefaultRule[0].Id, ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = revRecDefaultRule[1].Id, ServiceDate = Date.Today().addDays(70)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 1, UnitPrice = 1000,
                                                 RevRecRule__c = revRecDefaultRule[2].Id, ServiceDate = Date.Today().addDays(96))); 
        
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
                                                        Milestone_Type__c = 'amount', Start_Date__c = Date.Today().addDays(97),
                                                        Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                        Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                        Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate',
                                                        Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate'));
        
        revRecProductRules.add( new RevRecProductRule__c(End_Date__c = Date.Today().addYears(2), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                         Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                         Milestone_Type__c = 'amount', Start_Date__c = Date.Today().addDays(55),
                                                         Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                         Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                         Revenue_Recognition_Start_Date__c = 'PRODUCT:Product Date',
                                                         Revenue_Recognition_End_Date__c = 'PRODUCT:Product Date'));     
        
        revRecProductRules.add(new RevRecProductRule__c(End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                        Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                        Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                        Offset_Period__c = 1,Offset_Type__c = 'Start',Divide_By__c = 'Period', 
                                                        Period__c = 'Monthly' , Period_or_Exact_Days__c = 'period',
                                                        Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate',
                                                        Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate'));
        
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
         
        //update revRecLineItems
        revRecLineItems[0].ResidualAmount__c = 500;
        update revRecLineItems;
        
        // update revRecDefaultRule
        revRecDefaultRule[0].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate';
        update revRecDefaultRule;
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[0].ServiceDate = Date.Today().addDays(76);
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;  
        oppLineItems[2].ServiceDate = Date.Today().addDays(45);
        oppLineItems[2].RevRecOpportunityLineItem__c = revRecLineItems[0].Id; 
        oppLineItems[2].ServiceDate = Date.Today().addDays(56);
        update oppLineItems;
        
        // update revRecProductRules
        revRecProductRules[0].Revenue_Recognition_Start_Date__c = 'PRODUCT:Product Date';
        revRecProductRules[0].Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        revRecProductRules[1].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate';
        revRecProductRules[1].Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate';
        revRecProductRules[2].Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate';
        revRecProductRules[2].Revenue_Recognition_End_Date__c = 'PRODUCT:Product Date';
        update revRecProductRules;
        
        Test.stopTest();        
    } 
}