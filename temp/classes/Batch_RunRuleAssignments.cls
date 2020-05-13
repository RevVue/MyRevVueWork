/** 
 *	Description		:	This batch is used to run rule assignments.
 *
 *	Created Date	:	11/05/2016
 *	
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0 - Created 
**/
global with sharing class Batch_RunRuleAssignments implements Database.batchable<sObject> , Database.stateful {
	
	public Set<String> setOppIds = new Set<String>();
	public Set<String> setProductIds = new  Set<String>();
	public Set<String> setFamilies = new  Set<String>();
	public String opportunityOperator; 
	public String productOperator;
	public String familyOperator;
	public Id ruleToAssign;
	public Id ruleAssigID;
	public Set<Id> setOfOppportunitiesToBeExecuted; 
	
	//Constructer
	global Batch_RunRuleAssignments(Set<String> setOfOppsIds , Set<String> setOfProductsIds, Set<String> setOfFamilies, String opportunityOperators,
					 			    String productOperators, String familyOperators , Id ruleToAssignment, Id ruleAssignmentID) {
					 			    	
		//Assign values
		setOppIds = setOfOppsIds ;
		setProductIds = setOfProductsIds;
		setFamilies = setOfFamilies;
		opportunityOperator = opportunityOperators;
		productOperator = productOperators;
		familyOperator = familyOperators;
		ruleToAssign = ruleToAssignment;
		ruleAssigID = ruleAssignmentID;
		setOfOppportunitiesToBeExecuted =  new Set<Id>();
	}
	
	//Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
        
        //Query string
        string query = '';     
        query += 'Select Id, Name , Product2Id, Product2.Family ,  RevRecRule__c , OpportunityId From OpportunityLineItem ';
        query += 'WHERE ';
        
        if(setOppIds.size() > 0)
        	query += ' OpportunityId '+ opportunityOperator +' : setOppIds AND ';
        
        if(setProductIds.size() > 0)
        	query += ' Product2Id '+ productOperator +' : setProductIds AND ';
        
        if(setFamilies.size() > 0)
        	query += ' Product2.Family '+familyOperator+' : setFamilies';
			
		//Removing last AND and WHERE operator 
        query = query.removeEnd('AND ');
        query = query.removeEnd('WHERE ');
        query = query.trim();
        
        return Database.getQueryLocator(query);
    } 
    
    //Execute method 
    global void execute(Database.BatchableContext info, List<OpportunityLineItem> oppLines) {
    	
    	//List of opportunities to be updated
    	List<Opportunity> listOppsToBeUpdated = new List<Opportunity>();
    	
    	//Loop over all of the line items 
    	for(OpportunityLineItem oli : oppLines) {
    		oli.RevRecRule__c = ruleToAssign;
            oli.Rule_Assignment__c = ruleAssigID;
    		setOfOppportunitiesToBeExecuted.add(oli.OpportunityId);
    	}
    	
    	//Loop over set of opps
    	for(Id oppId : setOfOppportunitiesToBeExecuted) 
	   		listOppsToBeUpdated.add(new Opportunity(Id = oppId , REVvue_RevRecRule__c = ruleToAssign, REVvue_RuleAssignment__c = ruleAssigID));
    	
    	//Update opp line items 
    	database.update(listOppsToBeUpdated, false);
    	database.update(oppLines, false); 
    	
    } 
    
     //Finish Method
	global void finish(Database.BatchableContext info) { 
		
		//Calling batch from Trigger
    	//Instantiate the batch annd execute with batch size 10
    	if(setOfOppportunitiesToBeExecuted.size() > 0) {
    		
	        Batch_MassRevenueCalculate bc = new Batch_MassRevenueCalculate('Select Id FROM Opportunity' , setOfOppportunitiesToBeExecuted);
	        DataBase.executeBatch(bc, 1);
    	}
	}
}