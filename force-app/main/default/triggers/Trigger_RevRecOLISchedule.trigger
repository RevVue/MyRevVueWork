/**
 *	Description		:	Trigger for RevRecOpportunityLineItemSchedule__c.
 *
 *	Created Date	:	04/11/2020
 *
 *	Created By		:		
 *	
 *	Version			:	V_1.0
 *
**/
trigger Trigger_RevRecOLISchedule on RevRecOpportunityLineItemSchedule__c (after insert) {
 
    //By pass trigger
    if(Constants.IS_BY_PASS_SCHEDULES_TRIGGER == false)
        return; 

        //Checking for the event 
        if(Trigger.isAfter) {
                if(Trigger.isInsert)
                RevRecOLIScheduleTriggerHelper.calculateRollupData(Trigger.New);            
    }
}