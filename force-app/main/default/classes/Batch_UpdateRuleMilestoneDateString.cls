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
global with sharing class Batch_UpdateRuleMilestoneDateString implements Database.Batchable<sObject> {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRRMilesResult = Utility.getFieldPermissions('RevRecRuleMilestone__c');
    
	global Set<String> setOfOLIField;
  	global Set<String> setOfProductField;
  	
    global Batch_UpdateRuleMilestoneDateString() {
        
        //Describe call on OppoertunityLineItem and Product fields
        Map<String, Schema.SObjectField> mapObjectFieldsOfOli = Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap();
        System.debug('mapObjectFieldsOfOli...@@@' + mapObjectFieldsOfOli);
        Map<String, Schema.SObjectField> mapObjectFieldsOfProduct = Schema.getGlobalDescribe().get('Product2').getDescribe().fields.getMap();
        
        //Adding fields in set
        setOfOLIField = mapObjectFieldsOfOli.keySet();
        setOfProductField = mapObjectFieldsOfProduct.keySet();
    }
    
    
    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        //query through the lead
        return Database.getQueryLocator([Select Id, Milestone_Date_Source__c, Milestone_Date_Source_Label__c FROM RevRecRuleMilestone__c
                                         Where Milestone_Date_Source__c != null OR Milestone_Date_Source_Label__c != null]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext BC, List<RevRecRuleMilestone__c> milestones) {
        System.debug('Query milestones -->' +milestones);
        System.debug('setOfOLIField -->' +setOfOLIField);
        
        //List of rule to update
        List<RevRecRuleMilestone__c> milestonesToBeUpdate = new List<RevRecRuleMilestone__c>();
        
        //Loop over all rule
        for(RevRecRuleMilestone__c miles : milestones) {
            
            Boolean isChange = false;
            
            //Check for rule start date
            if(miles.Milestone_Date_Source__c != null) {
                
                //Spliting string
                List<String> strs = miles.Milestone_Date_Source__c.split(':');
                System.debug('String for Milestone_Date_Source__c --> '+strs);
                
                if(strs.size() > 1) {
                    System.debug('strs[0] --> '+strs[0]);
                    System.debug('strs[1] --> '+strs[1]);
                    
                    //Check if split string contains opportunity product
                    if(strs[0].contains('OPPORTUNITY PRODUCT')){
                        System.debug('Opportunity product -->'+ strs[0]);
                        
                    } else if(strs[0].contains('PRODUCT')) {
                        System.debug('product -->'+ strs[0]);
                        
                        //Loop over OLI field
                        for(String str : setOfOLIField) {
                            //Check if set contains date field
                            if(str.touppercase() == strs[1].touppercase()){
                                System.debug('condition matched -->'+ str);
                                strs[0] = 'OPPORTUNITY PRODUCT:'; //Setting value 
                                System.debug('Value assigned -->'+ strs[0]);
                            }
                        }
                        
                        //Stamp updated date value
                        if(Utility.checkFieldPermission(mapfieldRRMilesResult,'Milestone_Date_Source__c',Constants.PERMISSION_UPSERT))
                            miles.Milestone_Date_Source__c = strs[0] + strs[1];
                        
                        System.debug('Final Milestone_Date_Source__c --> ' +miles.Milestone_Date_Source__c);
                        
                        //Setting flag true on rule update
                        isChange = true;
                    }
                }
            }
            
            //Check for rule end date
            if(miles.Milestone_Date_Source_Label__c != null) {
                System.debug('String for Milestone_Date_Source_Label__c --> ');
                
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
                        if(Utility.checkFieldPermission(mapfieldRRMilesResult,'Milestone_Date_Source_Label__c',Constants.PERMISSION_UPSERT))
                            miles.Milestone_Date_Source_Label__c = strs[0] + strs[1];
                        
                        //Setting flag true on rule update
                        isChange = true;
                    }
                }
            }
            System.debug('IsChange -->' +isChange);
            System.debug('Add miles -->' +miles);
            //Check if any update
            if(isChange && (Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecRuleMilestone__c')))
                milestonesToBeUpdate.add(miles);
        }
        
        //Updating rule
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecRuleMilestone__c')){
            System.debug('milestonesToBeUpdate -->' +milestonesToBeUpdate);
            if(milestonesToBeUpdate.size() > 0)
                update milestonesToBeUpdate;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}