/**
 *  Description     :   Batch is used to update forecast and actual values of existing milestones.
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
global with sharing class Batch_UpdateOldRuleMilesForecast implements Database.Batchable<sObject> {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRRRMilesResult = Utility.getFieldPermissions('RevRecRuleMilestone__c');

    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        //query through the lead
        return Database.getQueryLocator([SELECT Id, Actual_Amount__c, Actual_Percent__c, Actual_Qty__c, Amount__c, Qty__c, 
                                         Percent__c, RevRecRule__r.Recognition_Type__c
                                         FROM RevRecRuleMilestone__c
        								 WHERE RevRecRule__r.Recognition_Type__c = 'Milestone' AND
        								 (Amount__c != null OR Qty__c != null OR Percent__c != null)]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext BC, List<RevRecRuleMilestone__c> milestones) {
        
        //List of rule to update
        List<RevRecRuleMilestone__c> milestonesToBeUpdate = new List<RevRecRuleMilestone__c>();
        
        //Loop over all rule
        for(RevRecRuleMilestone__c mile : milestones) {
            
            if(mile.RevRecRule__r.Recognition_Type__c == 'Milestone') {
                
                //Check if Forecast Amount is not null
                if(mile.Amount__c != null && mile.Amount__c != 0) {
                    if(Utility.checkFieldPermission(mapfieldRRRMilesResult,'Actual_Amount__c',Constants.PERMISSION_UPSERT))
                        mile.Actual_Amount__c = mile.Amount__c;
                    if(Utility.checkFieldPermission(mapfieldRRRMilesResult,'Amount__c',Constants.PERMISSION_UPSERT))
                        mile.Amount__c = 0;
                }
                
                //Check if Forecast Percent is not null
                if(mile.Percent__c != null && mile.Percent__c != 0) {
                    if(Utility.checkFieldPermission(mapfieldRRRMilesResult,'Actual_Percent__c',Constants.PERMISSION_UPSERT))
                        mile.Actual_Percent__c = mile.Percent__c;
                    if(Utility.checkFieldPermission(mapfieldRRRMilesResult,'Percent__c',Constants.PERMISSION_UPSERT))
                        mile.Percent__c = 0;
                }
                
                //Check if Forecast Qty is not null
                if(mile.Qty__c != null && mile.Qty__c != 0) {
                    if(Utility.checkFieldPermission(mapfieldRRRMilesResult,'Actual_Qty__c',Constants.PERMISSION_UPSERT))
                        mile.Actual_Qty__c = mile.Qty__c;
                    if(Utility.checkFieldPermission(mapfieldRRRMilesResult,'Qty__c',Constants.PERMISSION_UPSERT))
                        mile.Qty__c = 0;
                }
            }
            if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecRuleMilestone__c'))
                milestonesToBeUpdate.add(mile);
        }
    
    	//Check for size, then update milestone
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecRuleMilestone__c')){
            if(milestonesToBeUpdate.size() > 0)
                update milestonesToBeUpdate;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}