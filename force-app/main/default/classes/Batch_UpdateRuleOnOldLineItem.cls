/**
 *  Description     :   Batch is used to update RevRecRule over historical line items where product is assigned any rule.
 *
 *  Created By      :   
 *
 *  Created Date    :   03/23/2018
 *
 *  Version         :   V_1.0
 *
 *  Revision Logs   : 
 *      
 **/
global with sharing class Batch_UpdateRuleOnOldLineItem implements Database.Batchable<sObject>{
    
    //Start method
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        //query through the lead
        return Database.getQueryLocator([SELECT Id, RevRecRule__c, product2.RevRecRule__c 
                                         FROM OpportunityLineItem 
                                         WHERE RevRecRule__c = null AND product2.RevRecRule__c != null]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext bc, List<OpportunityLineItem> lineItems) {
        
        //List to update 
        List<OpportunityLineItem> ruleOnLineItemsToBeUpdated = new List<OpportunityLineItem>();
        Map<String, Schema.DescribeFieldResult> mapfieldOLIResult = Utility.getFieldPermissions('OpportunityLineItem');
        
        //Loop over line items
        for(OpportunityLineItem item : lineItems) {
            
            //Check if rule is on line item but not on its product
            if(item.RevRecRule__c == null && item.Product2.RevRecRule__c != null) {
                if(Utility.checkFieldPermission(mapfieldOLIResult,'RevRecRule__c',Constants.PERMISSION_UPSERT))
                    item.RevRecRule__c = item.Product2.RevRecRule__c;
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'OpportunityLineItem'))
                    ruleOnLineItemsToBeUpdated.add(item);
            }
        }
        
        //Check for size
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'OpportunityLineItem')){
            if(ruleOnLineItemsToBeUpdated.size() > 0 )
                update ruleOnLineItemsToBeUpdated;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}