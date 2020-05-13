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
 *	Description		:	This class is used to test the functionality of Batch_RunRuleAssignmentsForOpportunity.
 *
 *	Created Date	:	05/31/2016
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0 - Created
 *
 *	Coverage		:	100%
**/
@isTest(seeAllData=false) 
public with sharing class Batch_RunAsignmentForOpportunityTest {
    
    @testSetup static void setup() {
    	
    	//Test data of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2, Offset_Type__c = 'Start', 
        								   Default_Rule__c = true, Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));                                                          
        insert  revRecRules;
        
        //Test data of rule assignment
        List<Rule_Assignment__c> ruleAssignments = new List<Rule_Assignment__c>();
        ruleAssignments.add(new Rule_Assignment__c(Name = 'Test rule assignment', RevRecRule__c = revRecRules[0].Id));
        insert ruleAssignments;
        
        //Test data of opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test 1', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 2', CloseDate = Date.Today().addDays(2), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 2', CloseDate = Date.Today().addDays(3), StageName = 'Open', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 2', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        insert opportunities;
        
    }
    
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
    	
    	//Set of 
        Set<String> setOfOpportunityIds = new Set<String>();
        
        //List of opportunity query result
        List<Opportunity> listOfOpportunityInserted = [Select Id, Name from Opportunity ];
       	
       	//Assert
       	System.assertEquals(4,listOfOpportunityInserted.size());
       	
       	//Add Opportunities ids into set
       	setOfOpportunityIds.add(listOfOpportunityInserted[0].Id);
       	setOfOpportunityIds.add(listOfOpportunityInserted[1].Id);
       	
        //Batch execute
    	Batch_RunAsignmentForOpportunity batch = new Batch_RunAsignmentForOpportunity(setOfOpportunityIds, listOfRules[0].Id, listOfRuleAssignment[0].Id, 'IN');
    	DataBase.executeBatch(batch);
	   	
	   	//Test stop
        Test.stopTest();
        
        //Fetching opportunity
        listOfOpportunityInserted = [Select Id, REVvue_RevRecRule__c, REVvue_RuleAssignment__c from Opportunity where Id IN: setOfOpportunityIds];
        
        //Assert
        System.assertEquals(listOfRules[0].Id, listOfOpportunityInserted[0].REVvue_RevRecRule__c);
        System.assertEquals(listOfRuleAssignment[0].Id,listOfOpportunityInserted[0].REVvue_RuleAssignment__c);
        
        listOfOpportunityInserted = [Select Id, REVvue_RevRecRule__c, REVvue_RuleAssignment__c from Opportunity where Id NOT IN: setOfOpportunityIds];
        
        //Assert
        System.assertEquals(null, listOfOpportunityInserted[0].REVvue_RevRecRule__c);
        System.assertEquals(null,listOfOpportunityInserted[0].REVvue_RuleAssignment__c);
        
    }
    
    static testMethod void myUnitTest1() {
    
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
    	
    	//Set of 
        Set<String> setOfOpportunityIds = new Set<String>();
        
        //List of opportunity query result
        List<Opportunity> listOfOpportunityInserted = [Select Id, Name from Opportunity ];
       	
       	//Assert
       	System.assertEquals(4,listOfOpportunityInserted.size());
       	
       	//Add Opportunities ids into set
       	setOfOpportunityIds.add(listOfOpportunityInserted[0].Id);
       	setOfOpportunityIds.add(listOfOpportunityInserted[1].Id);
       	
        //Batch execute
    	Batch_RunAsignmentForOpportunity batch = new Batch_RunAsignmentForOpportunity(setOfOpportunityIds, listOfRules[0].Id, listOfRuleAssignment[0].Id, 'NOT IN');
    	DataBase.executeBatch(batch);
	   	
	   	//Test stop here
        Test.stopTest();
        
        //Query list of opportunity
        listOfOpportunityInserted = [Select Id, REVvue_RevRecRule__c, REVvue_RuleAssignment__c from Opportunity where Id IN: setOfOpportunityIds];
        
        //Assert
     	System.assertEquals(null, listOfOpportunityInserted[0].REVvue_RevRecRule__c);
        System.assertEquals(null,listOfOpportunityInserted[0].REVvue_RuleAssignment__c);
        
        //Query list of opportunity
        listOfOpportunityInserted = [Select Id, REVvue_RevRecRule__c, REVvue_RuleAssignment__c from Opportunity where Id NOT IN: setOfOpportunityIds];
        
        //Assert
       	System.assertEquals(listOfRules[0].Id, listOfOpportunityInserted[0].REVvue_RevRecRule__c);
        System.assertEquals(listOfRuleAssignment[0].Id,listOfOpportunityInserted[0].REVvue_RuleAssignment__c);
    }
}