/**
 *  Description     :   This class is use to execute batch for matching opportunity with selected criteria.
 * 
 *  Created Date    :   09/30/2014
 *
 *  Created By      :     
 *  
 *  Current vision  :   V1.1 
 * 
 *  Revision Logs   :   V1.0 - Created
 *                      V_1.0 - Modified - 11/26/2015 - As per to add dates picklist filter in searching functionality.
 *              
 **/
public with sharing class MassRevenueCalculateController{
    
    //Oopportunity initilization
    public Opportunity opportunity {get;set;}
    public Opportunity opportunity1 {get;set;} 
    public String query;
    Set<String> setAllDatesAPI = new Set<String>();
    
    //Variables to hold select list filter criteria value 
    public string selectedCriteriaField {get;set;}
    public string selectedCriteria {get;set;}
    
    //List of opportunity for matching criteria
    public List<Opportunity> searchCriteriaOpportunities ;
    
    //Map to hold Date field with their Data type
    Map<String , Schema.DisplayType> mapOppFieldWithType = new Map<String, Schema.DisplayType>();
    
    //List of Search Dates
    public List<SelectOption> getSearchDateOptions() {
        
        //List of options
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('--None--' , '--None--'));
        
        //Map to get all  fields related to Opportunity
        Map<String, Schema.SObjectField> oppAllFields = Schema.SObjectType.Opportunity.fields.getMap(); 
        
        //Loop over fields
        for (Schema.SObjectField item : oppAllFields.values()) {
            
            //Describe each field of opportunity
            Schema.Describefieldresult theField = item.getDescribe();
            
            //If field type is Date and add into list
            if (theField.getType() == Schema.DisplayType.Date || theField.getType() == Schema.DisplayType.DateTime) {
                
                //Checking for system dadte
                if(theField.getLabel() != 'System Modstamp') {
                    options.add(new SelectOption(theField.getName(),  theField.getLabel()));
                    
                    //Populate set with field's API name
                    setAllDatesAPI.add(theField.getName());
                    
                    //Map 
                    mapOppFieldWithType.put(theField.getName() ,theField.getType());
                }
            }
        }
        return options;
    }
    
    //Constructer initilization
    Public MassRevenueCalculateController() {
        
        //Memory allocaton  
        opportunity = new Opportunity();
        opportunity1 = new Opportunity();
        selectedCriteriaField = '--None--';
        selectedCriteria = '--None--';
        searchCriteriaOpportunities = new List<Opportunity>();
    }
    
    /**
     *  @description    :    Method to search opportunity for creitaria select from vf page and execute batch
     *                           
     *  @args           :    
     *                      
     *  @return         :    void           
     *
    **/
    public void searchOppRecordsWithMatchingCreteria () {
        
        //Creating query String
        Date dt1 = null;
        Date dt2 = null;
        
        String query = '';     
        query += 'SELECT Id, Name, StageName, Amount ';
        
        //Loop over all dates and add them into query
        for(String dateAPI : setAllDatesAPI)
             query += ', ' + dateAPI;
        
        query += ' FROM Opportunity ';
        query += 'WHERE ';
        
        if(String.isNotBlank(opportunity.StageName))
            query += 'StageName = \'' + opportunity.StageName + '\'' + ' AND ';
            
        if(String.isNotBlank(opportunity.Type))
            query += 'Type = \'' + opportunity.Type + '\'' + ' AND ';  
       
        if(opportunity.Amount != null)
            query += 'Amount >= '+opportunity.Amount +' AND ';   
            
        if(opportunity1.Amount != null)
            query += 'Amount <= '+ opportunity1.Amount+' AND ';  
        
        if(String.isNotBlank(opportunity.Name))
            query += 'Name = \'' + opportunity.Name + '\'' + ' AND ';
        
        if(String.isNotBlank(opportunity.AccountId))
            query += 'AccountId = \'' + opportunity.AccountId + '\'' + ' AND ';
        
        //Query variables
        String fieldName = '';
        
        //Checking for fields
        if(String.isNotBlank(selectedCriteriaField))
            fieldName = selectedCriteriaField;
        
        //If selected field not blank then checking for criteria
        if(String.isNotBlank(fieldName ))  {
                        
            //Checking for Selected filter criteria
            if(String.isNotBlank(selectedCriteria) && selectedCriteria != '--None--') {
                
                //Checking for no custom criteria
                if(selectedCriteria != 'Custom') {
                    query += String.escapeSingleQuotes(fieldName) +'= '+ String.escapeSingleQuotes(selectedCriteria) + 'AND '; 
                }else {                 
                    
                    //Checking for Created date not null
                    if(opportunity.REVvue_CreatedDate__c != null) {
                        
                        //Checking for conditions and field type DATETIME
                        if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.DateTime)
                            query += String.escapeSingleQuotes(fieldName) +' >= '+ opportunity.REVvue_CreatedDate__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')+' AND '; 
                        
                        //Checking for conditions and field type DATE
                        else if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.Date) {
                            
                            dt1 = opportunity.REVvue_CreatedDate__c.date();
                            query += String.escapeSingleQuotes(fieldName) +' >=: dt1 AND '; 
                        }
                    }
                    
                    //Checking for null
                    if(opportunity1.REVvue_CreatedDate__c != null) {
                        
                        //Checking for conditions and field type DATETIME
                        if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.DateTime)
                            query += String.escapeSingleQuotes(fieldName) + '<= '+  opportunity1.REVvue_CreatedDate__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')+' AND '; 
                            
                        //Checking for conditions and field type DATE
                        else if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.Date) {
                            
                            dt2 = opportunity1.REVvue_CreatedDate__c.date();
                            query += String.escapeSingleQuotes(fieldName) +' <=: dt2  AND '; 
                        }
                    }
                }                           
            }
        }
        
        //remove last AND and WHERE operator 
        query = query.removeEnd('AND ');
        query = query.removeEnd('WHERE ');
        query = query.trim();
        
        String queryStr ;
        queryStr = query;
        
        query += ' LIMIT 1';
        
        //Execute query
        searchCriteriaOpportunities = database.query(query); 
        
        //check for condition if any record matches with criteria
        if(searchCriteriaOpportunities.size() > 0) {
            
            //Instantiate the batch annd execute with batch size 10
            Batch_MassRevenueCalculate bc = new Batch_MassRevenueCalculate(queryStr);
            DataBase.executeBatch(bc, 25);
            
            //Apex page messages
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.Batch_Starts_Label));
        }else{
            //Apex page messages
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.No_Record_Found_Label));
        }
    }
    /**
     *  @description    :   List of select options to show the creiteria for filtering.
     *
     *  @return         :   List<SelectOption>
     *
     *  @args           :   
     **/
     public List<SelectOption> getFilterCriteria() {
        
        //List of select options
        List<SelectOption> options = new List<SelectOption>();
         
        options.add(new SelectOption('--None--' , '--None--'));
        options.add(new SelectOption('THIS_QUARTER' , 'This Quarter'));
        options.add(new SelectOption('LAST_QUARTER' , 'Last Quarter'));
        options.add(new SelectOption('LAST_FISCAL_QUARTER' , 'Last Fiscal Quarter'));
        options.add(new SelectOption('THIS_FISCAL_QUARTER' , 'This Fiscal Quarter'));
        options.add(new SelectOption('THIS_YEAR' , 'This Year'));
        options.add(new SelectOption('LAST_YEAR' , 'Last Year'));
        options.add(new SelectOption('THIS_FISCAL_YEAR' , 'This Fiscal Year'));
        options.add(new SelectOption('LAST_FISCAL_YEAR' , 'Last Fiscal Year'));
        options.add(new SelectOption('LAST_MONTH' , 'Last Month'));
        options.add(new SelectOption('THIS_MONTH' , 'This Month'));
        options.add(new SelectOption('THIS_WEEK' , 'This Week'));
        options.add(new SelectOption('LAST_WEEK' , 'Last Week'));
        options.add(new SelectOption('YESTERDAY' , 'Yesterday'));
        options.add(new SelectOption('TODAY' , 'Today'));
        options.add(new SelectOption('Custom' , 'Custom'));
        
        return options;
     }
     
    /**
     *  @description    :   This is blank method to be called on onchange of selected filter.
     *
     *  @return         :   void
     *
     *  @args           :   
     **/
     public void changeCriteria() {}
    
    /**
     *  @description    :   This method is used to update all Line Item which do not have Rule and Rule Assignment.
     *
     *  @return         :   void
     *
     *  @args           :   
     **/
     public void SetRuleAndRuleAssignmentOnLineItem() {
         
         RevRecRules__c defaultRule = null;
         
         //Fetching all rules
         List<RevRecRules__c> allDefaultRules = [SELECT Id,name, Active__c, Default_Rule__c
                                                 FROM RevRecRules__c where  Active__c = true AND Default_Rule__c = true
                                                 order by LastModifiedDate DESC limit 1];
         
         //If many rules then set first as default
         if(allDefaultRules.size() > 0) 
             defaultRule = allDefaultRules[0];
         
         //Initialization
         Boolean isRuleFound = false;
         List<OpportunityLineItem> oppLineItemToBeUpdated = new List<OpportunityLineItem>();
         
        //Set to hold opportunity id's
        Set<Id> setOpportunityIds = new Set<Id>();
        //Set to hold product2 id's
        Set<Id> setProduct2Ids = new Set<Id>();
         
        //Fetching all existing OpportunityLineItem, if RevRecRule is blank 
        List<OpportunityLineItem> oppLineItems = [Select Id, Name ,RevRecRule__c, Rule_Assignment__c, PriceBookEntry.Product2ID, PriceBookEntry.Product2.Family, OpportunityId 
                                                  From OpportunityLineItem Where RevRecRule__c = null];
          
        //Loop to fetch opportunityLineItem
        for(OpportunityLineItem opportunityLineItem : oppLineItems) {
            
            //Check if AppRopozSLN__RevRecRule__c field in null 
            if(opportunityLineItem.RevRecRule__c == null){
                
                //Adding values in set
                setOpportunityIds.add(opportunityLineItem.OpportunityId);
                setProduct2Ids.add(opportunityLineItem.PriceBookEntry.Product2ID);
            } 
        } 
        
        //Fetching opportunity and product2 data
        Map<Id,Opportunity> mapIdWithOpportunity = new Map<ID, Opportunity>([Select Id, REVvue_RuleAssignment__c, REVvue_RevRecRule__c 
                                                                             From Opportunity where Id IN : setOpportunityIds]);
        Map<Id,Product2> mapIdWithProduct2 = new Map<ID, Product2>([Select Id, Rule_Assignment__c, RevRecRule__c 
                                                                   From Product2 where Id IN : setProduct2Ids]);
        
        //Loop to fetch opportunityLineItem
        for(OpportunityLineItem opportunityLineItem : oppLineItems) {
         
            //Check if AppRopozSLN__RevRecRule__c field in null 
            if(opportunityLineItem.RevRecRule__c == null) {
                
                //Fetching product and opportunity instance from map
                Product2 product = mapIdWithProduct2.get(opportunityLineItem.PriceBookEntry.Product2Id);
                Opportunity opportunity = mapIdWithOpportunity.get(opportunityLineItem.OpportunityId);
                
                //Assigning rule from product on opportunity line item, if exist
                if(product.RevRecRule__c != null) {
                    
                    isRuleFound = true;
                    
                    //Assigning rule
                    opportunityLineItem.RevRecRule__c =  product.RevRecRule__c;
                    
                    //Assigning product rule assignment on opportunity line item, if exist
                    if(product.Rule_Assignment__c != null)
                        opportunityLineItem.Rule_Assignment__c =  product.Rule_Assignment__c;
                }
               
                //Assigning rule from opportunity on opportunity line item, if exist
                else if(opportunity.REVvue_RevRecRule__c != null) {
                     
                    isRuleFound = true; 
                    
                    //Assigning rule
                    opportunityLineItem.RevRecRule__c =  opportunity.REVvue_RevRecRule__c;
                                                                
                    //Assigning opportunity rule assignment on opportunity line item, if exist
                    if(opportunity.REVvue_RuleAssignment__c != null)
                        opportunityLineItem.Rule_Assignment__c =  opportunity.REVvue_RuleAssignment__c;
                }
                
                //Assigning default rule, if exist
                else if(defaultRule != null) {
                    isRuleFound = true; 
                    
                    //Assigning rule
                    opportunityLineItem.RevRecRule__c =  defaultRule.Id;
                }
                
                if(isRuleFound)
                    oppLineItemToBeUpdated.add(opportunityLineItem);
            } 
        } 
        //Check for condition if there is any record criteria without rule exist
         if(oppLineItemToBeUpdated.size() > 0) {
             
             Batch_MassRuleAssignmentOnOLI bc = new Batch_MassRuleAssignmentOnOLI(oppLineItemToBeUpdated);
             DataBase.executeBatch(bc, 25);
             
             //Apex page messages
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.Batch_Starts_Label));
         }else {
             //Apex page messages
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.No_Record_Found_Label));
        }
     }
}