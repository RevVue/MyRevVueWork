trigger RevRecTriggerForOverrideRuleMilestons on RevRecProductRuleMilestone__c (before update, after delete, after insert, after update) {
    
    //Code added 11/05/2014 - by pass the trigger
    if(Constants.IS_BY_PASS_TRIGGER){
    	return;
    }  
    
    RevRecProductRuleMilestoneTriggerHelper.oppCalculation(Trigger.new, Trigger.old);
}