/**
 *  Description         :   This is a handler for OpportunityLineItem trigger.
 *
 *  Created By          :   Bill Feeheley
 *
 *  Created Date        :   11/09/2016
 *
 *  Version             :   V_1.0 
 *
 *  Revision Log        :   V_1.0 - Created 
 **/
 public with sharing class RevRecProductRuleMilestoneTriggerHelper {
  
  /**
     *  @purpose    :   This method is used to set milestone checkbox if it is an manual update.
     *
     *  @return     :   
     *
     *  @args       :   Trigger.NewLlist of RevRecProductRuleMilestone__c), Trigger.Old (Map of Id and RevRecProductRuleMilestone)
     **/
    public static void setOverriddenRuleManualUpdateCheckBoxValue(List<RevRecProductRuleMilestone__c> newRRPRMilestones, Map<Id, RevRecProductRuleMilestone__c> mapOldRRPRMilestone) {
    
    	//Variable to hold id of overridden rule
    	Map<Id, Boolean> mapIOverriddenRuleIdWithUpdateFlag = new Map<Id, Boolean>();

    	//Loop over new milestone values
    	for(RevRecProductRuleMilestone__c milestone: newRRPRMilestones) {
    		
    		//Flag to check is update or not
    		Boolean isUpdateCheckBox = false;
    	
    		//Check, if blank update
    		if(milestone.Actual_Amount__c != mapOldRRPRMilestone.get(milestone.Id).Actual_Amount__c || milestone.Actual_Qty__c != mapOldRRPRMilestone.get(milestone.Id).Actual_Qty__c
    		  || milestone.Projected_Amount__c != mapOldRRPRMilestone.get(milestone.Id).Projected_Amount__c || milestone.Projected_Qty__c != mapOldRRPRMilestone.get(milestone.Id).Projected_Qty__c)
    		  	isUpdateCheckBox = true;	//Setting flag
    		
    		//Putting values in map
    		mapIOverriddenRuleIdWithUpdateFlag.put(milestone.RevRecProductRule__c, isUpdateCheckBox);	  
    	}
    	
    	//Check, if manual update found
    	if(mapIOverriddenRuleIdWithUpdateFlag.size() > 0) {
    	
    		//Fetching overridden rule 
    		List<RevRecProductRule__c> overriddenRules = [Select Id, Is_Manual_Update__c from RevRecProductRule__c where Id IN: mapIOverriddenRuleIdWithUpdateFlag.keySet()];
    		
    		//Check, if overridden rule found
    		if(overriddenRules.size() > 0) {
    			
    			//Loop over overridden rule
    			for(RevRecProductRule__c overriddenrule : overriddenRules)
    				overriddenrule.Is_Manual_Update__c = mapIOverriddenRuleIdWithUpdateFlag.get(overriddenrule.Id);	//Setting checkbox value
    			
    			update overriddenRules;	// updating overridden rule 
    		}
    	}
    }
     
   	public static void oppCalculation(List<RevRecProductRuleMilestone__c> newRROverriddenMiles, List<RevRecProductRuleMilestone__c> oldRROverriddenMiles) {
        
        String oppId = '';
        String msg = '';
        List<Id> ids = new List<Id>();
        
        if (Trigger.isUpdate || Trigger.isInsert) {
            for(RevRecProductRuleMilestone__c item : newRROverriddenMiles)
                    ids.add(item.RevRecProductRule__c);
        }else if(Trigger.isDelete) {
            for(RevRecProductRuleMilestone__c item : oldRROverriddenMiles)
                    ids.add(item.RevRecProductRule__c);
        }
        //Only one overrideRuleId is needed here 
        if(ids.size() > 0) {          
            RevRecProductRule__c overrideRule = [SELECT Id, name, Divide_By__c, initial_amount__c, initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, 
                            Period_or_Exact_Days__c, Recognition_Type__c, MileStone_Type__c, Residual_Amount__c, Residual_Amount_Type__c, Start_Date__c, End_Date__c,  Total_Period__c, RevRecOpportunityLineItem__c
                            FROM RevRecProductRule__c WHERE id = : ids[0]];
    
            List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, RevRecOpportunityLineItem__c, RevRecOpportunityLineItem__r.Id,
                            RevRecOpportunityLineItem__r.OpportunityLineItemId__c, RevRecOpportunityLineItem__r.DeferredRev__c,
                            RevRecOpportunityLineItem__r.TotalRev__c, RevRecOpportunityLineItem__r.RecognizedRev__c,
                            RevRecOpportunityLineItem__r.CalculatedAt__c, RevRecOpportunityLineItem__r.ResidualAmount__c,
                            RevRecOpportunityLineItem__r.ProductName__c
                            FROM OpportunityLineItem WHERE RevRecOpportunityLineItem__c != null 
                            AND RevRecOpportunityLineItem__c = :overrideRule.RevRecOpportunityLineItem__c];
            
            if (olis !=null && olis.size() > 0)
        		oppId = olis[0].OpportunityId;
        	else {
                msg += 'Wrong line item. ';
                return;
            }
            
            if(oppId.length() > 0) {
                try {
                     //Code added - 01/31/2015 - By pass the code looping
                     if(overrideRule.Recognition_Type__c == constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE ||
                        overrideRule.Recognition_Type__c == 'Milestone')
                        return;
                    
                    RevRecUtil util = new RevRecUtil();
                    RevRecUtilHelper utilHelper = new RevRecUtilHelper();
                    utilHelper.Cleanup();
                    util.EvaluateRevRecScheduleForOpportunity(oppId);
                } catch (Exception exp) { System.debug('Exception...@@@'+exp);}
            }
        }
    }
}