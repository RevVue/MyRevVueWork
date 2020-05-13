/**
*  Description     :	Batch Class to update Revenue recognition on all the opportunities line item records From Rule to product assignment tab
*
*  Created By      :	Fexle Services Private Limited   
*
*  Created Date    :	10/16/2019
*
*  Version         :	V1.0
*
**/
global with sharing class Batch_RuleAssignmentOnOLI implements Database.batchable<OpportunityLineItem> , Database.stateful {  
    
    //Variable to pass in method calling
    global List<OpportunityLineItem> oppLineItemToBeUpdated;
    global Integer totalProcessed = 0;  
    
    //Constructor
    global Batch_RuleAssignmentOnOLI(List<OpportunityLineItem> oppLineItems) {
        
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
        
    }
}