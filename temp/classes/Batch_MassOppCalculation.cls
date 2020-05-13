/**
 *  Description     :   Batch Class to perform calculation for set of opportunity.
 *
 *  Created By      :   
 *
 *  Created Date    :   06/17/2019
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   06/17/2019- Created   
 *
**/
global with sharing class Batch_MassOppCalculation implements Database.batchable<sObject> , Database.stateful {  
     
     //Variables 
     global Set<Id> oppIdToExecuteBatch ;
    
     //Parameterized Constructer initilization   
     global Batch_MassOppCalculation (Set<Id> oppIdToExecuteBatchParam) {
            oppIdToExecuteBatch = oppIdToExecuteBatchParam;
     }
     
    //Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
        
        String query = 'SELECT Id FROM Opportunity WHERE ID IN : oppIdToExecuteBatch';
        return Database.getQueryLocator(query);
    } 
    
    //Execute method 
    global void execute(Database.BatchableContext info, List<Opportunity> opps) {
        
        //Instantiate the utile class and calling methods
        RevRecUtil util = new RevRecUtil();
        RevRecUtilHelper utilHelper = new RevRecUtilHelper();
        utilHelper.Cleanup();
        util.IS_EXECUTING_BATCH = true;
        
        //Lopp through the oppoertunity
        for(Opportunity opp : opps)
            util.EvaluateRevRecScheduleForOpportunity(opp.Id);	//Calling method from controller to do calculation
    }
    
   //Finish Method
   global void finish(Database.BatchableContext info){ 
   }
}