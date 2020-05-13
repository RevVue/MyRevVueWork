/**
 *  Description     :   Batch is used to update start and end date on existing rule.
 *
 *  Created By      :   Bill Feeheley
 *
 *  Created Date    :   12/20/2016
 *
 *  Version         :   V_1.0
 *
 *  Revision Logs   : 
 *      
 **/
global with sharing class Batch_UpdateOldRuleStartAndEndDate implements Database.Batchable<sObject> {
    
	global Set<String> setOfOLIField;
  	global Set<String> setOfProductField;
  	
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRuleResult = Utility.getFieldPermissions('RevRecRules__c');
    
	global   Batch_UpdateOldRuleStartAndEndDate() {
	  
	 	//Describe call on OppoertunityLineItem and Product fields
	  	Map<String, Schema.SObjectField> mapObjectFieldsOfOli = Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap();
	  	Map<String, Schema.SObjectField> mapObjectFieldsOfProduct = Schema.getGlobalDescribe().get('Product2').getDescribe().fields.getMap();
	  	
	  	//Adding fields in set
	  	setOfOLIField = mapObjectFieldsOfOli.keySet();
	  	setOfProductField = mapObjectFieldsOfProduct.keySet();
	}
  
   	//Start method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        //query through the lead
        return Database.getQueryLocator([Select Id, Revenue_Recognition_End_Date__c, Revenue_Recognition_Start_Date__c FROM RevRecRules__c
        								 Where Revenue_Recognition_End_Date__c != null OR Revenue_Recognition_Start_Date__c != null]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext BC, List<RevRecRules__c> rules) {
    	
    	//List of rule to update
    	List<RevRecRules__c> ruleToBeUpdate = new List<RevRecRules__c>();
    	
    	//Loop over all rule
    	for(RevRecRules__c rule : rules) {
    		
    		Boolean isChange = false;
    		
    		//Check for rule start date
    		if(rule.Revenue_Recognition_Start_Date__c != null) {
    			
	    		//Spliting string
	    		List<String> strs = rule.Revenue_Recognition_Start_Date__c.split(':');
	    		
	    		if(strs.size() > 1) {
	    			
		    		//Check if split string contains opportunity product
		    		if(strs[0].contains('OPPORTUNITY PRODUCT')){
		    		
		    		} else if(strs[0].contains('PRODUCT')) {
		    			
		    			//Loop over OLI field
		    			for(String str : setOfOLIField) {
		    				
		    				//Check if set contains date field
		    				if(str.touppercase() == strs[1].touppercase()) 
			    				strs[0] = 'OPPORTUNITY PRODUCT:'; //Setting value 
		    			}
                        
		    			//Stamp updated date value
                        if(Utility.checkFieldPermission(mapfieldRuleResult,'Revenue_Recognition_Start_Date__c',Constants.PERMISSION_UPSERT))
                            rule.Revenue_Recognition_Start_Date__c = strs[0] + strs[1];
                        
                        //Setting flag true on rule update
                        isChange = true;
		    		}
    			}
			}
    		
    		//Check for rule end date
    		if(rule.Revenue_Recognition_End_Date__c != null) {
	    		
	    		//Spliting string
	    		List<String> strs = rule.Revenue_Recognition_End_Date__c.split(':');
	    		
	    		if(strs.size() > 1) {
		    		
		    		//Check if split string contains opportunity product
		    		if(strs[0].contains('OPPORTUNITY PRODUCT')){
		    		
		    		} else if(strs[0].contains('PRODUCT')) {
		    			
		    			//Loop over OLI field
		    			for(String str : setOfOLIField) {
		    				
		    				//Check if set contains date field
		    				if(str.touppercase() == strs[1].touppercase())
			    				strs[0] = 'OPPORTUNITY PRODUCT:';	//Setting value 
			    		}
                        
                        //Stamp updated date value
                        if(Utility.checkFieldPermission(mapfieldRuleResult,'Revenue_Recognition_End_Date__c',Constants.PERMISSION_UPSERT))
                            rule.Revenue_Recognition_End_Date__c = strs[0] + strs[1];
                        
                        //Setting flag true on rule update
                        isChange = true;
		    		}
	    		}
    		}
    		
    		//Check if any update
    		if(isChange && (Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecRules__c')))
    			ruleToBeUpdate.add(rule);
    	}
    	
    	//Updating rule
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecRules__c')){
            if(ruleToBeUpdate.size() > 0)
                update ruleToBeUpdate;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}