/** 
 *	Description		:	This trigger is used to perform pre and post operation.
 *
 *	Craeted By		:	William Feeheley
 *
 *	Created Date	:	08/03/2017
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0 - Created
**/
trigger TriggerRevRecProductCategory on AppRopozSLN__RevRecProductRuleCategory__c ( before update) {
	
	//checking for request type
	if(Trigger.isBefore) {
		
		//Checking for action
		if(Trigger.isUpdate) {
			RevRecProductCategoryTriggerHelper.setConveretedValues(Trigger.New);
		}
	}
}