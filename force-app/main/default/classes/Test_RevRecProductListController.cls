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
private class Test_RevRecProductListController {
/**
 *	Description		:	This class is used to test the RevRecProductListController functionality.
 *
 *	Created Date	:	09/03/2015
 *
 *	Version			:	V_1.0
 *
 *	Revision log	:	V_1.0 - Created
 *
 *	Coverage		:	100% 
**/
    static testMethod void myUnitTest() {
    	
    	//List of RevRecRule
    	List<RevRecRules__c> defaultRules = new List<RevRecRules__c>();    	
    	
    	//Add rules into list
    	defaultRules.add(new RevRecRules__c(Name = 'Rule - 1'));
    	defaultRules.add(new RevRecRules__c(Name = 'Rule - 2'));
    	
    	//Insert rules
    	insert defaultRules;
    	
    	//List of product
    	List<Product2> products = new List<Product2>();
    	
     	//Loop to add bulk records
    	for(Integer i= 0;i<5 ; i++) {
	    	
	    	//Add products into list
	    	products.add(new Product2(Name = 'Test Product-1', isActive = true));
	    	products.add(new Product2(Name = 'Genwat-1', isActive = true));
	    	products.add(new Product2(Name = 'Propen-1', isActive = true));
	    	products.add(new Product2(Name = 'Test Product-3', isActive = true));
	    	products.add(new Product2(Name = 'Product 2',isActive = true));
	    	products.add(new Product2(Name = 'Test-1', isActive = true));
    	}
    	
    	//Insert products
    	insert products;
    	
    	//Constructer
    	RevRecProductListController  controller =  new RevRecProductListController();
    	
    	//Assert for results
    	system.assertEquals(20, controller.productsList.size());
    	
    	//Set controller variable
    	controller.searchString = 'Test';
    	
    	//Calling controller method
    	controller.doSearch();
    	
    	//Assert for results
    	system.assertEquals(15, controller.productsList.size());
    	
    	controller.previous();
    	controller.next();
    	controller.First();
    	controller.Last();
    	controller.getPreviousButtonDisabled();
    	controller.getNextButtonDisabled();
        
        controller.productsList[0].product.RevRecRule__c = defaultRules[0].Id;
        controller.productsList[1].product.RevRecRule__c = defaultRules[0].Id;
        controller.productsList[2].product.RevRecRule__c = defaultRules[0].Id;
    	controller.saveResults(); 
    	
    	//Assert for results
    	List<Product2> productResults = [Select Id, RevRecRule__c From Product2 Where ID IN: products AND  RevRecRule__c != null];
    	system.assertEquals(3, productResults.size());    		
    }
}