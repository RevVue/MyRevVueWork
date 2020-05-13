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
private class Test_Batch_UpdateHistoricalRuleMilestone {
/**
  *    Description    :		This Test class check functionality batch to update historiacal Milestone_Date_Source__c
  *  
  *    Created By     :    
  *
  *    Created Date   :		01/20/2015
  *
  *    Version        :		V1.0
  *
  *    Revisison Log  :		V1.0 - 01/20/2015 - Created
  *
  *    Coverage       :		100%	
**/	
	
	//Method to test the functionality of Batch_UpdateHistoricalRuleMilestone
	static testMethod void myUnitTest() {
		
		//Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                       AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1', Time_of_Month_Selection_Types__c = '2');
                                       
        insert appSetting;
        
        //List of Default Rule
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        revRecRules.add(new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                        AppRopozSLN__Offset_Period__c = 2, AppRopozSLN__Offset_Type__c = 'Start', Default_Rule__c = true,
                                        Recognition_Type__c = 'Milestone'));
                                        
        revRecRules.add(new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                        AppRopozSLN__Offset_Period__c = 2, AppRopozSLN__Offset_Type__c = 'Start', Default_Rule__c = true,
                                        Recognition_Type__c = 'Milestone'));
                                        
                                                                    
        insert  revRecRules;
        
        //List of Rule Milestones
        List<RevRecRuleMilestone__c> milestones = new List<RevRecRuleMilestone__c>();
        milestones.add(new RevRecRuleMilestone__c(Name = 'Test' , RevRecRule__c = revRecRules[0].Id));
        milestones.add(new RevRecRuleMilestone__c(Name = 'Test' , RevRecRule__c = revRecRules[1].Id));
         
         insert milestones;
         
         //Test start from here 
         Test.startTest();
         
         //Batch initilization and calling batch
		 Batch_UpdateHistoricalRuleMilestones  bc = new Batch_UpdateHistoricalRuleMilestones();
		 Database.executeBatch(bc, 10);
         
         //Test stops here
         Test.stopTest();
         
         //Assert for results
         milestones = [Select Milestone_Date_Source__c From RevRecRuleMilestone__c WHERE ID IN: milestones];
         system.assertEquals(constants.MILESTONE_DATE_MANUAL, milestones[0].Milestone_Date_Source__c);
         system.assertEquals(constants.MILESTONE_DATE_MANUAL, milestones[1].Milestone_Date_Source__c);
	}	
}