/**
 *  Description         :   This is a handler for OpportunityLineItem trigger.
 *
 *  Created By          :   Bill Feeheley
 *
 *  Created Date        :   04/19/2016
 *
 *  Version             :   V_1.0 
 * 
 *  Revision Log        :   V_1.0 - Created 
 **/
public without sharing class OpportunityLinetemTriggerHelper { 
    
    //Opportunity line item to update
    public static  Map<Id, OpportunityLineItem> mapOfIdAndOpportunityLineItemToBeUpdated = new Map<Id, OpportunityLineItem>();
    public static Map<Id,Product2> mapIdWithProduct2 = new Map<Id,Product2>();
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRuleResult = Utility.getFieldPermissions('RevRecProductRule__c');
    Static Map<String, Schema.DescribeFieldResult> mapfieldOLIResult = Utility.getFieldPermissions('RevRecOpportunityLineItem__c');
    
    /**
     *  @description    :   This method is used to run Rule assignment whenever any line item is added on opportunity.
     *                      It will search any rule assignment with matching criteria and assign that rule on the line item.
     *
     *  @args           :   List<OpportunityLineItem> newLineItems
     *
     *  @return         :   
    **/
    public static void runRuleAssignments(List<OpportunityLineItem> newLineItems) {
        
        //Map to hold Rule Assignment with Id 
        Map<Id, Rule_Assignment__c> mapRuleAssignments = new Map<Id, Rule_Assignment__c>();
        
        //Map to hold Criteria field with Operator
        Map<Id , List<Rule_Assignment_Criteria__c>>  mapRuleAssignmentWithCriterias = new Map<Id , List<Rule_Assignment_Criteria__c>>();
        
        //Set of opportunity on which batch is going to execute
        Set<Id> setOpportunityIdsToBeProcessedForBatch = new Set<Id>();
        List<OpportunityLineItem> oppLines = new List<OpportunityLineItem>();
        
        //Query through All rule Assignments  and populating map
        for(Rule_Assignment__c ruleAsg : [Select Id, Active__c, Details__c, Opportunity_Name__c, Product_Family__c, Product_Name__c,
                                          RevRecRule__c, Selected_Familys__c, Selected_Opportunity_Ids__c, Selected_Product_Ids__c,
                                          (Select Id, Operator__c, Criteria_Field__c FROM Rule_Assignment_Criterias__r LIMIT  3)
                                          FROM Rule_Assignment__c WHERE Active__c = true order by LastModifiedDate DESC LIMIT 2000]) {
                
            //Cheacking for the Rule assignment criterias
            if(ruleAsg.Rule_Assignment_Criterias__r.size() > 0) {
                
                //Populating map                                
                mapRuleAssignments.put(ruleAsg.Id , ruleAsg);
                mapRuleAssignmentWithCriterias.put(ruleAsg.Id, ruleAsg.Rule_Assignment_Criterias__r);
            }
        }
         
      	Set<Id> setProduct2Ids = new Set<Id>();
        
        for(OpportunityLineItem oli: newLineItems) {
            
            setProduct2Ids.add(oli.Product2Id);
            oppLines.add(oli);
        }
        
        mapIdWithProduct2 = new Map<ID, Product2>([Select Id, Family, RevRecRule__c, Rule_Assignment__c
                                                   From Product2 where Id IN : setProduct2Ids]);
    		
        //Chekcing for the Rule Assignment size
        if(mapRuleAssignments.size() > 0) {
           
            //Loop over all Assignment RULES
            for(Rule_Assignment__c rule : mapRuleAssignments.values()) {
                
                //Set of operators
                Map<String,String> mapOperatorsWithField = new Map<String, String>();
                
                //Loop over childs
                for(Rule_Assignment_Criteria__c ruleAsgCriteria : mapRuleAssignmentWithCriterias.get(rule.Id)) 
                    mapOperatorsWithField.put(ruleAsgCriteria.Criteria_Field__c , ruleAsgCriteria.Operator__c);
                
                //Loop over All Trigger.New Line items
                for(OpportunityLineItem oppLine : oppLines) {
                    
                    //Boolean 
                    Boolean isRuleFound = false;
                
                    /**1. First we are checking for the selected opportunity ids **/
                    if(String.isNotBlank(rule.Selected_Opportunity_Ids__c)) {
                        
                        //Checking for contains key
                        //It means there is a rule
                        if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_OPPORTUNITY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_OPPORTUNITY_NAME) == Constants.OPERATOR_IN) {
                            
                            if(rule.Selected_Opportunity_Ids__c.Contains(oppLine.OpportunityId)) {
                                
                                //Checking for if : Product Name and Family both are in criteria
                                if(String.isNotBlank(rule.Selected_Product_Ids__c) && String.isNotBlank(rule.Product_Family__c)) {
                                    
                                    //Checking for operator , EQUALS
                                    if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_IN) {
                        
                                        if(rule.Selected_Product_Ids__c.contains(oppLine.Product2Id) ) {
                                            
                                            //Checking for operator , EQUALS
                                            if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                                            
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) 
                                                    isRuleFound = true;
                                            }else if (mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                                
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family))
                                                    isRuleFound = true;
                                            }
                                        }
                                    }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_NOT_IN) {
                                        
                                        if(!rule.Selected_Product_Ids__c.contains(oppLine.Product2Id) ) {
                                            
                                            //Checking for operator , EQUALS
                                            if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                                            
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) 
                                                    isRuleFound = true;
                                            }else if (mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                                
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family))
                                                    isRuleFound = true;
                                            }                                           
                                        }
                                    }
                                //If product and family both blank
                                }else if(String.isBlank(rule.Selected_Product_Ids__c) && String.isBlank(rule.Product_Family__c)) {
                                    isRuleFound = true;
                                
                                //Checking if Product id selected but not family seletced 
                                }else if(String.isNotBlank(rule.Selected_Product_Ids__c) && String.isBlank(rule.Selected_Familys__c)) {
                                    
                                    //Checking for operator , EQUALS
                                    if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_IN) {
                        
                                        if(rule.Selected_Product_Ids__c.contains(oppLine.Product2Id)) 
                                            isRuleFound = true;
                                        
                                    //Checking for operator , NOT EQUALS
                                    }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_NOT_IN) {
                        
                                        if(!rule.Selected_Product_Ids__c.contains(oppLine.Product2Id)) 
                                            isRuleFound = true;
                                    }
                                //Checking if family  selected but not product name  seletced 
                                }else if(String.isNotBlank(rule.Selected_Familys__c) && String.isBlank(rule.Selected_Product_Ids__c)) {
                                    
                                    //Checking for operator , EQUALS
                                    if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                        
                                        if(String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                            isRuleFound = true;
                                        }
                                    }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                        
                                        if(String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                            isRuleFound = true;
                                        }
                                    }
                                }
                            }
                        }else if (mapOperatorsWithField.containsKey(Constants.FIELD_NAME_OPPORTUNITY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_OPPORTUNITY_NAME) == Constants.OPERATOR_NOT_IN) {
                            if(rule.Selected_Opportunity_Ids__c.Contains(oppLine.OpportunityId)) {
                                
                                //Checking for if : Product Name and Family both are in criteria
                                if(String.isNotBlank(rule.Selected_Product_Ids__c) && String.isNotBlank(rule.Selected_Familys__c)) {
                                    
                                    //Checking for operator , EQUALS
                                    if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_IN) {
                        
                                        if(rule.Selected_Product_Ids__c.contains(oppLine.Product2Id) ) {
                                            
                                            //Checking for operator , EQUALS
                                            if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                                            
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family))
                                                    isRuleFound = true;
                                            }else if (mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                                
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family))
                                                    isRuleFound = true;
                                            }
                                        }
                                    }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_NOT_IN) {
                                        
                                        if(!rule.Selected_Product_Ids__c.contains(oppLine.Product2Id) ) {
                                            
                                            //Checking for operator , EQUALS
                                            if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                                            
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) 
                                                    isRuleFound = true;
                                            }else if (mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                                
                                                //Checking if line item family is exist in rule assignmemt
                                                if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family))
                                                    isRuleFound = true;
                                            }                                           
                                        }
                                    }
                                //If product and family both blank
                                }else if(String.isBlank(rule.Selected_Product_Ids__c) && String.isBlank(rule.Product_Family__c)) {
                                    isRuleFound = true;
                                
                                //Checking if Product id selected but not family seletced 
                                }else if(String.isNotBlank(rule.Selected_Product_Ids__c) && String.isBlank(rule.Selected_Familys__c)) {
                                    
                                    //Checking for operator , EQUALS
                                    if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_IN) {
                        
                                        if(rule.Selected_Product_Ids__c.contains(oppLine.Product2Id)) 
                                            isRuleFound = true;
                                        
                                    //Checking for operator , NOT EQUALS
                                    }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_NOT_IN) {
                        
                                        if(!rule.Selected_Product_Ids__c.contains(oppLine.Product2Id)) 
                                            isRuleFound = true;
                                    }
                                //Checking if family  selected but not product name  seletced 
                                }else if(String.isNotBlank(rule.Selected_Familys__c) && String.isBlank(rule.Selected_Product_Ids__c)) {
                                    
                                    //Checking for operator , EQUALS
                                    if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                        
                                        if(String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                            isRuleFound = true;
                                        }
                                    }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                        
                                        if(String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                            isRuleFound = true;
                                        }
                                    }
                                }
                            }
                        }
                    /**2  we are checking for the selected product ids **/
                    }else if(String.isNotBlank(rule.Selected_Product_Ids__c)) {
                        
                        //Checking for operator , EQUALS
                        if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_IN) {
                        	
                            //Checking if opportunity line item's Product Id is exist in Rule assignment criteria
                            if(rule.Selected_Product_Ids__c.contains(oppLine.Product2Id)) {
                                 
                                //Checking for operator , EQUALS
                                if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                        			
                                    //Checking if opportunity line item's Product family is exist in Rule assignment criteria
                                    if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                        isRuleFound = true;
                                    }
                                }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                    
                                    //Checking if opportunity line item's Product family is exist in Rule assignment criteria
                                    if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                        isRuleFound = true;
                                    }
                                }else if(!mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME)) 
                                    isRuleFound = true;
                            }
                        }else if (mapOperatorsWithField.containsKey(Constants.FIELD_NAME_PRODUCT_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_PRODUCT_NAME) == Constants.OPERATOR_NOT_IN) {
                            
                            //Checking if opportunity line item's Product Id is exist in Rule assignment criteria
                            if(!rule.Selected_Product_Ids__c.contains(oppLine.Product2Id)) {
                                    
                                //Checking for operator , EQUALS
                                if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                        
                                    //Checking if opportunity line item's Product family is exist in Rule assignment criteria
                                    if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                        isRuleFound = true;
                                    }
                                }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                                    
                                    //Checking if opportunity line item's Product family is exist in Rule assignment criteria
                                    if(String.isNotBlank(rule.Selected_Familys__c) && String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                        isRuleFound = true;
                                    }
                                }
                            }
                        }
                    /**3  we are checking for the selected product familys  **/
                     }else if(String.isNotBlank(rule.Selected_Familys__c)) {
                        
                        //Checking for operator , EQUALS
                        if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_IN) {
                            
                            //Checking if opportunity line item's Product family is exist in Rule assignment criteria
                            //If yes then add that opportunity id into set of id to be execute in batch
                            //And assign rule on the line item
                            if(String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                isRuleFound = true;
                            }
                        
                        //Checking for operator , NOT EQUALS
                        }else if(mapOperatorsWithField.containsKey(Constants.FIELD_NAME_FAMILY_NAME) && mapOperatorsWithField.get(Constants.FIELD_NAME_FAMILY_NAME) == Constants.OPERATOR_NOT_IN) {
                            
                            if(String.isNotBlank(mapIdWithProduct2.get(oppLine.Product2Id).Family) && !rule.Selected_Familys__c.contains(mapIdWithProduct2.get(oppLine.Product2Id).Family)) {
                                isRuleFound = true;
                            }
                        }
                    }
                    
                    //Checking for if rule found for the line item 
                    if(isRuleFound) {
                           
                        setOpportunityIdsToBeProcessedForBatch.add(oppLine.OpportunityId);
                        oppLine.RevRecRule__c = rule.RevRecRule__c;
                        oppLine.Rule_Assignment__c = rule.Id;
                        mapOfIdAndOpportunityLineItemToBeUpdated.put(oppLine.Id, oppLine);
                    }
                }
            }
        }
        //update opportunityLineItemToBeUpdated;
        
        if(setOpportunityIdsToBeProcessedForBatch.size() > 0) {
            //If test is not running
            if(!Test.isRunningTest()) {
    
                //Fetching opportunity to update batch flag
                List<Opportunity> opportunityToBeUpdate = new List<Opportunity>();  
    
                //Loop to set flag                                           
                for(Id oppId : setOpportunityIdsToBeProcessedForBatch) {
                    opportunityToBeUpdate.add(new Opportunity(Id = oppId, REVvue_ExecMassCalc__c = true));
                }
                
                update opportunityToBeUpdate;    
    
                //Check if teh batch is already running, do not need to execute it again
                List<AsyncApexJob> aSyncJobs = [Select Id, Status From AsyncApexJob Where ApexClass.Name = 'Batch_MassRevenueCalculate' 
                                                AND Status IN: Constants.ASYNC_APEX_JOB_PENDING_STATUSES];
    
                if(aSyncJobs.size() == 0){
    
                    //Calling batch from Trigger
                    //Instantiate the batch annd execute with batch size 10
                    Batch_MassRevenueCalculate bc = new Batch_MassRevenueCalculate('Select Id FROM Opportunity' , setOpportunityIdsToBeProcessedForBatch);
                    DataBase.executeBatch(bc, 1);
                }
            }else {
                
                //Calling batch from Trigger
                //Instantiate the batch annd execute with batch size 10
                Batch_MassRevenueCalculate bc = new Batch_MassRevenueCalculate('Select Id FROM Opportunity' , setOpportunityIdsToBeProcessedForBatch);
                DataBase.executeBatch(bc, 50);
            }
        }
    }
    
    /**
     *  @purpose    :   This method is used to set opportunityLineItem RevRecRule field values.
     *
     *  @return     :   
     *
     *  @args       :   Trigger.New(list of oportunityLineItem)
     **/
    public static void setRevRecRuleFieldValue(List<OpportunityLineItem> newOpportunityLineItems) {
        RevRecRules__c defaultRule = null;
        
        //Fetching all rules
        List<RevRecRules__c> allDefaultRules = [SELECT Id,name, Active__c, Default_Rule__c
                                                FROM RevRecRules__c where  Active__c = true AND Default_Rule__c = true
                                                order by LastModifiedDate DESC limit 1];
        
        //If many rules then set first as default
        if(allDefaultRules.size() > 0) 
            defaultRule = allDefaultRules[0];
        
        //Initialization
        //Set to hold opportunity id's
        Set<Id> setOpportunityIds = new Set<Id>();
        
        //Map to hold opportunity
        Map<Id,Opportunity> mapIdWithOpportunity;
        
        if(newOpportunityLineItems.size() > 0) {
            
            //Loop to fetch opportunityLineItem
	        for(OpportunityLineItem opportunityLineItem : newOpportunityLineItems) {
	            
	            //Check if AppRopozSLN__RevRecRule__c field in null 
	            if(opportunityLineItem.RevRecRule__c == null){
	                
	                //Adding values in set
	                setOpportunityIds.add(opportunityLineItem.OpportunityId);
	            } 
	        } 
        }
        
        if(setOpportunityIds.size() > 0) {
	        
	        //Fetching product2 data
	        mapIdWithOpportunity = new Map<ID, Opportunity>([Select Id, REVvue_RuleAssignment__c, REVvue_RevRecRule__c 
	                                                         From Opportunity where Id IN : setOpportunityIds]);
        }
        
        if(newOpportunityLineItems.size() > 0) {
	        
	        //Loop to fetch opportunityLineItem
	        for(OpportunityLineItem opportunityLineItem : newOpportunityLineItems) {
	         
	            //Check if AppRopozSLN__RevRecRule__c field in null 
	            if(opportunityLineItem.RevRecRule__c == null) {
                    
                    Product2 product;
                    Opportunity opportunity;

                    //Fetching product and opportunity instance from map
                    if(mapIdWithProduct2.containsKey(opportunityLineItem.Product2Id)) {
                        product = mapIdWithProduct2.get(opportunityLineItem.Product2Id);
                    }
                    //System.assert(false,mapIdWithOpportunity );
                    if(mapIdWithOpportunity.containsKey(opportunityLineItem.OpportunityId)) {
                        opportunity = mapIdWithOpportunity.get(opportunityLineItem.OpportunityId);
                    }
	                //Flag if product has any rule
	                Boolean isProductHasRule = false;
	                
	                if(product != null) {
		                //Assigning product rule on opportunity line item, if exist
		                if(product.RevRecRule__c != null) {
		                    
		                    //Assigning rule
		                    opportunityLineItem.RevRecRule__c =  product.RevRecRule__c;
		                    
		                    //Assigning product rule assignment on opportunity line item, if exist
		                    if(product.Rule_Assignment__c != null)
		                        opportunityLineItem.Rule_Assignment__c =  product.Rule_Assignment__c;
		                       
		                	isProductHasRule = true;
		                }
	                }
                    if(opportunity != null && !isProductHasRule) {
                        //Assigning opportunity rule on opportunity line item, if exist
                        if(opportunity.REVvue_RevRecRule__c != null) {
                            //Assigning rule
                            opportunityLineItem.RevRecRule__c =  opportunity.REVvue_RevRecRule__c;
                            
                            //Assigning opportunity rule assignment on opportunity line item, if exist
                            if(opportunity.REVvue_RuleAssignment__c != null)
                                opportunityLineItem.Rule_Assignment__c =  opportunity.REVvue_RuleAssignment__c;
                        }
                        else {
                            //Assigning default rule , if exist
                            if(defaultRule != null) 
                                opportunityLineItem.RevRecRule__c = defaultRule.Id;
                        }
                    }                    
                } 
            }
        }
 	}
    
   /** 
    *
    * This method is used to proccess revrec again
    *
   **/
	public static void updateRevVueProcessOnChange(List<OpportunityLineItem> newLines , Map<Id, OpportunityLineItem> oldOpportunities) {
		
		//Set of RevRecOpportunityLineItem__c IDS
		Set<Id> setRevRecIds = new Set<Id>();
		
	   	//Loop over Trigger.Neew 
	   	for(OpportunityLineItem oppLine : newLines) {
	   		
	   		if(oppLine.RevRecOpportunityLineItem__c != null) {
	   		
	   			//If total price changee
		   		if(oppLine.TotalPrice != oldOpportunities.get(oppLine.Id).TotalPrice)  {
		   					   			
		   			//Setting consyanys values
		   			Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE = true;
		   			//Adding values inthe set
	   				setRevRecIds.add(oppLine.RevRecOpportunityLineItem__c);
		   		}	   	
	   		}
	   	}
	   	
	   	if(setRevRecIds.size() > 0) {
	   		
	   		//Map oof rules
			Map<Id , RevRecProductRule__c> mapRevRecRules = new Map<Id , RevRecProductRule__c>();
		
			//Query all line items and related override rules 
			for(RevRecOpportunityLineItem__c revrecItem : [Select Id, Name, Opportunity__c, 
														   (Select Id FROM RevRecProductRules__r) 
														   From RevRecOpportunityLineItem__c WHERE ID IN : setRevRecIds]) {
								
				//Loop over inline ressylts
				if(revrecItem.RevRecProductRules__r.size() > 0) {
				
					//Loop over list 
					for(RevRecProductRule__c rule : revrecItem.RevRecProductRules__r) 
						mapRevRecRules.put(rule.Id , rule);
				}
			}
			
			if(mapRevRecRules.size() > 0)
				update mapRevRecRules.values();
	   	}
   }
    
    /**
    *   description     :   This method is used to calculate the date change dynamically related too the rule
    *
    *   args            :
    *
    *   return          :   
    **/  
    public static void calculateDateChange(List<OpportunityLineItem> newLines , Map<Id, OpportunityLineItem> mapOldOppLineItems) {
        System.debug('Entering the method -->');
        
        //Map oof rules
        Map<Id , List<RevRecProductRule__c>> mapRevRecRules = new Map<Id , List<RevRecProductRule__c>>();
        Set<Id> setOpportunityIds = new Set<Id>();
        Set<Id> setRROLIIds = new Set<Id>();
        Boolean processFurther = false;
        
        //rule to update
        List<RevRecProductRule__c> rulesToUpdate = new List<RevRecProductRule__c>();
        
        for(OpportunityLineItem oppLineItem : newLines) {
            
            setOpportunityIds.add(oppLineItem.OpportunityId);
            setRROLIIds.add(oppLineItem.RevRecOpportunityLineItem__c);
        }
        
        //Query all line items and related override rules 
        for(RevRecOpportunityLineItem__c revrecItem : [Select Id, Name, Opportunity__c , (
                            Select Id, Revenue_Recognition_Start_Date__c, Revenue_Recognition_End_Date__c, 
                            Is_Opportuunity_Date_Change__c, Is_Opportuunity_End_Date_Change__c, Start_Date__c, End_Date__c
                            FROM RevRecProductRules__r WHERE RevRecOpportunityLineItem__c IN : setRROLIIds) 
                            From RevRecOpportunityLineItem__c WHERE Opportunity__c IN : setOpportunityIds]) {
                                
          System.debug('Query revrecItem --> '+revrecItem); 
                            
            //Loop over inline ressylts
            if(revrecItem.RevRecProductRules__r.size() > 0) {
            
                //Loop over list 
                for(RevRecProductRule__c rule : revrecItem.RevRecProductRules__r) {

                    //Checking  for start date field
                    if((rule.Revenue_Recognition_Start_Date__c != null && String.isNotBlank(rule.Revenue_Recognition_Start_Date__c) && rule.Revenue_Recognition_Start_Date__c.contains(constants.SOBJECT_OPPORTUNITY)) ||
                    	(rule.Revenue_Recognition_End_Date__c != null && String.isNotBlank(rule.Revenue_Recognition_End_Date__c) && rule.Revenue_Recognition_End_Date__c.contains(constants.SOBJECT_OPPORTUNITY))) {
                        
                        //If its a field of opportunity
                        if((rule.Revenue_Recognition_Start_Date__c != null && rule.Revenue_Recognition_Start_Date__c.contains(constants.SOBJECT_LINE_ITEM_COLON)) || 
                           (rule.Revenue_Recognition_End_Date__c != null && rule.Revenue_Recognition_End_Date__c.contains(constants.SOBJECT_LINE_ITEM_COLON))) { 
                        	
                               //Checcking for date change
                               for(OpportunityLineItem oppLI : newLines) { 
                                   System.debug('newLines...@@@' + newLines);
                                   //Checcking for date change
                                   String field1 = rule.Revenue_Recognition_Start_Date__c.subString(20, rule.Revenue_Recognition_Start_Date__c.length());
                                   String field2 = rule.Revenue_Recognition_End_Date__c.subString(20, rule.Revenue_Recognition_End_Date__c.length());
                                   System.debug('field1...@@@' + field1 + 'field2...@@@' + field2);
                                   if((rule.Revenue_Recognition_Start_Date__c != null && mapOldOppLineItems.containsKey(oppLI.Id) && mapOldOppLineItems.get(oppLI.Id).get(rule.Revenue_Recognition_Start_Date__c.subString(20, rule.Revenue_Recognition_Start_Date__c.length())) != oppLI.get(rule.Revenue_Recognition_Start_Date__c.subString(20, rule.Revenue_Recognition_Start_Date__c.length())))||
                                      (rule.Revenue_Recognition_End_Date__c != null && mapOldOppLineItems.containsKey(oppLI.Id) && mapOldOppLineItems.get(oppLI.Id).get(rule.Revenue_Recognition_End_Date__c.subString(20, rule.Revenue_Recognition_End_Date__c.length())) != oppLI.get(rule.Revenue_Recognition_End_Date__c.subString(20, rule.Revenue_Recognition_End_Date__c.length())))) {                                          
                                          processFurther = true;
                                      }
                               }
                           }
                        }
                    
                    if(processFurther) {
                    	if(mapRevRecRules.containsKey(revrecItem.Opportunity__c))
	                        mapRevRecRules.get(revrecItem.Opportunity__c).add(rule);
	                    else
	                        mapRevRecRules.put(revrecItem.Opportunity__c , new List<RevRecProductRule__c>{rule});
                    }
                }
            }
        }
        
        if(mapRevRecRules.size() > 0) { 
                        
            if(setOpportunityIds.size() > 0) {
                
                //Dynamic query to get whole date field value of opportunity [if any formula found]
                List<Opportunity> newOpps = RevRecHelper.GetOpportunityWithAllFieldsByIdSet(setOpportunityIds);
                
                //Loop over newOpps
                for(Opportunity opp : newOpps) {
                    
                    if(mapRevRecRules.containsKey(opp.Id)) {
                        for(RevRecProductRule__c rule : mapRevRecRules.get(opp.Id)) {
                            
                            //Strt and end date fields VARIABLES
                            String startDateName = rule.Revenue_Recognition_Start_Date__c;
                            String endDateName = rule.Revenue_Recognition_End_Date__c;
                            Boolean isDateChange = false;
                            String fieldName = '';
                            
                            //Checking  for start date field
                            if(String.isNotBlank(startDateName) && startDateName.contains(constants.SOBJECT_OPPORTUNITY)) {
                                
                                //If its a field of opportunity
                                if(startDateName.contains(constants.SOBJECT_LINE_ITEM_COLON)) { 
                                    
                                    //Get field name
                                    fieldName = startDateName.subString(20, startDateName.length());
                                    
                                    for(OpportunityLineItem oppLI : newLines) { 
										
                                        //Checcking for date change
                                        if(mapOldOppLineItems.get(oppLI.Id).get(fieldName) != oppLI.get(fieldName)) {
                                            
                                            //Populate values
                                            if(Utility.checkFieldPermission(mapfieldRuleResult,'Start_Date__c',Constants.PERMISSION_UPSERT))  
                                                rule.Start_Date__c = Date.valueOf(oppLI.get(fieldName));
                                            isDateChange = true;
                                        }
                                    }
                                }     
                            }
                            
                            //Checking  for end date field
                            if(String.isNotBlank(endDateName) && endDateName.contains(constants.SOBJECT_OPPORTUNITY)) {
                                
                                //If its a field of opportunity
                                if(endDateName.contains(constants.SOBJECT_LINE_ITEM_COLON)) { 
                                    
                                    //Get field name
                                    fieldName = endDateName.subString(20, endDateName.length());
                                    
                                    for(OpportunityLineItem oppLI : newLines) { 

                                        //Checcking for date change
                                        if(mapOldOppLineItems.get(oppLI.Id).get(fieldName) != oppLI.get(fieldName)) {
                                            
                                            //Populate values
                                            if(Utility.checkFieldPermission(mapfieldRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT)) 
                                                rule.End_Date__c = Date.valueOf(oppLI.get(fieldName));
                                            isDateChange = true;
                                        }
                                    }
                                }     
                            }
                            
                            //If any date chnages
                            if( isDateChange && (Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRule__c'))) 
                                rulesToUpdate.add(rule);
                        }
                    }
                }
            }
           //Checking for list size
           if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecProductRule__c')){
           		if(rulesToUpdate.size() > 0) 
             		update rulesToUpdate; 
           }
        }
    }
    
    /**
     *  @description    :   This method is used to insert RROLI and update OLI
     *
     *  @args           :   List<OpportunityLineItem> newLineItems
     *
     *  @return         :   
    **/
    public static void rrOLIInsertAndOLIUpdate(List<OpportunityLineItem> newLineItems) {
        
       	String msg = '';
        String theOppId = '';
        Set<Id> LineItemIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        
        for(OpportunityLineItem item : newLineItems){
            LineItemIds.add(item.Id);
            opportunityIds.add(item.OpportunityId);
        }
                
        if (opportunityIds.size() != 1) {
            msg += 'Multiple Opportunities for LineItem Trigger';
            RevRecHelper.SendEmail(msg);
        }else {
            for(Id ids : opportunityIds)
            theOppId = ids;
            
            List<OpportunityLineItem> itemListWithAllFields = RevRecHelper.GetLineItemListWithAllFieldsByItemSet(LineItemIds);
            Map<Id, OpportunityLineItem> itemListWithAllFieldsMap = new Map<id, OpportunityLineItem>();
            
            for(OpportunityLineItem item: itemListWithAllFields) 
                itemListWithAllFieldsMap.put(item.Id, item);
                
            List<OpportunityLineItem> itemListWithRelations = [SELECT Id, PricebookEntry.Name, PricebookEntry.product2.id, 
                                                               PricebookEntry.product2.Family,
                                                               PricebookEntry.product2.RevRecRule__r.Id, 
                                                               PricebookEntry.product2.RevRecRule__r.name, 
                                                               PricebookEntry.product2.RevRecRule__r.Active__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Default_Rule__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Description__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Divide_By__c, 
                                                               PricebookEntry.product2.RevRecRule__r.initial_amount__c, 
                                                               PricebookEntry.product2.RevRecRule__r.initial_amount_type__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Offset_Period__c,  
                                                               PricebookEntry.product2.RevRecRule__r.offset_type__c,
                                                               PricebookEntry.product2.RevRecRule__r.Period__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Period_or_Exact_Days__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Recognition_Type__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Residual_Amount__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Residual_Amount_Type__c, 
                                                               PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_End_Date__c,  
                                                               PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_Start_Date__c,
                                                               RevRecOpportunityLineItem__r.Id,
                                                               RevRecOpportunityLineItem__r.OpportunityLineItemId__c,
                                                               RevRecOpportunityLineItem__r.TotalRev__c,
                                                               RevRecOpportunityLineItem__r.DeferredRev__c,
                                                               RevRecOpportunityLineItem__r.RecognizedRev__c,
                                                               RevRecOpportunityLineItem__r.CalculatedAt__c,
                                                               RevRecOpportunityLineItem__r.ResidualAmount__c,
                                                               RevRecOpportunityLineItem__r.DefReWei__c,
                                                               RevRecOpportunityLineItem__r.RecRevWei__c,
                                                               RevRecOpportunityLineItem__r.ResAmtWei__c,
                                                               RevRecOpportunityLineItem__r.ProductName__c,
                                                               RevRecOpportunityLineItem__r.Opportunity__c
                                                               FROM OpportunityLineItem WHERE Id in :LineItemIds];
            Map<id, OpportunityLineItem> itemListWithRelationsMap = new Map<id, OpportunityLineItem>();
            
            for(OpportunityLineItem item : itemListWithRelations) 
                itemListWithRelationsMap.put(item.Id, item);
            
            //Query updated with adding filter checking for not null or blank
            List<RevRecOpportunityLineItemSchedule__c> garbage = [select id, name from RevRecOpportunityLineItemSchedule__c 
                                                                  where OpportunityLineItemId__c != null AND OpportunityLineItemId__c != ''
                                                                  AND AppRopozSLN__External_OpportunityLineItemId__c in :LineItemIds];
            
            if (RevRecOpportunityLineItemSchedule__c.sObjectType.getDescribe().isDeletable()) {
                delete(garbage);
            }
            
            Map<string, RevRecOpportunityLineItem__c> allNewRevRecLineItemMap = new Map<string, RevRecOpportunityLineItem__c>();
            List<RevRecOpportunityLineItem__c> allNewRevRecLineItem = new List<RevRecOpportunityLineItem__c>();
            
            for(OpportunityLineItem newItem : newLineItems){
                String oppLineItemId = newItem.Id;
                OpportunityLineItem oli1 = itemListWithRelationsMap.get(oppLineItemId);
                
                //Variable to hold name
                String name;
                //Check if Product name is morethan 80 character
                if(oli1.PricebookEntry.Name.length() > 80)
                    name = oli1.PricebookEntry.Name.substring(0,79);
                else
                    name = oli1.PricebookEntry.Name;
                    
                RevRecOpportunityLineItem__c revRecLineItem = new RevRecOpportunityLineItem__c(name=name, opportunity__c = theOppId, OpportunityLineItemId__c = oppLineItemId);
                if(Utility.checkFieldPermission(mapfieldOLIResult,'ProductName__c',Constants.PERMISSION_CREATE))
                    revRecLineItem.ProductName__c = oli1.PricebookEntry.Name;
                if(Utility.checkFieldPermission(mapfieldOLIResult,'Product_Family__c',Constants.PERMISSION_CREATE))
                    revRecLineItem.Product_Family__c = oli1.PricebookEntry.Product2.Family;
                if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecOpportunityLineItem__c'))
                    allNewRevRecLineItem.add(revRecLineItem);
            } 
            if(Utility.checkObjectPermission(Constants.PERMISSION_CREATE, 'RevRecOpportunityLineItem__c')){
                insert(allNewRevRecLineItem); //after this action, RR_lineItem should have ID
            }
            
            for(RevRecOpportunityLineItem__c item : allNewRevRecLineItem) 
                allNewRevRecLineItemMap.put(item.OpportunityLineItemId__c, item);
            
            for(OpportunityLineItem item : itemListWithAllFields) {
                RevRecOpportunityLineItem__c rrItem = allNewRevRecLineItemMap.get(item.Id);
                if (rrItem != null) 
                    item.RevRecOpportunityLineItem__c = rrItem.Id;
            }
            update(itemListWithAllFields);  
        } 
    }
    
    public static void priceRelatedChangeCal(List<OpportunityLineItem> newOLIs, Map<Id, OpportunityLineItem> mapOldOLI) {
        
        String msg = '';
        Boolean ShouldContinue = false;
        String theOppId = '';
        Set<Id> LineItemIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        
        //Only Quantity and UnitPrice and Discount change affect result
        for(OpportunityLineItem newItem : newOLIs) {
            if(mapOldOLI != null){
                if (mapOldOLI.get(newItem.Id).Quantity != newItem.Quantity || mapOldOLI.get(newItem.Id).UnitPrice != newItem.UnitPrice 
                    || mapOldOLI.get(newItem.Id).Discount != newItem.Discount ) 
                    ShouldContinue = true;
            }
        }
        
        //Check if it is newly assigned RR_OLI id
        if(!ShouldContinue) {
            msg += 'It is not price related change';
            for(OpportunityLineItem newItem : newOLIs) {
                if(mapOldOLI.get(newItem.Id).RevRecOpportunityLineItem__c != newItem.RevRecOpportunityLineItem__c) 
                    ShouldContinue = true;
            }           
        }        
        
        if(!ShouldContinue) {
            msg += 'It is not newly added RR_OLI either';
            return;
        }
        
        for(OpportunityLineItem item : newOLIs){
            LineItemIds.add(item.Id);
            opportunityIds.add(item.OpportunityId);
            theOppId = item.OpportunityId;
        }
        
        if(opportunityIds.size() != 1) {
            msg += 'Multiple Opportunities for LineItem Trigger';
            RevRecHelper.SendEmail(msg);
        }else {
            
            //Query updated with adding filter checking for not null or blank
            List<RevRecOpportunityLineItemSchedule__c> garbage = [SELECT id, name FROM RevRecOpportunityLineItemSchedule__c 
                                                                  WHERE OpportunityLineItemId__c != null AND OpportunityLineItemId__c != ''
                                                                  AND AppRopozSLN__External_OpportunityLineItemId__c in :LineItemIds];
            
        }       
        if(theOppId.length() > 0) {    
            try {     
                RevRecUtil util = new RevRecUtil();
                RevRecUtilHelper utilHelper = new RevRecUtilHelper();
                utilHelper.Cleanup();
                
                util.EvaluateRevRecScheduleForOpportunity(theOppId);
            } catch (Exception exp){
                System.debug(exp); 
            }
        }
    }
    
    public static void deleteSchedule(Map<Id,OpportunityLineItem> mapOldOLI) {
        
        //Query updated with adding filter checking for not null or blank
        List<RevRecOpportunityLineItemSchedule__c> garbage = [SELECT id, name FROM RevRecOpportunityLineItemSchedule__c 
                                                              WHERE OpportunityLineItemId__c != null AND OpportunityLineItemId__c != ''
                                                              AND AppRopozSLN__External_OpportunityLineItemId__c in : mapOldOLI.keySet() ];
        
        if (RevRecOpportunityLineItemSchedule__c.sObjectType.getDescribe().isDeletable()) {
            delete(garbage);
        }
    }
}