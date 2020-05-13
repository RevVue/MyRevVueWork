/**
 *  Description     :   Batch Class to update Revenue recognition on all the opportunities records matching the filter criteria
 *
 *  Created By      :   
 *
 *  Created Date    :   03/24/2017
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   03/24/2017- Created  
 *
**/
global with sharing class Batch_MassRuleAssignmentOnOLI implements Database.batchable<OpportunityLineItem> , Database.stateful {  
	
    //Variable to pass in method calling
    global List<OpportunityLineItem> oppLineItemToBeUpdated;
    global Integer totalProcessed = 0;  
    
    //Constructor
    global Batch_MassRuleAssignmentOnOLI(List<OpportunityLineItem> oppLineItems) {
        
		//Initialization
        oppLineItemToBeUpdated = oppLineItems;        
    }
    
    //Start Method for batch with database.querylocater return type
    global Iterable<OpportunityLineItem> start(Database.BatchableContext info) { 
    	
        return oppLineItemToBeUpdated; //Returinig OLI list to process
    }
    
    //Execute method 
    global void execute(Database.BatchableContext info, List<OpportunityLineItem> opportunityLineItem) { 
    	
        totalProcessed += opportunityLineItem.size();
    	update opportunityLineItem; 
    }
    
    //Finish Method
    global void finish(Database.BatchableContext info) {
        
        //Single email Initilization
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
            String htmlBody  = 'Batch_MassRuleAssignmentOnOLI'+' '+string.valueOf(totalProcessed)+' '+Label.Records;
            
            //set body of email
            mail.setHtmlBody(htmlBody);
            
            System.debug('htmlBody...@@@' + htmlBody);
            // Send the email you have created.
            // If test is not running
            if(!Test.isRunningTest()) 
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}