/**
 *  Description     :   Batch is used to update forecast and actual values of existing milestones for Milestone type.
 *
 *  Created By      :   
 *
 *  Created Date    :   03/09/2018
 *
 *  Version         :   V_1.0
 *
 *  Revision Logs   : 
 *      
 **/
global with sharing class Batch_UpdateOldMilestoneForecast implements Database.Batchable<sObject> {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldProdRuleMilesResult = Utility.getFieldPermissions('RevRecProductRuleMilestone__c');

    //Start method
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        //query through the lead
        return Database.getQueryLocator([SELECT Id, Actual_Amount__c, Actual_Percent__c, Actual_Qty__c, Amount__c, Qty__c, Percent__c, 
                                         RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__c, RevRecProductRule__r.Recognition_Type__c
                                         FROM RevRecProductRuleMilestone__c
        								 WHERE RevRecProductRule__r.Recognition_Type__c = 'Milestone' AND
        								 (Amount__c != null OR Qty__c != null OR Percent__c != null)]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext bc, List<RevRecProductRuleMilestone__c> milestones) {
        
        //List of rule to update
    	List<RevRecProductRuleMilestone__c> milestonesToBeUpdate = new List<RevRecProductRuleMilestone__c>();
    	Set<Id> setOpportunityIds = new Set<Id>();
        Map<Id, OpportunityLineItem> mapRevRecLineItemWithLineItem = new Map<Id, OpportunityLineItem>();
        Map<Id, List<RevRecProductRuleMilestone__c>> mapRevRecLineItemWithMilestones = new Map<Id, List<RevRecProductRuleMilestone__c>>();
        
        //Loop over milestones
        for(RevRecProductRuleMilestone__c milestone : milestones) {
            
            //Set to hold opportunityId
            setOpportunityIds.add(milestone.RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__c);
            
            //Populate map to RevRecOppLinemile with corresponding Milestones
            if(!mapRevRecLineItemWithMilestones.containsKey(milestone.RevRecProductRule__r.RevRecOpportunityLineItem__c))
                mapRevRecLineItemWithMilestones.put(milestone.RevRecProductRule__r.RevRecOpportunityLineItem__c, new List<RevRecProductRuleMilestone__c>{milestone});
            else
                mapRevRecLineItemWithMilestones.get(milestone.RevRecProductRule__r.RevRecOpportunityLineItem__c).addAll(new List<RevRecProductRuleMilestone__c>{milestone});
        }
        
        //Loop over line mile 
        for(OpportunityLineItem oli : [SELECT Id, OpportunityId, Quantity, RevRecOpportunityLineItem__c, UnitPrice, TotalPrice
                                       FROM OpportunityLineItem 
                                       WHERE OpportunityId IN :setOpportunityIds AND RevRecRule__r.Recognition_Type__c = 'Milestone']) {
                                      
			//Check if key is already in map, then populate 
            if(!mapRevRecLineItemWithLineItem.containsKey(oli.RevRecOpportunityLineItem__c))
                mapRevRecLineItemWithLineItem.put(oli.RevRecOpportunityLineItem__c, oli);
        }

        //Loop over map to get oli
        for(Id revRecOppLineItemId : mapRevRecLineItemWithLineItem.keySet()) {
            
            if(mapRevRecLineItemWithMilestones.containsKey(revRecOppLineItemId)) {
                //Loop over map to get milestones
                for(RevRecProductRuleMilestone__c mile : mapRevRecLineItemWithMilestones.get(revRecOppLineItemId)) {
                    
                    //Calculation if Forecast Amount is not null
                    if(mile.Amount__c != null && mile.Amount__c > 0) {
                        if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Actual_Amount__c',Constants.PERMISSION_UPSERT))
                            mile.Actual_Amount__c = mile.Amount__c;
                        if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Amount__c',Constants.PERMISSION_UPSERT))
                            mile.Amount__c = 0;
                        mile.Actual_Percent__c = ((mile.Actual_Amount__c / mapRevRecLineItemWithLineItem.get(revRecOppLineItemId).TotalPrice)*100).setScale(2);
                        mile.Actual_Qty__c = (mapRevRecLineItemWithLineItem.get(revRecOppLineItemId).Quantity * mile.Actual_Percent__c / 100).setScale(2);
                    }
                    
                    //Calculation if Forecast Percent is not null
                    if(mile.Percent__c != null && mile.Percent__c > 0) {
                        if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Actual_Percent__c',Constants.PERMISSION_UPSERT))
                            mile.Actual_Percent__c = mile.Percent__c;
                        if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Percent__c',Constants.PERMISSION_UPSERT))
                            mile.Percent__c = 0;
                        mile.Actual_Qty__c = (mapRevRecLineItemWithLineItem.get(revRecOppLineItemId).Quantity * mile.Actual_Percent__c / 100).setScale(2);
                        mile.Actual_Amount__c = (mapRevRecLineItemWithLineItem.get(revRecOppLineItemId).TotalPrice * mile.Actual_Percent__c / 100).setScale(2);
                    }
                    
                    //Calculation if Forecast Qty is not null
                    if(mile.Qty__c != null && mile.Qty__c > 0) {
                        if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Actual_Qty__c',Constants.PERMISSION_UPSERT))
                            mile.Actual_Qty__c = mile.Qty__c;
                        if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Qty__c',Constants.PERMISSION_UPSERT))
                            mile.Qty__c = 0;
                        mile.Actual_Amount__c = (mapRevRecLineItemWithLineItem.get(revRecOppLineItemId).UnitPrice * mile.Actual_Qty__c).setScale(2);
                        mile.Actual_Percent__c = ((((mapRevRecLineItemWithLineItem.get(revRecOppLineItemId).UnitPrice * mile.Actual_Qty__c) / mapRevRecLineItemWithLineItem.get(revRecOppLineItemId).TotalPrice))*100).setScale(2);
                    }
                    
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleMilestone__c'))
                        milestonesToBeUpdate.add(mile);
                }
            }
        }

        //Check for size, then update milestone
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecProductRuleMilestone__c')){
            if(milestonesToBeUpdate.size() > 0)
                update milestonesToBeUpdate;
        }
        
        //Do functionality happened while refreshing opportunity page
        RevRecUtil util = new RevRecUtil();
        RevRecUtilHelper utilHelper = new RevRecUtilHelper();
        utilHelper.Cleanup();
        
        //Check for sixe
        if(setOpportunityIds.size() > 0) {
            for(Id oppId : setOpportunityIds) {
                util.EvaluateRevRecScheduleForOpportunity(oppId);
            }
        }
        
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}