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
@isTest(seeAllData= false)
private class Test_RuleToProductLineAssignmentControll {
/**
 *	Description		:	This method is used to test the RuleToProductLineAssignmentController.
 *
 *	Created Date	:	09/24/2015
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0 - Created
 *
 *	Coverage		:	100%
**/
	
	/** @description	: This method is used to test the RuleToProductLineAssignmentController functionality. **/	
    static testMethod void testRuleToProductLineAssignmentController() {
       
       //List of Product line
       List<RevRecProductFamilySetting__c> familySettings = new List<RevRecProductFamilySetting__c>();
       
       //Add records into list
       familySettings.add(new RevRecProductFamilySetting__c(Name='Hardware'));
       familySettings.add(new RevRecProductFamilySetting__c(Name='Software'));
       familySettings.add(new RevRecProductFamilySetting__c(Name='Tax'));
       familySettings.add(new RevRecProductFamilySetting__c(Name='MFG'));
       
       insert familySettings;
       
       //List of product to be inserted 
       List<Product2> products = new  List<Product2>();
       products.add(new Product2(IsActive = true, Name = 'Test-1' , Family = 'Hardware'));
       products.add(new Product2(IsActive = true, Name = 'Test-2' , Family = 'Software'));
       products.add(new Product2(IsActive = true, Name = 'Test-3' , Family = 'Tax'));
       products.add(new Product2(IsActive = true, Name = 'Test-4' , Family = 'MFG'));
       products.add(new Product2(IsActive = true, Name = 'Test-5' ));
       
       insert products;
       
       //List of Rules
       List<RevRecRules__c> revRecRules = new  List<RevRecRules__c>();
       
       //Add rules into list
       revRecRules.add(new RevRecRules__c(Name = 'Test-1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2, Offset_Type__c = 'Start',
                          									  Default_Rule__c = true, Recognition_Type__c = 'Amortize'));
       revRecRules.add(new RevRecRules__c(Name = 'Test-2', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2, Offset_Type__c = 'Start',
                          									  Default_Rule__c = true, Recognition_Type__c = 'Amortize'));
       
       //Insert rules
       insert  revRecRules;
       
       //Initilize constructer
       RuleToProductLineAssignmentController controller = new RuleToProductLineAssignmentController();
       
       //Assert for results
       System.assertEquals(4, controller.productFamilyRules.size());
       
       //Assign rules on Product families
       controller.productFamilyRules[0].RevRecRule__c = revRecRules[0].Id;
       controller.productFamilyRules[2].RevRecRule__c = revRecRules[1].Id;
       
       //Calling controller method
       controller.doSave();
       //Query on products
       products = [Select Id, Name , RevRecRule__c From Product2 Where ID IN : products];
       
       //Assert for results
       System.assertEquals(revRecRules[0].Id, products[0].RevRecRule__c);
       System.assertEquals(revRecRules[1].Id, products[1].RevRecRule__c);
       
       //Controller inIt
       	//controller.inIt();
        controller.blankMethod();
        RuleToProductLineAssignmentController.queryRules('Test');
        RuleToProductLineAssignmentController.queryRules(null);
        
    }
}