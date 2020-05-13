/**
 *  Description     :   Trigger for Opportunity.
 *
 *  Created Date    :   05/30/2016
 *
 *  Created By      :   Bill Feeheley   
 *  
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0 - Created
**/
trigger Trigger_Opportunity on Opportunity (before insert, before update ,after update) {
    
    //bypass trigger
    if(Constants.IS_BY_PASS_OPP_TRIGGER) 
        return;

    //Checking for the event 
    if(Trigger.isBefore) {
        
        //Checking for action and calling controller method
        if(Trigger.isInsert || Trigger.isUpdate) {
            OpportunityTriggerHelper.assignRulesOnOpportunity(Trigger.New, Trigger.oldMap);
            OpportunityTriggerHelper.validateCurrenceyTypeField(Trigger.New, Trigger.oldMap);
        }
    }  
    
    if(Trigger.isAfter) {
        //Checking for action and calling helper method 
        if(Trigger.isUpdate) 
            OpportunityTriggerHelper.calculateDateChange(Trigger.New, Trigger.oldMap);
        
    }
}