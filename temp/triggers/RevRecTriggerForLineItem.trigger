trigger RevRecTriggerForLineItem on OpportunityLineItem (before insert, before update, after delete, after update, after insert) {
    
    //By pass trigget
    if(Constants.IS_BY_PASS_LINE_ITEM_TRIGGER)
        return; 
    
    //Check for after
   	if(Trigger.isBefore) {
        
      	//Check for insert
        if(Trigger.IsInsert) {
        	  
        	//Method call of helper class
            OpportunityLinetemTriggerHelper.runRuleAssignments(Trigger.New); 
            OpportunityLinetemTriggerHelper.setRevRecRuleFieldValue(Trigger.new);
        } 
         
        //Check for insert
        if(Trigger.IsUpdate && !RevRecUtil.BY_PASS_REVREC_LINE_ITEM_TRIGGER)
         	OpportunityLinetemTriggerHelper.calculateDateChange(Trigger.New, Trigger.oldMap); 	//Method call of helper class
     }
    
    //Check for after
    if(Trigger.isAfter) { 
    	
        if(Trigger.isUpdate) { 
            
            //By pass line item trigger
          	/* if(!Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE_FROM_ADJUST)
                OpportunityLinetemTriggerHelper.updateRevVueProcessOnChange(Trigger.New, Trigger.oldMap);*/
        }
    	
        //For insert OLI, insert RR_OLI only, and update OLI with the RR_OLI id, then the update trigger will automatically pick up the change
        if(Trigger.isInsert)
            OpportunityLinetemTriggerHelper.rrOLIInsertAndOLIUpdate(Trigger.New);
        
        if(Trigger.isUpdate && !RevRecUtil.BY_PASS_OPP_LINE_ITEM_TRIGGER && !RevRecUtil.BY_PASS_REVREC_LINE_ITEM_TRIGGER)
            OpportunityLinetemTriggerHelper.priceRelatedChangeCal(Trigger.new, Trigger.oldMap);
                
        if(Trigger.isDelete) 
            OpportunityLinetemTriggerHelper.deleteSchedule(Trigger.oldMap);
    }
}