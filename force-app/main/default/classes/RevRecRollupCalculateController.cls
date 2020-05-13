public with sharing class RevRecRollupCalculateController {
    public Boolean isError{get;set;}
    public Boolean isHavingPermission{get;set;}
    public Boolean NoRecordsFound{get;set;}
    public Boolean NotAuthorized{get;set;}
    public Boolean isMultiCurrencyEnabled;
    
    //Oopportunity initilization
    public Opportunity opportunity {get;set;}
    public Opportunity opportunity1 {get;set;} public String query;
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
    Public RevRecRollupCalculateController() {
        
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
    public void SetYearlyAndMonthlyRollupOnOpportunity() {
        
        //Creating query String
        Date dt1 = null;
        Date dt2 = null;
        
        List<PermissionSetAssignment> lstcurrentUserPerSet = [SELECT Id, PermissionSet.Name,AssigneeId
                                                              FROM PermissionSetAssignment
                                                              WHERE AssigneeId = :Userinfo.getUserId()
                                                              AND PermissionSet.Name IN('REVvue_Opportunity_Mass_Rollup_Calculation') ];
        if(lstcurrentUserPerSet.size() > 0) {
            for (PermissionSetAssignment psa: lstcurrentUserPerSet) {
                if(psa.PermissionSet.Name.equals('REVvue_Opportunity_Mass_Rollup_Calculation'))  
                    isHavingPermission = false;
                else
                    isHavingPermission = true;
            }
        }
        else
            isHavingPermission = true;
        
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        
        //If the user have the permission of the rollup..
        if(!isHavingPermission) {
            //Query..
            String query = '';
            
            if(!isMultiCurrencyEnabled)
                query += 'SELECT Id, name, TCV_Actual__c, Probability, StageName, Amount';
            else
                query += 'SELECT Id, name, CurrencyIsoCode, TCV_Actual__c, Probability, StageName, Amount';
            
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
            
            //Database.query for schedules
            List<Opportunity> allOpp = database.query(query);
            
            //Check for condition if there is any record criteria without rule exist
            if(allOpp.size() > 0) {
                DataBase.executeBatch(new Batch_MassRollUpRevenueCalculation(allOpp,true), 1);
                
                //Apex page messages
                isError = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.Batch_Starts_Label));
            }
            else {
                //Apex page messages
                NoRecordsFound = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, Label.No_Record_Found_Label));
            }
        }
        else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You are not authorized to run the Calculations'));
            
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
}