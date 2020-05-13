/**
 *  Description     :   This is the helper class for Product Trigger.
 *
 *  Created Date    :   09/06/2016
 *
 *  Created By      :   
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0
**/
public without  sharing class ProductTriggerHelper {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldOLIResult = Utility.getFieldPermissions('OpportunityLineItem');
    
    /**
     *  @description    :   This method is used to find the related Rule criteria and stamp related rule on the Product.    
     *
     *  @args           :   Trigger.New, Trigger.oldMap
     *
     *  @return         :   
    **/
    public static void assignRulesOnProducts (List<Product2> newProducts) {
        
        //Map to hold Family with Rule
        Map<String , Rule_Assignment__c> mapRuleAssignments = new Map<String , Rule_Assignment__c>();
        Map<String, String> mapRuleWithOperator = new Map<String, String>();
        
        //Query to fetch all rule assignments
        for(Rule_Assignment__c ruleAsg : [Select Id, Name, Product_Family__c, RevRecRule__c ,Selected_Familys__c,
                                          (Select Id, Operator__c , Criteria_Field__c FROM Rule_Assignment_Criterias__r 
                                          where Criteria_Field__c = 'Family' LIMIT  1) 
                                          FROM Rule_Assignment__c where
                                          Is_Family_Assignment__c = true    
                                          AND Active__c = true
                                          ORDER BY LastModifiedDate DESC]) {
            //Map rule assignments                                      
            mapRuleAssignments.put(ruleAsg.Id , ruleAsg);
            
            if(ruleAsg.Rule_Assignment_Criterias__r.size() > 0)
                mapRuleWithOperator.put(ruleAsg.Id , ruleAsg.Rule_Assignment_Criterias__r[0].Operator__c);
        }
        
        //Checking for map size
        if(mapRuleAssignments.size() > 0 && mapRuleWithOperator.size() > 0) {
              
                //Loop over Trigger.New
                for(Product2 prod : newProducts) {
                    
                    Boolean isRuleAssigned = false;
                
                    //Loop over rule assignments 
                    for(Rule_Assignment__c rule : mapRuleAssignments.values()) {
                            
                        //Boolean 
                        Boolean isRuleFound = false;
                       
                        //Checking for operator 
                        if(mapRuleWithOperator.get(rule.Id) == Constants.OPERATOR_IN) {
                            
                            //Checking for Family type
                            if(String.isNotBlank(prod.Family) && rule.Selected_Familys__c.Contains(prod.Family))
                                isRuleFound = true;
                        }
                        
                        else if (mapRuleWithOperator.get(rule.Id) == Constants.OPERATOR_NOT_IN) {
                         
                            //Checking for Family type
                            if(String.isNotBlank(prod.Family) && !rule.Selected_Familys__c.Contains(prod.Family))
                                isRuleFound = true;
                        }
                          
                    
                     //Checking if any rule found
                    if(isRuleFound && !isRuleAssigned) {
                        prod.RevRecRule__c = rule.RevRecRule__c;
                        prod.Rule_Assignment__c = rule.Id;
                        isRuleAssigned = true;
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
    public static void calculateDateChange(Map<Id,Product2> mapNewProducts , Map<Id, Product2> mapOldProducts) {
        
        try {
            Database.executeBatch(new Batch_UpdateOLIWithRulFromProduct(mapNewProducts.keySet(),mapNewProducts.values(),mapOldProducts), 200); 
        } catch(Exception ex) {}
    }
    
    /**
     *  @description    :   This method is used to find the related line items to the product and stamp rule over them.    
     *
     *  @args           :   Trigger.New, Trigger.oldMap
     *
     *  @return         :   
    **/
    public static void ruleAssignmentOnLineItem(Map<Id,Product2> mapNewProduct , Map<Id, Product2> mapOldProducts) {
        
        //List of line items to update
        List<OpportunityLineItem> oppLineItemsToBeUpdated = new List<OpportunityLineItem>();
        Set<Id> setProductIds = new Set<Id>();
        Set<Id> setOpportunityIds = new Set<Id>();
        String theOppId = '';
        
        //Loop over new products if rule is changed
        for(Product2 prod : mapNewProduct.values()) {
            
            if(prod.RevRecRule__c != null && mapOldProducts.get(prod.Id).RevRecRule__c == null) {
                setProductIds.add(prod.Id);
            }
        }
        
        //Check for size
        if(setProductIds.size() > 0) {
            
            //Loop over line items
            for(OpportunityLineItem oli : [SELECT Id, opportunityId, Product2Id, RevRecRule__c FROM OpportunityLineItem WHERE Product2Id IN: setProductIds AND RevRecRule__c = null]) {
                
                setOpportunityIds.add(oli.OpportunityId);
                    
                //Check if productIds are same
                if(mapNewProduct.containsKey(oli.Product2Id)) {
                    if(Utility.checkFieldPermission(mapfieldOLIResult,'RevRecRule__c',Constants.PERMISSION_UPDATE))    
                        oli.RevRecRule__c = mapNewProduct.get(oli.Product2Id).RevRecRule__c;
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'OpportunityLineItem'))
                        oppLineItemsToBeUpdated.add(oli);
                }
            }
        }
        
        //Check for size
        if(oppLineItemsToBeUpdated.size() > 0) {
            if(oppLineItemsToBeUpdated.size() > 20) {
                Batch_RuleAssignmentOnOLI bcMassRuleAssignmentOnOLI = new Batch_RuleAssignmentOnOLI(oppLineItemsToBeUpdated);
                DataBase.executeBatch(bcMassRuleAssignmentOnOLI,10);
            }
            else {
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'OpportunityLineItem')){
                    update oppLineItemsToBeUpdated;
                }
            }
        }
        
        if(!Test.isRunningTest()) {
            Batch_MassOppCalculation bc = new Batch_MassOppCalculation(setOpportunityIds);
            DataBase.executeBatch(bc, 10);
        }
    }
}