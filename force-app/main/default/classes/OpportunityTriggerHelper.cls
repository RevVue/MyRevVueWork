/**
 *  Description     :   This is the helper class for Product Trigger.
 *
 *  Created Date    :   05/28/2016
 *
 *  Created By      :   Bill Feeheley
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0
**/
public without sharing class OpportunityTriggerHelper {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRuleResult = Utility.getFieldPermissions('RevRecProductRule__c');
    
    /**
     *  @description    :   This method is used to find the related Rule criteria and stamp related rule on the Opportunity.    
     *
     *  @args           :   Trigger.New, Trigger.OldMap
     *
     *  @return         :   
     **/
     public static void assignRulesOnOpportunity (List<Opportunity> newOpportunities, Map<Id,Opportunity> mapOldOpportunities) { 
     
        //Map to hold name with Rule
        Map<Id , Rule_Assignment__c> mapIdAndRuleAssignments = new Map<Id , Rule_Assignment__c>();
        Map<Id, Rule_Assignment_Criteria__c> mapRuleIdAndRuleAssignmentCriteria = new Map<Id, Rule_Assignment_Criteria__c>();
        
        //Query to fetch all rule assignments
        for(Rule_Assignment__c ruleAsg : [Select Id, Name, Product_Family__c, RevRecRule__c ,Selected_Familys__c, Product_Name__c,
                                                 (Select Id, Operator__c , Criteria_Field__c, Additional_Search_Criteria__c, Rule_Assignment__c FROM Rule_Assignment_Criterias__r 
                                                 where Criteria_Field__c = 'Name' AND Additional_Search_Criteria__c != '' AND Additional_Search_Criteria__c != null
                                                 AND Operator__c != '' AND Operator__c != null LIMIT  1) FROM Rule_Assignment__c where Active__c = true 
                                                 ORDER BY LastModifiedDate DESC]) {
            //Map rule assignments                                      
            mapIdAndRuleAssignments.put(ruleAsg.Id , ruleAsg);
            
            //Check if rule child is exist
            if(ruleAsg.Rule_Assignment_Criterias__r.size() > 0)
                mapRuleIdAndRuleAssignmentCriteria.put(ruleAsg.Id , ruleAsg.Rule_Assignment_Criterias__r[0]); //Map rule assignment criteria
        }
        
        //Checking for map size
        if(mapIdAndRuleAssignments.size() > 0 && mapRuleIdAndRuleAssignmentCriteria.size() > 0) { 
             
            //Loop over Trigger.New
            for(Opportunity opportunity : newOpportunities) { 
                
                //Check if rule assignment is manually change 
                if(mapOldOpportunities != null && opportunity.REVvue_RuleAssignment__c != mapOldOpportunities.get(opportunity.Id).REVvue_RuleAssignment__c && opportunity.Name == mapOldOpportunities.get(opportunity.Id).Name) {
                    
                    //Check if rule assignment is blank
                    if(opportunity.REVvue_RuleAssignment__c != null)
                        opportunity.REVvue_RuleAssignType__c = 'Overridden';
                    else
                        opportunity.REVvue_RuleAssignType__c = '';
                }
                    
                //Check for insert or update 
                if(mapOldOpportunities == null || (opportunity.Name != mapOldOpportunities.get(opportunity.Id).Name)) {
                     
                    //Loop over rule assignments 
                    for(Rule_Assignment__c rule : mapIdAndRuleAssignments.values()) {
                        
                        if(String.isBlank(rule.Product_Family__c) && String.isBlank(rule.Product_Name__c)) { 
                            
                            //Check for serch criteria and operator value 
                            if(mapRuleIdAndRuleAssignmentCriteria.containsKey(rule.Id) && opportunity.Name.contains(mapRuleIdAndRuleAssignmentCriteria.get(rule.Id).Additional_Search_Criteria__c)
                                                         && mapRuleIdAndRuleAssignmentCriteria.get(rule.Id).Operator__c == Constants.OPERATOR_IN) { 
                                //Assigning rule and rule assignment                     
                                opportunity.REVvue_RevRecRule__c = rule.RevRecRule__c; 
                                //Code added on 07/15/2016 - FEATURE # 8: Add links the assignment rule on oppty
                                opportunity.REVvue_RuleAssignment__c = rule.Id; 
                                opportunity.REVvue_RuleAssignType__c = '';
                            }
                        }
                    }
                }
            }
        }
    }
    
  	/**
    *   description     :   This method is used to calculate the date chnage dynamically related too the rule/
    *
    *   args            :
    *
    *   return          :   
    **/  
    public static void calculateDateChange(List<Opportunity> newOpps , Map<Id, Opportunity> mapOldOpportunities) {
        //Map oof rules
        Map<Id , List<RevRecProductRule__c>> mapRevRecRules = new Map<Id , List<RevRecProductRule__c>>();
        
        //rule to update
        List<RevRecProductRule__c> rulesToUpdate = new List<RevRecProductRule__c>();
        
        Map<Id, List<RevRecProductRule__c>> mapContractWithProductRules = new Map<Id, List<RevRecProductRule__c>>();
        
        //Query all line items and related override rules 
        for(RevRecOpportunityLineItem__c revrecItem : [Select Id, Name, Opportunity__c , (
                            Select Id, Revenue_Recognition_Start_Date__c, Revenue_Recognition_End_Date__c, 
                            Is_Opportuunity_Date_Change__c, Is_Opportuunity_End_Date_Change__c,  Start_Date__c, End_Date__c 
                            FROM RevRecProductRules__r ) 
                            From RevRecOpportunityLineItem__c WHERE Opportunity__c IN : newOpps]) {                              
            //Loop over inline ressylts
            if(revrecItem.RevRecProductRules__r.size() > 0) {
            
                //Loop over list 
                for(RevRecProductRule__c rule : revrecItem.RevRecProductRules__r) {
                    
                    if(mapRevRecRules.containsKey(revrecItem.Opportunity__c))
                        mapRevRecRules.get(revrecItem.Opportunity__c).add(rule);
                    else
                        mapRevRecRules.put(revrecItem.Opportunity__c , new List<RevRecProductRule__c>{rule});
                }
            }
        }
        
        if(mapRevRecRules.size() > 0) { 
                        
            //Dynamic query to get whole date field value of opportunity [if any formula found]
            newOpps = RevRecHelper.GetOpportunityWithAllFieldsByIdSet(mapOldOpportunities.keySet());
            
            //Loop over newOpps
            for(Opportunity opp : newOpps) {
                    
                if(mapRevRecRules.containsKey(opp.Id)) {
                    for(RevRecProductRule__c rule : mapRevRecRules.get(opp.Id)) {
                    
                        //Strt and end date fields VARIABLES
                        String startDateName = rule.Revenue_Recognition_Start_Date__c;
                        String endDateName = rule.Revenue_Recognition_End_Date__c;
                        Boolean isDateChange = false;
                        String fieldName = '';

                        //Checking 
                        if(String.isNotBlank(startDateName) &&  startDateName.contains(constants.SOBJECT_OPPORTUNITY)) {
                            
                            //If its a field of opportunity
                            if(!startDateName.contains(constants.SOBJECT_LINE_ITEM_COLON)) { 
                                
                                //Get field name
                                fieldName = startDateName.subString(12, startDateName.length());
                                
                                //Checcking for date change
                                if(mapOldOpportunities.get(opp.Id).get(fieldName) != opp.get(fieldName)) {
                                    
                                    //Populate values
                                    if(Utility.checkFieldPermission(mapfieldRuleResult,'Start_Date__c',Constants.PERMISSION_UPSERT))
                                        rule.Start_Date__c  = Date.valueOf(opp.get(fieldName));
                                    isDateChange = true;
                                }
                            }    
                        }
                        
                        //Checking  for end date field
                        if(String.isNotBlank(endDateName) && endDateName.contains(constants.SOBJECT_OPPORTUNITY)) {
                            
                            //If its a field of opportunity
                            if(!endDateName.contains(constants.SOBJECT_LINE_ITEM_COLON)) { 
                                
                                //Get field name
                                fieldName = endDateName.subString(12, endDateName.length());
                            
                                //Checcking for date change
                                if(mapOldOpportunities.get(opp.Id).get(fieldName) != opp.get(fieldName)) {
                                    
                                    //Populate values
                                    if(Utility.checkFieldPermission(mapfieldRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT))
                                        rule.End_Date__c = Date.valueOf(opp.get(fieldName));
                                    isDateChange = true;
                                }
                            }     
                        }
                        
                        //Checcking for date change
                        //If its a field of contract
                        if((String.isNotBlank(startDateName) &&  !startDateName.contains(constants.SOBJECT_OPPORTUNITY_COLON)) || (String.isNotBlank(endDateName) && endDateName.contains(constants.SOBJECT_OPPORTUNITY_COLON))) { 
                            if((String.isNotBlank(startDateName) && startDateName.contains(constants.SOBJECT_CONTRACT_COLON)) || (String.isNotBlank(endDateName) && endDateName.contains(constants.SOBJECT_CONTRACT_COLON))) { 
                                if(mapOldOpportunities.get(opp.Id).contractId != opp.contractId) {                                
                                    //Populate values
                                    if(!mapContractWithProductRules.containsKey(opp.contractId))
                                        mapContractWithProductRules.put(opp.contractId, new List<RevRecProductRule__c>{rule});
                                    else
                                        mapContractWithProductRules.get(opp.ContractId).add(rule);
                                } 
                            }
                        }
                        
                        //If any date chnages
                        if( isDateChange  && (Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRule__c'))) 
                            rulesToUpdate.add(rule);
                    }
                }
            }
            
            //Check for size
            if(mapContractWithProductRules != null && mapContractWithProductRules.size() > 0) {
                
                List<Contract> contracts = RevRecHelper.GetContractListWithAllFieldsByItemSetClone(mapContractWithProductRules.keySet());
                
                //Check for size
                if(contracts.size() > 0) {
                    for(Contract contract : contracts) {
                 		
                        //Loop over map key
                        for(RevRecProductRule__c rule : mapContractWithProductRules.get(contract.Id)) {
                           
                            //Strt and end date fields VARIABLES
                            String startDateName = rule.Revenue_Recognition_Start_Date__c;
                            String endDateName = rule.Revenue_Recognition_End_Date__c;
                            Boolean isDateChange = false;
                            String fieldName = '';
                            
                            //If its a field of contract
                            if(String.isNotBlank(startDateName) && startDateName.contains(constants.SOBJECT_CONTRACT_COLON)) { 
                                
                                //Get field name
                                fieldName = startDateName.subString(9, startDateName.length());

                                //Populate values
                                rule.Start_Date__c = Date.valueOf(contract.get(fieldName));
                                isDateChange = true;
                            }   
                            
                            //If its a field of contract
                            if(String.isNotBlank(endDateName) && endDateName.contains(constants.SOBJECT_CONTRACT_COLON)) { 
                                
                                //Get field name
                                fieldName = endDateName.subString(9, endDateName.length());
                            
                                //Populate values
                                rule.End_Date__c = Date.valueOf(contract.get(fieldName));
                                isDateChange = true;
                            }   
                            
                            //If any date chnages
                            if( isDateChange ) 
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
     *  @description    :   This method is used to update currency type on Opportunity insertion or updation.    
     *
     *  @args           :   Trigger.New, Trigger.OldMap
     *
     *  @return         :   
     **/
    public static void validateCurrenceyTypeField(List<Opportunity> newOpportunities, Map<Id,Opportunity> mapOldOpportunities) {
        
        //Getting boolean if multicurrency is enable or not
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Boolean isCurrencyChanged = false;
        
        //Check if multicurrency is enabled
        if(isMultiCurrencyEnabled) {
            
            //String to hold default currency 
            String defaultCurrency = '';
            
            //Loop over new opp
            for(Opportunity opp : newOpportunities) {
                
                //Check for blank update
                if(mapOldOpportunities == null ||  opp.REVvue_CurrencyType__c == null || mapOldOpportunities.get(opp.Id).REVvue_CurrencyType__c != opp.REVvue_CurrencyType__c ) {
                    isCurrencyChanged = true;
                }
            }
            
            if(isCurrencyChanged) {
	            //Query string
	            String queryStringForStaticExchangeRate = 'SELECT IsoCode, IsCorporate, ConversionRate FROM CurrencyType WHERE IsActive = true AND ConversionRate !=null';
	            //Query to get the dated exchange rate
	            List<Sobject> sObjectsList =  new List<Sobject>();
	            sObjectsList = database.query(queryStringForStaticExchangeRate);
	            
	            //Checking for size
	            if(sObjectsList.size() > 0) {
	                
	                //Loop through sObject type
	                for(SObject cType : sObjectsList) {
	                    
	                    //Getting default currency ISO code
	                    if(cType.get('IsCorporate') == true && cType.get('ConversionRate') != null)
	                        defaultCurrency = (String.ValueOf(cType.get('IsoCode')));
	                }
	            }
	            
	            //Loop over new opp
		        for(Opportunity opp : newOpportunities) {
		            
		            //Check for blank update
		            if(mapOldOpportunities == null ||  opp.REVvue_CurrencyType__c == null || mapOldOpportunities.get(opp.Id).REVvue_CurrencyType__c != opp.REVvue_CurrencyType__c ) {
		                
		                //Check if currency type is blank
		                if(opp.REVvue_CurrencyType__c == null)
		                    opp.REVvue_CurrencyType__c = defaultCurrency; //Setting default currency value
		            }
		        }
            }
        } 
    } 
}