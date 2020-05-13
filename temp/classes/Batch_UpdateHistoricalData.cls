/**
 *  Description     :   Batch Class to blank update RevrecSchedules records so External_OpportunityLineItemId__c will  
 *                      populated via  workflow on all schedules which were already exist in the org with feild value blank with them.  
 *                      This field was created to Resolve Non selective query issue.
 *
 *  Created By      :   
 *
 *  Created Date    :   12/19/2014
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   V1.0 - Created - 12/19/2014  
 *
**/
global with sharing class Batch_UpdateHistoricalData implements Database.batchable<sObject> { 
    
    //Query String 
    string queryString;
    
    //Constructer initilization
    global Batch_UpdateHistoricalData () {
        
        //Query string 
        queryString = 'Select Id, External_OpportunityLineItemId__c From RevRecOpportunityLineItemSchedule__c' 
        				+ ' WHERE External_OpportunityLineItemId__c = \'\'' ;
    }
        
    //Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
    	
    	//Query through RrevRecLineItemSchedules 
        return Database.getQueryLocator(queryString);  
    } 
   
    //Execute method     
    global void execute(Database.BatchableContext info, List<RevRecOpportunityLineItemSchedule__c> scope) {
        
        //Blank update all records 
        if(scope.size() >0)
        	update scope;
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
			mail.setToAddresses(new string[]{'Salesforce.security@gmail.com'});
			
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
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	//Send the email you have created
   		}
    }
}