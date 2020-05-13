/**
 *  Description     :   Batch Class to update the RevRecRule records. As we have added new field Milestone_Type__c so need to populate the existing
 *						records. We are putting default - "Percenrt".
 *						
 *  Created By      :
 *
 *  Created Date    :   02/27/2015
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   V1.0 - Created - 02/27/2015  
 *
**/
global with sharing class Batch_UpdateHistoricalRevRecRule implements Database.batchable<sObject> {  
    
    //Query String 
    string queryString;
     
    //list of Rules to be updated
    List<RevRecRules__c> rulesToBeUpdated = new List<RevRecRules__c>();
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRuleResult = Utility.getFieldPermissions('RevRecRules__c');

    //Constructer initilization
    global Batch_UpdateHistoricalRevRecRule () {
        
        //Query string 
        queryString = 'Select Id, Milestone_Type__c  From RevRecRules__c' 
        				+ ' WHERE  Milestone_Type__c = \'\'' ;
    }
        
    //Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
    	
    	//Query through RrevRecLineItemSchedules 
        return Database.getQueryLocator(queryString);  
    } 
   
    //Execute method     
    global void execute(Database.BatchableContext info, List<RevRecRules__c> scope) {
        
        //Checking for list size
        if(scope.size() >0)  {
        	
        	//loop through rules
        	for(RevRecRules__c rule : scope) {
        		
        		//Put Percent into Milestone type field
                if(Utility.checkFieldPermission(mapfieldRuleResult,'Milestone_Type__c',Constants.PERMISSION_UPSERT))
                    rule.Milestone_Type__c = 'percent';
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecRules__c'))
                    rulesToBeUpdated.add(rule);
                
        		System.debug('#@@@@@@@@'+rulesToBeUpdated);
        	}
        }
        
        //checking for list size
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecRules__c')){
            if(rulesToBeUpdated.size() >0)
                database.update(rulesToBeUpdated, false);
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
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	// Send the email you have created
   		}
    }
}