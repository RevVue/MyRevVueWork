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
private class Test_Batch_UpdateHistoricalRevRecRule {
/**
  *    Description    :		This Test class check functionality batch to update historiacal Milestone type 
  *  
  *    Created By     :  	  
  *
  *    Created Date   :		05/14/2015
  *
  *    Version        :		V1.0
  *
  *    Revisison Log  :		V1.0 - 05/14/2015 - Created
  *
  *    Coverage       :		100%
**/
    static testMethod void myUnitTest() {
    	
    	//App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', 
                                                                                           Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1',
                                                                                           Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                                    AppRopozSLN__Offset_Period__c = 2,
                                                                    AppRopozSLN__Offset_Type__c = 'Start',
                                                                    Default_Rule__c = true,
                                                                    Recognition_Type__c = 'Milestone');
                                                                    
        insert  revRecDefaultRule;
        
         //Test starts here
        Test.startTest();
        
        Batch_UpdateHistoricalRevRecRule bc = new Batch_UpdateHistoricalRevRecRule();
        Database.executeBatch(bc, 10);
        
        //Test stop here
        Test.stopTest();
        
        revRecDefaultRule = [Select ID, Milestone_Type__c From RevRecRules__c];
        
        //Assert for results
        System.assertEquals('percent' , revRecDefaultRule.Milestone_Type__c);

	}
}