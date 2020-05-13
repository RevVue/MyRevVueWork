/**
*  Description     :   Batch Class to calculate the monthly and yearly rollup calculations on all the opportunities records 
*
*  Created By      :	Bill Feeheley   
*
*  Created Date    :   12/18/2019
*
*  Version         :   V1.0
*
**/
global with sharing class Batch_MassRollUpRevenueCalculation implements Database.batchable<Opportunity>, Database.stateful{  
    
    //Variable to pass in method calling
    global List<Opportunity> opportunityToBeUpdated;
    global Integer totalProcessed = 0;
    global Boolean isExecuteBatch = false;
    
    //Constructor
    global Batch_MassRollUpRevenueCalculation(List<Opportunity> opportunities) {
        
        //Initialization
        opportunityToBeUpdated = opportunities;        
    }
    
    //Constructor
    global Batch_MassRollUpRevenueCalculation(List<Opportunity> opportunities, Boolean isExecuteBatch) {
        
        //Initialization
        opportunityToBeUpdated = opportunities;
        this.isExecuteBatch = isExecuteBatch;
        //System.debug('Inside contructor method isExecuteBatch -->'+isExecuteBatch);
    }
    
    //Start Method for batch with database.querylocater return type
    global Iterable<Opportunity> start(Database.BatchableContext info) { 
        
        return opportunityToBeUpdated; //Returinig Opportunity list to process
    }
    
    //Execute method 
    global void execute(Database.BatchableContext info, List<Opportunity> opportunity) { 
        
        MassRollUpCalculateController massRollController  = new MassRollUpCalculateController();
        if(opportunity.size() > 0)
            massRollController.MassRollupRevenueCalculation(opportunity);
        
        totalProcessed += opportunity.size();
    }
    
    //Finish Method
    global void finish(Database.BatchableContext info) {
        if(isExecuteBatch == true){
            //Single email Initilization
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            //Query result of Async Jobs
            AsyncApexJob asyncBatch = [Select Id, CompletedDate, ExtendedStatus, Status, 
                                       JobItemsProcessed, NumberOfErrors, TotalJobItems, ApexClass.name,
                                       CreatedBy.Email, CreatedBy.FirstName , CreatedBy.Name FROM AsyncApexJob WHERE Id =:info.getJobId()]; 
           
            //Check for not null
            if(string.IsNotBlank(asyncBatch.CreatedBy.Email)) {
                
                //Set to addresses
                //mail.setToAddresses(new string[]{'ballary@fexle.com'});
                mail.setToAddresses(new string[]{asyncBatch.CreatedBy.Email}); 
                
                // Specify the subject line for your email address.
                mail.setSubject('Batch job has been Completed ');
                
                // Set to True if you want to BCC yourself on the email.
                mail.setBccSender(false);
                
                // Optionally append the salesforce.com email signature to the email.
                // The email address of the user executing the Apex Code will be used.
                mail.setUseSignature(false);
                
                //Variable to hold email body
                String htmlBody  = 'Batch_MassRollUpRevenueCalculation'+' '+string.valueOf(totalProcessed)+' '+Label.Records;
                
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
}