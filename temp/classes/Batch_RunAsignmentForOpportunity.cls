/** 
 *  Description     :	This batch class is used to update all the opportunities meeting the critera.
 *
 *  Created Date    :   30/05/2016
 *
 *  Created By      :   Bill Feeheley
 *  
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0 - Created 
**/ 
global with sharing class Batch_RunAsignmentForOpportunity implements Database.batchable<sObject>, Database.stateful {
    
    //Declaration 
    public Set<String> setOppIds = new Set<String>();
    public Id ruleToassign;
    public Id RueAssignmentToAssign;
    public String operator;
    
    //Constructor
    global Batch_RunAsignmentForOpportunity(Set<String> setOpportunityIds, Id ruleId, Id ruleAssignmentId, String operatorValue) {
        
        //Assign values
        setOppIds = setOpportunityIds ;
        ruleToassign = ruleId;
        RueAssignmentToAssign = ruleAssignmentId;
        operator = operatorValue; 
    }
    
    //Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
               
        //Query string
        String query = '';     
        query += 'Select Id, AppRopozSLN__REVvue_RuleAssignment__c, AppRopozSLN__REVvue_RevRecRule__c From Opportunity ';
        
        if(setOppIds.size() > 0) {
        	query += 'WHERE Id ' + operator;
            query += ' : setOppIds';
        }
        
        return Database.getQueryLocator(query); 
    } 
    
    //Execute method 
    global void execute(Database.BatchableContext info, List<Opportunity> opportunities) {
              
        //Loop over all of the line items 
        for(Opportunity opportunity : opportunities) {
            
            //Assigning values
            opportunity.REVvue_RevRecRule__c = ruleToAssign;
            opportunity.REVvue_RuleAssignment__c = RueAssignmentToAssign;
        }
        
        //Update oppotunities
        database.update(opportunities, false);
    }
    
     //Finish Method
    global void finish(Database.BatchableContext info) { }
}