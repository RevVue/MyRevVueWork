/**
 *  Description     :   Batch Class to update the Milestone date source field of "RevRecProductRuleMilestone__c" with manual.
 *						Since It is a new field : Existing data need to be populated.
 *						
 *  Created By      :	
 *
 *  Created Date    :   01/20/2015
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   V1.0 - Created - 01/20/2015  
 *
**/
global with sharing class Batch_UpdateHistoricalProductMilestones implements Database.batchable<sObject>{
    
    //Query String 
    string queryString;
    
    //list of Milestones to be updated
    List<RevRecProductRuleMilestone__c> milestonesToBeUpdated = new List<RevRecProductRuleMilestone__c>();
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRuleMilesResult = Utility.getFieldPermissions('RevRecProductRuleMilestone__c');
    
    //Constructer initilization
    global Batch_UpdateHistoricalProductMilestones () {
        
        //Query string 
        queryString = 'Select Id, Milestone_Date_Source__c, Milestone_Date_Source_Label__c From RevRecProductRuleMilestone__c' 
        				+ ' WHERE  Milestone_Date_Source__c = \'\' AND Milestone_Date_Source_Label__c = \'\'' ;
    }
        
    //Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
    	
    	//Query through RrevRecLineItemSchedules 
        return Database.getQueryLocator(queryString);  
    } 
   
    //Execute method     
    global void execute(Database.BatchableContext info, List<RevRecProductRuleMilestone__c> scope) {
        
        //Checking for list size
        if(scope.size() >0)  {
        	
        	//loop through milestones
            for(RevRecProductRuleMilestone__c mileStone : scope) {
                
                //Put Manual into date source field
                if(Utility.checkFieldPermission(mapfieldRuleMilesResult,'Milestone_Date_Source__c',Constants.PERMISSION_UPSERT))
                    mileStone.Milestone_Date_Source__c = constants.MILESTONE_DATE_MANUAL;
                if(Utility.checkFieldPermission(mapfieldRuleMilesResult,'Milestone_Date_Source_Label__c',Constants.PERMISSION_UPSERT))
                    mileStone.Milestone_Date_Source_Label__c = constants.MILESTONE_DATE_MANUAL;
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleMilestone__c'))
                    milestonesToBeUpdated.add(mileStone);
                
                System.debug('#@@@@@@@@'+milestonesToBeUpdated);
            }
        }
        
        //checking for list size
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecProductRuleMilestone__c')){
            if(milestonesToBeUpdated.size() >0)
                database.update(milestonesToBeUpdated, false);
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