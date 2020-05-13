/**
*  Description     :   Scheduler to schedule the Batch_MassRollUpRevenueCalculation at midnight
*
*  Created By      :   Bill Feeheley   
*
*  Created Date    :   4/7/2019
*
*  Version         :   V1.0
*
**/
global with sharing class BatchSchedule_MassRollUpCalculation implements Schedulable{
    
    //Variables to be used for the Scheduler...
    global  Boolean isHavingPermission{get; set;}
    global  Boolean isMultiCurrencyEnabled;
    global  List<Opportunity> allOpp;
    
    //Scheduleable Execute method..
    global void execute(SchedulableContext sc) {
        
    //List of the users that have permissions...
    List<PermissionSetAssignment> lstcurrentUserPerSet = [SELECT Id, PermissionSet.Name,AssigneeId
                                                          FROM PermissionSetAssignment
                                                          WHERE AssigneeId = :Userinfo.getUserId()
                                                          AND PermissionSet.Name IN('REVvue_Opportunity_Mass_Rollup_Calculation')];
        //Check the size of the permission list..
        if(lstcurrentUserPerSet.size() > 0) {
            for (PermissionSetAssignment psa: lstcurrentUserPerSet) {
                if(psa.PermissionSet.Name.equals('REVvue_Opportunity_Mass_Rollup_Calculation'))  
                    isHavingPermission = false;
                else
                    isHavingPermission = true;
            }
        }
        else
            isHavingPermission = true;
        
        //Check the currency type...
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        
        //If the user have the permissio
        if(!isHavingPermission) {
            //String to hold the query..
            String queryOpp = '';
            
            //Check if the multicurrency is enabled or not...
            if(!isMultiCurrencyEnabled)
                queryOpp += 'SELECT Id, name, CloseDate , TCV_Actual__c, Probability FROM Opportunity';
            else
                queryOpp += 'SELECT Id, name, CurrencyIsoCode, CloseDate , TCV_Actual__c, Probability FROM Opportunity';
            
            //Database.query for schedules
            allOpp = database.query(queryOpp);
        }
        
        // We now call the batch class to be scheduled
        Batch_MassRollUpRevenueCalculation batchSch = new Batch_MassRollUpRevenueCalculation(allOpp);
        
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(batchSch,200);
    }
}