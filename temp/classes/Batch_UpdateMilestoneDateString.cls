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
global with sharing class Batch_UpdateMilestoneDateString implements Database.Batchable<sObject> {
    
	global Set<String> setOfOLIField;
  	global Set<String> setOfProductField;
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldProdMilesResult = Utility.getFieldPermissions('RevRecProductRuleMilestone__c');
  	
	global   Batch_UpdateMilestoneDateString() {
	  
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
        return Database.getQueryLocator([Select Id, Milestone_Date_Source__c, Milestone_Date_Source_Label__c FROM RevRecProductRuleMilestone__c
        								 Where Milestone_Date_Source__c != null OR Milestone_Date_Source_Label__c != null]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext BC, List<RevRecProductRuleMilestone__c> milestones) {
    	
    	//List of rule to update
    	List<RevRecProductRuleMilestone__c> milestonesToBeUpdate = new List<RevRecProductRuleMilestone__c>();
    	
    	//Loop over all rule
    	for(RevRecProductRuleMilestone__c miles : milestones) {
    		
    		Boolean isChange = false;
    		
    		//Check for rule start date
    		if(miles.Milestone_Date_Source__c != null) {
    			
	    		//Spliting string
	    		List<String> strs = miles.Milestone_Date_Source__c.split(':');
	    		
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
                        if(Utility.checkFieldPermission(mapfieldProdMilesResult,'Milestone_Date_Source__c',Constants.PERMISSION_UPSERT))
                            miles.Milestone_Date_Source__c = strs[0] + strs[1];
                        
                        //Setting flag true on rule update
                        isChange = true;
		    		}
	    		}
			}
    		
    		//Check for rule end date
    		if(miles.Milestone_Date_Source_Label__c != null) {
	    		
	    		//Spliting string
	    		List<String> strs = miles.Milestone_Date_Source_Label__c.split(':');
	    		
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
                        if(Utility.checkFieldPermission(mapfieldProdMilesResult,'Milestone_Date_Source_Label__c',Constants.PERMISSION_UPSERT))
                            miles.Milestone_Date_Source_Label__c = strs[0] + strs[1];
                        
                        //Setting flag true on rule update
                        isChange = true;
		    		}
	    		}
    		}
    		
            //Check if any update
            if(isChange && (Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleMilestone__c')))
                milestonesToBeUpdate.add(miles);
        }
        
        //Updating rule
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecProductRuleMilestone__c')){
            if(milestonesToBeUpdate.size() > 0)
                update milestonesToBeUpdate;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}