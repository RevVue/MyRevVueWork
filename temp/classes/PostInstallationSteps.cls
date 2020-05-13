/**
 *  Description     :   Post installation class to call a batch to update historical data package installaion.
 *
 *  Created By      :   
 *
 *  Created Date    :   12/19/2014
 *
 *  Version         :   V1.1
 *
 *  Revision Log    :   V1.0 - Created - 12/19/2014  
 *
**/
global class PostInstallationSteps implements InstallHandler {
    
    //Method called on package installation 
    global void onInstall(InstallContext context) {
        //try block...
        try{
            //Abort the Job Scheduled at midnight..
            List<CronTrigger> cronTrigAbort = [SELECT Id, CronJobDetail.Name, CronJobDetail.Id, State FROM CronTrigger WHERE CronJobDetail.Name = 'Midnight Batch Schedule job'];
            if(cronTrigAbort.size() > 0)
                System.abortJob(cronTrigAbort[0].Id);
            
            //Batch initilization and calling batch
            Batch_UpdateHistoricalData  bc = new Batch_UpdateHistoricalData();
            Database.executeBatch(bc, 200);
            
            Batch_UpdateHistoricalRuleMilestones bc1 = new Batch_UpdateHistoricalRuleMilestones();
            Database.executeBatch(bc1, 200);
            
            Batch_UpdateHistoricalProductMilestones bc2 = new Batch_UpdateHistoricalProductMilestones();
            Database.executeBatch(bc2, 200);
            
            Batch_PopulateRuleOnLineItems bc5 =  new Batch_PopulateRuleOnLineItems(); 
            Database.executeBatch(bc5, 200);   
            
            Batch_UpdateHistoricalRevRecRule bc3 = new Batch_UpdateHistoricalRevRecRule();
            Database.executeBatch(bc3, 200);
            
            /** Batch_UpdateAMMilesRules bc6 = new Batch_UpdateAMMilesRules();
				Database.executeBatch(bc6, 200);    **/
            
            Batch_CompareMilesAmountForManualCal b6 = new Batch_CompareMilesAmountForManualCal();
            Database.executeBatch(b6, 200);
            
            if(context.previousVersion() != null) {
                if(context.previousVersion().compareTo(new Version(2,85)) < 0) {
                    
                    Batch_UpdateOldMilestoneForecast b7 = new Batch_UpdateOldMilestoneForecast();
                    Database.executeBatch(b7, 200);
                    
                    Batch_UpdateOldRuleMilesForecast b8 = new Batch_UpdateOldRuleMilesForecast();
                    Database.executeBatch(b8, 200);
                }
            }
            
            Batch_UpdateRuleOnOldLineItem b9 = new Batch_UpdateRuleOnOldLineItem();
            Database.executeBatch(b9, 200);
            
            //Run batch to remove revrecrule from oli that does not exist anymore now
            Batch_UpdateRuleOnOLIWithBlank b10 = new Batch_UpdateRuleOnOLIWithBlank();
            Database.executeBatch(b10, 200);
            
            //Query string
            string query = 'SELECT Id, Name, CreatedDate, CloseDate, StageName, Amount FROM Opportunity ';
            
            //Instantiate the batch annd execute with batch size 10
            Batch_MassRevenueCalculate bc4 = new Batch_MassRevenueCalculate(query);
            DataBase.executeBatch(bc4, 10);
            
            /** Post installation script to hold the product rule with family**/
            //Checking for package version
            if(context.previousVersion() == null) {
                
                //List to be inserted
                List<RevRecProductFamilySetting__c> pFamilyToBeInserted = new List<RevRecProductFamilySetting__c>();
                
                /** Getting the picklist values using describe method and populating wrapper**/
                Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();     
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                
                //Loop over picklist entries and populate wrapper
                for( Schema.PicklistEntry f : ple) {
                    pFamilyToBeInserted.add(new RevRecProductFamilySetting__c(Name = f.getLabel()));
                }  
                
                //Checking for the list size and insert the defaults
                if(pFamilyToBeInserted.size() > 0)
                    insert pFamilyToBeInserted ;
            }else {
                
                /** Getting the picklist values using describe method and populating wrapper**/
                Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe(); 
                
                //Set to hold all family name
                Set<String> setOfFamilyName = new Set<String>();
                
                //Loop over product family
                for(Schema.PicklistEntry ple : fieldResult.getPicklistValues())
                    setOfFamilyName.add(ple.getLabel()); //Adding values in set
                
                //Get already exiting records and delete them
                List<RevRecProductFamilySetting__c> pFamilyToBeDeleted = new List<RevRecProductFamilySetting__c>();
                
                //Loop over existing family setting
                for(RevRecProductFamilySetting__c fs : [Select ID, Name from RevRecProductFamilySetting__c LIMIT 50000]) {
                    
                    //Check to delete existing family setting if family doesn't exist anymore
                    if(!setOfFamilyName.contains(fs.Name))
                        pFamilyToBeDeleted.add(fs);
                    else
                        setOfFamilyName.remove(fs.Name);    // Removing family name if family setting is already exist
                }
                
                //Checking for the list size and delete
                if(pFamilyToBeDeleted.size() > 0 && (RevRecProductFamilySetting__c.sObjectType.getDescribe().isDeletable()))
                    delete pFamilyToBeDeleted;
                
                //List to be inserted
                List<RevRecProductFamilySetting__c> pFamilyToBeInserted1 = new List<RevRecProductFamilySetting__c>();
                
                //Loop over set of family Name
                for( String fName : setOfFamilyName)
                    pFamilyToBeInserted1.add(new RevRecProductFamilySetting__c(Name = fName));
                
                //Checking for the list size and insert defaults
                if(pFamilyToBeInserted1.size() > 0)
                    insert pFamilyToBeInserted1 ;
            }
            
            /*Batch_UpdateRuleMilestoneDateString b1 = new Batch_UpdateRuleMilestoneDateString();
            Database.executeBatch(b1, 200);
            
            Batch_UpdateRuleCategoryDateString b2 = new Batch_UpdateRuleCategoryDateString();
            Database.executeBatch(b2, 200);
            
            Batch_UpdateOldRuleStartAndEndDate b3 = new Batch_UpdateOldRuleStartAndEndDate();
            Database.executeBatch(b3, 200);
            
            Batch_UpdateMilestoneDateString b4 = new Batch_UpdateMilestoneDateString();
            Database.executeBatch(b4, 200);
            
            Batch_UpdateCategoryDateString b5 = new Batch_UpdateCategoryDateString();
            Database.executeBatch(b5, 200);*/           
        }
        //catch block...
        catch(Exception e) {
            System.debug(' error: '+ e);
            sendErrroMail(e.getMessage(),e.getLineNumber(),e.getTypeName(),e.getCause(),e.getStackTraceString());              
        } 
    }
    
    //method to capture the error message if the post installation script failed / generate any error....
    public static void sendErrroMail(String errorMessage, Integer errorLineNumber, String errorType, Exception errorCause, String errorStackTrace){              
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'taruna.sharma@fexle.com'};
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('support@id.com');  
        mail.setSenderDisplayName('Apex error message');
        mail.setSubject('Error from Org : ' + UserInfo.getOrganizationName());
        String errorMsg = 'Error Line Number --> '+errorLineNumber;
        errorMsg += ' Error Message -->  ' +errorMessage;
        errorMsg += 'Error Type -->  '+ errorType;
        errorMsg += 'Error Cause --> '+errorCause;
        errorMsg += 'errorStackTrace --> '+errorStackTrace;
        mail.setPlainTextBody(errorMsg);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}