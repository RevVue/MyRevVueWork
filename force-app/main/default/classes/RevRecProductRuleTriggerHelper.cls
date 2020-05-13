/**
 *  Purpose         :   This is helper class for Trigger on RevRecProductRule to performing all Post and Pre logic.
 *
 *  Created By      :   
 *
 *  Created Date    :   11/07/2014
 *
 *  Current Version :   V1.0
 *
 *  Revision Log    :   V1.0 - Created
 **/
public without sharing class RevRecProductRuleTriggerHelper {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRevRecOLIResult = Utility.getFieldPermissions('RevRecOpportunityLineItem__c');
    
     /**
     *  @description    :   Method responsible When a product rules's start and end date  is changed , then deleting old milestones creating
     *                      new milestones according to month difference between Start and end date
     *
     *  @args           :   List<RevRecProductRule__c> newProductRule, Map<Id, RevRecProductRule__c> mapOldProductRule
     * 
     *  @return         :   void
     * 
     **/
    /*
    public static void createMileStoneOnDateChanege(List<RevRecProductRule__c> newProductRule, Map<Id, RevRecProductRule__c> mapOldProductRule) {
        
        //Code modified -  (01/08/2015) - Boolean variable to hold that multiCurrency enabled in org or not
        Boolean isMultiCurrencyEnabled =  UserInfo.isMultiCurrencyOrganization();
        
        //Set to hold the RevRecID
        Set<Id> revRecOppLineItemIds = new Set<Id>();
        
        //set to hold the RuleId
        Set<Id> productRuleId  = new Set<Id>();
            
        //List of Schedule
        List<RevRecOpportunityLineItemSchedule__c> allSch = new List<RevRecOpportunityLineItemSchedule__c>();
        
        //List Of Rule
        List<RevRecProductRule__c> revProductRules = new List<RevRecProductRule__c>();
        
        //Map of milestones
        Map<id, List<RevRecProductRuleMilestone__c>> revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
            
        //String to hold opprtunity id
        String oppId;
         
        //Lopp through Trigger.new
        for(RevRecProductRule__c productRule : newProductRule) {
        	
        	System.debug(Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE + '######################');
            
            //checking if start and end date is changed only
            if(string.isNotBlank(productRule.Recognition_Type__c) && productRule.Start_Date__c != null  && productRule.End_Date__c != null 
               && (mapOldProductRule == null || (mapOldProductRule.get(productRule.Id).Start_Date__c != productRule.Start_Date__c ||
                                                 mapOldProductRule.get(productRule.Id).End_Date__c != productRule.End_Date__c || 
                                                 mapOldProductRule.get(productRule.Id).Divide_By__c != productRule.Divide_By__c || 
                                                 mapOldProductRule.get(productRule.Id).Period_or_Exact_Days__c != productRule.Period_or_Exact_Days__c || 
                                                 mapOldProductRule.get(productRule.Id).Initial_Amount__c != productRule.Initial_Amount__c || 
               									 mapOldProductRule.get(productRule.Id).Initial_Amount_Type__c != productRule.Initial_Amount_Type__c || 
               									 mapOldProductRule.get(productRule.Id).Offset_Period__c != productRule.Offset_Period__c || 
               									 mapOldProductRule.get(productRule.Id).Offset_Type__c != productRule.Offset_Type__c || 
    		   									 mapOldProductRule.get(productRule.Id).Residual_Amount__c != productRule.Residual_Amount__c || 
    		   									 mapOldProductRule.get(productRule.Id).Residual_Amount_Type__c != productRule.Residual_Amount_Type__c ||
    		   									 Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE
    		   									 ))) {
                                    
                //Add ids into set
                revRecOppLineItemIds.add(productRule.RevRecOpportunityLineItem__c);
                productRuleId.add(productRule.Id);  
                revProductRules.add(productRule);
            }
        }

        //checking for size 
        if(revRecOppLineItemIds.size() > 0) {
            
            //Check for null and queery through Milestones to be delete
            if(productRuleId.size() > 0) {
                
                for(RevRecProductRuleMilestone__c proMiles : [Select Id, Name, RevRecProductRule__c, RevRecProductRule__r.Recognition_Type__c  
                                                              From RevRecProductRuleMilestone__c 
                                                              WHERE RevRecProductRule__c IN :productRuleId 
                                                              AND RevRecProductRule__r.Recognition_Type__c !=: Constants.RULE_RECOGNITION_TYPE_MILESTONE]) {
					
          			if(!revRecProductRuleMilestonesMap.containsKey(proMiles.RevRecProductRule__c))
                        revRecProductRuleMilestonesMap.put(proMiles.RevRecProductRule__c, new List<RevRecProductRuleMilestone__c>{proMiles});
               		else
                        revRecProductRuleMilestonesMap.get(proMiles.RevRecProductRule__c).add(proMiles);                  
				} 
            }
            
            //Query through line items 
            List<OpportunityLineItem> lineItems = [SELECT Id, Name , OpportunityId, RevRecOpportunityLineItem__r.Id, TotalPrice,Quantity, Rule_Assignment__c, RevRecRule__c,
                                                        RevRecOpportunityLineItem__r.OpportunityLineItemId__c, RevRecOpportunityLineItem__r.TotalRev__c,
                                                        RevRecOpportunityLineItem__r.ProductName__c From OpportunityLineItem 
                                                        WHERE RevRecOpportunityLineItem__c != null AND RevRecOpportunityLineItem__c IN : revRecOppLineItemIds];
            
            List<RevRecOpportunityLineItem__c> revRecs = new List<RevRecOpportunityLineItem__c>();
                
            //Query through line items 
            if(lineItems.size() > 0)
                revRecs = [SELECT Id, OpportunityLineItemId__c,TotalRev__c,DeferredRev__c,RecognizedRev__c, Rule_Assignment__c, RevRecRule__c,
                           CalculatedAt__c,ResidualAmount__c,ProductName__c,Opportunity__c 
                           From RevRecOpportunityLineItem__c 
                           WHERE ID IN :revRecOppLineItemIds AND OpportunityLineItemId__c =: lineItems[0].Id];
                          
            //Query through schedules  to be deleted
            List<RevRecOpportunityLineItemSchedule__c> schedules  = new List<RevRecOpportunityLineItemSchedule__c>();
            
            if(revRecs.size() > 0)
            	 schedules = [Select id from RevRecOpportunityLineItemSchedule__c WHERE RevRecOpportunityLineItem__c=:revRecs[0].id];
                                                                    
          	//checking for list size                                         
            if(schedules.size() >0)                                                     
                delete schedules;                                                       
             
            // checking for null
            if(lineItems.size() >0 && lineItems[0].OpportunityId != null)                                   
                oppId = lineItems[0].opportunityId;
            
            //Code modified -  (1/8/2015) - Check if multi currency enabled then do this
            //Creating dynamic query
            String query = '';
            query += 'SELECT Id, StageName, Type, CloseDate, isWon, isClosed, Probability, REVvue_CurrencyType__c';
            
            //Checking if multi currency enabled
            if(isMultiCurrencyEnabled)
                query += ', CurrencyIsoCode ';
            
            query += ' From Opportunity WHERE ID =: oppId';
            List<Opportunity> opps = database.query(query); 
            
            //Code added - 06/18/2015 -  As per Blended Revenue Recognition 
    		Map<Id, List<RevRecProductRuleCategory__c>> mapLineItemWithProductCategory = new  Map<Id, List<RevRecProductRuleCategory__c>>();
            
            //stage
            OpportunityStage theStage = null;
            
            List<OpportunityStage>  stageList = new List<OpportunityStage>();
            
            if(opps.size() > 0)
            	stageList = [select Id, Description, MasterLabel FROM  OpportunityStage WHERE MasterLabel = :opps[0].StageName];
        
            if(stageList.size() > 0)
                theStage = stageList[0];
                 
            //Cheking for null
            if(String.isNotBlank(oppId)) {
                try {
                    RevRecUtil util = new RevRecUtil();
                    RevRecUtilHelper utilHelper = new RevRecUtilHelper();
                    //Calling method to create new milestone records 
                    utilHelper.Cleanup();
                    util.EvaluateRevRecSchedule(opps[0], lineItems, revRecs, allSch, theStage, revProductRules, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);

                    //Checking for list size
                    if(allSch.size() >0)
                        insert allsch; 
                        
                    Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE = false;
                        
                } catch (Exception exp) {
                    System.debug(exp);
                }
            }   
        }          
    }
    */
    /**
     *  @description    :   Method responsible to remove overriden rule id from oli when a overriden rule is deleted.
     *
     *  @args           :   List<RevRecProductRule__c> oldRevRecProductRules
     * 
     *  @return         :   void
     **/
    public static void deleteRuleTypeFromOpportunityLIneItem(List<RevRecProductRule__c> oldRevRecProductRules) {
        
        //Check if, old list has no value
        if(oldRevRecProductRules != null) {
            
            //Set to hold RevRecOpportunityLineItem id's
            Set<Id> setRevRecOLIs = new Set<Id>();
            
            //Loop over RevRecProductRule
            for(RevRecProductRule__c rrpr : oldRevRecProductRules)
                setRevRecOLIs.add(rrpr.RevRecOpportunityLineItem__c);//Adding id's in set 
            
            //Query to fetch opportunityLineItem 
            List<OpportunityLineItem> olis = [Select Id, Overriden_Rule_Assignment_Id__c from OpportunityLineItem where RevRecOpportunityLineItem__c =: setRevRecOLIs];
            
            //Check if list has no value 
            if(olis.size() > 0) {
                
                //Loop over OpportunityLineItem
                for(OpportunityLineItem oli : olis) {
                
                	oli.Overriden_Rule_Assignment_Id__c = '';//Setting '' in oli field
                	oli.Overridden_Rule__c = '';	
                }
                
                //updating oli list
                update olis;
            }
        }
    }
    
    /**
     *  @description    :   Method responsible to remove overriden rule id from oli when a overriden rule is deleted.
     *
     *  @args           :   List<RevRecProductRule__c> newProRules
     * 
     *  @return         :   void
     **/
    public static void overriddenRuleCal(List<RevRecProductRule__c> newProRules) {
        
    	String msg = '';
        String oppId = '';
        Boolean isMileStoneRule = false;
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
    
        if(newProRules.size() != 1) {
            RevRecHelper.SendEmail('Multiple Override rules for override Trigger');
            return;
        }else { 
            
            RevRecProductRule__c overrideRule = [SELECT Id, name, Divide_By__c, initial_amount__c, initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, 
                                                 Period_or_Exact_Days__c, Recognition_Type__c,  Milestone_Type__c, Residual_Amount__c, Residual_Amount_Type__c, Start_Date__c, End_Date__c,  Total_Period__c, RevRecOpportunityLineItem__c,
                                                 (SELECT ID, Milestone_Name__c, Milestone_Sequence__c, Percent__c, Milestone_Date__c, RevRecProductRule__c  
                                                 FROM RevRecProductRuleMilestones__r ORDER BY Milestone_Sequence__c)  
                                                 FROM RevRecProductRule__c WHERE id = : newProRules[0].Id];
            
            if (overrideRule != null && (overrideRule.Recognition_Type__c == 'Milestone' 
                                         || overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE 
                                         || overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE )){
            	isMileStoneRule = true;
             }                       
            
            //Check if multi currency enabled then do this
            List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
            string query = '';
            query += 'SELECT Id, OpportunityId, '
                +'RevRecOpportunityLineItem__r.Id, '
                +'RevRecOpportunityLineItem__r.OpportunityLineItemId__c, '
                +'RevRecOpportunityLineItem__r.TotalRev__c, '
                +'RevRecOpportunityLineItem__r.DeferredRev__c, '
                +'RevRecOpportunityLineItem__r.RecognizedRev__c, '
                +'RevRecOpportunityLineItem__r.CalculatedAt__c, '
                +'RevRecOpportunityLineItem__r.ResidualAmount__c,'
                +'RevRecOpportunityLineItem__r.ProductName__c ' ;
            
            //If multi currency enabled
            if(isMultiCurrencyEnabled)
                query += ' , CurrencyIsoCode ';
            
            String revrecId = overrideRule.RevRecOpportunityLineItem__c;
            query += 'FROM OpportunityLineItem WHERE RevRecOpportunityLineItem__c != null AND RevRecOpportunityLineItem__c =: revrecId' ;
            
            olis = database.query(query);
               
            if (olis != null && olis.size() > 0)
                oppId = olis[0].OpportunityId;
            else{ 
                msg += 'Wrong line item. ';   
                return;
            }
            RevRecOpportunityLineItem__c revrecLineItem = olis[0].RevRecOpportunityLineItem__r;
            
            //Assign calculated at as 
            if(Utility.checkFieldPermission(mapfieldRevRecOLIResult,'CalculatedAt__c',Constants.PERMISSION_UPDATE))
                revrecLineItem.CalculatedAt__c = Date.Today().addDays(-2);
            
            //Check if multi currency enabled then do this
            //If true the do this 
            if(isMultiCurrencyEnabled)
                revrecLineItem.put('CurrencyIsoCode' , olis[0].get('CurrencyIsoCode'));
            
            if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecOpportunityLineItem__c')){
                update(revrecLineItem);
            }
        }
        
        if (oppId.length() > 0) {
        
            try {
                RevRecUtil util = new RevRecUtil();
                RevRecUtilHelper utilHelper = new RevRecUtilHelper();
                utilHelper.Cleanup();
                
                if(!Constants.IS_BY_PASS_RULE_TRIGGER)
                    util.EvaluateRevRecScheduleForOpportunity(oppId); 
            } catch (Exception exp) { 
                System.debug(exp);
            }
    	}
    }
}