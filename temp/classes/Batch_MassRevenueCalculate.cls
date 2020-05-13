/**
 *  Description     :   Batch Class to update Revenue recognition on all the opportunities records matching the filter criteria
 *
 *  Created By      :   
 *
 *  Created Date    :   09/17/2014
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   09/17/2014- Created   
 *
**/
global with sharing class Batch_MassRevenueCalculate implements Database.batchable<sObject> , Database.stateful {  
     
     //Variables 
     global String queryString;
     global Set<Id> oppIdToExecuteBatch ;
     global Date dt1;
     global Date dt2;
     global Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
       
     //Parameterized Constructer initilization
     global Batch_MassRevenueCalculate (string query) {
         queryString = query;	//query string         
     }
      
     //Parameterized Constructer initilization
     global Batch_MassRevenueCalculate (string query , Date d1 , Date d2) {
     	
     	 //Assign
         dt1 = d1;
         dt2 = d2;
         //query string
         queryString = query;         
     }
     
      //Parameterized Constructer initilization   
     global Batch_MassRevenueCalculate (string query, Set<Id> oppIdToExecuteBatchParam) {
        
         //query string
         queryString = query; 
         oppIdToExecuteBatch =   oppIdToExecuteBatchParam ;
         mapOpportunities = new Map<Id, Opportunity>(); 
         
         if(oppIdToExecuteBatch.size() > 0) {
            queryString += ' WHERE ID IN  : oppIdToExecuteBatch';
         
             for(Opportunity opp : [Select Id, REVvue_ExecMassCalc__c From Opportunity where Id IN: oppIdToExecuteBatchParam
                                                  AND REVvue_ExecMassCalc__c = true])
                mapOpportunities.put(opp.Id, opp);
         }         
     }
     
     
     //variable to hold the record count 
     global Integer totalProcessed = 0;
     
    //Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
        
        return Database.getQueryLocator(queryString);
    } 
    
    //Execute method 
    global void execute(Database.BatchableContext info, List<Opportunity> opps) {
        
        //hold the record count which processed
        totalProcessed  += opps.size();
        
        //Instantiate the utile class and calling methods
        RevRecUtil util = new RevRecUtil();
        RevRecUtilHelper utilHelper = new RevRecUtilHelper();
        utilHelper.Cleanup();
        util.IS_EXECUTING_BATCH = true;
        
        //Lopp through the oppoertunity
        for(Opportunity opp : opps) {
            
            //Calling method from controller to do calculation
            util.EvaluateRevRecScheduleForOpportunity(opp.Id);
        }
        if(mapOpportunities.size() >0 || mapOpportunities != null) {
            for(Opportunity opportunity : mapOpportunities.values()) {
              opportunity.REVvue_ExecMassCalc__c = false;
            }
        }
        update mapOpportunities.values(); 
    }
    
   //Finish Method
   global void finish(Database.BatchableContext info){ 
        
        Set<Id> setOpportunityIdsToBeProcessedForBatch = new Set<Id>();
        
        if(mapOpportunities.values().size() > 0) {
            for(Opportunity opportunity : mapOpportunities.values()) {
                
                if(opportunity.REVvue_ExecMassCalc__c)
                    setOpportunityIdsToBeProcessedForBatch.add(opportunity.Id);
            }
        }
        
        if(setOpportunityIdsToBeProcessedForBatch.size() > 0) {
           
            Batch_MassRevenueCalculate bc = new Batch_MassRevenueCalculate('Select Id FROM Opportunity' , setOpportunityIdsToBeProcessedForBatch);
            DataBase.executeBatch(bc, 5);
        }
       
        // Single email Initilization
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        //Query result of Async Jobs
       AsyncApexJob asyncBatch = [Select Id, CompletedDate, ExtendedStatus, Status, 
                                  JobItemsProcessed, NumberOfErrors, TotalJobItems, ApexClass.name,
                                  CreatedBy.Email, CreatedBy.FirstName , CreatedBy.Name FROM AsyncApexJob WHERE Id =:info.getJobId()]; 
       
        //Check for not null
        if(string.IsNotBlank(asyncBatch.CreatedBy.Email)) {
            
            //Set to addresses
            //mail.setToAddresses(new string[]{'taruna.kunwar@simplyforce.com'});
            mail.setToAddresses(new string[]{asyncBatch.CreatedBy.Email}); 
            
            // Specify the subject line for your email address.
            mail.setSubject('Batch job has been Completed ');
            
            // Set to True if you want to BCC yourself on the email.
            mail.setBccSender(false);
            
            // Optionally append the salesforce.com email signature to the email.
            // The email address of the user executing the Apex Code will be used.
            mail.setUseSignature(false);
            
            //Variable to hold email body
            String htmlBody  = Label.Batch_Completion_Message+' '+string.valueOf(totalProcessed)+' '+Label.Records;
            
            //set body of email
            mail.setHtmlBody(htmlBody);
            
            //If test is not running
            if(!Test.isRunningTest())
           		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	// Send the email you have created
        }
   }    
}