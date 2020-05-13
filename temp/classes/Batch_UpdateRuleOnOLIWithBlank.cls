/**
*  Description     :   Batch is used to update RevRecRule with blank values over line items, if rule is already deleted.
*
*  Created By      :   
*
*  Created Date    :   30/01/2019
*
*  Version         :   V_1.0
*
*  Revision Logs   : 
*      
**/
global with sharing class Batch_UpdateRuleOnOLIWithBlank implements Database.Batchable<sObject>, Database.stateful{
    
    //Map to hold existing 
    Map<Id, RevRecRules__c> mapRules = new Map<Id, RevRecRules__c>([SELECT Id, Name FROM RevRecRules__c LIMIT 50000]);
    
    //Start method
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        //query through the lead
        return Database.getQueryLocator([SELECT Id, RevRecRule__c 
                                         FROM OpportunityLineItem 
                                         WHERE RevRecRule__c != null]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext bc, List<OpportunityLineItem> lineItems) {
        
        //Map is used to hold the field permission
    	Map<String, Schema.DescribeFieldResult> mapfieldOLIResult = Utility.getFieldPermissions('OpportunityLineItem');
    
        //List to update 
        List<OpportunityLineItem> ruleOnLineItemsToBeUpdated = new List<OpportunityLineItem>();
        Set<Id> setRevRecRuleIds = new Set<Id>();
        
        //Loop over oli
        for(OpportunityLineItem oli : lineItems) {
            if(!mapRules.containsKey(oli.RevRecRule__c)) {
                if(Utility.checkFieldPermission(mapfieldOLIResult,'RevRecRule__c',Constants.PERMISSION_UPDATE))
                    oli.RevRecRule__c = null;
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'OpportunityLineItem'))
                    ruleOnLineItemsToBeUpdated.add(oli);
            }
        }
        
        //Check for size
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'OpportunityLineItem')){
            if(ruleOnLineItemsToBeUpdated.size() > 0)
                update ruleOnLineItemsToBeUpdated;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}