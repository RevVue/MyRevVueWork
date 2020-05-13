/**
 *  Description     :   This method is used to create and assign rules on opportunity.This controller is used for RuleAssignment page.
 *
 *  Created Date    :   02/05/2016 
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0 - Created
**/
public with sharing class RuleAssignmentController {
    
    //Rule assignment instance
    public Rule_Assignment__c ruleAssignment1 {get;set;}
    
    //List of wrapper
    public List<FilterSelectionWrapper> ruleAssignmentWrapper {get; set;}
    public List<RuleAssignmentRecordsWrapper> ruleAssignmentRecordsWrapper {get; set;}
    public String selectedCriteriaFromButton {get;set;}
    
    //Select Unselect Properties
    public List<SelectOption> opportunitySelectList {get;set;}
    public List<string> leftOpportunityTypeSelected {get;set;}
    public List<string> rightOpportunityTypeSelected {get;set;}
    public List<SelectOption> itemSeletedOppList {get;set;}
    public String additionalSearchText {get; set;}
    public String selectedSearchVal {get;set;}
    public String selectedRowNum {get; set;}
    
    //Variables
    Set<String> leftOpportunityTypes = new Set<String>();
    Set<String> rightOpportunityTypes = new Set<String>();
    Map<String, String> rightItemMap = new Map<String, String>();
    Map<String, String> allAvailableOppAndProMap;
    Map<String, String> mapFieldWithAdditionalVal = new  Map<String, String>();
    
    //Variable to hold additional search value
    public String opportunityAdditionalsearch;
    public String productAdditionalsearch;
    public String familyAdditionalsearch;
    
    //Collections to hold selected Ids
    Set<String> selectedOppIds = new Set<String>();
    Set<String> selectedProductIds = new Set<String>();
    Set<String> selectFamily = new Set<String>();
    String opportunityOperator;
    String productOperator;
    String familyOperator;
    
    //Variables to get select options and criteria values
    List<SelectOption> selectOperators;
    List<SelectOption> selectCriterias;
    
    //To search records from popup
    public String searchString {get; set;}
    
    //Info message for more than 1000 data
    public string infoMsg {get; set;}
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldResult = Utility.getFieldPermissions('Rule_Assignment__c');
    
    
    //Constructer
    public RuleAssignmentController () {
        
        //Load defaults
        inIt();
    }
    
    /**
     *  @descriptoion   :   This method is used to load defaults related to rule assignments.
     *
     *  @args           :	
     *
     *  @return         :   Void
    **/
    public void inIt() {
        
        //Initilization of wrapper
        ruleAssignmentWrapper = new List<FilterSelectionWrapper>();
        ruleAssignmentRecordsWrapper = new List<RuleAssignmentRecordsWrapper>();
        opportunitySelectList = new List<SelectOption>();
        ruleAssignment1 = new Rule_Assignment__c(); 
        
        //Initilization of variable related to select - unselect functionality
        selectedCriteriaFromButton = '';
        selectedRowNum = '';
        selectedSearchVal = '';
        leftOpportunityTypeSelected = new List<String>();
        rightOpportunityTypeSelected = new List<String>();
        allAvailableOppAndProMap = new Map<String, String>();
        itemSeletedOppList = new List<SelectOption>();
        
        //Select options
        selectOperators = Constants.getFilterOperatorOptions();
        selectCriterias = Constants.getFilterConditionOptions();
        selectFamily = new Set<String>();
        selectedOppIds = new Set<String>();
        selectedProductIds = new Set<String>();
        opportunityOperator = '';
        productOperator = '';
        familyOperator = '';
        
        //Additional search variable initialization
        opportunityAdditionalsearch = '';
        productAdditionalsearch = '';
        familyAdditionalsearch = '';
    
        //Populate wrapper 3 times
        for(Integer i=0 ; i<=2 ; i++)
            ruleAssignmentWrapper.add(new FilterSelectionWrapper(selectOperators, selectCriterias , new Rule_Assignment_Criteria__c(Criteria_Field__c  = 'None' , Operator__c = 'None') , i));
        
        //Fetching Rule Assignments
        fetchRuleAssignments();
        
        //Code is added on 07/16/2016 - FEATURE # 8: Add links the assignment rule on oppty
        //Check if, URL has rule assignment id as parameter
        if(ApexPages.currentPage().getParameters().get('ruleIdEdit') != null)
            editRuleAssignment(); //method call to edit assignment rule
    }
    
    /**
     *  @Description     :   This method is used to save the Rule Assignment rule .
     *
     *  @args            :
     *
     *  @return          :   pageReference
     **/
    public pageReference saveRuleAssinment() {      
        
        //List of rule assignment to be inserted
        List<Rule_Assignment_Criteria__c> ruleAssignmentsCriteriaToBeInserted = new List<Rule_Assignment_Criteria__c>();
        
        try {
            //Checking for name and rule 
            if(String.isNotBlank(ruleAssignment1.Name)  && ruleAssignment1.RevRecRule__c != null) { 
                
                //Loop over wrapper
                for(FilterSelectionWrapper wrap : ruleAssignmentWrapper) {
                                                
                    //Checking for values   
                    if(wrap.ruleAssignmentCriteria.Criteria_Field__c == 'Name') {
                        ruleAssignment1.Opportunity_Name__c = wrap.ruleAssignmentCriteria.Opportunity_Name__c ;
                        opportunityOperator = wrap.ruleAssignmentCriteria.Operator__c;
                    }
                    else if (wrap.ruleAssignmentCriteria.Criteria_Field__c == 'Family') {
                        ruleAssignment1.Product_Family__c = wrap.ruleAssignmentCriteria.Product_Family__c ;
                        familyOperator = wrap.ruleAssignmentCriteria.Operator__c;
                    }
                    else if(wrap.ruleAssignmentCriteria.Criteria_Field__c == 'Product Name') {
                        ruleAssignment1.Product_Name__c = wrap.ruleAssignmentCriteria.Product_Name__c ;
                        productOperator = wrap.ruleAssignmentCriteria.Operator__c;
                    }
                    
                    //Add into wrapper
                    ruleAssignmentsCriteriaToBeInserted.add(wrap.ruleAssignmentCriteria);
                }
                
                //Checking for the none
                if(opportunityOperator == '' || opportunityOperator == 'None')
                    selectedOppIds = new Set<String>();
                
                //Checking for the none
                if(familyOperator == '' || familyOperator == 'None')
                    selectFamily = new Set<String>();
                    
                //Checking for the none
                if(productOperator == '' || productOperator == 'None')
                    selectedProductIds = new Set<String>();
                
                if(Utility.checkFieldPermission(mapfieldResult,'Selected_Opportunity_Ids__c',Constants.PERMISSION_UPSERT)){
                       //Loop over sets 
                       if(selectedOppIds.size() > 0) {
                           
                           //Loop over selected ids
                           for(String sr  : selectedOppIds) {
                               
                               //Chhecking for already blank and existing values 
                               if(ruleAssignment1.Selected_Opportunity_Ids__c != null && !ruleAssignment1.Selected_Opportunity_Ids__c.contains(sr))
                                   ruleAssignment1.Selected_Opportunity_Ids__c += sr + ',';
                               else if(ruleAssignment1.Selected_Opportunity_Ids__c == null) 
                                   ruleAssignment1.Selected_Opportunity_Ids__c = sr + ',';
                           }
                           
                           //Removing end , from the string
                           ruleAssignment1.Selected_Opportunity_Ids__c = ruleAssignment1.Selected_Opportunity_Ids__c.removeEnd(',');
                       }else { //If no any selected id then blank selected fields from the database
                           ruleAssignment1.Selected_Opportunity_Ids__c = '';
                           if(Utility.checkFieldPermission(mapfieldResult,'Opportunity_Name__c',Constants.PERMISSION_UPSERT))
                               ruleAssignment1.Opportunity_Name__c = '';
                       }
                   }
                
                if(Utility.checkFieldPermission(mapfieldResult,'Selected_Product_Ids__c',Constants.PERMISSION_UPSERT)){
                       //Chcking for the set size
                       if(selectedProductIds.size() > 0) {
                           
                           //Loop over seletced ids
                           for(String sr  : selectedProductIds) {
                               
                               //Chhecking for already blank and existing values 
                               if(ruleAssignment1.Selected_Product_Ids__c != null && !ruleAssignment1.Selected_Product_Ids__c.contains(sr))
                                   ruleAssignment1.Selected_Product_Ids__c += sr + ',';
                               else if (ruleAssignment1.Selected_Product_Ids__c == null) 
                                   ruleAssignment1.Selected_Product_Ids__c = sr + ',';
                           }
                           //Removing end , from the string
                           ruleAssignment1.Selected_Product_Ids__c = ruleAssignment1.Selected_Product_Ids__c.removeEnd(',');
                       }else { //If no any selected id then blank selected fields from the database
                           ruleAssignment1.Selected_Product_Ids__c = '';
                           if(Utility.checkFieldPermission(mapfieldResult,'Product_Name__c',Constants.PERMISSION_UPSERT)){
                                  ruleAssignment1.Product_Name__c = '';
                              }
                       }
                   }
                
                if(Utility.checkFieldPermission(mapfieldResult,'Selected_Familys__c',Constants.PERMISSION_UPSERT)){
                       //Checking for the set size
                       if(selectFamily.size() > 0) {
                           
                           //Loop over selected ids 
                           for(String sr  : selectFamily) {
                               
                               //Chhecking for already blank and existing values 
                               if(ruleAssignment1.Selected_Familys__c != null && !ruleAssignment1.Selected_Familys__c.contains(sr))
                                   ruleAssignment1.Selected_Familys__c += sr + ',';
                               else if(ruleAssignment1.Selected_Familys__c == null)
                                   ruleAssignment1.Selected_Familys__c = sr + ',';
                           }
                           //Removing end , from the string
                           ruleAssignment1.Selected_Familys__c = ruleAssignment1.Selected_Familys__c.removeEnd(',');
                           
                           //Setting flag
                           if(selectedProductIds.size() == 0 &&  selectedOppIds.size() == 0 && Utility.checkFieldPermission(mapfieldResult,'Is_Family_Assignment__c',Constants.PERMISSION_UPSERT))
                               ruleAssignment1.Is_Family_Assignment__c =  true;
                           else
                               ruleAssignment1.Is_Family_Assignment__c = false;
                       }else { //If no any selected id then blank selected fields from the database
                           ruleAssignment1.Selected_Familys__c = '';
                           if(Utility.checkFieldPermission(mapfieldResult,'Product_Family__c',Constants.PERMISSION_UPSERT))
                               ruleAssignment1.Product_Family__c = '';
                       }
                   }
                
                if(Utility.checkFieldPermission(mapfieldResult,'Active__c',Constants.PERMISSION_UPSERT))
                    ruleAssignment1.Active__c = true;
               
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'Rule_Assignment__c')){
                       //Upsert rule
                       upsert ruleAssignment1;
                   }
                
                //Checking for list size
                if(ruleAssignmentsCriteriaToBeInserted.size() > 0 && ruleAssignment1.Id != null) {
                    
                    //Checking for list size
                    for(Rule_Assignment_Criteria__c crt : ruleAssignmentsCriteriaToBeInserted)
                        crt.Rule_Assignment__c = ruleAssignment1.Id; 
                    
                    //Insert
                    upsert ruleAssignmentsCriteriaToBeInserted;
                }
                
                /** Batch - MASS CALCULATE SELECTED OPPORTUNITY **/
                System.debug('@@@@@@@@@@@set opp ::::: : ' + selectedOppIds);
                System.debug('@@@@@@@@@@@set pro ::::: : ' + selectedProductIds);
                System.debug('@@@@@@@@@@@set family ::::: : ' + selectFamily);
                
                //Set of ids
                Set<Id> oppIdToExecuteBatch = new Set<Id>();
                
                //Checking for set size
                if(selectedOppIds.size() > 0 || selectedProductIds.size() > 0 || selectFamily.size() > 0  || String.isNotBlank(opportunityAdditionalSearch) ||
                   String.isNotBlank(productAdditionalsearch) || String.isNotBlank(familyAdditionalsearch)) { 
                
                    //Query string
                    string query = '';     
                    query += 'Select Id, Product2Id, Product2.Family , RevRecRule__c , OpportunityId From OpportunityLineItem ';
                    query += 'WHERE ';
                        
                    //If opportunity additional search selected
                   	if(String.isNotBlank(opportunityAdditionalSearch)) {
                        
                        opportunityAdditionalSearch = opportunityAdditionalSearch.replaceAll('[*]', '');
                        query += ' Opportunity.Name LIKE \'%' + opportunityAdditionalSearch + '%\' AND ';
                    }
                    
                    //If product2 additional search selected
                   	if(String.isNotBlank(productAdditionalsearch)) {
                           
                        productAdditionalsearch = productAdditionalsearch.replaceAll('[*]', '');
                        query += ' Product2.Name LIKE \'%' + productAdditionalsearch + '%\' AND ';
                    }
                    //If product2 additional search selected
                    if(String.isNotBlank(familyAdditionalsearch)) {
                           
                        familyAdditionalsearch = familyAdditionalsearch.replaceAll('[*]', '');
                        query += ' Product2.Family LIKE \'%' + familyAdditionalsearch + '%\' AND ';
                    }
                    //If opportunity selected
                    if(selectedOppIds.size() > 0)
                        query += ' OpportunityId '+ opportunityOperator +' : selectedOppIds AND ';
                    
                    //If product ids selected 
                    if(selectedProductIds.size() > 0)
                        query += ' Product2Id '+ productOperator +' : selectedProductIds AND ';
                    
                    //If family selected 
                    if(selectFamily.size() > 0)
                        query += ' Product2.Family '+familyOperator+' : selectFamily';
                    
                    //Removing last AND and WHERE operator 
                    query = query.removeEnd('AND ');
                    query = query.removeEnd('WHERE ');
                    query = query.trim();
                    query += ' LIMIT 1';
                    System.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@' + query);
                    
                    //Query on line items 
                    List<OpportunityLineItem> oppLines = database.query(query);
                        
                    //Checking for list size
                    if(oppLines.size() > 0) {
                        
                        //Loop over line items 
                        for(OpportunityLineItem oli : oppLines) {
                            
                            //Assigning ruule on line items 
                            oli.RevRecRule__c = ruleAssignment1.RevRecRule__c;
                            //Code added on 07/15/2016 - FEATURE # 8: Add links the assignment rule on oppty
                            oli.Rule_Assignment__c = ruleAssignment1.Id;
                            oppIdToExecuteBatch.add(oli.OpportunityId);
                        }
                        
                        Constants.IS_BY_PASS_LINE_ITEM_TRIGGER = true;
                        
                        //Updating line items with rev rec rule
                        update oppLines; 
                        Constants.IS_BY_PASS_LINE_ITEM_TRIGGER = false;
                    } 
                }
                
                //Checking for the set size         
                if(oppIdToExecuteBatch.size() > 0) {
                    
                    //Checking for the set size
                    if(selectedOppIds.size() > 0 || selectedProductIds.size() > 0 || selectFamily.size() > 0) { 
                        
                        //Calling batch to update all line items 
                        Batch_RunRuleAssignments bc = new Batch_RunRuleAssignments(selectedOppIds , selectedProductIds, selectFamily, 
                                        opportunityOperator, productOperator, familyOperator, ruleAssignment1.RevRecRule__c, ruleAssignment1.Id);
                                        
                        Database.executeBatch(bc, 100);
                     }
                      
                     //If no any opportunity criteria selected
                     if(selectedOppIds.size() == 0) {
                        
                        //Calling batch to update products 
                        //Code added on 07/15/2016 - FEATURE # 8: Add links the assignment rule on oppty
                        //Parameter is updated in batch
                        Batch_RunRuleAssignmentForProducts bc1 = new Batch_RunRuleAssignmentForProducts(selectedProductIds, selectFamily, 
                                            productOperator, familyOperator, ruleAssignment1.RevRecRule__c, ruleAssignment1.Id);
                                        
                        Database.executeBatch(bc1, 100);
                          
                        //Checking for the set size
                        if(selectedOppIds.size() > 0 ) { 
                            
                            //Calling batch to update all line items 
                            Batch_RunAsignmentForOpportunity bc2 = new Batch_RunAsignmentForOpportunity(selectedOppIds , ruleAssignment1.RevRecRule__c, ruleAssignment1.Id,
                                                                                                        opportunityOperator);
                            Database.executeBatch(bc2, 100);                     
                        }
                     }
                     
                    //Apex page messages
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.Batch_Starts_Label));
                    
                    //Load defaults
                    inIt();
                }else{
                     
                    //Checking for the set size
                    if(selectedOppIds.size() > 0 ) { 
                        
                        //Calling batch to update all line items 
                        Batch_RunAsignmentForOpportunity bc2 = new Batch_RunAsignmentForOpportunity(selectedOppIds , ruleAssignment1.RevRecRule__c, ruleAssignment1.Id,
                                                                                                    opportunityOperator);
                        Database.executeBatch(bc2, 100);     
                        
                       	//Apex page messages
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.Batch_Starts_Label));
                    }
                    
                    //Check if product and family not stamp with OLI
                    //Code added on 08/23/2016
                    else if(String.isNotBlank(productAdditionalsearch) != null || String.isNotBlank(familyAdditionalsearch)) {
                        
                        //Query string
                        string productQuery = '';     
                        productQuery += 'Select Id, Name, Family, RevRecRule__c , Rule_Assignment__c From Product2 ';
                        productQuery += 'WHERE ';
                        
                        //If product2 additional search selected
                        if(String.isNotBlank(productAdditionalsearch)) 
                            productQuery += ' Name LIKE \'%' + productAdditionalsearch + '%\' AND ';
                        
                        //If product2 additional search selected
                        if(String.isNotBlank(familyAdditionalsearch)) 
                            productQuery += ' Family LIKE \'%' + familyAdditionalsearch + '%\' AND ';
                        
                        //Removing last AND and WHERE operator 
                        productQuery = productQuery.removeEnd('AND ');
                        productQuery = productQuery.removeEnd('WHERE ');
                        productQuery = productQuery.trim();
                        productQuery += ' LIMIT 1';
                        
                        //Query on products 
                        List<Product2> products = database.query(productQuery);
                        
                        //Check if, product found
                        if(products.size() > 0) {
                            
                            //Batch execution to update products
                            Batch_RunRuleAssignmentForProducts bc1 = new Batch_RunRuleAssignmentForProducts(selectedProductIds, selectFamily, 
                                                productOperator, familyOperator, ruleAssignment1.RevRecRule__c, ruleAssignment1.Id);
                                            
                            Database.executeBatch(bc1, 100);
                            
                            //Apex page messages
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.Batch_Starts_Label));
                        }
                    }else {
                        
                        //Apex page messages
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.No_Record_Found_Label));                        
                    }
                }
                
            }else { 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Rule Definition section is required.'));
            }
        }catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        
        //Fetching Rule Assignments
        fetchRuleAssignments();
        
        //Return
        return null;
    }
    
    /**
     *  @description    :   This method is used to fetch the all the Rule Assignments.
     *
     *  @args           :   -
     *
     *  @return         :   -
    **/
    public void fetchRuleAssignments() {
        
        //Initlize
        ruleAssignmentRecordsWrapper = new List<RuleAssignmentRecordsWrapper>();
        
        //Query to fetch all rule assignments and add them in wrapper
        for(Rule_Assignment__c rule : [Select Active__c, Details__c, Name, Opportunity_Name__c, Product_Family__c, Product_Name__c, RevRecRule__c, RevRecRule__r.Name,
                                        Is_Family_Assignment__c From Rule_Assignment__c ORDER BY LastModifiedDate DESC LIMIT 20]) 
            ruleAssignmentRecordsWrapper.add(new RuleAssignmentRecordsWrapper(false, rule));        
    }
    
    /**
    *   @description    :   This method is used to called on the onchange of selected field values from the page.
    *   
    *   @args           :   -
    *
    *   return          :   void
    **/
        
    public void onChangeCriteria () {
        
        //Fetching selected row
        String selectedRow = ApexPages.CurrentPage().getParameters().get('rowCount');
        
        //Checking for the Selected row and selected row value
        if(String.isNotBlank(selectedRow) ) {
            ruleAssignmentWrapper[Integer.valueOf(selectedRow)].ruleAssignmentCriteria.Product_Name__c = '';
            ruleAssignmentWrapper[Integer.valueOf(selectedRow)].ruleAssignmentCriteria.Product_Family__c = '';
            ruleAssignmentWrapper[Integer.valueOf(selectedRow)].ruleAssignmentCriteria.Opportunity_Name__c = '';
            ruleAssignmentWrapper[Integer.valueOf(selectedRow)].ruleAssignmentCriteria.Operator__c = '';
        }
    }
        
    /**
     *  @description    :   This method is used to delete the selected rule assignment.
     *
     *  @args           :   -
     *
     *  @return         :   void
    **/
    public void deleteSelected () {
        
        //List of rule assignments to be deleted
        List<Rule_Assignment__c> ruleAsgToBeDeleted = new List<Rule_Assignment__c>();
        
        //Loop over records wrapper
        for(RuleAssignmentRecordsWrapper wrap : ruleAssignmentRecordsWrapper) {
            
            //Checking for selected value
            if(wrap.isSelected)
                ruleAsgToBeDeleted.add(wrap.rule);
        }
        
        //Checking for list size
        if(ruleAsgToBeDeleted.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'Rule_Assignment__c')))
            delete ruleAsgToBeDeleted;
        
        //Fetching remaining rule assignment
        fetchRuleAssignments();
    }
    
    /**
     *  @description    :   This method is used to edit the selected rule assignment.
     *
     *  @args           :   -
     *
     *  @return         :   void
    **/
    public void editRuleAssignment() {
        
        //Fetching record Id
        Id recordId = ApexPages.CurrentPage().getParameters().get('ruleIdEdit');
        
        //Initilization
        ruleAssignmentWrapper = new List<FilterSelectionWrapper>();
        Integer i=0;
        selectedOppIds = new Set<String>();
        selectedProductIds = new Set<String>();
        selectFamily = new Set<String>();
        
        //Fetching record
        for(Rule_Assignment_Criteria__c editRuleCriteria : [Select  Name, Opportunity_Name__c, Product_Family__c, Product_Name__c,Rule_Assignment__c,
                                Rule_Assignment__r.Name, Rule_Assignment__r.RevRecRule__c,Criteria_Field__c, Operator__c ,
                                Rule_Assignment__r.Selected_Opportunity_Ids__c,Rule_Assignment__r.Selected_Product_Ids__c,
                                Rule_Assignment__r.Selected_Familys__c,Rule_Assignment__r.Active__c, Rule_Assignment__r.Details__c,Additional_Search_Criteria__c
                                From Rule_Assignment_Criteria__c where Rule_Assignment__c =: recordId LIMIT 3]) {
            ruleAssignmentWrapper.add(new FilterSelectionWrapper(selectOperators, selectCriterias , editRuleCriteria, i));
            i++;
        }
        
        //Checking for the wrapper size
        if(ruleAssignmentWrapper.size() > 0) {
            ruleAssignment1 = ruleAssignmentWrapper[0].ruleAssignmentCriteria.Rule_Assignment__r;
            
            //checking for values and populate set
            if(String.isNotBlank(ruleAssignmentWrapper[0].ruleAssignmentCriteria.Rule_Assignment__r.Selected_Opportunity_Ids__c)) 
                selectedOppIds.addAll(ruleAssignmentWrapper[0].ruleAssignmentCriteria.Rule_Assignment__r.Selected_Opportunity_Ids__c.split(','));
            
            //Checking for values and populate set
            if(String.isNotBlank(ruleAssignmentWrapper[0].ruleAssignmentCriteria.Rule_Assignment__r.Selected_Product_Ids__c)) 
                selectedProductIds.addAll(ruleAssignmentWrapper[0].ruleAssignmentCriteria.Rule_Assignment__r.Selected_Product_Ids__c.split(','));

            //Checking for family values and populate set
            if(String.isNotBlank(ruleAssignmentWrapper[0].ruleAssignmentCriteria.Rule_Assignment__r.Selected_Familys__c))
                selectFamily.addAll(ruleAssignmentWrapper[0].ruleAssignmentCriteria.Rule_Assignment__r.Selected_Familys__c.split(','));
                
            //Loop over criteria
            for(FilterSelectionWrapper ruleWrap : ruleAssignmentWrapper) {
                
                if(ruleWrap.ruleAssignmentCriteria.Criteria_Field__c == 'Name')
                    mapFieldWithAdditionalVal.put('Name', ruleWrap.ruleAssignmentCriteria.Additional_Search_Criteria__c);
                else if(ruleWrap.ruleAssignmentCriteria.Criteria_Field__c == 'Product Name') 
                    mapFieldWithAdditionalVal.put('Product Name', ruleWrap.ruleAssignmentCriteria.Additional_Search_Criteria__c);
                else if(ruleWrap.ruleAssignmentCriteria.Criteria_Field__c == 'Family')
                    mapFieldWithAdditionalVal.put('Family', ruleWrap.ruleAssignmentCriteria.Additional_Search_Criteria__c);
            }
        }
    }
    
    /**
     *  @description    :   This method is used to delete the selected rule assignment.
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public void deleteRuleAssignment() {
        
        //Fetching record Id
        Id recordId = ApexPages.CurrentPage().getParameters().get('ruleIdDelete');
        
        //Checking for null
        if(recordId != null) {
            
            //fetching rule criteria to be delete
            List<Rule_Assignment__c> ruleToDelete = [Select Id From Rule_Assignment__c where Id =: recordId LIMIT 1];
            
            //Chhecking for list size
            if(ruleToDelete.size() > 0 && (Rule_Assignment__c.sObjectType.getDescribe().isDeletable()))
                delete ruleToDelete;
        }
        
        //Fetching records
        fetchRuleAssignments();
    }
    /**
     *  @description    :   This method is used to select Items(Opportunity/Product)
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public void fetchRelatedRecords() {
        
        //Initilization
        allAvailableOppAndProMap = new Map<String, String>();
        rightItemMap = new Map<String, String>();
        opportunitySelectList= new List<SelectOption>();
        itemSeletedOppList = new List<SelectOption>();      
        selectedSearchVal = '';
        searchString = '';
        additionalSearchText = '';
        
        //Additional search variable initialization
        opportunityAdditionalsearch = '';
        productAdditionalsearch = '';
        familyAdditionalsearch = '';
        
        //Calling method to fetch all related records
        fetchAll();
    }
    
    /**
     *  @description    :
     *
     *  @args           :   String selectedCriteriaFromButton
     *
     *  @return         :
     **/
    public void fetchAll() {
        
        /** Case - 1 - Opportunity **/
        //Checking if select is hitting from Opportunity Criteria
        if(selectedCriteriaFromButton.equals('Name')) {
            
            //Fetching data of opportunity
            List<Opportunity> opps = [Select Id, Name From Opportunity limit 1000];
            
            //Checking for the size
            if(opps.size() ==  1000) 
                infoMsg = Constants.MORE_THAN_1000_RECORDS;
            else 
                infoMsg = '';
            
            //Query over opportunities from database
            for(Opportunity opp : opps) {
                
                //Putting all 
                if(!selectedOppIds.contains(opp.Id)) {
                    allAvailableOppAndProMap.put(opp.Id, opp.Name);
                    opportunitySelectList.add(new SelectOption(opp.Id, opp.Name));
                }else {
                    
                    //populating map and select list
                    itemSeletedOppList.add(new SelectOption(opp.Id, opp.Name));
                    rightItemMap.put(opp.Id, opp.Name);             
                }
            }
            additionalSearchText = mapFieldWithAdditionalVal.get('Name');
        }

        /** Case - 2 - Family  **/
        //Checking for if selecy is hitting from the product family
        if(selectedCriteriaFromButton.equals('Family')) {
        
            /** Getting the picklist values using describe method and populating select option**/
            Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();     
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            //Checking for the size
            if(ple.size() == 1000) 
                infoMsg = Constants.MORE_THAN_1000_RECORDS;
            else 
                infoMsg = '';
                
            //Loop over picklist entries and populate wrapper
            for( Schema.PicklistEntry f : ple) {
                
                //Add all family values into select option
                if(!selectFamily.contains(f.getLabel())) {
                    allAvailableOppAndProMap.put(f.getLabel(), f.getLabel());
                    opportunitySelectList.add(new SelectOption(f.getLabel(), f.getLabel()));
                }else {
                    
                    //populating map and select list
                    itemSeletedOppList.add(new SelectOption(f.getLabel(), f.getLabel()));
                    rightItemMap.put(f.getLabel(), f.getLabel());      
                }
            } 
            additionalSearchText = mapFieldWithAdditionalVal.get('Family'); 
        }
        
        /** Case - 3 - Product Name **/
        //Checking for if selecy is hitting from the product Name
        if(selectedCriteriaFromButton.equals('Product Name')) {
        
            //Fetching products 
            List<Product2> products = [Select Id, Name From Product2 limit 1000 ];
            
            //Checking for the size
            if(products.size() == 1000) 
                infoMsg = Constants.MORE_THAN_1000_RECORDS;
            else 
                infoMsg = '';
            
            //Query over all the products and it into select options
            for(Product2 pro : products) {
                
                if(!selectedProductIds.contains(pro.Id)) {
                    allAvailableOppAndProMap.put(pro.Id, pro.Name);
                    opportunitySelectList.add(new SelectOption(pro.Id, pro.Name));
                }else {
                    itemSeletedOppList.add(new SelectOption(pro.Id, pro.Name));
                    rightItemMap.put(pro.Id, pro.Name);         
                }
            }
            additionalSearchText = mapFieldWithAdditionalVal.get('Product Name'); 
        }
        
        //Checking for map key
        for(String key : rightItemMap.keySet())
            selectedSearchVal += rightItemMap.get(key) + ' OR ';
        
        //Adding additional search text in selected search value
        if(additionalSearchText != null)
            selectedSearchVal += additionalSearchText + ' OR ';
        
        //Checking for the string value 
        if(String.isNotBlank(selectedSearchVal)) 
            selectedSearchVal = selectedSearchVal.removeEnd(' OR ');        
    }
    
    /**
     *  @description    :   This method is invoke on click of button "Add selection" from page 
     *                      This method is removing values from left select option and adding them into right select option
     *
     *  @args           :   
     *
     *  @return         :   
    **/
     public void OpportunityTypeSelectClick() {
        
        //Initilization
        rightOpportunityTypes = new Set<String>();
        rightOpportunityTypeSelected.clear(); 
        opportunitySelectList = new List<SelectOption>();
        selectedSearchVal = '';
        
        //Loop over all selected value from page and add them into right selected type and remove from left selected type
        for(string s: leftOpportunityTypeSelected) {
            rightOpportunityTypes.add(s);
            leftOpportunityTypes.remove(s);
        }
        
        //Loop over all rigght selected values and then populate both left and right select option
        for(String itemId : rightOpportunityTypes) {
            
            //Checking for conatainsKey
            if(allAvailableOppAndProMap.containsKey(itemId)) {
                
                //Populate right selected select option
                itemSeletedOppList.add(new SelectOption(itemId, allAvailableOppAndProMap.get(itemId)));
                
                //Holding map for right values 
                rightItemMap.put(itemId, allAvailableOppAndProMap.get(itemId));
                
                //Remove values from left map
                allAvailableOppAndProMap.remove(itemId);
            }
        }
        
        //Populate left select option by looping over left side map
        for(String key : allAvailableOppAndProMap.keySet()) {
            
            //Checkimg for map key
            if(allAvailableOppAndProMap.containsKey(key)) 
                opportunitySelectList.add(new SelectOption(key, allAvailableOppAndProMap.get(key)));
        }
        
        //Loop over right selected map
        for(String key : rightItemMap.keySet()) {
            
            //Checking for map key
            if(rightItemMap.containsKey(key))
                selectedSearchVal += rightItemMap.get(key) + ' OR ';
            
            //Populating set of selected opp
            if(selectedCriteriaFromButton.equalsIgnoreCase('Name'))
                selectedOppIds.add(key);
            
            //Populating set of selected product 
            if(selectedCriteriaFromButton.equalsIgnoreCase('Product Name'))
                selectedProductIds.add(key);
            
            //Populating set of selected product family
            if(selectedCriteriaFromButton.equalsIgnoreCase('Family'))
                selectFamily.add(key);   
        }
        
        //Checking for the selected 
        if(String.isNotBlank(additionalSearchText))
            selectedSearchVal += additionalSearchText;
        
        //Removing last  | 
        selectedSearchVal = selectedSearchVal.removeEnd(' OR ');
    }

    /**
     *  @description    :   This method is invoke on click of button "Remove from selection" from page 
     *                      This method is removing values from right select option and adding them into left select option
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public void OpportunityTypeUnSelectClick() {
        
        //Variable initilization
        rightOpportunityTypes = new Set<String>();
        leftOpportunityTypeSelected.clear();
        itemSeletedOppList = new List<SelectOption>();
        selectedSearchVal = '';
        additionalSearchText = '';
        
        //Loop over all the value selected in the right select option
        for(string s: rightOpportunityTypeSelected) {
            
            //Add values in left side and remove from right side
            rightOpportunityTypes.remove(s);
            leftOpportunityTypes.add(s); 
        }    
        
        //Loop over all left selected values
        for(String itemId : leftOpportunityTypes) {
            
            //Checking for the containsKy 
            if(rightItemMap.containsKey(itemId)) {
                
                //Add values in the left select options
                opportunitySelectList.add(new SelectOption(itemId, rightItemMap.get(itemId)));
                
                //Holding map for the all left selet option values
                allAvailableOppAndProMap.put(itemId, rightItemMap.get(itemId));
                
                //Removing values for the right side map
                rightItemMap.remove(itemId);
            }
        }
        
        //Loop over right side map and populate right select options
        for(String key : rightItemMap.keySet()) {
            
            //Checking for the contains key and populate select option
            if(rightItemMap.containsKey(key)) 
                itemSeletedOppList.add(new SelectOption(key , rightItemMap.get(key)));
        }
        
         //Loop over right selected map
        for(String key : rightItemMap.keySet()) {
            
            //Checking for map key
            if(rightItemMap.containsKey(key))
                selectedSearchVal += rightItemMap.get(key) + ' OR ';
            
            //Populating set of selected opp
            if(selectedCriteriaFromButton.equalsIgnoreCase('Name'))
                selectedOppIds.add(key);
            
            //Populating set of selected product 
            if(selectedCriteriaFromButton.equalsIgnoreCase('Product Name'))
                selectedProductIds.add(key);
            
            //Populating set of selected product family
            if(selectedCriteriaFromButton.equalsIgnoreCase('Family'))
                selectFamily.add(key);          
        }
        
        //Removing last  ||
        selectedSearchVal = selectedSearchVal.removeEnd(' OR ');
    }
    /**
     *  @description    :   This method is used to add aditional values into right options.
     *
     *  @args           :   
     *
     *  @return         :
     **/
    public void addAdditionalSearchValues () {
        
        //Initilization
        //leftOpportunityTypeSelected = new List<String>();
        //itemSeletedOppList = new List<SelectOption>();
        //opportunitySelectList = new List<SelectOption>();
        
        //Set value
        if(String.isBlank(selectedSearchVal))
            selectedSearchVal +=  additionalSearchText;
      	else
            selectedSearchVal +=  ' OR ' + additionalSearchText;
        
        /** Case - 1 - Opportunity **/
        //Checking if select is hitting from Opportunity Criteria
        if(selectedCriteriaFromButton.equals('Name')) {
            
            //Additional search  string
            opportunityAdditionalSearch = additionalSearchText;
            
            //List of opportunity
            List<Opportunity> opps = new List<Opportunity>();
            
            //Checking for the search string to fetch opportunity
            if(String.isNotBlank(additionalSearchText)) {
                
                String tempAdditionalSearchText = additionalSearchText;
                if(tempAdditionalSearchText.contains('*')) {
                    tempAdditionalSearchText = tempAdditionalSearchText.replaceAll('[*]', '%'); 
                    tempAdditionalSearchText = tempAdditionalSearchText.trim();

                    opps = [Select Id, Name From Opportunity where Name LIKE : tempAdditionalSearchText
                            and ID NOT IN : selectedOppIds limit 1000];
                    System.debug('opps...@@@' + opps);

                } else {
                    opps = [Select Id, Name From Opportunity where Name LIKE : additionalSearchText + '%' 
                            and ID NOT IN : selectedOppIds limit 1000];
                    System.debug('opps...@@@' + opps);
                }
            }
            
            //Checking if opportunity found
            if(opps.size() > 0) {
                
                //Loop to add opportunity id in set
                for(Opportunity opp : opps) {
                    
                    //Checking if set alerady contains opportunity id
                    if(!selectedOppIds.contains(opp.Id))
                        selectedOppIds.add(opp.Id);
                }                   
            }
        }
        
        /** Case - 2 - Product Name **/
        //Checking for if selecy is hitting from the product Name
        if(selectedCriteriaFromButton.equals('Product Name')) {
            
            //Additional search string
            productAdditionalsearch = additionalSearchText;
            
            //List of products
            List<Product2> products = new List<Product2>();
            
            //Query to fetch products
            if(String.isNotBlank(additionalSearchText)) {
            
           		String tempAdditionalSearchText = additionalSearchText;
                
                if(tempAdditionalSearchText.contains('*')) {
                    
                    tempAdditionalSearchText = tempAdditionalSearchText.replaceAll('[*]', '%'); 
                    tempAdditionalSearchText = tempAdditionalSearchText.trim();
                
                	products =  [Select Id From Product2 where Name LIKE : tempAdditionalSearchText + '%' AND 
                                 ID NOT IN : selectedProductIds limit 1000];
                    
            	} else {
                    products =  [Select Id From Product2 where Name LIKE : additionalSearchText + '%' AND 
                                 ID NOT IN : selectedProductIds limit 1000];
          		}
            }
            
            if(products.size() > 0) {
                
                //Loop to add opportunity id in set
                for(Product2 product : products) {
                    
                    //Checking if set alerady contains product id
                    if(!selectedProductIds.contains(product.Id))
                        selectedProductIds.add(product.Id);
                }                   
            }
        }
        
        /** Case - 3 - Family **/
        if(selectedCriteriaFromButton.equals('Family'))
            familyAdditionalsearch = additionalSearchText;
        
        //Calling method to fecth the data
        //searchByString(additionalSearchText);
        
        //Calling method to put values into right selected value
        //OpportunityTypeSelectClick();
    }
    
    /**
     *  @description    :   This method is used to 
     *
     *  @args           :
     *
     *  @return         :   
    **/
    public void saveSelectedRecords () {
        
        //Checking for the row count AND button param
        if(String.isNotBlank(selectedRowNum ) && String.isNotBlank(selectedCriteriaFromButton)) {
            
            if(selectedCriteriaFromButton.equalsIgnoreCase('Name')) {
                ruleAssignmentWrapper[Integer.valueOf(selectedRowNum)].ruleAssignmentCriteria.Opportunity_Name__c = selectedSearchVal;
                ruleAssignmentWrapper[Integer.valueOf(selectedRowNum)].ruleAssignmentCriteria.Additional_Search_Criteria__c = additionalSearchText;
            }
            else if(selectedCriteriaFromButton.equalsIgnoreCase('Family')) {
                ruleAssignmentWrapper[Integer.valueOf(selectedRowNum)].ruleAssignmentCriteria.Product_Family__c = selectedSearchVal;
                ruleAssignmentWrapper[Integer.valueOf(selectedRowNum)].ruleAssignmentCriteria.Additional_Search_Criteria__c = additionalSearchText;
            }
            else if(selectedCriteriaFromButton.equalsIgnoreCase('Product Name')) {
                ruleAssignmentWrapper[Integer.valueOf(selectedRowNum)].ruleAssignmentCriteria.Product_Name__c = selectedSearchVal;
                ruleAssignmentWrapper[Integer.valueOf(selectedRowNum)].ruleAssignmentCriteria.Additional_Search_Criteria__c = additionalSearchText;
            }
        }
        
        fetchRuleAssignments();
    }
    
    /**
     *  @description    :   This method is used to fetch the data by filtered using search string from popup.
     *
     *  @args           :   -
     *     
     *  @return         :   -
    **/
    public void searchRecords() {
        
        selectedSearchVal = '';
        
        //Initilization
        allAvailableOppAndProMap = new Map<String, String>();
        opportunitySelectList = new List<SelectOption>();
        
        //Calling method to fetch the data
        searchByString(searchString);
        leftOpportunityTypeSelected = new List<String>();
    }
    
    /**
     *  @description    :   This method is used to fetch the data related to search string
     *
     *  @args           :   String additionalSearchText
     *
     *  @return         :   
    **/
    public void searchByString( String additionalSearchText) {
        
        /** Case - 1 - Opportunity **/
        //Checking if select is hitting from Opportunity Criteria
        if(selectedCriteriaFromButton.equals('Name')) {
            
            //List of opportunity
            List<Opportunity> opps = new List<Opportunity>();
            
            //Check for * 
            /*if(additionalSearchText.contains('*')) {
                additionalSearchText = additionalSearchText.replaceAll('[*]', ''); 
                additionalSearchText = additionalSearchText.trim();
            }*/
            //Chhecking for the search string
            if(String.isNotBlank(additionalSearchText)) {
                
                String tempAdditionalSearchText = additionalSearchText;
                
                if(additionalSearchText.contains('*')) {
                    tempAdditionalSearchText = additionalSearchText.replaceAll('[*]', '%'); 
                    tempAdditionalSearchText = additionalSearchText.trim();

                    opps = [Select Id, Name From Opportunity where Name LIKE : tempAdditionalSearchText
                                                and ID NOT IN : selectedOppIds limit 1000];

                } else {
                    opps = [Select Id, Name From Opportunity where Name LIKE : additionalSearchText + '%' 
                                                and ID NOT IN : selectedOppIds limit 1000];
                }
                //additionalSearchText = tempAdditionalSearchText;

            } else
                opps = [Select Id, Name From Opportunity where ID NOT IN : selectedOppIds limit 1000];
                
            //Checking for the size
            if(opps.size() == 1000) 
                infoMsg = Constants.MORE_THAN_1000_RECORDS;
            else 
                infoMsg = '';
            
            //Query over opportunities from database
            for(Opportunity opp : opps) {
                
                //Putting all 
                allAvailableOppAndProMap.put(opp.Id, opp.Name);
                opportunitySelectList.add(new SelectOption(opp.Id, opp.Name));
                leftOpportunityTypeSelected.add(opp.Id);
            }
        }

        /** Case - 2 - Family  **/
        //Checking for if selecy is hitting from the product family
        if(selectedCriteriaFromButton.equals('Family')) {
        
            /** Getting the picklist values using describe method and populating select option**/
            Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();     
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            //Checking for the size
            if(ple.size() == 1000) 
                infoMsg = Constants.MORE_THAN_1000_RECORDS;
            else 
                infoMsg = '';
            
            //Loop over picklist entries and populate wrapper
            for( Schema.PicklistEntry f : ple) {
                
                //Add all family values into select option
                allAvailableOppAndProMap.put(f.getLabel(), f.getLabel());
                opportunitySelectList.add(new SelectOption(f.getLabel(), f.getLabel()));
            }  
        }
        
        /** Case - 3 - Product Name **/
        //Checking for if selecy is hitting from the product Name
        if(selectedCriteriaFromButton.equals('Product Name')) {
            
            //List of products
            List<Product2> products = new List<Product2>();
            
            //Query to  fetch products
            if(String.isNotBlank(additionalSearchText)) {
                
                String tempAdditionalSearchText = additionalSearchText;
                
                if(additionalSearchText.contains('*')) {
                    tempAdditionalSearchText = additionalSearchText.replaceAll('[*]', '%'); 
                    tempAdditionalSearchText = additionalSearchText.trim();
                    
                    products =  [Select Id, Name From Product2 where Name LIKE : tempAdditionalSearchText + '%'
                                    AND ID NOT IN : selectedProductIds limit 1000];
                } else {
                    
                    products =  [Select Id, Name From Product2 where Name LIKE : additionalSearchText + '%'
                                    AND ID NOT IN : selectedProductIds limit 1000];
                }
            }
                
            else
                products =  [Select Id, Name From Product2 where ID NOT IN : selectedProductIds limit 1000];
            
            //Checking for the size
            if(products.size() == 1000) 
                infoMsg = Constants.MORE_THAN_1000_RECORDS;
            else 
                infoMsg = '';
                    
            //Query over all the products and it into select options
            for(Product2 pro : products) {
                        
                allAvailableOppAndProMap.put(pro.Id, pro.Name);
                opportunitySelectList.add(new SelectOption(pro.Id, pro.Name));
                leftOpportunityTypeSelected.add(pro.Id);
            }
        }
    }

    /**
     *  Wrapper class to hold the selected opportunity , product and family values.
    **/
    public class FilterSelectionWrapper {
        
        public List<SelectOption> selectOperators {get; set;}
        public List<SelectOption> selectCriterias {get; set;}
        public Rule_Assignment_Criteria__c ruleAssignmentCriteria {get; set;}
        public Integer rowNum {get; set;}
        
        //Constructer
        public FilterSelectionWrapper(List<SelectOption> selectOperators , List<SelectOption> selectCriterias , Rule_Assignment_Criteria__c ruleAssignmentCriteria , Integer rowNum) {
            
            //Variable assignment
            this.selectOperators = selectOperators;
            this.selectCriterias = selectCriterias;
            this.ruleAssignmentCriteria = ruleAssignmentCriteria;
            this.rowNum = rowNum;
        }
    }
    
    /**
     *  Wrapper class to show all rule assignment records.
     **/
    public class RuleAssignmentRecordsWrapper {
        
        //Properties
        public Boolean isSelected {get; set;}
        public Rule_Assignment__c rule {get; set;}
        
        //Constructer
        public RuleAssignmentRecordsWrapper(Boolean isSelected , Rule_Assignment__c rule) {
            
            //Assignments
            this.isSelected = isSelected;
            this.rule = rule;
        } 
    }  
   
    public void operatorValueChange() {
    }
}