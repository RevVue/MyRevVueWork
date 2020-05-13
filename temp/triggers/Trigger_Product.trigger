/**
 *	Description		:	Trigger for Product2.
 *
 *	Created Date	:	09/05/2016
 *
 *	Created By		:		
 *	
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0 - Created
**/
trigger Trigger_Product on Product2 (before insert, after update) {
	
	//Checking for the event 
	if(Trigger.isBefore) {
		
		//Checking for action and calling controller method
		if(Trigger.isInsert)
			ProductTriggerHelper.assignRulesOnProducts(Trigger.New);
	}
    
    //Checking for the event 
	if(Trigger.isAfter) {
		
		//Checking for action and calling controller method
        if(Trigger.isUpdate) {
			ProductTriggerHelper.calculateDateChange(Trigger.NewMap, Trigger.oldMap);
            ProductTriggerHelper.ruleAssignmentOnLineItem(Trigger.NewMap, Trigger.oldMap);
        }
	}
}