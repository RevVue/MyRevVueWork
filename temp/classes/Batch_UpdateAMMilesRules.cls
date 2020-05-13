/**
 *  Description     :   This batch class is used to delete RevRecRule Milestone records which were created on RevRecRule.
 *                      
 *  Created By      :
 *
 *  Created Date    :   05/04/2016
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0 - Created - 05/04/2016  
 *
**/
global without sharing class Batch_UpdateAMMilesRules implements Database.batchable<sObject> { 
   
    //Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
        
        //Query through RevREcRuleMilestones
        return Database.getQueryLocator([Select Id From RevRecRuleMilestone__c where RevRecRule__r.Recognition_Type__c =: Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE]);  
    } 
   
    //Execute method     
    global void execute(Database.BatchableContext info, List<RevRecRuleMilestone__c> scope) {
        if (RevRecRuleMilestone__c.sObjectType.getDescribe().isDeletable()) {
            //Delete records
            delete scope;
        }
    }
    
     //Finish Method    
    global void finish(Database.BatchableContext info){  
        
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
        
            //Set body of the mail
            mail.setPlainTextBody(asyncBatch.ExtendedStatus);
            
            //String to hold html body
            string htmlBody = 'NumberOfErrors = ' + asyncBatch.NumberOfErrors;
            
            //Set html body of the mail
            mail.setHtmlBody(htmlBody);
            
            //If test is not running
            if(!Test.isRunningTest()) 
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   //Send the email you have created.
        }
    }
}