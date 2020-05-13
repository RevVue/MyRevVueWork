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
 *	Description		:	This class is used to test the functionality of Batch_UpdateAMMilesRules
 *
 *	Created Date	:	12/05/2016
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0-Created
 *
 *	Coverage		:	100%
**/
@isTest(seeAllData=false)
private class Batch_UpdateAMMilesRulesTest {

	/**
	 *	@description	:	This method is used to test the functionality of Batch_UpdateAMMilesRules.
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
        
        //RevRecRule milestone
        List<RevRecRuleMilestone__c> ruleMilestones = new List<RevRecRuleMilestone__c>();
        ruleMilestones.add(new RevRecRuleMilestone__c(Name = 'Test1',Milestone_Name__c='Test 2',RevRecRule__c = revRecRules[0].Id));
        ruleMilestones.add(new RevRecRuleMilestone__c(Name = 'Test1',Milestone_Name__c='Test 2',RevRecRule__c = revRecRules[0].Id));
        ruleMilestones.add(new RevRecRuleMilestone__c(Name = 'Test1',Milestone_Name__c='Test 2',RevRecRule__c = revRecRules[1].Id));
        ruleMilestones.add(new RevRecRuleMilestone__c(Name = 'Test1',Milestone_Name__c='Test 2',RevRecRule__c = revRecRules[1].Id));
        
        insert ruleMilestones;
        
        //Test start here
        Test.startTest();
        
        //Execute batch
        Batch_UpdateAMMilesRules bc = new Batch_UpdateAMMilesRules();
        Database.ExecuteBatch(bc, 10);
        
        //Test stop here
        Test.stopTest();
        
        //Assert for results
        ruleMilestones = [Select Id From RevRecRuleMilestone__c where ID IN : ruleMilestones];
        System.assertEquals(0, ruleMilestones.size());
    }
}