/**
 *   Purpose         :   This test class is used to test all functionality of Batch_UpdateMilestoneDateString
 *               
 *   Created By      :   Bill Feehaley
 *   
 *   Created Date    :   12/20/2016
 *   
 *   Revision Logs   :   V_1.0 - Created
 *                       
 **/
@IsTest(SeeAllData=false)
public class Batch_UpdateRuleCategoryDateStringTest {
    
    /**
     * This method is used to test batch class
     **/
     @isTest 
     public static void testBatch_UpdateMilestoneDateString() {
        
        List<RevRecRuleCategory__c>  ruleCategories= new List<RevRecRuleCategory__c>();
        ruleCategories.add(new RevRecRuleCategory__c(Category_Start_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate' , Category_End_Date__c = 'OPPORTUNITY PRODUCT:ServiceDate'));
        ruleCategories.add(new RevRecRuleCategory__c(Category_Start_Date__c = 'PRODUCT:ServiceDate' , Category_End_Date__c = 'PRODUCT:ServiceDate'));
        ruleCategories.add(new RevRecRuleCategory__c(Category_Start_Date__c = 'OPPORTUNITYAppRopozSLN__End_Revenue_Date__c' , Category_End_Date__c = 'OPPORTUNITYAppRopozSLN__End_Revenue_Date__c'));
        insert ruleCategories;
         
        //Calling start method
        Test.startTest();

        //Instance of Batch_UpdateOldRuleStartAndEndDate Batch class 
        Batch_UpdateRuleCategoryDateString ruleCategory =new Batch_UpdateRuleCategoryDateString();
    
        //Execute batch
        DataBase.executebatch(ruleCategory);
        
        //Calling start method to stop batch
        Test.stopTest();
        
        //Query on Category
        ruleCategories= [select Id, Category_Start_Date__c, Category_End_Date__c from RevRecRuleCategory__c];
         
        System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate', ruleCategories[1].Category_Start_Date__c);
        System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate', ruleCategories[1].Category_End_Date__c);
     }
}