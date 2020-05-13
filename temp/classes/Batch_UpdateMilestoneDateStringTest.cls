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
 public class Batch_UpdateMilestoneDateStringTest {
    
    /**
	 * This method is used to test batch class
	 **/
    @isTest 
     public static void testMilesetupData() {
         //Test Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-23), StageName = 'Closed Won', 
                                                  Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test', CloseDate = Date.Today().addDays(-23), StageName = 'Closed Lost', 
                                                  Type = 'Existing Business'));                                               
        insert opportunities;
         //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportunities[0].Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportunities[0].Id, ResidualAmount__c = 100,
                                                             DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
		
		//Product override rule
        List<RevRecProductRule__c> revRecProductRules = new  List<RevRecProductRule__c>();
        revRecProductRules.add( new RevRecProductRule__c(  End_Date__c = Date.Today().addYears(1), Residual_Amount__c = 4000, RevRecOpportunityLineItem__c = revRecLineItems[0].Id,
                                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
                                                           Milestone_Type__c = 'amount', Start_Date__c = Date.Today(),
                                                           /*Amortize_By__c = 'amount',*/ Offset_Period__c = 1,
                                                           Offset_Type__c = 'Start'));
                                                                         
        insert   revRecProductRules;         
	
		List<RevRecProductRuleMilestone__c>  milestones= new List<RevRecProductRuleMilestone__c>();
         milestones.add(new RevRecProductRuleMilestone__c(Milestone_Date_Source__c = 'OPPORTUNITY PRODUCT:ServiceDate' , Milestone_Date_Source_Label__c = 'OPPORTUNITY PRODUCT:ServiceDate', RevRecProductRule__c = revRecProductRules[0].ID));
         milestones.add(new RevRecProductRuleMilestone__c(Milestone_Date_Source__c = 'PRODUCT:ServiceDate' , Milestone_Date_Source_Label__c = 'PRODUCT:ServiceDate', RevRecProductRule__c = revRecProductRules[0].ID));
         milestones.add(new RevRecProductRuleMilestone__c(Milestone_Date_Source__c = 'OPPORTUNITY:AppRopozSLN__End_Revenue_Date__c' , Milestone_Date_Source_Label__c = 'OPPORTUNITYAppRopozSLN__End_Revenue_Date__c', RevRecProductRule__c = revRecProductRules[0].ID));
         insert milestones;
         
         // Calling start method to start batch
		 Test.startTest();

		// instance of Batch_UpdateOldRuleStartAndEndDate Batch class 
		Batch_UpdateMilestoneDateString milestonebatch =new Batch_UpdateMilestoneDateString();

		// Execute batch
		DataBase.executebatch(milestonebatch);
        
         // Calling start method to stop batch
         Test.stopTest();
         
         //Query on RevRecRules__c
         milestones = [select Id,Milestone_Date_Source__c ,Milestone_Date_Source_Label__c from RevRecProductRuleMilestone__c];
         
         System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate',milestones[1].Milestone_Date_Source_Label__c);
         System.assertEquals('OPPORTUNITY PRODUCT:ServiceDate',milestones[1].Milestone_Date_Source__c);
         
	}
}