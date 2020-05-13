/**
 *  Description     :   Batch is used to update rules after any changes in the dates.
 *
 *  Created By      :   
 *
 *  Created Date    :   22/01/2019
 *
 *  Version         :   V_1.0
 *
 *  Revision Logs   : 
 *      
 **/
global with sharing class Batch_UpdateOLIWithRulFromProduct implements Database.Batchable<sObject>, Database.stateful{

    //rule to update
    List<RevRecProductRule__c> rulesToUpdate = new List<RevRecProductRule__c>();
    List<Product2> newProducts = new List<Product2>();
    public Set<Id> setProductIds = new Set<Id>();
    Map<Id, Product2> mapOldProducts = new Map<Id, Product2>();
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldProdRuleResult = Utility.getFieldPermissions('RevRecProductRule__c');
    
    //Constructor
    global Batch_UpdateOLIWithRulFromProduct(Set<Id> setProductIds, List<Product2> newProducts, Map<Id, Product2> mapOldProducts) {

        this.newProducts = newProducts;
        this.setProductIds = setProductIds;
        this.mapOldProducts = mapOldProducts;        
        System.debug('@@@ setProductIds' +setProductIds);
    }
    
    //Start method to query OLI whose products are updated
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Name, Product2Id, OpportunityId FROM OpportunityLineItem WHERE Product2Id IN :setProductIds');
    }
    
    //Execute method to do manipulations on queried data
    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> oppLineItems) {
        Set<Id> setOpportunityIds = new Set<Id>();
        
        //Map oof rules
        Map<Id , List<RevRecProductRule__c>> mapRevRecRules = new Map<Id , List<RevRecProductRule__c>>();

        //Getting opp Ids
        for(OpportunityLineItem oppLineItem : oppLineItems) {
            setOpportunityIds.add(oppLineItem.OpportunityId);      
        }
        
        //Query all line items and related override rules 
        for(RevRecOpportunityLineItem__c revrecItem : [Select Id, Name, Opportunity__c , (
            Select Id, Revenue_Recognition_Start_Date__c, Revenue_Recognition_End_Date__c, 
            Is_Opportuunity_Date_Change__c, Is_Opportuunity_End_Date_Change__c  
            FROM RevRecProductRules__r ) 
            From RevRecOpportunityLineItem__c WHERE Opportunity__c IN : setOpportunityIds]) {

                //Loop over inline ressylts
                if(revrecItem.RevRecProductRules__r.size() > 0) {
                    
                    //Loop over list 
                    for(RevRecProductRule__c rule : revrecItem.RevRecProductRules__r) {
                        
                        if(mapRevRecRules.containsKey(revrecItem.Opportunity__c))
                            mapRevRecRules.get(revrecItem.Opportunity__c).add(rule);
                        else
                            mapRevRecRules.put(revrecItem.Opportunity__c , new List<RevRecProductRule__c>{rule});
                    }
                }
            }
        
        if(mapRevRecRules.size() > 0) { 
            
            if(setOpportunityIds.size() > 0) {
                
                //Dynamic query to get whole date field value of opportunity [if any formula found]
                List<Opportunity> newOpps = RevRecHelper.GetOpportunityWithAllFieldsByIdSet(setOpportunityIds);
                
                //Loop over newOpps
                for(Opportunity opp : newOpps) {
                    
                    if(mapRevRecRules.containsKey(opp.Id)) {
                        for(RevRecProductRule__c rule : mapRevRecRules.get(opp.Id)) {
                            
                            //Strt and end date fields VARIABLES
                            String startDateName = rule.Revenue_Recognition_Start_Date__c;
                            String endDateName = rule.Revenue_Recognition_End_Date__c;
                            Boolean isDateChange = false;
                            String fieldName = '';
                            
                            //If its a field of opportunity
                            if(String.isNotBlank(startDateName) && startDateName.contains(constants.SOBJECT_LINE_ITEM_COLON) && !(startDateName.contains(constants.SOBJECT_OPPORTUNITY))) { 
                                
                                //Get field name
                                fieldName = startDateName.subString(21, startDateName.length());
                                
                                for(Product2 prod : newProducts) { 
                                    
                                    if(!test.isRunningTest()) {
                                        //Checcking for date change
                                        if(mapOldProducts.get(prod.Id).get(fieldName) != prod.get(fieldName)) {
                                            
                                            //Populate values
                                            if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Start_Date__c',Constants.PERMISSION_UPSERT))
                                                rule.Start_Date__c = Date.valueOf(prod.get(fieldName));
                                            isDateChange = true;
                                        }
                                    }
                                }
                            }
                            
                            //If its a field of opportunity
                            if(String.isNotBlank(endDateName) && endDateName.contains(constants.SOBJECT_LINE_ITEM_COLON) && !(endDateName.contains(constants.SOBJECT_OPPORTUNITY))) { 
                                
                                //Get field name
                                fieldName = endDateName.subString(21, endDateName.length());
                                
                                for(Product2 prod : newProducts) { 
                                    
                                    if(!test.isRunningTest()) {
                                        //Checcking for date change
                                        if(mapOldProducts.get(prod.Id).get(fieldName) != prod.get(fieldName)) {
                                            
                                            //Populate values
                                            if(Utility.checkFieldPermission(mapfieldProdRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT))
                                                rule.End_Date__c = Date.valueOf(prod.get(fieldName));
                                            isDateChange = true;
                                        }
                                    }
                                }
                            }
                            
                            //If any date chnages
                            if( isDateChange && (Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRule__c')))
                                rulesToUpdate.add(rule);
                        }
                    }
                }
            }
        }
        //Update rules
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecProductRule__c')){
            if(rulesToUpdate.size() > 0) 
                update rulesToUpdate;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}