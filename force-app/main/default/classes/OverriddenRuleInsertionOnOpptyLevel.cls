/**
 *  Description     :   This class is used to create overridden rule on opportunity level.
 *
 *  Created Date    :   07/19/2016 
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0 - Created 
**/
public class OverriddenRuleInsertionOnOpptyLevel {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldProdRuleResult = Utility.getFieldPermissions('RevRecProductRule__c');
    
    /** 
     *  @description        :   Method to upsert overridden rule on opportunity level.
     *
     *  @args               :   Opportunity, Map<Id, OpportunityLineItem>, Set<Id>(revrecopportunitylineitem id's)
     *
     *  @return             :   String
     **/
    public String overriddenRuleOnOpptyLevel(Opportunity oppty, Map<Id, OpportunityLineItem> mapRuleIdWithOLI, Set<Id> revRecOLIIds) {
        
        //Variable 
        String msg = '';
        
        Opportunity theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', oppty.Id);
        
        //Fetching rule detail to create overridden rule
        List<RevRecRules__c> theRules = [Select Residual_Amount__c, Residual_Amount_Type__c, initial_amount__c, initial_amount_type__c,
                                  Recognition_Type__c, offset_type__c, Divide_By__c, name, Period_or_Exact_Days__c,
                                  Milestone_Type__c, Start_Percentage__c, End_Percentage__c, Is_Split_Categories__c, Offset_Period__c,
                                  Revenue_Recognition_Start_Date__c, Revenue_Recognition_End_Date__c, Enable_Manual_Forecast__c, 
                                  Forecast_With_Zero_Value__c
                                  From RevRecRules__c where Id =: oppty.REVvue_RevRecRule__c AND Is_Split_Categories__c = false];
        
        //List to upsert overridden rule
        List<RevRecProductRule__c> overrideRuleToBeUpserted = new List<RevRecProductRule__c>();
        
        if(theRules.size() > 0) {
            
            //Loop to fetch revrecopportunitylineitem id's
            for(Id revRecId : revRecOLIIds) {
                
                //Overridden rule instance
                RevRecProductRule__c overrideRule = new RevRecProductRule__c();
                
                OpportunityLineItem theOLI = (OpportunityLineItem)RevRecHelper.SelectAllFieldsForObject('OpportunityLineItem', mapRuleIdWithOLI.get(revRecId).Id);
                Product2 theProduct2 = (Product2)RevRecHelper.SelectAllFieldsForObject('Product2', mapRuleIdWithOLI.get(revRecId).PricebookEntry.product2.Id);
                Contract theContract = (Contract)RevRecHelper.SelectAllFieldsForObject('Contract', theOppty.ContractId);
                
                //Get the start date and end date
                String RevRecStartDateField = theRules[0].Revenue_Recognition_Start_Date__c;
                String RevRecEndDateField = theRules[0].Revenue_Recognition_End_Date__c;
                Date startDate = null;
                Date endDate = null;
                
                //Check if, start date is needed
                if(theRules[0].Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_MILESTONE && 
                   theRules[0].Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
                    
                    //Fetching date
                    if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_OPPORTUNITY)){
                    	if(RevRecStartDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
	                        String fieldName = RevRecStartDateField.subString(20, RevRecStartDateField.length()); 
	                        startDate = (Date)theOLI.get(fieldName);
                    	} else {
	                        String fieldName = RevRecStartDateField.subString(12, RevRecStartDateField.length()); 
	                        startDate = (Date)theOppty.get(fieldName);
                    	}
                    } else if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        String fieldName = RevRecStartDateField.subString(8, RevRecStartDateField.length());
                        startDate = (Date)theProduct2.get(fieldName);
                    } else if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_CONTRACT_COLON)) {
                        String fieldName = RevRecStartDateField.subString(9, RevRecStartDateField.length());
                        startDate = (Date)theContract.get(fieldName);
                    }
                    
                    //Assigning date
                    if (theRules[0].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                        endDate = startDate;
                    } else {
                        if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_OPPORTUNITY)) {
                        	if(RevRecEndDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        		String fieldName = RevRecEndDateField.subString(20, RevRecEndDateField.length());
                            	endDate = (Date)theOLI.get(fieldName);	
                        	}
                        	else {
                        		string fieldName = RevRecEndDateField.subString(12, RevRecEndDateField.length());
                            	endDate = (Date)theOppty.get(fieldName);
                        	}
                        } else if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)){
                            string fieldName = RevRecEndDateField.subString(8, RevRecEndDateField.length());
                            endDate = (Date)theProduct2.get(fieldName);
	                    } else if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_CONTRACT_COLON)){
                            string fieldName = RevRecEndDateField.subString(9, RevRecEndDateField.length());
                            endDate = (Date)theContract.get(fieldName);
	                    } 
                    }
                }
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'RevRecOpportunityLineItem__c',Constants.PERMISSION_UPSERT))
                    overrideRule.RevRecOpportunityLineItem__c = revRecId;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Residual_Amount__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Residual_Amount__c = theRules[0].Residual_Amount__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Residual_Amount_Type__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Residual_Amount_Type__c = theRules[0].Residual_Amount_Type__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'initial_amount__c',Constants.PERMISSION_UPSERT))
                    overrideRule.initial_amount__c = theRules[0].initial_amount__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'initial_amount_type__c',Constants.PERMISSION_UPSERT))
                    overrideRule.initial_amount_type__c = theRules[0].initial_amount_type__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Recognition_Type__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Recognition_Type__c = theRules[0].Recognition_Type__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'offset_type__c',Constants.PERMISSION_UPSERT))
                    overrideRule.offset_type__c  = theRules[0].offset_type__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Offset_Period__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Offset_Period__c  = theRules[0].Offset_Period__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Divide_By__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Divide_By__c  = theRules[0].Divide_By__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'name',Constants.PERMISSION_UPSERT))
                    overrideRule.name  = '[overridden] ' + theRules[0].name ;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Period_or_Exact_Days__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Period_or_Exact_Days__c = theRules[0].Period_or_Exact_Days__c;
                //overrideRule.Amortize_By__c = theRules[0].Amortize_By__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Milestone_Type__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Milestone_Type__c = theRules[0].Milestone_Type__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Start_Percentage__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Start_Percentage__c = theRules[0].Start_Percentage__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'End_Percentage__c',Constants.PERMISSION_UPSERT))
                    overrideRule.End_Percentage__c = theRules[0].End_Percentage__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Is_Split_Categories__c',Constants.PERMISSION_UPSERT))
                    overrideRule.Is_Split_Categories__c = theRules[0].Is_Split_Categories__c;
                
                if(theRules[0].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                    if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Start_Date__c',Constants.PERMISSION_UPSERT))
                        overrideRule.Start_Date__c = startDate;
                    
                    if(overrideRule.Start_Date__c == null)
                        msg = 'Start Date can not null'; 
                }else if (theRules[0].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE ||
                          theRules[0].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
                              
                              if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Start_Date__c',Constants.PERMISSION_UPSERT))
                                  overrideRule.Start_Date__c = startDate;
                              if(Utility.checkFieldPermission(mapfieldProdRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT))
                                  overrideRule.End_Date__c = endDate;
                              
                    if(overrideRule.Start_Date__c == null || overrideRule.End_Date__c == null)
                        msg = Constants.START_END_DATE_ERROR_MESSAGE;
               }
                
                if(overrideRule.End_Date__c < overrideRule.Start_Date__c)
                    msg = Constants.END_DATE_CANNOT_GREATER_ERROR_MESSAGE;
                
                //Adding values in list
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRule__c'))
                    overrideRuleToBeUpserted.add(overrideRule);
            }
        }
        if (msg.length() > 0)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg));
            
        else {
            
            //Query to fetch already existing overriden rule 
            List<RevRecProductRule__c> existingRules = [Select Id From RevRecProductRule__c Where RevRecOpportunityLineItem__c =: revRecOLIIds];
            
            //Checking for the list size and delete that rule after that creating a new one.
            if(existingRules.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'RevRecProductRule__c')))
                delete existingRules;
        
            //Check if, list has values to update
            if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRule__c')){
                if(overrideRuleToBeUpserted.size() > 0)
                    upsert overrideRuleToBeUpserted;    
            }
        }
        return msg;
    }
}