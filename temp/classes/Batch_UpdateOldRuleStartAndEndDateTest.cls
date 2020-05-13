/**
 *   Purpose         :   This test class is used to test all functionality of Batch
 *               
 *   Created By      :   
 *   
 *   Created Date    :   12/20/2016
 *   
 *   Revision Logs   :   V_1.0 - Created
 *                       
 **/
@IsTest(SeeAllData=false)
public class Batch_UpdateOldRuleStartAndEndDateTest {

	/**
	 * This method is used to test batch class
	 **/
    @isTest 
     public static void testSetUpData() {

        //List of RevRecRules__c
        List<RevRecRules__c> rules = new List<RevRecRules__c>();
        rules.add(new RevRecRules__c(Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate' , Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate'));
        rules.add(new RevRecRules__c(Revenue_Recognition_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate' , Revenue_Recognition_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate'));
        rules.add(new RevRecRules__c(Revenue_Recognition_End_Date__c = 'PRODUCT:ServiceDate' , Revenue_Recognition_Start_Date__c = 'PRODUCT:ServiceDate'));
        rules.add(new RevRecRules__c(Revenue_Recognition_End_Date__c = 'OPPORTUNITYAppRopozSLN__End_Revenue_Date__c' , Revenue_Recognition_Start_Date__c = 'OPPORTUNITYAppRopozSLN__End_Revenue_Date__c'));
        rules.add(new RevRecRules__c(Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate' , Revenue_Recognition_Start_Date__c = 'OPPORTUNITY:CloseDate'));
        
         ///Insert RevRecRules__c
         insert rules;
        
        // Calling start method to start batch
		Test.startTest();

		// instance of Batch_UpdateOldRuleStartAndEndDate Batch class 
		Batch_UpdateOldRuleStartAndEndDate rulesbatch = new Batch_UpdateOldRuleStartAndEndDate();

		// Execute batch
		DataBase.executebatch(rulesbatch);
         
         // Calling start method to stop batch
         Test.stopTest();
         
         //Query on RevRecRules__c
         rules= [select Id,Revenue_Recognition_End_Date__c ,Revenue_Recognition_Start_Date__c from RevRecRules__c];
         
         System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate',rules[2].Revenue_Recognition_End_Date__c);
         System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate',rules[2].Revenue_Recognition_Start_Date__c);
    }
}