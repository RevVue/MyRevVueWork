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
 *	Description		:	This class is used to test the functionality of Batch_RunRuleAssignmentForProducts.
 *
 *	Created Date	:	05/13/2016
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0-Created
 *
 *	Coverage		:	100%
**/
@isTest(seeAllData=false)
private class Batch_RunRuleAssignmentForProductsTest {

	/**
 	 *	This method is used to test the functionality of Batch_RunRuleAssignmentForProducts.
	**/
    static testMethod void myUnitTest() {
    	
    	//RevRec Rule
    	List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
    	
    	//Adding records into list
    	revRecRules.add(new RevRecRules__c(Name = 'Test-1', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                   											  Default_Rule__c = true, Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE));
    	revRecRules.add(new RevRecRules__c(Name = 'Test-2', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                   											  Default_Rule__c = true, Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE));
    	
        insert  revRecRules;
    	
        //Adding records into list
        List<Rule_Assignment__c> ruleAssignments = new List<Rule_Assignment__c>();
        ruleAssignments.add(new Rule_Assignment__c(Name = 'test rule assignment', RevRecRule__c = revRecRules[0].Id));
        insert ruleAssignments;
        
    	//List of products 
    	List<Product2> products = new List<Product2>();
    	products.add(new Product2(Name = 'Test' , Family = 'Hardware'));
    	products.add(new Product2(Name = 'Test' , Family = 'Software'));
    	products.add(new Product2(Name = 'Test' , Family = 'MFG'));
    	products.add(new Product2(Name = 'Test' , Family = 'Test'));
    	
    	insert products;
    	
    	///Test strats here 
    	Test.startTest();
    	 
    	Batch_RunRuleAssignmentForProducts bc = new Batch_RunRuleAssignmentForProducts(new Set<String>{products[0].Id,products[1].Id},
    								new Set<String>{'Hardware'} , 'IN', 'IN', revRecRules[0].Id, ruleAssignments[0].Id);
    	Database.executeBatch(bc, 20);
    	
    	//Test stop here
    	Test.stopTest();
    	
    	//Assert for results
    	products = [Select Id, Name , RevRecRule__c From Product2 Where ID IN : products AND RevRecRule__c != null];
    	System.assertEquals(1, products.size());
    	System.assertEquals(revRecRules[0].Id, products[0].RevRecRule__c);
    }
}