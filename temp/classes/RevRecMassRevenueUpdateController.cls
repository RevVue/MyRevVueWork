/**
*  Description     :   This Class is to show the Projeted and Actual Amount
* 
*  Created Date    :   01/07/2020
*
*  Created By      :	     
*              
**/
public with sharing class RevRecMassRevenueUpdateController{
    /*
    //Opportunity initilization
    public Opportunity opportunity {get;set;}
    public Opportunity opportunity1 {get;set;} 
    public String query;
    
    Set<String> setAllDatesAPI = new Set<String>();
    
    //Variables to hold select list filter criteria value 
    public string selectedCriteriaField {get;set;}
    public string selectedCriteria {get;set;}
    
    public Boolean isShow{get;set;}
    public Blob csvFileBody {get;set;}
    public String csvAsString {get;set;}
    public boolean displayPopup {get; set;}
    
    public Blob contentFile{get;set;}
    public string nameFile{get;set;}
    
    //String array for taking csv data by line.
    String[] filelines = new String[]{};
        
   	//string array for taking csv columns.
   	String[] fileColumns = new String[]{};
            
    //List of opportunity for matching criteria
    public List<Opportunity> searchCriteriaOpportunities ;
    
    //wrapper
    public List<rrProjectedAndActualWrapper> listWithProjectedAndActualAmountWrapper {get;set;}
    
    public List<CSVUploadedWrapper> listOfCSVUploadWrapper {get;set;}
    
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
    Public RevRecMassRevenueUpdateController() {
        
        //Memory allocaton  
        opportunity = new Opportunity();
        opportunity1 = new Opportunity();
        selectedCriteriaField = '--None--';
        selectedCriteria = '--None--';
        searchCriteriaOpportunities = new List<Opportunity>();
        
    }*/
    
    /**
    *  @description    :    Method to search opportunity for creitaria select from vf page and execute batch
    *                           
    *  @args           :    
    *                      
    *  @return         :    void           
    *
    **/
    /*
    public void extractOppWithProjectedAndActualAmount () {
        
        listWithProjectedAndActualAmountWrapper = new List<rrProjectedAndActualWrapper>();
        
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
                    query += fieldName +'= '+ selectedCriteria + 'AND '; 
                }else {                 
                    
                    //Checking for Created date not null
                    if(opportunity.REVvue_CreatedDate__c != null) {
                        
                        //Checking for conditions and field type DATETIME
                        if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.DateTime)
                            query += fieldName +' >= '+ opportunity.REVvue_CreatedDate__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')+' AND '; 
                        
                        //Checking for conditions and field type DATE
                        else if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.Date) {
                            
                            dt1 = opportunity.REVvue_CreatedDate__c.date();
                            query += fieldName +' >=: dt1 AND '; 
                        }
                    }
                    
                    //Checking for null
                    if(opportunity1.REVvue_CreatedDate__c != null) {
                        
                        //Checking for conditions and field type DATETIME
                        if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.DateTime)
                            query += fieldName + '<= '+  opportunity1.REVvue_CreatedDate__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')+' AND '; 
                        
                        //Checking for conditions and field type DATE
                        else if(mapOppFieldWithType.containsKey(fieldName) && mapOppFieldWithType.get(fieldName) == Schema.DisplayType.Date) {
                            
                            dt2 = opportunity1.REVvue_CreatedDate__c.date();
                            query += fieldName +' <=: dt2  AND '; 
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
        
        //Execute query
        searchCriteriaOpportunities = database.query(queryStr); 
        
        List<RevRecOpportunityLineItem__c> listOfRevRecOppLineItems = [SELECT Id, Opportunity__c, RevRecRule__c 
                                                                       FROM RevRecOpportunityLineItem__c 
                                                                       Where Opportunity__c IN :searchCriteriaOpportunities];
        //Initiliazation
        Set<Id> revRecOpportunityLineItemIds = new Set<Id>();
        
        for(RevRecOpportunityLineItem__c item : listOfRevRecOppLineItems) {
            revRecOpportunityLineItemIds.add(item.id);           
        }
        
        List<RevRecProductRule__c> listOfRevRecProductRule = [Select Id, Name, RevRecOpportunityLineItem__r.Opportunity__r.Id, Recognition_Type__c, RevRecOpportunityLineItem__c 
                                                              From RevRecProductRule__c 
                                                              Where (Recognition_Type__c = 'Blended Revenue' OR 
                                                                     Recognition_Type__c = 'Amortized Milestone' OR
                                                                     Recognition_Type__c = 'Milestone') AND
                                                              RevRecOpportunityLineItem__c IN :revRecOpportunityLineItemIds];
        //Initiliazation
        Set<Id> revRecProductRuleIds = new Set<Id>();
        
        for(RevRecProductRule__c productRulesIds : listOfRevRecProductRule) {
            revRecProductRuleIds.add(productRulesIds.id);           
        }
        
        List<RevRecProductRuleMilestone__c> listOfRRProductRuleMilestone = [Select Id, Name, Milestone_Sequence__c, Actual_Amount__c, Projected_Amount__c, RevRecProductRule__c, 
                                                                            RevRecProductRule__r.Recognition_Type__c, RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Id,
                                                                            RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Name,
                                                                            RevRecProductRule__r.RevRecOpportunityLineItem__r.RevRecRule__r.Name
                                                                            From  RevRecProductRuleMilestone__c
                                                                            Where RevRecProductRule__c IN :revRecProductRuleIds];
        
        if(listOfRRProductRuleMilestone.size() > 0) {
            for(RevRecProductRuleMilestone__c rrProductRuleMilestones : listOfRRProductRuleMilestone) {
                if((rrProductRuleMilestones.RevRecProductRule__r.Recognition_Type__c == 'Milestone') || (rrProductRuleMilestones.RevRecProductRule__r.Recognition_Type__c == 'Amortized Milestone')){
                    listWithProjectedAndActualAmountWrapper.add(new rrProjectedAndActualWrapper(rrProductRuleMilestones.RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Name, rrProductRuleMilestones.RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Id, rrProductRuleMilestones.RevRecProductRule__r.RevRecOpportunityLineItem__r.RevRecRule__r.Name, rrProductRuleMilestones.Name, rrProductRuleMilestones.RevRecProductRule__r.Id, rrProductRuleMilestones.Id, rrProductRuleMilestones.Milestone_Sequence__c, rrProductRuleMilestones.Actual_Amount__c, rrProductRuleMilestones.Projected_Amount__c));
                }
            }
        }
        
        List<RevRecProductRuleCategory__c> listOfRRProductRuleCategory = [Select Id, Name, Sequence__c, Recognized_Amount__c, Projected_Amount__c, RevRecProductRule__c, 
                                                                          RevRecProductRule__r.Recognition_Type__c, RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Id,
                                                                          RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Name,
                                                                          RevRecProductRule__r.RevRecOpportunityLineItem__r.RevRecRule__r.Name
                                                                          From  RevRecProductRuleCategory__c
                                                                          Where RevRecProductRule__c IN :revRecProductRuleIds];
        
        if(listOfRRProductRuleCategory.size() > 0) {
            for(RevRecProductRuleCategory__c rrProductRuleCategory : listOfRRProductRuleCategory) {
                if(rrProductRuleCategory.RevRecProductRule__r.Recognition_Type__c == 'Blended Revenue'){
                    listWithProjectedAndActualAmountWrapper.add(new rrProjectedAndActualWrapper(rrProductRuleCategory.RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Name, rrProductRuleCategory.RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Id, rrProductRuleCategory.RevRecProductRule__r.RevRecOpportunityLineItem__r.RevRecRule__r.Name, rrProductRuleCategory.Name, rrProductRuleCategory.RevRecProductRule__r.Id, rrProductRuleCategory.id, rrProductRuleCategory.Sequence__c, rrProductRuleCategory.Recognized_Amount__c, rrProductRuleCategory.Projected_Amount__c));
                }
            }  
        }
    }
*/
    /**
    *  @description    :   List of select options to show the creiteria for filtering.
    *
    *  @return         :   List<SelectOption>
    *
    *  @args           :   
    **/
    /*
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
*/
    /**
    *  @description    :   This is blank method to be called on onchange of selected filter.
    *
    *  @return         :   void
    *
    *  @args           :   
    **/
    /*
    public void changeCriteria() {}
    
    public Pagereference uploadOppWithProjectedAndActualAmount() {
        isShow = false;
        displayPopup = true;
        
        listOfCSVUploadWrapper = new List<CSVUploadedWrapper>();
        Set<String> setOfrrMilestoneOrCategoryId = new Set<String>();
        Map<Id, RevRecProductRuleCategory__c> mapOfOppWithProductRuleWithCategory;
        Map<Id, RevRecProductRuleMilestone__c> mapOfOppWithProductRuleWithMilestone;
        
        //If without selecting csv file you clicked on upload it will give error message.
        if(nameFile == null) {
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'You should select csv file to upload');
            ApexPages.addMessage(errormsg);
            return null;
        }
        //Taking file extension.
        String extension = nameFile.substring(nameFile.lastIndexOf('.')+1);
        
        //Checking if file extension is .csv.
        if(extension == 'csv' ||extension == 'CSV') {
            
            nameFile = contentFile.toString();
            
            //Spliting by new line
            filelines = nameFile.split('\n');
            
            //Spliting values by (,) for checking coloumn size
            fileColumns = filelines[0].split(',');
            
            //If column size is 5 then only it will proceed.
            if(fileColumns.size() == 9) {
                for (Integer i=1;i<filelines.size();i++) {
                    String[] inputvalues = new String[]{};
                        inputvalues = filelines[i].split(',');
                    setOfrrMilestoneOrCategoryId.add(inputvalues[5]);
                    listOfCSVUploadWrapper.add(new CSVUploadedWrapper(inputvalues[1], inputvalues[5], inputvalues[7], inputvalues[8]));
                    System.debug('listOfCSVUploadWrapper...###'+listOfCSVUploadWrapper);
                }
                mapOfOppWithProductRuleWithMilestone = new Map<Id, RevRecProductRuleMilestone__c>();
                mapOfOppWithProductRuleWithCategory = new Map<Id, RevRecProductRuleCategory__c>();
                List<RevRecProductRuleMilestone__c> listToBeUpdatedOfMilestone = new List<RevRecProductRuleMilestone__c>();
                List<RevRecProductRuleCategory__c > listToBeUpdateOfCategory = new List<RevRecProductRuleCategory__c >();
                
                for(RevRecProductRuleMilestone__c rrPRM : [Select Id, Actual_Amount__c, Projected_Amount__c, 
                                                           RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Id
                                                           From RevRecProductRuleMilestone__c
                                                           Where Id IN : setOfrrMilestoneOrCategoryId]) {
                if(!mapOfOppWithProductRuleWithMilestone.containsKey(rrPRM.Id))
                	mapOfOppWithProductRuleWithMilestone.put(rrPRM.Id , new RevRecProductRuleMilestone__c());
                mapOfOppWithProductRuleWithMilestone.get(rrPRM.Id);                                
               	}
                
                for(RevRecProductRuleCategory__c rrPRC : [Select Id, Recognized_Amount__c, Projected_Amount__c, 
                                                          RevRecProductRule__r.RevRecOpportunityLineItem__r.Opportunity__r.Id
                                                          From RevRecProductRuleCategory__c
                                                          Where Id IN : setOfrrMilestoneOrCategoryId]) {
                if(!mapOfOppWithProductRuleWithCategory.containsKey(rrPRC.Id))
                	mapOfOppWithProductRuleWithCategory.put(rrPRC.Id , new RevRecProductRuleCategory__c());
                mapOfOppWithProductRuleWithCategory.get(rrPRC.Id);                                
               	}
                
                for(CSVUploadedWrapper wrapList : listOfCSVUploadWrapper) {
                    if(mapOfOppWithProductRuleWithMilestone.containskey(wrapList.rrMilestoneOrCategoryId)) {
                        if((mapOfOppWithProductRuleWithMilestone.get(wrapList.rrMilestoneOrCategoryId).Actual_Amount__c != Decimal.valueOf(wrapList.actualAmount)) ||
                           (mapOfOppWithProductRuleWithMilestone.get(wrapList.rrMilestoneOrCategoryId).Projected_Amount__c != Decimal.valueOf(wrapList.projectedAmount))) {
                               
                               RevRecProductRuleMilestone__c rrPRMilestone  = new RevRecProductRuleMilestone__c();
                               
                               rrPRMilestone.Id = wrapList.rrMilestoneOrCategoryId;
                               rrPRMilestone.Actual_Amount__c = Decimal.valueOf(wrapList.actualAmount);
                               rrPRMilestone.Projected_Amount__c = Decimal.valueOf(wrapList.projectedAmount);
                               
                               listToBeUpdatedOfMilestone.add(rrPRMilestone);
                           }
                    }
                    
                    if(mapOfOppWithProductRuleWithCategory.containskey(wrapList.rrMilestoneOrCategoryId)) {
                        if((mapOfOppWithProductRuleWithCategory.get(wrapList.rrMilestoneOrCategoryId).Recognized_Amount__c != Decimal.valueOf(wrapList.actualAmount)) ||
                           (mapOfOppWithProductRuleWithCategory.get(wrapList.rrMilestoneOrCategoryId).Projected_Amount__c != Decimal.valueOf(wrapList.projectedAmount))) {
                               
                               RevRecProductRuleCategory__c rrPRCategory  = new RevRecProductRuleCategory__c();
                               
                               rrPRCategory.Id = wrapList.rrMilestoneOrCategoryId;
                               rrPRCategory.Recognized_Amount__c = Decimal.valueOf(wrapList.actualAmount);
                               rrPRCategory.Projected_Amount__c = Decimal.valueOf(wrapList.projectedAmount);
                               
                               listToBeUpdateOfCategory.add(rrPRCategory);
                           }
                    }
                }
                if(listToBeUpdatedOfMilestone.size() > 0)
                    update listToBeUpdatedOfMilestone;
                if(listToBeUpdateOfCategory.size() > 0)
                    update listToBeUpdateOfCategory;
                
                ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.info,'File uploaded successfully');
                ApexPages.addMessage(errormsg);
                
                return null;
            }
            else {
                ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'There should be 9 columns in csv file');
                ApexPages.addMessage(errormsg);
                return null;
            }
        }
        else {
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'File type should be csv type');
            ApexPages.addMessage(errormsg);
            return null;
        }
    }
    
    public void showAllOppWithProjectedAndActualAmount() {
        isShow = true;
    }
    
    public void updateAllOppWithProjectedAndActualAmount() {
        isShow = true;
    }
    
    public PageReference  importCSVFile() {        
        displayPopup = false;
        return null;
    }  
    
    public void cancelPopup() {        
        displayPopup = false; 
    }
    
    public class rrProjectedAndActualWrapper {
        public String OppName {get;set;}
        public Id OppId {get;set;}
        public String rrRule {get;set;}
        public String name {get;set;}
        public Id rrProductRule {get;set;}
        public Id rrMilestoneOrCategoryId {get;set;}
        public Decimal sequence {get;set;}
        public Decimal actualAmount {get;set;}
        public Decimal projectedAmount {get;set;}
        
        public rrProjectedAndActualWrapper(String OppName, Id OppId, String rrRule, String name, Id rrProductRule, Id rrMilestoneOrCategoryId, Decimal sequence, Decimal actualAmount, Decimal projectedAmount) {
            this.OppName = OppName;
            this.OppId = OppId;            
            this.rrRule = rrRule;
            this.name = name;
            this.rrProductRule = rrProductRule;
            this.rrMilestoneOrCategoryId = rrMilestoneOrCategoryId;
            this.sequence = sequence;
            this.actualAmount = actualAmount;
            this.projectedAmount = projectedAmount;
            
        }
    }
    
    public class CSVUploadedWrapper {
        public String OppId {get;set;}
        public String rrMilestoneOrCategoryId {get;set;}
        public String actualAmount {get;set;}
        public String projectedAmount {get;set;}
        
        public CSVUploadedWrapper (String OppId, String rrMilestoneOrCategoryId, String actualAmount, String projectedAmount) {
            this.OppId = OppId;
            this.rrMilestoneOrCategoryId = rrMilestoneOrCategoryId;
            this.actualAmount = actualAmount;
            this.projectedAmount = projectedAmount;
        }
    }
    */
}