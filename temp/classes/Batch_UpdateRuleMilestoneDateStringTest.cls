/**
 *   Purpose         :   This test class is used to test all functionality of Batch_UpdateRuleMilestoneDateString
 *               
 *   Created By      :   Bill Feehaley
 *   
 *   Created Date    :   12/20/2016
 *   
 *   Revision Logs   :   V_1.0 - Created
 *                       
 **/
@isTest(SeeAllData=false)
public class Batch_UpdateRuleMilestoneDateStringTest {

	/**
     * This method is used to test batch class
     **/
     @isTest 
     public static void testBatch_UpdateMilestoneDateString() {
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2',  Offset_Period__c = 2, Offset_Type__c = 'Start',
                                                              Default_Rule__c = true, Recognition_Type__c = 'Amortize', Period__c = 'Monthly');
        insert  revRecDefaultRule;
        
        //Milestone data
       	List<RevRecRuleMilestone__c>  milestones= new List<RevRecRuleMilestone__c>();
        milestones.add(new RevRecRuleMilestone__c(Milestone_Date_Source__c = 'OPPORTUNITY PRODUCT:ServiceDate' , Milestone_Date_Source_Label__c = 'OPPORTUNITY PRODUCT:ServiceDate', RevRecRule__c = revRecDefaultRule.Id));
        milestones.add(new RevRecRuleMilestone__c(Milestone_Date_Source__c = 'PRODUCT:ServiceDate' , Milestone_Date_Source_Label__c = 'PRODUCT:ServiceDate', RevRecRule__c = revRecDefaultRule.Id));
        milestones.add(new RevRecRuleMilestone__c(Milestone_Date_Source__c = 'OPPORTUNITYAppRopozSLN__End_Revenue_Date__c' , Milestone_Date_Source_Label__c = 'OPPORTUNITYAppRopozSLN__End_Revenue_Date__c', RevRecRule__c = revRecDefaultRule.Id));
        insert milestones;
         
        //Calling start method
        Test.startTest();

        //Instance of Batch_UpdateOldRuleStartAndEndDate Batch class 
        Batch_UpdateRuleMilestoneDateString ruleMilestone =new Batch_UpdateRuleMilestoneDateString();
    
        //Execute batch
        DataBase.executebatch(ruleMilestone);
        
        //Calling start method to stop batch
        Test.stopTest();
        
        //Query on Category
        milestones= [select Id, Milestone_Date_Source__c, Milestone_Date_Source_Label__c from RevRecRuleMilestone__c];
         
        System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate', milestones[1].Milestone_Date_Source__c);
        System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate', milestones[1].Milestone_Date_Source_Label__c);
     }    
}