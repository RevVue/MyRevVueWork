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
global with sharing class Batch_UpdateRuleCategoryDateString implements Database.Batchable<sObject> {
    
	global Set<String> setOfOLIField;
  	global Set<String> setOfProductField;
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRRCatResult = Utility.getFieldPermissions('RevRecRuleCategory__c');
    
	global   Batch_UpdateRuleCategoryDateString() {
	  
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
        return Database.getQueryLocator([Select Id, Category_Start_Date__c, Category_End_Date__c FROM RevRecRuleCategory__c
        								 Where Category_Start_Date__c != null OR Category_End_Date__c != null]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext BC, List<RevRecRuleCategory__c> categories) {
    	
    	//List of rule to update
    	List<RevRecRuleCategory__c> categoriesToBeUpdate = new List<RevRecRuleCategory__c>();
    	
    	//Loop over all rule
    	for(RevRecRuleCategory__c categori : categories) {
    		
    		Boolean isChange = false;
    		
    		//Check for rule start date
    		if(categori.Category_Start_Date__c != null) {
    			
	    		//Spliting string
	    		List<String> strs = categori.Category_Start_Date__c.split(':');
	    		
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
                        if(Utility.checkFieldPermission(mapfieldRRCatResult,'Category_Start_Date__c',Constants.PERMISSION_UPSERT))
                            categori.Category_Start_Date__c = strs[0] + strs[1];
                        
                        //Setting flag true on rule update
                        isChange = true;
		    		}
	    		}
			}
    		
    		//Check for rule end date
    		if(categori.Category_End_Date__c != null) {
	    		
	    		//Spliting string
	    		List<String> strs = categori.Category_End_Date__c.split(':');
	    		
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
                        if(Utility.checkFieldPermission(mapfieldRRCatResult,'Category_End_Date__c',Constants.PERMISSION_UPSERT))
                            categori.Category_End_Date__c = strs[0] + strs[1];
                        
                        //Setting flag true on rule update
                        isChange = true;
		    		}
	    		}
    		}
    		
    		//Check if any update
    		if(isChange && (Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecRuleCategory__c')))
    			categoriesToBeUpdate.add(categori);
    	}
    	
    	//Updating rule
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecRuleCategory__c')){
            if(categoriesToBeUpdate.size() > 0)
                update categoriesToBeUpdate;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}