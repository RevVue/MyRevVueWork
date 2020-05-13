trigger RevRecTriggerForOverrideRule on RevRecProductRule__c (after insert, after update, before delete) {
    
    if(Constants.IS_BY_PASS_TRIGGER)
    	return;
    
	//Checking for event type
	if(Trigger.isBefore) {
	    		 
		//Checking for request type
		if(Trigger.isDelete)  
			RevRecProductRuleTriggerHelper.deleteRuleTypeFromOpportunityLineItem(Trigger.Old);
   	}
   		
    //Checking for event type
	if(Trigger.isAfter) {
		
        //Checking for request type
        if(Trigger.isUpdate || Trigger.isInsert) {
          	//RevRecProductRuleTriggerHelper.createMileStoneOnDateChanege(Trigger.New, Trigger.oldMap);
            RevRecProductRuleTriggerHelper.overriddenRuleCal(Trigger.New);
        }
   	}
}