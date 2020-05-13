/** 
 *	Description		:	This batch is used to update/ Assign rule on products by checking in rule assignment rules.
 *
 *	Created Date	:	12/05/2016
 *	
 *	Version			:	V_1.0
 *
 *	Revision Log	:	V_1.0 - Created 
**/
global with sharing class Batch_RunRuleAssignmentForProducts implements Database.batchable<sObject> , Database.stateful {
	
	public Set<String> setProductIds = new  Set<String>();
	public Set<String> setFamilies = new  Set<String>();
	public String productOperator;
	public String familyOperator;
	public Id ruleToAssign;
    public Id ruleAssignmentId;
	
	//Constructer
	global Batch_RunRuleAssignmentForProducts( Set<String> setOfProductsIds, Set<String> setOfFamilies,
					 			    String productOperators, String familyOperators , Id ruleToAssignment, 
                                    Id ruleAssignId) {
					 			    	
		//Assign values
		setProductIds = setOfProductsIds;
		setFamilies = setOfFamilies;
		productOperator = productOperators;
		familyOperator = familyOperators;
		ruleToAssign = ruleToAssignment;
        ruleAssignmentId = ruleAssignId;
	}
	
	//Start Method for batch with database.querylocater return type
    global Database.queryLocator start(Database.BatchableContext info) { 
        
        //Query string
		string queryProd = '';     
		queryProd += 'Select Id, Family , RevRecRule__c  From Product2 ';
		queryProd += 'WHERE ';
		
		if(setProductIds.size() > 0)
			queryProd += ' Id '+ productOperator +' : setProductIds AND ';
		
		if(setFamilies.size() > 0)
			queryProd += ' Family '+familyOperator+' : setFamilies';
			
		//Removing last AND and WHERE operator 
		queryProd = queryProd.removeEnd('AND ');
		queryProd = queryProd.removeEnd('WHERE ');
		queryProd = queryProd.trim();

		//Return query
        return Database.getQueryLocator(queryProd);
    } 
    
    //Execute method 
    global void execute(Database.BatchableContext info, List<Product2> products) {
    	
    	//Loop over all of the line items 
        for(Product2 prd : products) {
            
    		prd.RevRecRule__c = ruleToAssign;
        	prd.Rule_Assignment__c = ruleAssignmentId;    	
        }
        
    	//Update opp line items 
    	update products;
    }
    
     //Finish Method
	global void finish(Database.BatchableContext info) { 
	}
}